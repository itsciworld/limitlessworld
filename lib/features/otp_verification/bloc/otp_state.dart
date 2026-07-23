import 'package:equatable/equatable.dart';

/// One state class rather than a hierarchy: the OTP screen needs the entered
/// digits, the cooldown and the busy flag visible at the same time, and a
/// sealed hierarchy would force the UI to re-derive them on every transition.
class OtpState extends Equatable {
  final String email;
  final String otp;
  final bool isVerifying;
  final bool isResending;

  /// Seconds until "Resend code" becomes tappable again.
  final int resendCooldown;

  /// One-shot flags, cleared by the UI listener after it reacts.
  final String? errorMessage;
  final String? infoMessage;
  final bool isVerified;

  const OtpState({
    required this.email,
    this.otp = '',
    this.isVerifying = false,
    this.isResending = false,
    this.resendCooldown = 0,
    this.errorMessage,
    this.infoMessage,
    this.isVerified = false,
  });

  static const int otpLength = 6;

  bool get isComplete => otp.length == otpLength;
  bool get canSubmit => isComplete && !isVerifying;
  bool get canResend => resendCooldown == 0 && !isResending && !isVerifying;
  bool get isBusy => isVerifying || isResending;

  OtpState copyWith({
    String? otp,
    bool? isVerifying,
    bool? isResending,
    int? resendCooldown,
    bool? isVerified,
    // Messages are one-shot: passing nothing clears them, which is what every
    // transition after the listener has fired wants.
    String? errorMessage,
    String? infoMessage,
  }) {
    return OtpState(
      email: email,
      otp: otp ?? this.otp,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
        email,
        otp,
        isVerifying,
        isResending,
        resendCooldown,
        errorMessage,
        infoMessage,
        isVerified,
      ];
}
