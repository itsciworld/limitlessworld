import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load the profile — fired when the Profile tab is first opened.
class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

/// Re-load after a pull-to-refresh or a failed first attempt. Unlike
/// [ProfileRequested] this keeps the current data on screen while it runs.
class ProfileRefreshed extends ProfileEvent {
  const ProfileRefreshed();
}

/// Save edited details via PATCH /api/users/{id}.
class ProfileUpdateRequested extends ProfileEvent {
  final String name;
  final int age;
  final String gender;

  const ProfileUpdateRequested({
    required this.name,
    required this.age,
    required this.gender,
  });

  @override
  List<Object?> get props => [name, age, gender];
}
