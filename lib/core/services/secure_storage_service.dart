import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted store for the session.
///
/// Deliberately holds only the tokens and the user id — every other profile
/// field is fetched from `/api/users/{id}` so the app can never show a stale
/// name, age or verification flag.
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  /// True when both a token and a user id are present — either alone is not a
  /// usable session, since every profile call needs the id.
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  /// Wipe everything (logout / unrecoverable session).
  Future<void> clearAll() => _storage.deleteAll();

  /// Drop tokens but keep the user id.
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
