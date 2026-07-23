import 'package:equatable/equatable.dart';

/// Response of GET /api/users/{id}.
///
/// The user object is returned flat (no `user` wrapper) with an extra
/// `assessments` list appended.
class ProfileModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final bool passwordResetRequired;
  final String paymentStatus;
  final int age;
  final String gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Kept raw until the assessment contract is defined — the sample response
  /// only ever shows an empty list.
  final List<Map<String, dynamic>> assessments;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
    this.passwordResetRequired = false,
    this.paymentStatus = 'pending',
    this.age = 0,
    this.gender = '',
    this.createdAt,
    this.updatedAt,
    this.assessments = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawAssessments = json['assessments'];

    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      passwordResetRequired: json['password_reset_required'] ?? false,
      paymentStatus: json['payment_status'] ?? 'pending',
      age: json['age'] is int
          ? json['age']
          : int.tryParse('${json['age']}') ?? 0,
      gender: json['gender'] ?? '',
      createdAt: DateTime.tryParse('${json['created_at']}'),
      updatedAt: DateTime.tryParse('${json['updated_at']}'),
      assessments: rawAssessments is List
          ? rawAssessments
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }

  ProfileModel copyWith({
    String? name,
    int? age,
    String? gender,
    List<Map<String, dynamic>>? assessments,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      emailVerified: emailVerified,
      passwordResetRequired: passwordResetRequired,
      paymentStatus: paymentStatus,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assessments: assessments ?? this.assessments,
    );
  }

  /// Initials for the avatar, e.g. "Ravi Saini" -> "RS".
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        emailVerified,
        passwordResetRequired,
        paymentStatus,
        age,
        gender,
        createdAt,
        updatedAt,
        assessments,
      ];
}
