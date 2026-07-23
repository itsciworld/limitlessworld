import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/repository/auth_repository.dart';
import 'otp_event.dart';
import 'otp_state.dart';

/// Drives the OTP verification screen: digit entry, verify, resend + cooldown.
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final AuthRepository _authRepository;

  /// Name is only needed for the resend call's payload.
  final String _name;

  Timer? _cooldownTimer;

  /// Seconds a user must wait before asking for another code.
  static const int resendCooldownSeconds = 60;

  OtpBloc({
    required AuthRepository authRepository,
    required String email,
    required String name,
  })  : _authRepository = authRepository,
        _name = name,
        super(OtpState(email: email)) {
    on<OtpScreenStarted>(_onStarted);
    on<OtpChanged>(_onChanged);
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
    on<OtpCooldownTicked>(_onCooldownTicked);
  }

  void _onStarted(OtpScreenStarted event, Emitter<OtpState> emit) {
    // The first code was already sent by the registration flow, so the screen
    // opens with the cooldown already running.
    _startCooldown(emit);
  }

  void _onChanged(OtpChanged event, Emitter<OtpState> emit) {
    emit(state.copyWith(otp: event.otp));
  }

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    if (!state.isComplete) {
      emit(state.copyWith(errorMessage: 'Please enter the 6-digit code'));
      return;
    }
    if (state.isVerifying) return;

    emit(state.copyWith(isVerifying: true));

    try {
      final result = await _authRepository.verifyOtp(
        VerifyOtpRequest(email: state.email, otp: state.otp),
      );

      if (result.verified) {
        emit(state.copyWith(isVerifying: false, isVerified: true));
      } else {
        emit(
          state.copyWith(
            isVerifying: false,
            otp: '',
            errorMessage: 'That code is not valid. Please try again.',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isVerifying: false, otp: '', errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isVerifying: false,
          errorMessage: 'Verification failed. Please try again.',
        ),
      );
    }
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState> emit,
  ) async {
    if (!state.canResend) return;

    emit(state.copyWith(isResending: true));

    try {
      final result = await _authRepository.sendOtp(
        SendOtpRequest(email: state.email, name: _name),
      );

      emit(
        state.copyWith(
          isResending: false,
          otp: '',
          infoMessage: result.sent
              ? 'A new code is on its way to ${state.email}'
              : 'We could not send the code. Please try again.',
        ),
      );
      if (result.sent) _startCooldown(emit);
    } on ApiException catch (e) {
      emit(state.copyWith(isResending: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isResending: false,
          errorMessage: 'Could not resend the code. Please try again.',
        ),
      );
    }
  }

  void _onCooldownTicked(OtpCooldownTicked event, Emitter<OtpState> emit) {
    emit(state.copyWith(resendCooldown: event.secondsLeft));
  }

  void _startCooldown(Emitter<OtpState> emit) {
    _cooldownTimer?.cancel();
    emit(state.copyWith(resendCooldown: resendCooldownSeconds));

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldown - 1;
      if (next <= 0) {
        timer.cancel();
        add(const OtpCooldownTicked(0));
      } else {
        add(OtpCooldownTicked(next));
      }
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
