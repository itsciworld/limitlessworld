import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../service/api_interceptor_service/api_interceptor_service.dart';
import '../models/auth_models.dart';

/// All auth network calls. Errors surface as [ApiException] (already
/// normalized by the interceptor), so callers only ever catch that.
class AuthRepository {
  final ApiInterceptorService _api;
  final SecureStorageService _storage;

  AuthRepository({
    required ApiInterceptorService apiService,
    SecureStorageService? storage,
  })  : _api = apiService,
        _storage = storage ?? SecureStorageService();

  /// POST /api/auth/register — creates the account and returns a token that is
  /// persisted immediately, before email verification.
  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _api.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );

    final result = RegisterResponse.fromJson(_asMap(response.data));

    if (result.token.isNotEmpty) {
      await _api.setAuthToken(result.token);
    }
    // Only the id is persisted; the rest of the profile is re-fetched.
    await _storage.saveUserId(result.user.id);

    return result;
  }

  /// POST /api/auth/login
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    final result = LoginResponse.fromJson(_asMap(response.data));

    if (result.token.isNotEmpty) {
      await _api.setAuthToken(result.token);
    }
    // Only the id is persisted; the rest of the profile is re-fetched.
    await _storage.saveUserId(result.user.id);

    return result;
  }

  /// POST /api/auth/send-otp — email verification code.
  Future<SendOtpResponse> sendOtp(SendOtpRequest request) async {
    final response = await _api.post(
      ApiEndpoints.sendOtp,
      data: request.toJson(),
    );
    return SendOtpResponse.fromJson(_asMap(response.data));
  }

  /// POST /api/auth/verify-otp
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    final response = await _api.post(
      ApiEndpoints.verifyOtp,
      data: request.toJson(),
    );

    // No local mirror to update — the verified flag comes back from
    // /api/users/{id} the next time the profile is loaded.
    return VerifyOtpResponse.fromJson(_asMap(response.data));
  }

  /// POST /api/auth/forgot-password — sends a reset OTP to the email.
  Future<SendOtpResponse> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _api.post(
      ApiEndpoints.forgotPassword,
      data: request.toJson(),
    );
    return SendOtpResponse.fromJson(_asMap(response.data));
  }

  /// POST /api/auth/reset-password — OTP + new password.
  Future<ResetPasswordResponse> resetPassword(
    ResetPasswordRequest request,
  ) async {
    final response = await _api.post(
      ApiEndpoints.resetPassword,
      data: request.toJson(),
    );
    return ResetPasswordResponse.fromJson(_asMap(response.data));
  }

  /// Restore a session from storage, returning the stored user id, or null
  /// when there is no usable session. Profile details are not cached, so the
  /// caller gets an id and nothing more.
  Future<String?> restoreSession() async {
    if (!await _storage.isLoggedIn()) return null;
    return _storage.getUserId();
  }

  /// POST /api/auth/logout — the interceptor attaches the bearer token, and
  /// the server invalidates it.
  ///
  /// The local session is cleared either way: if the call fails the token is
  /// unusable to us regardless, and stranding the user signed-in would be
  /// worse than a token the server still considers live.
  Future<LogoutResponse> logout() async {
    try {
      final response = await _api.post(ApiEndpoints.logout);
      return LogoutResponse.fromJson(_asMap(response.data));
    } finally {
      await _api.removeAuthToken();
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException(
      message: 'Unexpected response from the server. Please try again.',
    );
  }
}
