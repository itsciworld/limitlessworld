import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/auth/auth_bloc.dart';
import '../../../../bloc/auth/auth_event.dart';
import '../../../../bloc/auth/auth_state.dart';
import '../../../../components/auth_background.dart';
import '../../../../components/gradient_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Landing screen for a verified, signed-in user.
///
/// Intentionally bare for now — it exists so login, registration + email
/// verification, and session restore all have somewhere to land. The router
/// guard already guarantees the session before this builds.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Sign out?', style: AppTextStyles.titleLarge),
        content: Text(
          'You will need to sign in again to get back in.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sign out',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    // The bloc calls /api/auth/logout with the bearer token, then the router
    // guard drops this screen for /login.
    if (signOut == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isSigningOut = state is AuthLoading;

        return AuthBackground(
          scrollable: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.textSecondary,
                  ),
                  onPressed:
                      isSigningOut ? null : () => _confirmLogout(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Home', style: AppTextStyles.headlineLarge),
                ),
              ),
              GradientButton(
                text: 'Logout',
                icon: Icons.logout,
                isLoading: isSigningOut,
                onPressed: isSigningOut ? null : () => _confirmLogout(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
