import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class ActivitySection extends StatelessWidget {
  const ActivitySection({super.key});

  final List<Map<String, dynamic>> activities = const [
    {
      'type': 'purchased',
      'nftName': 'Cosmic Dreams #1234',
      'price': '2.5 ETH',
      'time': '2 hours ago',
      'icon': Icons.shopping_bag,
      'color': AppColors.success,
    },
    {
      'type': 'listed',
      'nftName': 'Digital Genesis #567',
      'price': '1.8 ETH',
      'time': '1 day ago',
      'icon': Icons.sell,
      'color': AppColors.info,
    },
    {
      'type': 'minted',
      'nftName': 'Abstract Vision #001',
      'price': null,
      'time': '3 days ago',
      'icon': Icons.create,
      'color': AppColors.primary,
    },
    {
      'type': 'followed',
      'nftName': 'ArtistDAO',
      'price': null,
      'time': '1 week ago',
      'icon': Icons.person_add,
      'color': AppColors.secondary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildActivityItem(activities[index]),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    children: [
                      TextSpan(
                        text: _getActivityText(activity['type']),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' ${activity['nftName']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (activity['price'] != null)
                        TextSpan(
                          text: ' for ${activity['price']}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          
          Icon(
            Icons.chevron_right,
            color: AppColors.gray400,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _getActivityText(String type) {
    switch (type) {
      case 'purchased':
        return 'Purchased';
      case 'listed':
        return 'Listed';
      case 'minted':
        return 'Minted';
      case 'followed':
        return 'Followed';
      default:
        return 'Activity on';
    }
  }
}
