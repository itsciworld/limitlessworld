/// Every route in the app, in one place.
///
/// Screens that need data carry it in the query string rather than in
/// go_router's `extra`: `extra` is dropped whenever the router re-parses the
/// current location (which every auth state change triggers via
/// `refreshListenable`), and a half-built screen is worse than a long URL.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Signed-in tabs, hosted by MainShell's bottom navigation bar.
  static const String home = '/home';
  static const String profile = '/profile';

  /// Nested under [profile] so the bottom bar stays visible while editing.
  static const String profileEdit = '/profile/edit';

  /// Path segment for the nested route definition.
  static const String profileEditSegment = 'edit';

  /// Query keys, shared by the builders below and the route definitions.
  static const String qEmail = 'email';
  static const String qName = 'name';
  static const String qExpires = 'expires';

  /// `/verify-otp?email=…&name=…&expires=…`
  static String verifyOtpPath({
    required String email,
    required String name,
    int expiresInMinutes = 10,
  }) {
    return Uri(
      path: verifyOtp,
      queryParameters: {
        qEmail: email,
        qName: name,
        qExpires: '$expiresInMinutes',
      },
    ).toString();
  }

  /// `/reset-password?email=…&expires=…`
  static String resetPasswordPath({
    required String email,
    int expiresInMinutes = 10,
  }) {
    return Uri(
      path: resetPassword,
      queryParameters: {qEmail: email, qExpires: '$expiresInMinutes'},
    ).toString();
  }

  /// `/forgot-password[?email=…]` — the email only pre-fills the field.
  static String forgotPasswordPath({String? email}) {
    if (email == null || email.isEmpty) return forgotPassword;
    return Uri(
      path: forgotPassword,
      queryParameters: {qEmail: email},
    ).toString();
  }
}

class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String verifyOtp = 'verifyOtp';
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String profileEdit = 'profileEdit';
}
