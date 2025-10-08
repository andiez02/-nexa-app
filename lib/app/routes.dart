import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/main_navigation_wrapper.dart';
import '../features/get_started/presentation/screens/get_started_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/nft_detail/presentation/screens/nft_detail_screen.dart';
import '../features/mint/presentation/screens/mint_nft_screen.dart';

class AppRoutes {
  // Route paths
  static const String onboarding = '/onboarding';
  static const String getStarted = '/get-started';
  static const String home = '/';
  static const String nftDetail = '/nft-detail';
  static const String mint = '/mint';
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
            return AppRoutes.home;
          default:
            return AppRoutes.home;
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

      // Main App (Home with Bottom Navigation)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainNavigationWrapper(),
        routes: [
          // NFT Detail (Stack Navigation)
          GoRoute(
            path: 'nft-detail/:id',
            name: 'nft-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '1';
              return NFTDetailScreen(nftId: id);
            },
          ),
          
          // Mint NFT (Modal Navigation)
          GoRoute(
            path: 'mint',
            name: 'mint',
            pageBuilder: (context, state) {
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: const MintNFTScreen(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end).chain(
                    CurveTween(curve: curve),
                  );

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
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
              context.go(AppRoutes.home);
            }
          });

          return const MainNavigationWrapper();
        },
      ),
    ],

    // Error page
    errorBuilder: (context, state) {
      return _buildErrorPage(state.error);
    },
  );

  static Widget _buildErrorPage(Exception? error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => AppRouter.router.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}