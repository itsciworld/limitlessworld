import 'package:equatable/equatable.dart';

import '../../features/auth/models/auth_models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Sign the user up. On success the bloc immediately fires the send-otp call
/// itself — the UI does not have to chain it.
class RegisterRequested extends AuthEvent {
  final RegisterRequest request;

  const RegisterRequested({required this.request});

  @override
  List<Object?> get props => [request];
}

class LoginRequested extends AuthEvent {
  final LoginRequest request;

  const LoginRequested({required this.request});

  @override
  List<Object?> get props => [request];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Restore a session from secure storage (used by the splash screen).
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Marks the user as fully authenticated once OTP verification succeeds.
class EmailVerified extends AuthEvent {
  const EmailVerified();
}

/// Step 1 of password recovery: POST /api/auth/forgot-password
class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Step 2 of password recovery: POST /api/auth/reset-password
class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword];
}

/// Return the bloc to a neutral state after a screen has consumed a one-shot
/// state (error toast, success navigation).
class AuthStateReset extends AuthEvent {
  const AuthStateReset();
}
