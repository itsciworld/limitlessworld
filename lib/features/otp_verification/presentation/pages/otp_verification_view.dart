import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../bloc/auth/auth_bloc.dart';
import '../../../../bloc/auth/auth_event.dart';
import '../../../../components/auth_background.dart';
import '../../../../components/gradient_button.dart';
import '../../../../components/otp_field.dart';
import '../../../../core/app_images/app_images.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../bloc/otp_bloc.dart';
import '../../bloc/otp_event.dart';
import '../../bloc/otp_state.dart';

/// Email verification screen shown right after registration (and on login when
/// the account is still unverified).
///
/// Navigate to it via [AppRoutes.verifyOtp] with [OtpRouteArgs] as `extra`;
/// the router provides the [OtpBloc].
class OtpVerificationView extends StatelessWidget {
  final String email;
  final String name;
  final int expiresInMinutes;

  const OtpVerificationView({
    super.key,
    required this.email,
    required this.name,
    this.expiresInMinutes = 10,
  });

  @override
  Widget build(BuildContext context) {
    return _OtpVerificationBody(
      email: email,
      expiresInMinutes: expiresInMinutes,
    );
  }
}

class _OtpVerificationBody extends StatefulWidget {
  final String email;
  final int expiresInMinutes;

  const _OtpVerificationBody({
    required this.email,
    required this.expiresInMinutes,
  });

  @override
  State<_OtpVerificationBody> createState() => _OtpVerificationBodyState();
}

class _OtpVerificationBodyState extends State<_OtpVerificationBody> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, OtpState state) {
    // The bloc clears the field on a bad code / resend; mirror that here.
    if (state.otp.isEmpty && _otpController.text.isNotEmpty) {
      _otpController.clear();
    }

    if (state.errorMessage != null) {
      AppToast.showError(state.errorMessage!);
    }
    if (state.infoMessage != null) {
      AppToast.showSuccess(state.infoMessage!);
    }

    if (state.isVerified) {
      AppToast.showSuccess('Email verified');
      // Flipping the auth state also satisfies the router guard, so `go` here
      // and the redirect agree on the destination.
      context.read<AuthBloc>().add(const EmailVerified());
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;

    final double logoHeight = isCompact ? 130 : 170;
    final double sectionSpacing = isCompact ? 20 : 28;
    final double titleFontSize = isCompact ? 24 : 28;
    final double bodyFontSize = isCompact ? 13 : 14;

    return BlocConsumer<OtpBloc, OtpState>(
      listener: _onStateChanged,
      builder: (context, state) {
        return PopScope(
          // Leaving mid-verification would strand a half-created account, so
          // send the user back to login deliberately instead.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !state.isBusy) _confirmExit(context);
          },
          child: AuthBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isCompact ? 8 : 12),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: state.isBusy ? null : () => _confirmExit(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(height: isCompact ? 8 : 12),
                Center(
                  child: Image.asset(
                    AppImages.appLogo,
                    width: 280,
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 20),
                Text(
                  'Verify your email',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: titleFontSize,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: bodyFontSize,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(
                        text: widget.email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: bodyFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sectionSpacing),
                Center(
                  child: OtpField(
                    controller: _otpController,
                    enabled: !state.isVerifying,
                    onChanged: (value) =>
                        context.read<OtpBloc>().add(OtpChanged(value)),
                    onCompleted: (_) =>
                        context.read<OtpBloc>().add(const OtpSubmitted()),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'The code expires in ${widget.expiresInMinutes} minutes',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                SizedBox(height: sectionSpacing),
                GradientButton(
                  text: 'Verify',
                  icon: Icons.arrow_forward,
                  isLoading: state.isVerifying,
                  onPressed: state.canSubmit
                      ? () => context.read<OtpBloc>().add(const OtpSubmitted())
                      : null,
                ),
                SizedBox(height: sectionSpacing),
                Center(
                  child: _ResendRow(
                    state: state,
                    bodyFontSize: bodyFontSize,
                  ),
                ),
                SizedBox(height: isCompact ? 16 : 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Leave verification?', style: AppTextStyles.titleLarge),
        content: Text(
          'Your account is created but not verified yet. You can verify later '
          'by signing in again.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Leave',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (leave == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
      context.go(AppRoutes.login);
    }
  }
}

/// "Didn't get the code? Resend" with the cooldown countdown.
class _ResendRow extends StatelessWidget {
  final OtpState state;
  final double bodyFontSize;

  const _ResendRow({required this.state, required this.bodyFontSize});

  @override
  Widget build(BuildContext context) {
    if (state.isResending) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: bodyFontSize,
          ),
        ),
        if (state.resendCooldown > 0)
          Text(
            'Resend in ${state.resendCooldown}s',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
              fontSize: bodyFontSize,
            ),
          )
        else
          TextButton(
            onPressed: state.canResend
                ? () => context.read<OtpBloc>().add(const OtpResendRequested())
                : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Resend code',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: bodyFontSize,
              ),
            ),
          ),
      ],
    );
  }
}
