import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_state.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/toast_helper.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/profile/repository/profile_repository.dart';
import 'service/api_interceptor_service/api_interceptor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must run before anything reads AppConfig.baseUrl.
  await AppConfig.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiInterceptorService _apiService;
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Built here rather than in providers because the router needs the bloc
    // instance up front for its redirect, and the interceptor needs a way to
    // kick the user out when a refresh fails.
    _apiService = ApiInterceptorService(onSessionExpired: _handleSessionExpired);
    _authRepository = AuthRepository(apiService: _apiService);
    _profileRepository = ProfileRepository(apiService: _apiService);
    _authBloc = AuthBloc(authRepository: _authRepository);
    _router = AppRouter.create(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _router.dispose();
    _apiService.close();
    super.dispose();
  }

  /// Token refresh failed and storage was cleared — drop back to login.
  void _handleSessionExpired() => _router.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiInterceptorService>.value(value: _apiService),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ProfileRepository>.value(value: _profileRepository),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: _authBloc,
        // Sits above the router so it survives the redirect that logout and
        // session expiry trigger — a listener on the outgoing screen would be
        // torn down before it could fire.
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is Unauthenticated || current is SessionExpired,
          listener: (context, state) {
            if (state is Unauthenticated && state.message != null) {
              AppToast.showSuccess(state.message!);
            } else if (state is SessionExpired) {
              AppToast.showWarning(state.message);
            }
          },
          child: MaterialApp.router(
            title: 'Limitless',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
