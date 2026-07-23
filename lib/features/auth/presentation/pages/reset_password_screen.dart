import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../bloc/auth/auth_bloc.dart';
import '../../../../bloc/auth/auth_event.dart';
import '../../../../bloc/auth/auth_state.dart';
import '../../../../components/auth_background.dart';
import '../../../../components/custom_text_field.dart';
import '../../../../components/gradient_button.dart';
import '../../../../components/otp_field.dart';
import '../../../../core/app_images/app_images.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../models/auth_models.dart';

/// Step 2 of password recovery — OTP + new password, hitting
/// POST /api/auth/reset-password.
///
/// On success it pops back to the login screen so the user signs in with the
/// new password.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final int expiresInMinutes;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.expiresInMinutes = 10,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_otpController, _passwordController, _confirmController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isLoading &&
      _otpController.text.length == 6 &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_otpController.text.length != 6) {
      AppToast.showError('Please enter the 6-digit code');
      return;
    }

    context.read<AuthBloc>().add(
          ResetPasswordRequested(
            email: widget.email,
            otp: _otpController.text,
            newPassword: _passwordController.text,
          ),
        );
  }

  String? _validateNewPassword(String? value) => validatePassword(value ?? '');

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 700;
    final double sectionSpacing = isCompact ? 18 : 24;
    final double titleFontSize = isCompact ? 24 : 28;
    final double bodyFontSize = isCompact ? 13 : 14;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = state is AuthLoading);

        if (state is PasswordResetSuccess) {
          AppToast.showSuccess(state.message);
          // Clear the one-shot state before leaving, so the login screen does
          // not start life holding a finished password-reset result.
          context.read<AuthBloc>().add(const AuthStateReset());
          // `go` clears the recovery stack, so back does not lead into a
          // reset flow whose OTP has already been consumed.
          context.go(AppRoutes.login);
        } else if (state is AuthError) {
          AppToast.showError(state.message);
        }
      },
      child: AuthBackground(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isCompact ? 8 : 12),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: _isLoading ? null : () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(height: isCompact ? 8 : 12),
              Center(
                child: Image.asset(
                  AppImages.appLogo,
                  width: 280,
                  height: isCompact ? 120 : 150,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: isCompact ? 12 : 20),
              Text(
                'Reset Password',
                style: AppTextStyles.headlineLarge
                    .copyWith(fontSize: titleFontSize),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: bodyFontSize,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the code we sent to\n'),
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
                  enabled: !_isLoading,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'The code expires in ${widget.expiresInMinutes} minutes',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
              ),
              SizedBox(height: sectionSpacing),
              CustomTextField(
                controller: _passwordController,
                hintText: 'New Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: _validateNewPassword,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _confirmController,
                hintText: 'Confirm New Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: _validateConfirm,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 12),
              Text(
                'Use at least 8 characters with an uppercase letter, a '
                'lowercase letter and a number.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
              SizedBox(height: sectionSpacing),
              GradientButton(
                text: 'Update Password',
                icon: Icons.arrow_forward,
                isLoading: _isLoading,
                onPressed: _canSubmit ? _submit : null,
              ),
              SizedBox(height: isCompact ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
