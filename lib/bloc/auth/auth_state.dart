import 'package:equatable/equatable.dart';

import '../../features/auth/models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Signed in, with a token and a user id in storage.
class Authenticated extends AuthState {
  /// Always known — it is the one profile field the app persists.
  final String userId;
  final String token;

  /// Only set when login/register just returned it. Null after a cold start,
  /// because profile details are never cached — screens that need them load
  /// from `/api/users/{id}`.
  final UserModel? user;

  const Authenticated({
    required this.userId,
    required this.token,
    this.user,
  });

  @override
  List<Object?> get props => [userId, token, user];
}

class Unauthenticated extends AuthState {
  /// Set only when the user actively signed out, so the app can toast the
  /// server's own wording. Null on a plain "no session found" check, which
  /// must stay silent.
  final String? message;

  const Unauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// Registration succeeded and the verification OTP was sent. The UI navigates
/// to the OTP screen from here.
class RegistrationSuccess extends AuthState {
  final UserModel user;
  final String token;
  final int otpExpiresInMinutes;

  /// False when the account was created but the OTP email failed to go out —
  /// the user can still resend from the OTP screen.
  final bool otpSent;

  const RegistrationSuccess({
    required this.user,
    required this.token,
    this.otpExpiresInMinutes = 10,
    this.otpSent = true,
  });

  @override
  List<Object?> get props => [user, token, otpExpiresInMinutes, otpSent];
}

/// forgot-password succeeded; a reset OTP is in the user's inbox.
class PasswordResetOtpSent extends AuthState {
  final String email;
  final int expiresInMinutes;

  const PasswordResetOtpSent({
    required this.email,
    this.expiresInMinutes = 10,
  });

  @override
  List<Object?> get props => [email, expiresInMinutes];
}

/// reset-password succeeded; the user can sign in with the new password.
class PasswordResetSuccess extends AuthState {
  final String message;

  const PasswordResetSuccess({
    this.message = 'Password updated. Please sign in.',
  });

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  final int? statusCode;

  const AuthError({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class SessionExpired extends AuthState {
  final String message;

  const SessionExpired({
    this.message = 'Your session has expired. Please log in again.',
  });

  @override
  List<Object?> get props => [message];
}
