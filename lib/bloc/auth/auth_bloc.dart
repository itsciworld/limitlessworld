import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_exception.dart';
import '../../features/auth/models/auth_models.dart';
import '../../features/auth/repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Owns registration, login, session restore and password recovery.
///
/// OTP entry itself lives in its own feature bloc; this bloc only kicks off the
/// first send-otp call after registration and reacts to the verified result.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  /// Held between registration and verification so [EmailVerified] can emit a
  /// complete [Authenticated] state without another round-trip.
  UserModel? _pendingUser;
  String? _pendingToken;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<RegisterRequested>(_onRegisterRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<EmailVerified>(_onEmailVerified);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthStateReset>((_, emit) => emit(const AuthInitial()));
  }

  /// Register, then send the verification OTP without any further user action.
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    final validationError = event.request.validate();
    if (validationError != null) {
      emit(AuthError(message: validationError));
      return;
    }

    emit(const AuthLoading(message: 'Creating your account...'));

    try {
      final result = await _authRepository.register(event.request);
      _pendingUser = result.user;
      _pendingToken = result.token;

      emit(const AuthLoading(message: 'Sending verification code...'));

      // The account already exists at this point. If the OTP email fails we
      // still move the user forward — they can resend from the OTP screen.
      SendOtpResponse? otp;
      try {
        otp = await _authRepository.sendOtp(
          SendOtpRequest(
            email: result.user.email,
            name: result.user.name,
          ),
        );
      } on ApiException {
        otp = null;
      }

      emit(
        RegistrationSuccess(
          user: result.user,
          token: result.token,
          otpExpiresInMinutes: otp?.expiresInMinutes ?? 10,
          otpSent: otp?.sent ?? false,
        ),
      );
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(AuthError(message: 'Registration failed. Please try again. $e'));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final validationError = event.request.validate();
    if (validationError != null) {
      emit(AuthError(message: validationError));
      return;
    }

    emit(const AuthLoading(message: 'Signing in...'));

    try {
      // The repository has already persisted the token by the time this
      // returns. Verification is a registration-time step only, so an
      // unverified account still goes straight through.
      final result = await _authRepository.login(event.request);
      emit(
        Authenticated(
          userId: result.user.id,
          token: result.token,
          user: result.user,
        ),
      );
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(AuthError(message: 'Sign in failed. Please try again. $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));
    _pendingUser = null;
    _pendingToken = null;

    // The repository clears the local session even if the call fails, so the
    // user always ends up signed out — only the message differs.
    String message;
    try {
      message = (await _authRepository.logout()).message;
    } on ApiException catch (e) {
      // A rejected token is already invalid, which is exactly what logout
      // wanted; reporting it as an error would only confuse the user.
      message = (e.isNetwork || e.isUnauthorized)
          ? 'Signed out on this device.'
          : e.message;
    } catch (_) {
      message = 'Signed out on this device.';
    }

    emit(Unauthenticated(message: message));
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final userId = await _authRepository.restoreSession();
      if (userId == null) {
        emit(const Unauthenticated());
        return;
      }
      // Only the id survives a cold start; the profile screen fetches the
      // rest from /api/users/{id}.
      emit(Authenticated(userId: userId, token: ''));
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  /// The OTP feature calls this once the server confirms verification.
  Future<void> _onEmailVerified(
    EmailVerified event,
    Emitter<AuthState> emit,
  ) async {
    final user = _pendingUser;
    if (user == null) {
      // Nothing cached (e.g. hot restart mid-flow) — send them to login.
      emit(const Unauthenticated());
      return;
    }

    emit(
      Authenticated(
        userId: user.id,
        token: _pendingToken ?? '',
        user: user.copyWith(emailVerified: true),
      ),
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    if (!isValidEmail(email)) {
      emit(const AuthError(message: 'Please enter a valid email address'));
      return;
    }

    emit(const AuthLoading(message: 'Sending reset code...'));

    try {
      final result = await _authRepository.forgotPassword(
        ForgotPasswordRequest(email: email),
      );
      emit(
        PasswordResetOtpSent(
          email: email,
          expiresInMinutes: result.expiresInMinutes,
        ),
      );
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(AuthError(message: 'Could not send the reset code. $e'));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final passwordError = validatePassword(event.newPassword);
    if (passwordError != null) {
      emit(AuthError(message: passwordError));
      return;
    }
    if (event.otp.length < 6) {
      emit(const AuthError(message: 'Please enter the 6-digit code'));
      return;
    }

    emit(const AuthLoading(message: 'Updating your password...'));

    try {
      final result = await _authRepository.resetPassword(
        ResetPasswordRequest(
          email: event.email,
          otp: event.otp,
          newPassword: event.newPassword,
        ),
      );

      if (!result.success) {
        emit(const AuthError(message: 'Could not reset the password.'));
        return;
      }
      emit(const PasswordResetSuccess());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(AuthError(message: 'Password reset failed. $e'));
    }
  }
}
