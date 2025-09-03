import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nexa_app/app/constants.dart';

Widget buildMarketTab() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.gray500, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search NFTs...",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              Icon(Icons.filter_list, color: AppColors.gray500, size: 20),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // NFT Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 6, // Demo data
            itemBuilder: (context, index) => _buildNFTCard(index),
          ),
        ),
      ],
    ),
  );
}

Widget _buildNFTCard(int index) {
  final List<String> demoTitles = [
    "Cosmic Cat #123",
    "Digital Sunset",
    "Pixel Warrior",
    "Abstract Dreams",
    "Neon City",
    "Future Vibes",
  ];

  final List<String> demoPrices = ["0.5", "1.2", "0.8", "2.1", "0.3", "1.5"];

  return Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gray200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NFT Image placeholder
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            image: DecorationImage(
              image: AssetImage('assets/images/nft_image_${index + 1}.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // NFT Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                demoTitles[index % demoTitles.length],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Image.asset(
                    'assets/images/ethereum.png',
                    width: 14,
                    height: 14,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${demoPrices[index % demoPrices.length]} USDC",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
