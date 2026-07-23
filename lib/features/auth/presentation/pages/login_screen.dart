import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../bloc/auth/auth_bloc.dart';
import '../../../../bloc/auth/auth_event.dart';
import '../../../../bloc/auth/auth_state.dart';
import '../../../../components/auth_background.dart';
import '../../../../components/custom_text_field.dart';
import '../../../../components/gradient_button.dart';
import '../../../../components/social_auth_button.dart';
import '../../../../core/app_images/app_images.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../models/auth_models.dart';

/// Login = POST /api/auth/login.
///
/// If the account exists but its email is unverified the bloc emits
/// [EmailVerificationRequired] and this screen routes to OTP verification
/// rather than home.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              request: LoginRequest(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              ),
            ),
          );
    }
  }

  void _navigateToSignup() => context.push(AppRoutes.signup);

  void _navigateToForgotPassword() {
    context.push(
      AppRoutes.forgotPasswordPath(email: _emailController.text.trim()),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!isValidEmail(value)) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 700;

    final double topSpacing = isCompact ? 10 : 16;
    final double sectionSpacing = isCompact ? 20 : 28;
    const double fieldSpacing = 12;
    final double titleSpacing = isCompact ? 16 : 24;
    final double bottomSpacing = isCompact ? 16 : 24;
    final double titleFontSize = isCompact ? 24 : 28;
    final double bodyFontSize = isCompact ? 13 : 14;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = state is AuthLoading);

        if (state is Authenticated) {
          // The token is already in secure storage — straight to home.
          context.go(AppRoutes.home);
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
              SizedBox(height: topSpacing),
              // Only offer "back" when there is somewhere to go — login is the
              // root route after logout.
              if (context.canPop())
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _isLoading ? null : () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              SizedBox(height: topSpacing),
              Center(
                child: Image.asset(
                  AppImages.appLogo,
                  width: 280,
                  height: isCompact ? 150 : 190,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: titleSpacing),
              Text(
                'Welcome Back',
                style: AppTextStyles.headlineLarge
                    .copyWith(fontSize: titleFontSize),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue to your account',
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
              const SizedBox(height: fieldSpacing),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: _validatePassword,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _navigateToForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: bodyFontSize,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: fieldSpacing),
              GradientButton(
                text: 'Sign In',
                icon: Icons.arrow_forward,
                onPressed: _isLoading ? null : _handleLogin,
                isLoading: _isLoading,
              ),
              SizedBox(height: sectionSpacing),
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.borderColor, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: bodyFontSize,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.borderColor, thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),
              Row(
                children: [
                  Expanded(
                    child: SocialAuthButtonIcon(
                      text: 'Google',
                      imagePath: AppImages.googleIcon,
                      onPressed: _isLoading
                          ? null
                          : () => AppToast.showInfo('Google Sign-In coming soon'),
                      isLoading: false,
                    ),
                  ),
                  const SizedBox(width: fieldSpacing),
                  Expanded(
                    child: SocialAuthButtonIcon(
                      text: 'Apple',
                      icon: Icons.apple,
                      onPressed: _isLoading
                          ? null
                          : () => AppToast.showInfo('Apple Sign-In coming soon'),
                      isLoading: false,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _navigateToSignup,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: bodyFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
