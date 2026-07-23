import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Signup = POST /api/auth/register.
///
/// On success the bloc also fires send-otp, and this screen forwards the user
/// straight to the OTP verification route.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _gender;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  static const _genders = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _emailController,
      _ageController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_updateButtonState);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _areRequiredFieldsFilled =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _ageController.text.trim().isNotEmpty &&
      _gender != null &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  bool get _canSubmit =>
      _areRequiredFieldsFilled && _agreedToTerms && !_isLoading;

  void _updateButtonState() => setState(() {});

  void _handleSignup() {
    if (!_agreedToTerms) {
      AppToast.showWarning('Please agree to the Terms & Conditions');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
          RegisterRequested(
            request: RegisterRequest(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              age: int.tryParse(_ageController.text.trim()) ?? 0,
              gender: _gender ?? '',
              password: _passwordController.text,
            ),
          ),
        );
  }

  void _navigateToLogin() => context.go(AppRoutes.login);

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!isValidEmail(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Please enter a valid age';
    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Please enter a valid age';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 700;

    final double topSpacing = isCompact ? 8 : 12;
    final double logoHeight = isCompact ? 130 : 170;
    final double sectionSpacing = isCompact ? 16 : 24;
    const double fieldSpacing = 12;
    final double titleSpacing = isCompact ? 12 : 20;
    final double bottomSpacing = isCompact ? 16 : 24;
    final double titleFontSize = isCompact ? 24 : 28;
    final double bodyFontSize = isCompact ? 13 : 14;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = state is AuthLoading);

        if (state is RegistrationSuccess) {
          AppToast.showSuccess(
            state.otpSent
                ? 'Account created. Check your email for the code.'
                : 'Account created. Tap resend to get your code.',
          );
          // Replace signup in the stack — going "back" into a submitted form
          // would only let the user re-register the same email.
          context.pushReplacement(
            AppRoutes.verifyOtpPath(
              email: state.user.email,
              name: state.user.name,
              expiresInMinutes: state.otpExpiresInMinutes,
            ),
          );
        } else if (state is AuthError) {
          // Covers "This email is already registered. Please log in instead.."
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
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: _isLoading
                    ? null
                    : () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.login),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(height: topSpacing),
              Center(
                child: Image.asset(
                  AppImages.appLogo,
                  width: 280,
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: titleSpacing),
              Text(
                'Create Account',
                style: AppTextStyles.headlineLarge
                    .copyWith(fontSize: titleFontSize),
              ),
              const SizedBox(height: 8),
              Text(
                'Get started by creating your account',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: bodyFontSize,
                ),
              ),
              SizedBox(height: sectionSpacing),
              CustomTextField(
                controller: _nameController,
                hintText: 'Full Name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                validator: _validateName,
                enabled: !_isLoading,
              ),
              const SizedBox(height: fieldSpacing),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                enabled: !_isLoading,
              ),
              const SizedBox(height: fieldSpacing),
              // Age and gender sit side by side — both are short fields and it
              // keeps the form above the fold on small phones.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      hintText: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: _validateAge,
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: fieldSpacing),
                  Expanded(child: _buildGenderField()),
                ],
              ),
              const SizedBox(height: fieldSpacing),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => validatePassword(value ?? ''),
                enabled: !_isLoading,
              ),
              const SizedBox(height: fieldSpacing),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: _validateConfirmPassword,
                enabled: !_isLoading,
              ),
              SizedBox(height: sectionSpacing),
              _buildTermsRow(bodyFontSize),
              SizedBox(height: sectionSpacing),
              GradientButton(
                text: 'Create Account',
                icon: Icons.arrow_forward,
                onPressed: _canSubmit ? _handleSignup : null,
                isLoading: _isLoading,
              ),
              SizedBox(height: sectionSpacing),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _navigateToLogin,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign In',
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

  /// Styled to match [CustomTextField] so the row reads as one control pair.
  Widget _buildGenderField() {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return DropdownButtonFormField<String>(
      initialValue: _gender,
      isExpanded: true,
      dropdownColor: AppColors.cardBackground,
      style: AppTextStyles.bodyLarge,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
      hint: Text(
        'Gender',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Select your gender' : null,
      onChanged:
          _isLoading ? null : (value) => setState(() => _gender = value),
      items: [
        for (final gender in _genders)
          DropdownMenuItem(
            value: gender,
            // The API takes lowercase; the label is title-cased for display.
            child: Text(
              '${gender[0].toUpperCase()}${gender.substring(1)}',
              style: AppTextStyles.bodyLarge,
            ),
          ),
      ],
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.wc_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: border(AppColors.borderColor),
        enabledBorder: border(AppColors.borderColor),
        focusedBorder: border(AppColors.borderActive, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildTermsRow(double bodyFontSize) {
    final linkStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.primaryBlue,
      fontWeight: FontWeight.w600,
      fontSize: bodyFontSize - 1,
    );
    final textStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: bodyFontSize - 1,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _agreedToTerms = value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('I agree to the ', style: textStyle),
              GestureDetector(
                onTap: () =>
                    AppToast.showInfo('Terms & Conditions coming soon'),
                child: Text('Terms & Conditions', style: linkStyle),
              ),
              Text(' and ', style: textStyle),
              GestureDetector(
                onTap: () => AppToast.showInfo('Privacy Policy coming soon'),
                child: Text('Privacy Policy', style: linkStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
