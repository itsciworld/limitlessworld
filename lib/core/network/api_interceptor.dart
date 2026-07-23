import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../services/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// Single interceptor responsible for three things:
///
/// 1. attaching the stored bearer token to every outgoing request,
/// 2. refreshing an expired token once and replaying the failed request,
/// 3. normalizing every failure into an [ApiException] so repositories never
///    have to read Dio internals.
class ApiInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;

  /// Called when the token is gone/unrecoverable so the app can send the user
  /// back to login.
  final VoidCallback? onSessionExpired;

  /// Only one refresh runs at a time; parallel 401s all await this future.
  Future<bool>? _refreshInFlight;

  ApiInterceptor(
    this._dio, {
    SecureStorageService? storage,
    this.onSessionExpired,
  }) : _storage = storage ?? SecureStorageService();

  /// Endpoints that must never carry a token or trigger a refresh — a 401 from
  /// these means "wrong credentials", not "expired session".
  static const _publicPaths = <String>{
    ApiEndpoints.register,
    ApiEndpoints.login,
    ApiEndpoints.refresh,
    ApiEndpoints.sendOtp,
    ApiEndpoints.verifyOtp,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
  };

  bool _isPublic(String path) => _publicPaths.any(path.endsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';

    if (!_isPublic(options.path) &&
        !options.headers.containsKey('Authorization')) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    _log('➡️  ${options.method} ${options.path}  body=${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log('✅ ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    _log('❌ ${err.response?.statusCode} $path  ${err.response?.data}');

    final isExpiredSession =
        err.response?.statusCode == 401 &&
        !_isPublic(path) &&
        err.requestOptions.extra['retried'] != true;

    if (isExpiredSession) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        try {
          return handler.resolve(await _retry(err.requestOptions));
        } on DioException catch (e) {
          return handler.next(_wrap(e));
        }
      }
      await _storage.clearAll();
      onSessionExpired?.call();
    }

    handler.next(_wrap(err));
  }

  /// Attach a normalized [ApiException] without losing the original Dio data.
  DioException _wrap(DioException err) =>
      err.copyWith(error: ApiException.fromDio(err));

  /// Exchange the refresh token for a fresh access token. Returns false when
  /// there is nothing to refresh with or the server rejects it.
  Future<bool> _refreshToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // A bare Dio instance — going through _dio would re-enter this
      // interceptor and can loop.
      final response =
          await Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              connectTimeout: AppConfig.timeoutDuration,
              receiveTimeout: AppConfig.timeoutDuration,
            ),
          ).post(
            ApiEndpoints.refresh,
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );

      final data = response.data;
      final newToken = data is Map
          ? data['token'] ?? data['accessToken']
          : null;
      if (newToken is! String || newToken.isEmpty) return false;

      await _storage.saveAccessToken(newToken);
      final newRefresh = data is Map ? data['refreshToken'] : null;
      if (newRefresh is String && newRefresh.isNotEmpty) {
        await _storage.saveRefreshToken(newRefresh);
      }
      _log('🔄 token refreshed');
      return true;
    } catch (e) {
      _log('🔄 token refresh failed: $e');
      return false;
    }
  }

  /// Replay the original request with the new token, marked so a second 401
  /// cannot start another refresh cycle.
  Future<Response> _retry(RequestOptions options) async {
    final token = await _storage.getAccessToken();
    return _dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      cancelToken: options.cancelToken,
      options: Options(
        method: options.method,
        headers: {...options.headers, 'Authorization': 'Bearer $token'},
        responseType: options.responseType,
        contentType: options.contentType,
        extra: {...options.extra, 'retried': true},
      ),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
