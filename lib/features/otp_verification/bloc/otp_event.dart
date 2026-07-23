import 'package:equatable/equatable.dart';

abstract class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

/// Start the resend cooldown when the screen opens after registration already
/// sent the first code.
class OtpScreenStarted extends OtpEvent {
  final int expiresInMinutes;

  const OtpScreenStarted({this.expiresInMinutes = 10});

  @override
  List<Object?> get props => [expiresInMinutes];
}

/// Keeps the entered digits in state so the submit button can enable itself.
class OtpChanged extends OtpEvent {
  final String otp;

  const OtpChanged(this.otp);

  @override
  List<Object?> get props => [otp];
}

class OtpSubmitted extends OtpEvent {
  const OtpSubmitted();
}

class OtpResendRequested extends OtpEvent {
  const OtpResendRequested();
}

/// Emitted once per second by the bloc's own timer.
class OtpCooldownTicked extends OtpEvent {
  final int secondsLeft;

  const OtpCooldownTicked(this.secondsLeft);

  @override
  List<Object?> get props => [secondsLeft];
}
