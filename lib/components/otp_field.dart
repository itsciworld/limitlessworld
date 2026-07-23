import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// The app's 6-digit OTP input, themed to match [CustomTextField].
///
/// Used by both email verification and password reset so the two screens look
/// and behave identically.
class OtpField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool hasError;
  final int length;

  const OtpField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.hasError = false,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Shrink the boxes on narrow phones so six of them still fit on one row.
    final width = MediaQuery.of(context).size.width;
    final boxWidth = width < 360 ? 42.0 : 52.0;
    final boxHeight = width < 360 ? 52.0 : 60.0;

    final defaultTheme = PinTheme(
      width: boxWidth,
      height: boxHeight,
      textStyle: AppTextStyles.headlineMedium.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.borderColor,
        ),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      // Lets the OS offer the code from its one-time-code autofill banner.
      autofillHints: const [AutofillHints.oneTimeCode],
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      closeKeyboardWhenCompleted: true,
      onChanged: onChanged,
      onCompleted: onCompleted,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyDecorationWith(
        border: Border.all(color: AppColors.borderActive, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 12,
          ),
        ],
      ),
      submittedPinTheme: defaultTheme.copyDecorationWith(
        border: Border.all(color: AppColors.primaryBlue),
      ),
      errorPinTheme: defaultTheme.copyDecorationWith(
        border: Border.all(color: AppColors.error),
      ),
      separatorBuilder: (_) => SizedBox(width: width < 360 ? 6 : 10),
    );
  }
}
