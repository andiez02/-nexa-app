import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/get_started/get_started_screen.dart';
import '../screens/home/home_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String getStarted = '/get-started';
  static const String home = '/home';

  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    routes: [
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: getStarted,
        name: 'get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
