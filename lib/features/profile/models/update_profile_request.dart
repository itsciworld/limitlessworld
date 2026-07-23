import 'package:equatable/equatable.dart';

/// Body of PATCH /api/users/{id}.
///
/// The endpoint only accepts these three fields — email, verification and
/// payment status are server-owned and cannot be changed from the app.
class UpdateProfileRequest extends Equatable {
  final String name;
  final int age;
  final String gender;

  const UpdateProfileRequest({
    required this.name,
    required this.age,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
      };

  /// Returns the first problem found, or null when the payload is good.
  /// Mirrors the signup rules so a profile cannot be edited into a state
  /// registration would have rejected.
  String? validate() {
    if (name.trim().length < 2) return 'Please enter your full name';
    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Please enter a valid age';
    if (gender.isEmpty) return 'Please select your gender';
    return null;
  }

  @override
  List<Object?> get props => [name, age, gender];
}
