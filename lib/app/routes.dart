import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/get_started/presentation/screens/get_started_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/wallet/presentation/screens/home_screen.dart';

class AppRoutes {
  // Route paths
  static const String onboarding = '/onboarding';
  static const String getStarted = '/get-started';
  static const String home = '/home';
  static const String walletCallback = '/wallet-callback';

  // Private constructor to prevent instantiation
  AppRoutes._();
}

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    routes: [
      // Onboarding Flow
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Flow
      GoRoute(
        path: AppRoutes.getStarted,
        name: 'get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),

      // Main App Flow
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => _buildErrorPage(state.error),
  );

  static Widget _buildErrorPage(Exception? error) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}
