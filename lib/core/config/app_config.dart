import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from environment variables (`.env`).
///
/// Call [initialize] once from `main()` before anything reads these values.
class AppConfig {
  AppConfig._();

  static bool _initialized = false;

  /// Initialize app configuration by loading the `.env` asset.
  static Future<void> initialize() async {
    if (_initialized) return;
    await dotenv.load(fileName: '.env');
    _initialized = true;
  }

  static String _env(String key, String fallback) {
    if (!_initialized) return fallback;
    final value = dotenv.env[key];
    return (value == null || value.isEmpty) ? fallback : value;
  }

  /// API base url, e.g. `https://limitless-api.160-153-179-249.sslip.io`
  static String get baseUrl =>
      _env('BASE_URL', 'https://limitless-api.160-153-179-249.sslip.io');

  /// Request timeout in milliseconds.
  static int get apiTimeout =>
      int.tryParse(_env('API_TIMEOUT', '30000')) ?? 30000;

  static Duration get timeoutDuration => Duration(milliseconds: apiTimeout);
}
