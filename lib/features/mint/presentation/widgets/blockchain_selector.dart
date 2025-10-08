import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class BlockchainSelector extends StatelessWidget {
  final String selectedBlockchain;
  final Function(String) onChanged;

  BlockchainSelector({
    super.key,
    required this.selectedBlockchain,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> blockchains = [
    {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'icon': Icons.currency_bitcoin,
      'color': AppColors.primary,
      'gasPrice': 'High',
      'description': 'Most popular blockchain for NFTs',
    },
    {
      'name': 'Polygon',
      'symbol': 'MATIC',
      'icon': Icons.hexagon,
      'color': AppColors.secondary,
      'gasPrice': 'Low',
      'description': 'Fast and cheap transactions',
    },
    {
      'name': 'Binance Smart Chain',
      'symbol': 'BNB',
      'icon': Icons.account_balance,
      'color': AppColors.warning,
      'gasPrice': 'Medium',
      'description': 'BSC ecosystem integration',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blockchain',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the blockchain network for your NFT',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 12),
        
        Column(
          children: blockchains.map((blockchain) {
            final isSelected = selectedBlockchain == blockchain['name'];
            return _buildBlockchainOption(blockchain, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBlockchainOption(Map<String, dynamic> blockchain, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(blockchain['name']),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.gray300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Blockchain icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (blockchain['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    blockchain['icon'] as IconData,
                    color: blockchain['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Blockchain info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            blockchain['name'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getGasColor(blockchain['gasPrice']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${blockchain['gasPrice']} Gas',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getGasColor(blockchain['gasPrice']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        blockchain['description'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray300),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGasColor(String gasPrice) {
    switch (gasPrice.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }
}
