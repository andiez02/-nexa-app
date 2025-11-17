import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';
import '../../../../data/services/nft_service.dart';
import '../../../../core/services/smart_contract_service.dart';
import '../../../../features/wallet/wallet_provider.dart';

class HotCollectionsSection extends StatefulWidget {
  const HotCollectionsSection({super.key});

  @override
  State<HotCollectionsSection> createState() => _HotCollectionsSectionState();
}

class _HotCollectionsSectionState extends State<HotCollectionsSection> {
  static const int _maxTokensToDisplay = 40;
  static const int _batchSize = 8;
  static const Duration _cacheTTL = Duration(minutes: 3);

  static List<NFTModel>? _cachedNFTs;
  static DateTime? _cacheTimestamp;
  static String? _cachedUserAddress;

  List<NFTModel> _allNFTs = [];
  bool _isLoading = true;
  String? _currentUserAddress;
  NFTService? _nftService;

  @override
  void initState() {
    super.initState();
    _loadAllNFTs();
  }

  Future<void> _loadAllNFTs({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedNFTs != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTTL) {
      setState(() {
        _allNFTs = _cachedNFTs!;
        _currentUserAddress = _cachedUserAddress;
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
      _nftService = NFTService(smartContractService);

      // Fetch all NFTs from contract (both listed and unlisted)
      final allNFTs = await _fetchAllNFTsFromContract(smartContractService);

      debugPrint('📊 Home screen loaded ${allNFTs.length} NFTs');

      if (mounted) {
        setState(() {
          _allNFTs = allNFTs;
          _isLoading = false;
        });
      }

      _cachedNFTs = allNFTs;
      _cacheTimestamp = DateTime.now();
      _cachedUserAddress = _currentUserAddress;
    } catch (e) {
      debugPrint('❌ Error loading NFTs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<NFTModel>> _fetchAllNFTsFromContract(
    SmartContractService smartContractService,
  ) async {
    final allNFTs = <NFTModel>[];

    try {
      // Get total supply
      final totalSupplyStr = await smartContractService.getNFTTotalSupply();
      final totalSupply = _parseBigIntFromHex(totalSupplyStr);
      debugPrint('📊 Total NFT supply: $totalSupply');

      if (totalSupply == 0) {
        return [];
      }

      final latestTokenId = totalSupply;
      final lowestTokenId = max(1, latestTokenId - _maxTokensToDisplay + 1);
      final tokenIds = <String>[];

      for (int tokenId = latestTokenId; tokenId >= lowestTokenId; tokenId--) {
        tokenIds.add(tokenId.toString());
      }

      for (final batch in _chunkList(tokenIds, _batchSize)) {
        final results = await Future.wait(
          batch.map((tokenId) async {
            try {
              if (_nftService == null) return null;
              return await _nftService!.fetchNFTById(
                tokenId,
                skipCreator: true,
              );
            } catch (e) {
              debugPrint('⚠️ Error loading NFT #$tokenId: $e');
              return null;
            }
          }),
          eagerError: false,
        );

        allNFTs.addAll(results.whereType<NFTModel>());
      }
    } catch (e) {
      debugPrint('❌ Error fetching all NFTs: $e');
    }

    return allNFTs;
  }

  int _parseBigIntFromHex(String hexString) {
    try {
      String cleaned = hexString.startsWith('0x')
          ? hexString.substring(2)
          : hexString;
      if (cleaned.isEmpty) return 0;
      return int.parse(cleaned, radix: 16);
    } catch (e) {
      return 0;
    }
  }

  List<List<String>> _chunkList(List<String> items, int chunkSize) {
    final chunks = <List<String>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      final end = min(i + chunkSize, items.length);
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading collection...'),
            ],
          ),
        ),
      );
    }

    if (_allNFTs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.gray400,
              ),
              const SizedBox(height: 16),
              Text(
                'No NFTs found',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mint your first NFT to get started',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate collection stats
    final totalItems = _allNFTs.length;
    final listedNFTs = _allNFTs
        .where((nft) => nft.isListed && nft.price != null)
        .toList();
    final floorPrice = listedNFTs.isNotEmpty
        ? listedNFTs.map((nft) => nft.price!).reduce((a, b) => a < b ? a : b)
        : null;

    // Get preview images (first 3 NFTs)
    final previewNFTs = _allNFTs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nexa NFT Collection',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Collection card
        Container(
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
              // Collection preview images
              Container(
                height: 200,
                margin: const EdgeInsets.all(12),
                child: previewNFTs.length >= 3
                    ? Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildPreviewImage(previewNFTs[0]),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _buildPreviewImage(previewNFTs[1]),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: _buildPreviewImage(previewNFTs[2]),
                          ),
                        ],
                      )
                    : previewNFTs.length == 2
                    ? Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildPreviewImage(previewNFTs[0]),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _buildPreviewImage(previewNFTs[1]),
                          ),
                        ],
                      )
                    : previewNFTs.length == 1
                    ? _buildPreviewImage(previewNFTs[0])
                    : Container(),
              ),
              // Collection info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nexa NFT Collection',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ),
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
                      '$totalItems items',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (floorPrice != null) ...[
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
                            '${floorPrice.toStringAsFixed(4)} ETH',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // NFT Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All NFTs',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _allNFTs.length,
                itemBuilder: (context, index) =>
                    _buildNFTCard(context, _allNFTs[index]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage(NFTModel nft) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        image: nft.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(nft.imageUrl),
                fit: BoxFit.cover,
              )
            : null,
        color: nft.imageUrl.isEmpty ? AppColors.gray200 : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: nft.imageUrl.isEmpty
          ? const Center(
              child: Icon(Icons.image, color: AppColors.gray400, size: 40),
            )
          : null,
    );
  }

  Widget _buildNFTCard(BuildContext context, NFTModel nft) {
    final isMyNFT =
        _currentUserAddress != null &&
        (nft.seller?.toLowerCase() == _currentUserAddress!.toLowerCase() ||
            nft.owner.toLowerCase() == _currentUserAddress!.toLowerCase());

    return GestureDetector(
      onTap: () {
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
                    // My NFT badge
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
                            borderRadius: BorderRadius.circular(12),
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
}
