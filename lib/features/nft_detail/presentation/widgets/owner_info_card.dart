import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';

class OwnerInfoCard extends StatelessWidget {
  final NFTModel nft;
  final String? currentUserAddress;

  const OwnerInfoCard({super.key, required this.nft, this.currentUserAddress});

  bool get isOwner {
    if (currentUserAddress == null) return false;
    return nft.owner.toLowerCase() == currentUserAddress!.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
          _buildUserInfo(
            title: isOwner ? 'My account' : 'Owner',
            address: nft.owner,
            isOwner: isOwner,
          ),
          if (nft.creator != null && nft.creator!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.gray200),
            const SizedBox(height: 16),
            _buildUserInfo(
              title: 'Created by',
              address: nft.creator!,
              isOwner: currentUserAddress != null &&
                  nft.creator!.toLowerCase() ==
                      currentUserAddress!.toLowerCase(),
            ),
          ],
          if (nft.seller != null && nft.seller!.isNotEmpty && !isOwner) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.gray200),
            const SizedBox(height: 16),
            _buildUserInfo(
              title: 'Listed by',
              address: nft.seller!,
              isOwner: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo({
    required String title,
    required String address,
    required bool isOwner,
  }) {
    // Generate avatar letter from address
    final avatarLetter = address.length > 2
        ? address.substring(2, 3).toUpperCase()
        : 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // User avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isOwner ? AppColors.primary : AppColors.gray400,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isOwner
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : Text(
                        avatarLetter,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),

            // Address info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwner ? 'Your account' : 'Wallet Address',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.length > 10
                        ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
                        : address,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
