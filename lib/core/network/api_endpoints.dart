/// Every API path used by the app, relative to [AppConfig.baseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  static const String _auth = '/api/auth';

  // Registration & login
  static const String register = '$_auth/register';
  static const String login = '$_auth/login';
  static const String logout = '$_auth/logout';
  static const String refresh = '$_auth/refresh';
  static const String me = '$_auth/me';

  // Email verification (OTP)
  static const String sendOtp = '$_auth/send-otp';
  static const String verifyOtp = '$_auth/verify-otp';

  // Password recovery
  static const String forgotPassword = '$_auth/forgot-password';
  static const String resetPassword = '$_auth/reset-password';

  // Users
  static const String _users = '/api/users';

  /// GET /api/users/{id} — full profile, requires the bearer token.
  static String userById(String id) => '$_users/$id';
}
