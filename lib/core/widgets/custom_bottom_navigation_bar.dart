import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/constants.dart';

/// Persistent Bottom Navigation Bar for StatefulShellRoute
class PersistentBottomNavigationBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PersistentBottomNavigationBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // tăng blur
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25), // nền trắng mờ rõ hơn
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.4), // border sáng nhẹ
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // shadow nhẹ hơn
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabCount = 4;
                final tabWidth = constraints.maxWidth / tabCount;

                return Stack(
                  children: [
                    // indicator highlight
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      left: navigationShell.currentIndex * tabWidth,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                            0.18,
                          ), // highlight rõ hơn
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildNavItem(
                          icon: Icons.account_balance_wallet_outlined,
                          activeIcon: Icons.account_balance_wallet,
                          label: 'Wallet',
                          index: 0,
                          width: tabWidth,
                          navigationShell: navigationShell,
                        ),
                        _buildNavItem(
                          icon: Icons.search_outlined,
                          activeIcon: Icons.search,
                          label: 'Search',
                          index: 1,
                          width: tabWidth,
                          navigationShell: navigationShell,
                        ),
                        _buildNavItem(
                          icon: Icons.collections_outlined,
                          activeIcon: Icons.collections,
                          label: 'NFTs',
                          index: 2,
                          width: tabWidth,
                          navigationShell: navigationShell,
                        ),
                        _buildNavItem(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'Profile',
                          index: 3,
                          width: tabWidth,
                          navigationShell: navigationShell,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required double width,
    required StatefulNavigationShell navigationShell,
  }) {
    final isActive = navigationShell.currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        navigationShell.goBranch(index);
      },
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 26,
              color: isActive ? AppColors.primary : AppColors.gray900,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
