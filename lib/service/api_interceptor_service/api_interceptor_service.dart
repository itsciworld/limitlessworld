import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_interceptor.dart';
import '../../core/services/secure_storage_service.dart';

/// Thin Dio facade used by every repository.
///
/// All auth-header, refresh and error-normalization logic lives in
/// [ApiInterceptor]; this class just exposes the HTTP verbs and rethrows a
/// clean [ApiException] so callers never touch [DioException].
class ApiInterceptorService {
  late final Dio _dio;
  final String baseUrl;
  final SecureStorageService _storage;

  ApiInterceptorService({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    VoidCallback? onSessionExpired,
    SecureStorageService? storage,
    Map<String, dynamic>? headers,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _storage = storage ?? SecureStorageService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: connectTimeout ?? AppConfig.timeoutDuration,
        receiveTimeout: receiveTimeout ?? AppConfig.timeoutDuration,
        sendTimeout: sendTimeout ?? AppConfig.timeoutDuration,
        headers: headers ??
            {'Content-Type': 'application/json', 'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      ApiInterceptor(
        _dio,
        storage: _storage,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  /// Underlying client, for the rare case a caller needs it.
  Dio get dio => _dio;

  /// Set the token for the current session *and* persist it.
  Future<void> setAuthToken(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    await _storage.saveAccessToken(token);
  }

  /// Drop the token from headers and storage.
  Future<void> removeAuthToken() async {
    _dio.options.headers.remove('Authorization');
    await _storage.clearAll();
  }

  void updateHeaders(Map<String, dynamic> headers) =>
      _dio.options.headers.addAll(headers);

  void addInterceptor(Interceptor interceptor) =>
      _dio.interceptors.add(interceptor);

  // ==================== HTTP METHODS ====================

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) =>
      _guard(
        () => _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        ),
      );

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      _guard(
        () => _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        ),
      );

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _guard(
        () => _dio.put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _guard(
        () => _dio.patch(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _guard(
        () => _dio.delete(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ),
      );

  Future<Response> upload(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) =>
      _guard(
        () => _dio.post(
          path,
          data: formData,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
        ),
      );

  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) =>
      _guard(
        () => _dio.download(
          urlPath,
          savePath,
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
        ),
      );

  /// Run a Dio call and translate any failure into an [ApiException].
  Future<Response> _guard(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Something went wrong. Please try again. $e');
    }
  }

  void close({bool force = false}) => _dio.close(force: force);
}
