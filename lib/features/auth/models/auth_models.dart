import 'package:equatable/equatable.dart';

// =============================================================================
// Requests
// =============================================================================

/// POST /api/auth/register
class RegisterRequest extends Equatable {
  final String name;
  final String email;
  final int age;
  final String gender;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'password': password,
      };

  /// Returns the first problem found, or null when the payload is good.
  String? validate() {
    if (name.trim().length < 2) return 'Please enter your full name';
    if (!isValidEmail(email)) return 'Please enter a valid email address';
    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Please enter a valid age';
    if (gender.isEmpty) return 'Please select your gender';
    return validatePassword(password);
  }

  @override
  List<Object?> get props => [name, email, age, gender, password];
}

/// POST /api/auth/login
class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};

  String? validate() {
    if (!isValidEmail(email)) return 'Please enter a valid email address';
    if (password.isEmpty) return 'Password is required';
    return null;
  }

  @override
  List<Object?> get props => [email, password];
}

/// POST /api/auth/send-otp
class SendOtpRequest extends Equatable {
  final String email;
  final String name;

  const SendOtpRequest({required this.email, required this.name});

  Map<String, dynamic> toJson() => {'email': email, 'name': name};

  @override
  List<Object?> get props => [email, name];
}

/// POST /api/auth/verify-otp
class VerifyOtpRequest extends Equatable {
  final String email;
  final String otp;

  const VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};

  @override
  List<Object?> get props => [email, otp];
}

/// POST /api/auth/forgot-password
class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};

  @override
  List<Object?> get props => [email];
}

/// POST /api/auth/reset-password
class ResetPasswordRequest extends Equatable {
  final String email;
  final String otp;
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      };

  @override
  List<Object?> get props => [email, otp, newPassword];
}

// =============================================================================
// Responses
// =============================================================================

/// The user object returned by register / login / reset-password.
class UserModel extends Equatable {
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

  const UserModel({
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'email_verified': emailVerified,
        'password_reset_required': passwordResetRequired,
        'payment_status': paymentStatus,
        'age': age,
        'gender': gender,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserModel copyWith({bool? emailVerified, String? paymentStatus}) => UserModel(
        id: id,
        name: name,
        email: email,
        emailVerified: emailVerified ?? this.emailVerified,
        passwordResetRequired: passwordResetRequired,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        age: age,
        gender: gender,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

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
      ];
}

/// Response of POST /api/auth/register.
///
/// `token` is issued right away even though the email is not verified yet, so
/// it is stored immediately and used for the verification calls.
class RegisterResponse extends Equatable {
  final UserModel user;
  final String? tempPassword;
  final String token;

  const RegisterResponse({
    required this.user,
    this.tempPassword,
    required this.token,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        user: UserModel.fromJson(
          Map<String, dynamic>.from(json['user'] ?? const {}),
        ),
        tempPassword: json['tempPassword'],
        token: json['token'] ?? '',
      );

  @override
  List<Object?> get props => [user, tempPassword, token];
}

/// Response of POST /api/auth/login.
class LoginResponse extends Equatable {
  final String token;
  final UserModel user;

  /// Present in the contract but not modelled yet — kept raw so the assessment
  /// feature can parse it when it lands.
  final Map<String, dynamic>? latestAssessment;

  const LoginResponse({
    required this.token,
    required this.user,
    this.latestAssessment,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] ?? '',
        user: UserModel.fromJson(
          Map<String, dynamic>.from(json['user'] ?? const {}),
        ),
        latestAssessment: json['latestAssessment'] is Map
            ? Map<String, dynamic>.from(json['latestAssessment'])
            : null,
      );

  @override
  List<Object?> get props => [token, user, latestAssessment];
}

/// Response of POST /api/auth/send-otp and /api/auth/forgot-password.
class SendOtpResponse extends Equatable {
  final bool sent;
  final int expiresInMinutes;

  const SendOtpResponse({required this.sent, this.expiresInMinutes = 10});

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      SendOtpResponse(
        sent: json['sent'] ?? false,
        expiresInMinutes: json['expiresInMinutes'] ?? 10,
      );

  @override
  List<Object?> get props => [sent, expiresInMinutes];
}

/// Response of POST /api/auth/verify-otp.
class VerifyOtpResponse extends Equatable {
  final bool verified;
  final bool emailVerified;

  const VerifyOtpResponse({
    required this.verified,
    required this.emailVerified,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        verified: json['verified'] ?? false,
        emailVerified: json['emailVerified'] ?? false,
      );

  @override
  List<Object?> get props => [verified, emailVerified];
}

/// Response of POST /api/auth/logout.
class LogoutResponse extends Equatable {
  final bool success;
  final String message;

  const LogoutResponse({
    required this.success,
    this.message = 'You have been signed out.',
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) => LogoutResponse(
        success: json['success'] ?? false,
        message: json['message'] is String && (json['message'] as String).isNotEmpty
            ? json['message']
            : 'You have been signed out.',
      );

  @override
  List<Object?> get props => [success, message];
}

/// Response of POST /api/auth/reset-password.
class ResetPasswordResponse extends Equatable {
  final bool success;
  final UserModel? user;

  const ResetPasswordResponse({required this.success, this.user});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ResetPasswordResponse(
        success: json['success'] ?? false,
        user: json['user'] is Map
            ? UserModel.fromJson(Map<String, dynamic>.from(json['user']))
            : null,
      );

  @override
  List<Object?> get props => [success, user];
}

// =============================================================================
// Shared validation
// =============================================================================

final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

/// One password rule for the whole app: signup and reset must agree, otherwise
/// a user can set a password on one screen that the other screen rejects.
String? validatePassword(String password) {
  if (password.isEmpty) return 'Password is required';
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'Password must include an uppercase letter';
  }
  if (!password.contains(RegExp(r'[a-z]'))) {
    return 'Password must include a lowercase letter';
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Password must include a number';
  }
  return null;
}
