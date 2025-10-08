import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class ActionButtons extends StatelessWidget {
  final bool isForSale;
  final String saleType;
  final VoidCallback onBuyNow;
  final VoidCallback onPlaceBid;
  final VoidCallback onMakeOffer;

  const ActionButtons({
    super.key,
    required this.isForSale,
    required this.saleType,
    required this.onBuyNow,
    required this.onPlaceBid,
    required this.onMakeOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (isForSale) ...[
            Row(
              children: [
                if (saleType == 'fixed') ...[
                  Expanded(
                    flex: 2,
                    child: _buildPrimaryButton(
                      text: 'Buy Now',
                      icon: Icons.shopping_cart,
                      onPressed: onBuyNow,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryButton(
                      text: 'Make Offer',
                      icon: Icons.local_offer,
                      onPressed: onMakeOffer,
                    ),
                  ),
                ] else if (saleType == 'auction') ...[
                  Expanded(
                    flex: 2,
                    child: _buildPrimaryButton(
                      text: 'Place Bid',
                      icon: Icons.gavel,
                      onPressed: onPlaceBid,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryButton(
                      text: 'Watch',
                      icon: Icons.visibility,
                      onPressed: () {},
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    text: 'Make Offer',
                    icon: Icons.local_offer,
                    onPressed: onMakeOffer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryButton(
                    text: 'Add to Watchlist',
                    icon: Icons.bookmark_border,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          
          // Secondary actions row
          Row(
            children: [
              Expanded(
                child: _buildOutlineButton(
                  text: 'View on Etherscan',
                  icon: Icons.open_in_new,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOutlineButton(
                  text: 'Refresh Metadata',
                  icon: Icons.refresh,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.gray600, size: 16),
              const SizedBox(width: 6),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
