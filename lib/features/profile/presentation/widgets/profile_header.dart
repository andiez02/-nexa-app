import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class ProfileHeader extends StatelessWidget {
  final String avatar;
  final String displayName;
  final String walletAddress;
  final Function(String) onCopyAddress;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.avatar,
    required this.displayName,
    required this.walletAddress,
    required this.onCopyAddress,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final shortAddress = walletAddress.isNotEmpty
        ? '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}'
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: walletAddress.isNotEmpty
                          ? () => onCopyAddress(walletAddress)
                          : null,
                      child: Row(
                        children: [
                          Text(
                            shortAddress,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (walletAddress.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: AppColors.gray400,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
