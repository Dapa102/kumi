import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_controller.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/profile/presentation/profile_controller.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/presentation/tasks_controller.dart';
import 'features/tasks/presentation/tasks_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KumiApp());
}

class KumiApp extends StatefulWidget {
  const KumiApp({super.key});

  @override
  State<KumiApp> createState() => _KumiAppState();
}

class _KumiAppState extends State<KumiApp> {
  late final ApiClient _api;
  late final TokenStorage _storage;
  late final AuthRepository _authRepository;
  late final AuthController _authController;
  late final TaskRepository _taskRepository;
  late final NotificationService _notifications;
  late final HomeController _homeController;
  late final TasksController _tasksController;
  late final ProfileController _profileController;
  late final GoRouter _router;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _storage = TokenStorage();
    _notifications = NotificationService();
    _authRepository = AuthRepository(api: _api, storage: _storage);
    _authController = AuthController(
      repository: _authRepository,
      storage: _storage,
    );
    _taskRepository = TaskRepository(_api);
    _homeController = HomeController(
      repository: _taskRepository,
      auth: _authController,
    );
    _tasksController = TasksController(
      repository: _taskRepository,
      auth: _authController,
      notifications: _notifications,
    );
    _profileController = ProfileController(
      repository: _taskRepository,
      auth: _authController,
    );

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _authController,
      redirect: (context, state) {
        final status = _authController.status;
        final location = state.uri.path;

        if (status == AuthStatus.unknown) {
          return location == '/' ? null : '/';
        }

        final loggedIn = status == AuthStatus.authenticated;
        if (!loggedIn) {
          return location == '/login' ? null : '/login';
        }

        if (location == '/' || location == '/login') {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    await _authController.bootstrap();
    await _notifications.initialize();

    final elapsed = DateTime.now().difference(started);
    if (elapsed < AppConfig.splashMinimumDuration) {
      await Future<void>.delayed(AppConfig.splashMinimumDuration - elapsed);
    }

    _bootstrapped = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _homeController.dispose();
    _tasksController.dispose();
    _profileController.dispose();
    _authController.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      return MaterialApp(
        title: 'Kumi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SplashScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authController),
        ChangeNotifierProvider.value(value: _homeController),
        ChangeNotifierProvider.value(value: _tasksController),
        ChangeNotifierProvider.value(value: _profileController),
        Provider.value(value: _notifications),
      ],
      child: MaterialApp.router(
        title: 'Kumi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
