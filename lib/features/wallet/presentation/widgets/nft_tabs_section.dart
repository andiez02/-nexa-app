import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';

class NFTTabsSection extends StatelessWidget {
  final TabController tabController;

  const NFTTabsSection({
    super.key,
    required this.tabController,
  });

  // Mock NFT data for different tabs
  final List<Map<String, String>> collectedNFTs = const [
    {
      'id': '1',
      'name': 'Cosmic Dreams #1234',
      'price': '2.5 ETH',
      'image': 'nft_image_1',
      'collection': 'Cosmic Collection',
    },
    {
      'id': '2',
      'name': 'Digital Genesis #567',
      'price': '1.8 ETH',
      'image': 'nft_image_2',
      'collection': 'Genesis Art',
    },
    {
      'id': '3',
      'name': 'Pixel Warriors #890',
      'price': '3.2 ETH',
      'image': 'nft_image_3',
      'collection': 'Pixel World',
    },
    {
      'id': '4',
      'name': 'Neon Landscapes #123',
      'price': '0.9 ETH',
      'image': 'nft_image_4',
      'collection': 'Neon Art',
    },
  ];

  final List<Map<String, String>> createdNFTs = const [
    {
      'id': '5',
      'name': 'My First Creation #001',
      'price': '0.5 ETH',
      'image': 'nft_image_5',
      'collection': 'Personal Art',
    },
    {
      'id': '6',
      'name': 'Abstract Vision #002',
      'price': '1.2 ETH',
      'image': 'nft_image_6',
      'collection': 'Abstract Series',
    },
  ];

  final List<Map<String, String>> onSaleNFTs = const [
    {
      'id': '7',
      'name': 'Rare Gem #456',
      'price': '5.0 ETH',
      'image': 'nft_image_1',
      'collection': 'Gem Collection',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        _buildNFTGrid(context, collectedNFTs, 'No NFTs collected yet'),
        _buildNFTGrid(context, createdNFTs, 'No NFTs created yet'),
        _buildNFTGrid(context, onSaleNFTs, 'No NFTs on sale'),
      ],
    );
  }

  Widget _buildNFTGrid(BuildContext context, List<Map<String, String>> nfts, String emptyMessage) {
    if (nfts.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: nfts.length,
        itemBuilder: (context, index) => _buildNFTCard(context, nfts[index]),
      ),
    );
  }

  Widget _buildNFTCard(BuildContext context, Map<String, String> nft) {
    return GestureDetector(
      onTap: () => context.go('/nft-detail/${nft['id']}'),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFT Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage('assets/images/${nft['image']}.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // NFT Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nft['name']!,
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
                      nft['collection']!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.currency_bitcoin,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          nft['price']!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring to collect NFTs',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}