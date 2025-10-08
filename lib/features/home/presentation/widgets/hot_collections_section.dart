import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class HotCollectionsSection extends StatelessWidget {
  const HotCollectionsSection({super.key});

  final List<Map<String, String>> collections = const [
    {
      'name': 'Bored Ape Yacht Club',
      'items': '10,000',
      'floorPrice': '23.5 ETH',
      'image': 'nft_image_1',
      'verified': 'true',
    },
    {
      'name': 'CryptoPunks',
      'items': '10,000',
      'floorPrice': '67.8 ETH',
      'image': 'nft_image_2',
      'verified': 'true',
    },
    {
      'name': 'Azuki',
      'items': '10,000',
      'floorPrice': '8.9 ETH',
      'image': 'nft_image_3',
      'verified': 'true',
    },
    {
      'name': 'Doodles',
      'items': '10,000',
      'floorPrice': '4.2 ETH',
      'image': 'nft_image_4',
      'verified': 'false',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hot Collections',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => _buildCollectionCard(collections[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, String> collection) {
    return Container(
      width: 200,
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
          // Collection preview images (3 stacked images)
          Container(
            height: 120,
            margin: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildPreviewImage(collection['image']!, 0),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildPreviewImage(collection['image']!, 1),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildPreviewImage(collection['image']!, 2),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection['name']!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (collection['verified'] == 'true')
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection['items']} items',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Floor: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        collection['floorPrice']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildPreviewImage(String imageName, int index) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(
          image: AssetImage('assets/images/$imageName.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
