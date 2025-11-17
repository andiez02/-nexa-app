import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';
import '../../../../data/services/nft_service.dart';
import '../../../../core/services/smart_contract_service.dart';
import '../../../../features/wallet/wallet_provider.dart';

class NFTGrid extends StatefulWidget {
  const NFTGrid({super.key});

  @override
  State<NFTGrid> createState() => _NFTGridState();
}

class _NFTGridState extends State<NFTGrid> {
  static List<NFTModel>? _cachedListedNFTs;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTTL = Duration(minutes: 2);

  List<NFTModel> _listedNFTs = [];
  bool _isLoading = true;
  String? _currentUserAddress;

  @override
  void initState() {
    super.initState();
    _loadListedNFTs();
  }

  Future<void> _loadListedNFTs({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedListedNFTs != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTTL) {
      setState(() {
        _listedNFTs = _cachedListedNFTs!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      if (walletProvider.appKitModal == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Initialize SmartContractService
      final smartContractService = SmartContractService(
        walletProvider.appKitModal!,
      );

      // Initialize the service (load ABIs)
      await smartContractService.init();

      // Get current user address
      _currentUserAddress = smartContractService.getCurrentUserAddress();
      debugPrint('👤 Current user address: $_currentUserAddress');

      // Create NFTService
      final nftService = NFTService(smartContractService);
      final listedNFTs = await nftService.fetchAllListedNFTs(
        currentUserAddress: _currentUserAddress,
      );

      debugPrint('📊 Explore screen loaded ${listedNFTs.length} listed NFTs');

      if (mounted) {
        setState(() {
          _listedNFTs = listedNFTs;
          _isLoading = false;
        });
      }
      _cachedListedNFTs = listedNFTs;
      _cacheTimestamp = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error loading listed NFTs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isMyNFT(NFTModel nft) {
    if (_currentUserAddress == null) return false;
    return nft.seller?.toLowerCase() == _currentUserAddress!.toLowerCase() ||
        nft.owner.toLowerCase() == _currentUserAddress!.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading marketplace...'),
          ],
        ),
      );
    }

    if (_listedNFTs.isEmpty) {
      return Center(
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
                Icons.store_outlined,
                size: 40,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No NFTs listed yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to list an NFT!',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadListedNFTs(forceRefresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: _listedNFTs.length,
        itemBuilder: (context, index) =>
            _buildNFTCard(context, _listedNFTs[index]),
      ),
    );
  }

  Widget _buildNFTCard(BuildContext context, NFTModel nft) {
    final isMyNFT = _isMyNFT(nft);

    return GestureDetector(
      onTap: () async {
        // Navigate to detail screen and wait for result
        final result = await context.pushNamed(
          'nft-detail',
          pathParameters: {'id': nft.tokenId},
        );

        // If purchase was successful, refresh the listed NFTs
        if (result == true && mounted) {
          debugPrint('🔄 Refreshing explore screen after purchase...');
          // Clear cache and reload
          final walletProvider = Provider.of<WalletProvider>(
            context,
            listen: false,
          );
          if (walletProvider.appKitModal != null) {
            final smartContractService = SmartContractService(
              walletProvider.appKitModal!,
            );
            await smartContractService.init();
            final nftService = NFTService(smartContractService);
            nftService.clearListedNFTsCache(); // Clear cache
            _clearLocalCache();
            _loadListedNFTs(forceRefresh: true); // Reload
          }
        }
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
              flex: 4,
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

                    // "My NFT" badge
                    if (isMyNFT)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'My NFT',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Token ID badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
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
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NFT name
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
                    const SizedBox(height: 4),

                    // Collection info
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

                    // Price or "My NFT"
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMyNFT ? 'Status' : 'Price',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.gray500,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Row(
                                children: [
                                  if (!isMyNFT) ...[
                                    Icon(
                                      Icons.currency_bitcoin,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 2),
                                  ],
                                  Text(
                                    isMyNFT ? 'My NFT' : nft.formattedPrice,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isMyNFT
                                          ? AppColors.primary
                                          : AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Owner avatar
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isMyNFT
                                ? AppColors.primary
                                : AppColors.gray400,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              nft.seller?.substring(2, 3).toUpperCase() ?? '?',
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

  void _clearLocalCache() {
    _cachedListedNFTs = null;
    _cacheTimestamp = null;
  }
}
