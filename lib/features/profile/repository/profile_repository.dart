import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../service/api_interceptor_service/api_interceptor_service.dart';
import '../models/profile_model.dart';
import '../models/update_profile_request.dart';

/// Profile network calls.
///
/// Reads the user id from secure storage itself, so callers (and the bloc)
/// never have to thread it through — it is the only profile field the app
/// persists.
class ProfileRepository {
  final ApiInterceptorService _api;
  final SecureStorageService _storage;

  ProfileRepository({
    required ApiInterceptorService apiService,
    SecureStorageService? storage,
  })  : _api = apiService,
        _storage = storage ?? SecureStorageService();

  /// GET /api/users/{id} — the interceptor attaches the bearer token.
  ///
  /// Pass [userId] to override the stored one; otherwise it is read from
  /// secure storage.
  Future<ProfileModel> getProfile({String? userId}) async {
    final id = userId ?? await _storage.getUserId();
    if (id == null || id.isEmpty) {
      throw const ApiException(
        message: 'We could not identify your account. Please sign in again.',
        type: ApiErrorType.unauthorized,
      );
    }

    final response = await _api.get(ApiEndpoints.userById(id));
    return _parseProfile(response.data);
  }

  /// PATCH /api/users/{id} — updates name, age and gender.
  ///
  /// The response is the full user object but *without* `assessments`, so the
  /// caller is expected to keep the list it already had rather than trust the
  /// empty default. [ProfileBloc] does exactly that.
  Future<ProfileModel> updateProfile(
    UpdateProfileRequest request, {
    String? userId,
  }) async {
    final id = userId ?? await _storage.getUserId();
    if (id == null || id.isEmpty) {
      throw const ApiException(
        message: 'We could not identify your account. Please sign in again.',
        type: ApiErrorType.unauthorized,
      );
    }

    final response = await _api.patch(
      ApiEndpoints.userById(id),
      data: request.toJson(),
    );
    return _parseProfile(response.data);
  }

  ProfileModel _parseProfile(dynamic data) {
    if (data is! Map) {
      throw const ApiException(
        message: 'Unexpected response from the server. Please try again.',
      );
    }
    return ProfileModel.fromJson(Map<String, dynamic>.from(data));
  }
}
