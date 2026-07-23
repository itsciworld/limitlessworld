import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/auth_background.dart';
import '../../../../components/custom_text_field.dart';
import '../../../../components/gradient_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../models/profile_model.dart';

/// Edit name, age and gender — the only fields PATCH /api/users/{id} accepts.
///
/// Shares the [ProfileBloc] with the profile tab, so a successful save updates
/// that screen without a refetch.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;

  /// Seeded once from the bloc so later rebuilds cannot overwrite typing.
  bool _initialized = false;

  static const _genders = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  void _seedFrom(ProfileModel profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _ageController.text = profile.age > 0 ? '${profile.age}' : '';
    _gender = _genders.contains(profile.gender) ? profile.gender : null;
  }

  bool _hasChanges(ProfileModel profile) {
    return _nameController.text.trim() != profile.name ||
        _ageController.text.trim() != (profile.age > 0 ? '${profile.age}' : '') ||
        _gender != (profile.gender.isEmpty ? null : profile.gender);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            name: _nameController.text.trim(),
            age: int.tryParse(_ageController.text.trim()) ?? 0,
            gender: _gender ?? '',
          ),
        );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
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

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 700;
    final double sectionSpacing = isCompact ? 18 : 24;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is! ProfileLoaded) return;

        if (state.successMessage != null) {
          AppToast.showSuccess(state.successMessage!);
          if (context.canPop()) context.pop();
        } else if (state.errorMessage != null) {
          AppToast.showError(state.errorMessage!);
        }
      },
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          // Only reachable if the profile was cleared while editing.
          return const AuthBackground(
            scrollable: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        _seedFrom(state.profile);
        final isSaving = state.isSaving;
        final canSave = !isSaving && _hasChanges(state.profile);

        return AuthBackground(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isCompact ? 8 : 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: isSaving ? null : () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Text('Edit Profile', style: AppTextStyles.headlineMedium),
                  ],
                ),
                SizedBox(height: sectionSpacing),
                // Email is shown but not editable — the API does not accept it.
                _ReadOnlyField(label: 'Email', value: state.profile.email),
                SizedBox(height: sectionSpacing),
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                  enabled: !isSaving,
                ),
                const SizedBox(height: 12),
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
                        enabled: !isSaving,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGenderField(isSaving)),
                  ],
                ),
                SizedBox(height: sectionSpacing),
                GradientButton(
                  text: 'Save Changes',
                  icon: Icons.check,
                  isLoading: isSaving,
                  onPressed: canSave ? _save : null,
                ),
                const SizedBox(height: 12),
                if (!_hasChanges(state.profile) && !isSaving)
                  Center(
                    child: Text(
                      'Make a change to enable saving',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
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

  Widget _buildGenderField(bool isSaving) {
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
          isSaving ? null : (value) => setState(() => _gender = value),
      items: [
        for (final gender in _genders)
          DropdownMenuItem(
            value: gender,
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
}

/// A field the API will not accept changes for, styled to read as disabled.
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.textHint, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
