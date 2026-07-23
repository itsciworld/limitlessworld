import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../bloc/auth/auth_bloc.dart';
import '../../../../bloc/auth/auth_event.dart';
import '../../../../bloc/auth/auth_state.dart';
import '../../../../components/auth_background.dart';
import '../../../../components/custom_text_field.dart';
import '../../../../components/gradient_button.dart';
import '../../../../core/app_images/app_images.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../models/auth_models.dart';

/// Step 1 of password recovery — asks for the email and triggers
/// POST /api/auth/forgot-password.
class ForgotPasswordScreen extends StatefulWidget {
  /// Pre-fills the field with whatever the user typed on the login screen.
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!isValidEmail(value)) return 'Please enter a valid email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 700;
    final double sectionSpacing = isCompact ? 20 : 28;
    final double titleFontSize = isCompact ? 24 : 28;
    final double bodyFontSize = isCompact ? 13 : 14;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // This screen stays mounted under the reset screen, and both listen to
        // the same bloc. Without this, a reset-password result would also be
        // handled here — showing the toast twice.
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

        setState(() => _isLoading = state is AuthLoading);

        if (state is PasswordResetOtpSent) {
          AppToast.showSuccess('Reset code sent to ${state.email}');
          context.push(
            AppRoutes.resetPasswordPath(
              email: state.email,
              expiresInMinutes: state.expiresInMinutes,
            ),
          );
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
                onPressed:
                    _isLoading ? null : () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(height: isCompact ? 8 : 12),
              Center(
                child: Image.asset(
                  AppImages.appLogo,
                  width: 280,
                  height: isCompact ? 130 : 170,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: isCompact ? 12 : 20),
              Text(
                'Forgot Password',
                style:
                    AppTextStyles.headlineLarge.copyWith(fontSize: titleFontSize),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the email linked to your account and we\'ll send you a '
                'code to reset your password.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: bodyFontSize,
                ),
              ),
              SizedBox(height: sectionSpacing),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                enabled: !_isLoading,
              ),
              SizedBox(height: sectionSpacing),
              GradientButton(
                text: 'Send Reset Code',
                icon: Icons.arrow_forward,
                isLoading: _isLoading,
                onPressed:
                    _emailController.text.trim().isEmpty || _isLoading
                        ? null
                        : _submit,
              ),
              SizedBox(height: sectionSpacing),
              Center(
                child: TextButton(
                  onPressed:
                      _isLoading ? null : () => context.pop(),
                  child: Text(
                    'Back to Sign In',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: bodyFontSize,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
