import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';

class NFTInfoSection extends StatelessWidget {
  final NFTModel nft;

  const NFTInfoSection({
    super.key,
    required this.nft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NFT Name and Token ID
          Row(
            children: [
              Expanded(
                child: Text(
                  nft.name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${nft.tokenId}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Collection name if available
          if (nft.collection != null && nft.collection!.isNotEmpty) ...[
            Text(
              nft.collection!,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Blockchain info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public,
                  color: AppColors.secondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ethereum',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nft.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.gray600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Contract and Token ID info
          _buildInfoRow('Contract Address', nft.contractAddress ?? 'Unknown'),
          const SizedBox(height: 8),
          _buildInfoRow('Token Standard', 'ERC-721'),
          const SizedBox(height: 8),
          _buildInfoRow('Blockchain', 'Ethereum'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.gray700,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            // Copy to clipboard functionality
          },
          child: Icon(
            Icons.copy,
            size: 16,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }
}
