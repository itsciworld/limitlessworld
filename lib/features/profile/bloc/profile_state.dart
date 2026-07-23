import 'package:equatable/equatable.dart';

import '../models/profile_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// First load — nothing to show yet, so the view renders a spinner.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;

  /// True while a refresh runs on top of already-visible data.
  final bool isRefreshing;

  /// True while a PATCH is in flight.
  final bool isSaving;

  /// One-shot outcomes of a save, cleared by [copyWith] once the UI has
  /// reacted — so a rebuild cannot re-toast or re-navigate.
  final String? successMessage;
  final String? errorMessage;

  const ProfileLoaded({
    required this.profile,
    this.isRefreshing = false,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  ProfileLoaded copyWith({
    ProfileModel? profile,
    bool? isRefreshing,
    bool? isSaving,
    // Passing nothing clears these, which is what every transition after the
    // listener has fired wants.
    String? successMessage,
    String? errorMessage,
  }) =>
      ProfileLoaded(
        profile: profile ?? this.profile,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSaving: isSaving ?? this.isSaving,
        successMessage: successMessage,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        profile,
        isRefreshing,
        isSaving,
        successMessage,
        errorMessage,
      ];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
