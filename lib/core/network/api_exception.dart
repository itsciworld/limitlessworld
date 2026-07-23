import 'package:dio/dio.dart';

/// The kind of failure a request hit, so callers can branch without
/// string-matching messages.
enum ApiErrorType {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  cancelled,
  certificate,
  unknown,
}

/// A normalized error every repository throws.
///
/// [message] is always safe to show to the user — the interceptor pulls the
/// server's own `error` / `message` field when present, otherwise it falls
/// back to a friendly default for the status code.
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.type = ApiErrorType.unknown,
    this.statusCode,
    this.data,
  });

  bool get isUnauthorized => type == ApiErrorType.unauthorized;
  bool get isNetwork =>
      type == ApiErrorType.network || type == ApiErrorType.timeout;

  /// Rebuild an [ApiException] out of a [DioException].
  ///
  /// The interceptor stores the exception on `DioException.error`, so in the
  /// normal path this just unwraps it; the mapping below is the safety net for
  /// errors raised before the interceptor ran.
  factory ApiException.fromDio(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'The request timed out. Please try again.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection. Please check your network.',
          type: ApiErrorType.network,
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Could not establish a secure connection.',
          type: ApiErrorType.certificate,
        );
      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request cancelled.',
          type: ApiErrorType.cancelled,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: messageFromResponse(e.response) ?? defaultMessageFor(status),
          type: typeFromStatus(status),
          statusCode: status,
          data: e.response?.data,
        );
      default:
        return ApiException(
          message: e.message ?? 'Something went wrong. Please try again.',
          type: ApiErrorType.unknown,
          statusCode: status,
        );
    }
  }

  /// Pull the human-readable message the backend sent, if any.
  static String? messageFromResponse(Response? response) {
    final data = response?.data;
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) return data;

    if (data is Map) {
      for (final key in const ['error', 'message', 'detail', 'msg']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      // Laravel/Express style: {"errors": {"email": ["already taken"]}}
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
    }
    return null;
  }

  static ApiErrorType typeFromStatus(int? status) {
    switch (status) {
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 409:
        return ApiErrorType.conflict;
      case 422:
        return ApiErrorType.validation;
      case 429:
        return ApiErrorType.rateLimited;
      default:
        if (status != null && status >= 500) return ApiErrorType.server;
        return ApiErrorType.unknown;
    }
  }

  static String defaultMessageFor(int? status) {
    switch (status) {
      case 400:
        return 'Invalid request. Please check your details.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to do that.';
      case 404:
        return 'We couldn\'t find what you were looking for.';
      case 409:
        return 'That already exists.';
      case 422:
        return 'Please check your input and try again.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
        return 'Something went wrong on our end. Please try again.';
      case 502:
      case 503:
      case 504:
        return 'The service is temporarily unavailable. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => message;
}
