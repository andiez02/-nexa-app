import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';

class NFTGrid extends StatelessWidget {
  const NFTGrid({super.key});

  // Mock NFT data
  final List<Map<String, String>> nfts = const [
    {
      'id': '1',
      'name': 'Cosmic Dreams #1234',
      'price': '2.5 ETH',
      'image': 'nft_image_1',
      'creator': 'ArtistDAO',
      'owner': '0x1234...5678',
      'liked': 'true',
      'views': '1.2k',
    },
    {
      'id': '2',
      'name': 'Digital Genesis #567',
      'price': '1.8 ETH',
      'image': 'nft_image_2',
      'creator': 'CryptoArt',
      'owner': '0x9876...4321',
      'liked': 'false',
      'views': '856',
    },
    {
      'id': '3',
      'name': 'Pixel Warriors #890',
      'price': '3.2 ETH',
      'image': 'nft_image_3',
      'creator': 'PixelMaster',
      'owner': '0x1111...2222',
      'liked': 'true',
      'views': '2.1k',
    },
    {
      'id': '4',
      'name': 'Neon Landscapes #123',
      'price': '0.9 ETH',
      'image': 'nft_image_4',
      'creator': 'NeonArt',
      'owner': '0x3333...4444',
      'liked': 'false',
      'views': '643',
    },
    {
      'id': '5',
      'name': 'Abstract Visions #456',
      'price': '4.1 ETH',
      'image': 'nft_image_5',
      'creator': 'AbstractDAO',
      'owner': '0x5555...6666',
      'liked': 'true',
      'views': '3.4k',
    },
    {
      'id': '6',
      'name': 'Cyber Punk #789',
      'price': '1.5 ETH',
      'image': 'nft_image_6',
      'creator': 'CyberArt',
      'owner': '0x7777...8888',
      'liked': 'false',
      'views': '892',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: nfts.length,
      itemBuilder: (context, index) => _buildNFTCard(context, nfts[index]),
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
            // NFT Image with overlay
            Expanded(
              flex: 4,
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
                      // Like button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            nft['liked'] == 'true'
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: nft['liked'] == 'true'
                                ? Colors.red
                                : AppColors.gray600,
                            size: 16,
                          ),
                        ),
                      ),
                      
                      // Views counter
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                nft['views']!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NFT name
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
                    const SizedBox(height: 4),
                    
                    // Creator info
                    Text(
                      'by ${nft['creator']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Price and owner
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.gray500,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.currency_bitcoin,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    nft['price']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Owner avatar placeholder
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              nft['owner']![2],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
}
