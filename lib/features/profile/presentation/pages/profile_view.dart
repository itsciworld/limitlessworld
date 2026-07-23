import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/auth_background.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../models/profile_model.dart';

/// Profile tab — everything on it comes from GET /api/users/{id}; nothing is
/// read from local storage except the id the request is built from.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    // The bloc is owned by the shell so the edit screen can share it, which
    // means the fetch is triggered here — the first time the tab is opened,
    // not when the shell is built.
    final bloc = context.read<ProfileBloc>();
    if (bloc.state is ProfileInitial) {
      bloc.add(const ProfileRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      scrollable: false,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // Surfaces a failed save when the edit screen has already closed.
          if (state is ProfileLoaded && state.errorMessage != null) {
            AppToast.showError(state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            );
          }

          if (state is ProfileError) {
            return _ProfileErrorView(message: state.message);
          }

          final loaded = state as ProfileLoaded;
          return RefreshIndicator(
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.cardBackground,
            onRefresh: () async =>
                context.read<ProfileBloc>().add(const ProfileRefreshed()),
            child: _ProfileContent(
              profile: loaded.profile,
              isRefreshing: loaded.isRefreshing,
            ),
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileModel profile;
  final bool isRefreshing;

  const _ProfileContent({required this.profile, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Always scrollable so pull-to-refresh works even on a short profile.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Profile', style: AppTextStyles.headlineLarge),
            ),
            if (isRefreshing)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.profileEdit),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileHeader(profile: profile),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Account details',
          children: [
            _InfoRow(label: 'Name', value: profile.name),
            _InfoRow(label: 'Email', value: profile.email),
            _InfoRow(
              label: 'Age',
              value: profile.age > 0 ? '${profile.age}' : '—',
            ),
            _InfoRow(
              label: 'Gender',
              value: profile.gender.isEmpty ? '—' : _titleCase(profile.gender),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Status',
          children: [
            _InfoRow(
              label: 'Email verified',
              value: profile.emailVerified ? 'Verified' : 'Not verified',
              valueColor:
                  profile.emailVerified ? AppColors.success : AppColors.warning,
            ),
            _InfoRow(
              label: 'Payment',
              value: _titleCase(profile.paymentStatus),
              valueColor: profile.paymentStatus == 'paid'
                  ? AppColors.success
                  : AppColors.warning,
            ),
            _InfoRow(
              label: 'Password reset',
              value: profile.passwordResetRequired ? 'Required' : 'Not needed',
            ),
            _InfoRow(
              label: 'Assessments',
              value: '${profile.assessments.length}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Activity',
          children: [
            _InfoRow(label: 'Joined', value: _formatDate(profile.createdAt)),
            _InfoRow(label: 'Last updated', value: _formatDate(profile.updatedAt)),
            _InfoRow(label: 'User ID', value: profile.id, isMonospace: true),
          ],
        ),
      ],
    );
  }
}

/// Avatar + name + email banner.
class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Text(
              profile.initials,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.name.isEmpty ? 'Unnamed' : profile.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _VerifiedChip(isVerified: profile.emailVerified),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  final bool isVerified;

  const _VerifiedChip({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.error_outline_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            isVerified ? 'Verified' : 'Unverified',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMonospace;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontFamily: isMonospace ? 'monospace' : null,
                fontSize: isMonospace ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;

  const _ProfileErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load profile',
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                context.read<ProfileBloc>().add(const ProfileRequested()),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
