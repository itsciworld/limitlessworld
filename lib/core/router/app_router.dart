import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/reset_password_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/otp_verification/bloc/otp_bloc.dart';
import '../../features/otp_verification/bloc/otp_event.dart';
import '../../features/otp_verification/presentation/pages/otp_verification_view.dart';
import '../../features/profile/bloc/profile_bloc.dart';
import '../../features/profile/presentation/pages/edit_profile_view.dart';
import '../../features/profile/presentation/pages/profile_view.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/shell/presentation/pages/main_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_routes.dart';
import 'bloc_listenable.dart';
import 'navigator_key.dart';

/// Builds the app's [GoRouter].
///
/// The redirect is the single source of truth for "who may see what": screens
/// navigate freely and the guard corrects them, so no screen has to re-check
/// the session itself.
class AppRouter {
  AppRouter._();

  /// Routes that make no sense once the user is fully signed in.
  static const _preAuthRoutes = <String>{
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.verifyOtp,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
  };

  /// Routes that require a session. Every bottom-bar tab belongs here.
  static const _protectedRoutes = <String>{
    AppRoutes.home,
    AppRoutes.profile,
  };

  static GoRouter create(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      // Shared with AppToast so it can reach an Overlay without a context.
      navigatorKey: rootNavigatorKey,
      refreshListenable: BlocListenable(authBloc.stream),
      redirect: (context, state) => _guard(authBloc, state),
      errorBuilder: (context, state) => _RouteErrorScreen(state: state),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          name: AppRouteNames.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.verifyOtp,
          name: AppRouteNames.verifyOtp,
          // No email means a stale deep link — there is nothing to verify.
          redirect: (context, state) =>
              _requireEmail(state) == null ? AppRoutes.login : null,
          builder: (context, state) {
            final email = _requireEmail(state)!;
            final name = state.uri.queryParameters[AppRoutes.qName] ?? '';

            // The OtpBloc is scoped to this route, so leaving the screen
            // disposes its resend timer.
            return BlocProvider(
              create: (context) => OtpBloc(
                authRepository: context.read<AuthRepository>(),
                email: email,
                name: name,
              )..add(OtpScreenStarted(expiresInMinutes: _expiry(state))),
              child: OtpVerificationView(
                email: email,
                name: name,
                expiresInMinutes: _expiry(state),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: AppRouteNames.forgotPassword,
          builder: (context, state) => ForgotPasswordScreen(
            initialEmail: state.uri.queryParameters[AppRoutes.qEmail],
          ),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          name: AppRouteNames.resetPassword,
          // Without an email there is no reset to complete, so restart the
          // recovery flow rather than rendering a broken form.
          redirect: (context, state) =>
              _requireEmail(state) == null ? AppRoutes.forgotPassword : null,
          builder: (context, state) => ResetPasswordScreen(
            email: _requireEmail(state)!,
            expiresInMinutes: _expiry(state),
          ),
        ),
        // Signed-in area: one branch per bottom-bar tab, each with its own
        // navigator so tab state survives switching.
        StatefulShellRoute.indexedStack(
          // The ProfileBloc lives here, above both profile routes, so the
          // edit screen shares the tab's instance and a save updates it
          // without a refetch. ProfileView fires the initial load itself.
          builder: (context, state, navigationShell) => BlocProvider(
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
            child: MainShell(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: AppRouteNames.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: AppRouteNames.profile,
                  builder: (context, state) => const ProfileView(),
                  routes: [
                    // Nested, so the bottom bar stays visible and the edit
                    // screen inherits the shell's ProfileBloc.
                    GoRoute(
                      path: AppRoutes.profileEditSegment,
                      name: AppRouteNames.profileEdit,
                      builder: (context, state) => const EditProfileView(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// The `email` query param, or null when it is absent or blank.
  static String? _requireEmail(GoRouterState state) {
    final email = state.uri.queryParameters[AppRoutes.qEmail];
    return (email == null || email.isEmpty) ? null : email;
  }

  /// The `expires` query param in minutes, defaulting to the API's 10.
  static int _expiry(GoRouterState state) =>
      int.tryParse(state.uri.queryParameters[AppRoutes.qExpires] ?? '') ?? 10;

  /// Returns the location to send the user to, or null to let them through.
  static String? _guard(AuthBloc authBloc, GoRouterState state) {
    final auth = authBloc.state;
    final location = state.matchedLocation;

    // A request is in flight. Leaving the current screen up lets it show its
    // own progress — otherwise the first frame of a logout would yank the user
    // off /home before the API call had even been sent.
    if (auth is AuthLoading) return null;

    // Signed in and verified: the auth flow is behind them.
    if (auth is Authenticated) {
      return _preAuthRoutes.contains(location) ? AppRoutes.home : null;
    }

    // Everything else is not a full session, so the app itself is off limits.
    // Prefix-matched so nested routes (e.g. /profile/edit) are covered too.
    final isProtected = _protectedRoutes.any(
      (route) => location == route || location.startsWith('$route/'),
    );
    if (isProtected) return AppRoutes.login;

    return null;
  }
}

/// Shown for an unknown path — reachable via a bad deep link.
class _RouteErrorScreen extends StatelessWidget {
  final GoRouterState state;

  const _RouteErrorScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_off_outlined,
                  color: AppColors.textSecondary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text('Page not found', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  state.uri.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Go to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
