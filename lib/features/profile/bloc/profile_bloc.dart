import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../models/update_profile_request.dart';
import '../repository/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// Loads and refreshes GET /api/users/{id}.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial()) {
    on<ProfileRequested>(_onProfileRequested);
    on<ProfileRefreshed>(_onProfileRefreshed);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
  }

  /// PATCH the editable fields, then fold the result into the visible profile.
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded || current.isSaving) return;

    final request = UpdateProfileRequest(
      name: event.name.trim(),
      age: event.age,
      gender: event.gender,
    );

    final validationError = request.validate();
    if (validationError != null) {
      emit(current.copyWith(errorMessage: validationError));
      return;
    }

    emit(current.copyWith(isSaving: true));

    try {
      final updated = await _profileRepository.updateProfile(request);
      emit(
        ProfileLoaded(
          // The PATCH response omits `assessments`; keeping the list we
          // already have avoids the count silently dropping to zero.
          profile: updated.copyWith(assessments: current.profile.assessments),
          successMessage: 'Profile updated',
        ),
      );
    } on ApiException catch (e) {
      emit(current.copyWith(isSaving: false, errorMessage: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          isSaving: false,
          errorMessage: 'Could not update your profile. Please try again.',
        ),
      );
    }
  }

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    await _load(emit);
  }

  /// Keeps the current profile visible while re-fetching, so a refresh does
  /// not blank the screen.
  Future<void> _onProfileRefreshed(
    ProfileRefreshed event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is ProfileLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const ProfileLoading());
    }
    await _load(emit, previous: current is ProfileLoaded ? current : null);
  }

  Future<void> _load(
    Emitter<ProfileState> emit, {
    ProfileLoaded? previous,
  }) async {
    try {
      final profile = await _profileRepository.getProfile();
      emit(ProfileLoaded(profile: profile));
    } on ApiException catch (e) {
      // A failed refresh should not throw away data the user can still read.
      if (previous != null) {
        emit(previous.copyWith(isRefreshing: false));
      } else {
        emit(ProfileError(message: e.message));
      }
    } catch (_) {
      if (previous != null) {
        emit(previous.copyWith(isRefreshing: false));
      } else {
        emit(
          const ProfileError(
            message: 'Could not load your profile. Please try again.',
          ),
        );
      }
    }
  }
}
