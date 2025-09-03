import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_app/features/nfts/presentation/screens/nfts_screen.dart';
import 'package:nexa_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:nexa_app/features/search/presentation/screens/search_screen.dart';

import '../core/widgets/custom_bottom_navigation_bar.dart';
import '../features/get_started/presentation/screens/get_started_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/wallet/presentation/screens/wallet_screen.dart';

class AppRoutes {
  // Route paths
  static const String onboarding = '/onboarding';
  static const String getStarted = '/get-started';
  static const String wallet = '/wallet';
  static const String nfts = '/nfts';
  static const String search = '/search';
  static const String profile = '/profile';
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
    redirect: (context, state) {
      final uri = state.uri;

      if (uri.scheme == 'nexanft') {
        final path = uri.path;

        switch (path) {
          case '/wallet-callback':
            return AppRoutes.walletCallback;
          case '/wallet/':
            return AppRoutes.wallet;
          default:
            return AppRoutes.wallet;
        }
      }
      return null;
    },
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

      // Main App Flow with persistent bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainAppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wallet,
                name: 'wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.nfts,
                name: 'nfts',
                builder: (context, state) => const NftsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Wallet Callback - Deep link handler
      GoRoute(
        path: AppRoutes.walletCallback,
        name: 'wallet-callback',
        builder: (context, state) {
          // Redirect to home screen after processing the callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AppRoutes.wallet);
            }
          });

          return const WalletScreen();
        },
      ),
    ],

    // Error page
    errorBuilder: (context, state) {
      return _buildErrorPage(state.error);
    },
  );

  static Widget _buildErrorPage(Exception? error) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}

/// Main app shell with persistent bottom navigation
class MainAppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainAppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Screen content takes full space
          navigationShell,

          // Bottom navigation overlays on top
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PersistentBottomNavigationBar(
              navigationShell: navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}
