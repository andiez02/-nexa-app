import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';

class NFTTabsSection extends StatelessWidget {
  final TabController tabController;
  final Map<NFTCategory, List<NFTModel>> nftData;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const NFTTabsSection({
    super.key,
    required this.tabController,
    required this.nftData,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading your NFTs...'),
          ],
        ),
      );
    }

    // Combine collected and created into "My NFT"
    // If an NFT is also listed, use the listed version (with price/listing info)
    final onSaleNFTs = nftData[NFTCategory.onSale] ?? <NFTModel>[];
    final onSaleTokenIds = onSaleNFTs.map((nft) => nft.tokenId).toSet();

    final List<NFTModel> myNFTs = [];

    // Add collected NFTs (skip if already in onSale)
    for (final nft in (nftData[NFTCategory.collected] ?? <NFTModel>[])) {
      if (onSaleTokenIds.contains(nft.tokenId)) {
        // Use the onSale version which has listing info
        final listedVersion = onSaleNFTs.firstWhere(
          (listed) => listed.tokenId == nft.tokenId,
        );
        myNFTs.add(listedVersion);
      } else {
        myNFTs.add(nft);
      }
    }

    // Add created NFTs (skip if already added from collected or onSale)
    final addedTokenIds = myNFTs.map((nft) => nft.tokenId).toSet();
    for (final nft in (nftData[NFTCategory.created] ?? <NFTModel>[])) {
      if (onSaleTokenIds.contains(nft.tokenId)) {
        // Use the onSale version which has listing info
        if (!addedTokenIds.contains(nft.tokenId)) {
          final listedVersion = onSaleNFTs.firstWhere(
            (listed) => listed.tokenId == nft.tokenId,
          );
          myNFTs.add(listedVersion);
          addedTokenIds.add(nft.tokenId);
        }
      } else if (!addedTokenIds.contains(nft.tokenId)) {
        myNFTs.add(nft);
        addedTokenIds.add(nft.tokenId);
      }
    }

    return TabBarView(
      controller: tabController,
      children: [
        _buildNFTGrid(context, myNFTs, 'No NFTs yet'),
        _buildNFTGrid(
          context,
          nftData[NFTCategory.onSale] ?? [],
          'No NFTs on sale',
        ),
      ],
    );
  }

  Widget _buildNFTGrid(
    BuildContext context,
    List<NFTModel> nfts,
    String emptyMessage,
  ) {
    if (nfts.isEmpty) {
      return _buildEmptyState(emptyMessage, context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: Padding(
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
      ),
    );
  }

  Widget _buildNFTCard(BuildContext context, NFTModel nft) {
    return GestureDetector(
      onTap: () {
        debugPrint('🎯 Navigating to NFT detail for tokenId: ${nft.tokenId}');
        context.pushNamed('nft-detail', pathParameters: {'id': nft.tokenId});
      },
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: AppColors.gray200,
                ),
                child: Stack(
                  children: [
                    // NFT Image
                    if (nft.imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            nft.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.gray200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.gray500,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Placeholder for empty image
                    if (nft.imageUrl.isEmpty)
                      Positioned.fill(
                        child: Container(
                          color: AppColors.gray200,
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              color: AppColors.gray500,
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // More menu
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

                    // Token ID badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${nft.tokenId}',
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
                      nft.name,
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
                      nft.collection ?? 'Nexa NFT Collection',
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
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nft.formattedPrice,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: nft.isListed
                                  ? AppColors.black
                                  : AppColors.gray500,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyState(String message, BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.gray200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
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
                  'Pull down to refresh or mint new NFTs',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                ),
                if (onRefresh != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
