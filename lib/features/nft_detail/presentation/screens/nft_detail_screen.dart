import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';
import '../../../../data/services/nft_service.dart';
import '../../../../core/services/smart_contract_service.dart';
import '../../../../features/wallet/wallet_provider.dart';
import '../widgets/nft_hero_image.dart';
import '../widgets/nft_info_section.dart';
import '../widgets/nft_attributes.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/price_section.dart';
import '../widgets/action_buttons.dart';
import '../widgets/list_for_sale_dialog.dart';
import '../widgets/cancel_listing_dialog.dart';

class NFTDetailScreen extends StatefulWidget {
  final String nftId;

  const NFTDetailScreen({super.key, required this.nftId});

  @override
  State<NFTDetailScreen> createState() => _NFTDetailScreenState();
}

class _NFTDetailScreenState extends State<NFTDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isLiked = false;
  bool isLoading = true;
  NFTModel? nft;
  String? errorMessage;

  NFTService? _nftService;
  SmartContractService? _smartContractService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeServices() async {
    if (!mounted) return;

    try {
      final walletProvider = context.read<WalletProvider>();

      // Initialize AppKit if not already initialized
      if (walletProvider.appKitModal == null) {
        await walletProvider.initAppKit(context);
      }

      if (walletProvider.appKitModal != null) {
        // Initialize smart contract service
        _smartContractService = SmartContractService(
          walletProvider.appKitModal!,
        );

        try {
          await _smartContractService!.init();
          debugPrint('✅ SmartContractService initialized successfully');
        } catch (e) {
          debugPrint('⚠️ SmartContractService init failed: $e');
          // Continue anyway - service might still work for some operations
        }

        _nftService = NFTService(_smartContractService!);
        await _loadNFTData();
      } else {
        setState(() {
          errorMessage =
              'Wallet not initialized. Please connect your wallet first.';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing services: $e');
      setState(() {
        errorMessage = 'Failed to initialize services: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadNFTData() async {
    if (_nftService == null || !mounted) return;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      debugPrint('🔍 Loading NFT data for tokenId: ${widget.nftId}');
      final fetchedNFT = await _nftService!.fetchNFTById(widget.nftId);

      if (!mounted) return;

      setState(() {
        nft = fetchedNFT;
        isLoading = false;
        if (fetchedNFT == null) {
          errorMessage = 'NFT not found or failed to load';
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading NFT data: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load NFT: $e';
      });
    }
  }

  bool get _isOwner {
    if (nft == null || _smartContractService == null) return false;
    final currentUser = _smartContractService!.getCurrentUserAddress();
    if (currentUser == null) return false;
    return nft!.owner.toLowerCase() == currentUser.toLowerCase();
  }

  String? get _currentUserAddress {
    if (_smartContractService == null) return null;
    return _smartContractService!.getCurrentUserAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.gray50, body: _buildBody());
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading NFT details...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.gray500),
            const SizedBox(height: 16),
            Text(
              'Error Loading NFT',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _initializeServices();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (nft == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: AppColors.gray500,
            ),
            SizedBox(height: 16),
            Text(
              'NFT Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This NFT may not exist or may have been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              NFTInfoSection(nft: nft!),
              const SizedBox(height: 20),
              OwnerInfoCard(nft: nft!, currentUserAddress: _currentUserAddress),
              const SizedBox(height: 20),
              NFTAttributes(nft: nft!),
              const SizedBox(height: 20),
              PriceSection(nft: nft!),
              const SizedBox(height: 20),
              ActionButtons(
                nft: nft!,
                onBuyNow: _onBuyNow,
                onPlaceBid: _onPlaceBid,
                onMakeOffer: _onMakeOffer,
                onListForSale: _onListForSale,
                onCancelListing: _onCancelListing,
                isOwner: _isOwner,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : AppColors.black,
            ),
            onPressed: () => setState(() => isLiked = !isLiked),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          // child: IconButton(
          //   icon: const Icon(Icons.share, color: AppColors.black),
          //   onPressed: _onShare,
          // ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: nft != null
            ? NFTHeroImage(
                imageUrl: nft!.imageUrl,
                views: '0', // Views not implemented yet
                likes: '0', // Likes not implemented yet
              )
            : Container(
                color: AppColors.gray200,
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: AppColors.gray500),
                ),
              ),
      ),
    );
  }

  Future<void> _onBuyNow() async {
    if (nft == null || _smartContractService == null) return;

    final currentUser = _smartContractService!.getCurrentUserAddress();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your wallet first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if NFT is listed
    if (!nft!.isListed || nft!.price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This NFT is not currently listed for sale'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user is trying to buy their own NFT
    if (nft!.seller?.toLowerCase() == currentUser.toLowerCase() ||
        nft!.owner.toLowerCase() == currentUser.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot buy your own NFT'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Buy NFT',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase ${nft!.name}?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  Text(
                    nft!.formattedPrice,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.gray600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm Purchase',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Processing purchase...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please confirm the transaction in your wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final contractAddress =
          nft!.contractAddress ?? _smartContractService!.nftContractAddress;
      final priceInWei = SmartContractService.ethToWei(nft!.price!);

      debugPrint('💰 Buying NFT #${nft!.tokenId} for ${nft!.price} ETH');
      final txHash = await _smartContractService!.buyNFT(
        contractAddress,
        nft!.tokenId,
        priceInWei,
        currentUser,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Purchase Successful!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You now own ${nft!.name}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (txHash.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt,
                          size: 16,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTransactionHash(txHash),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Reload NFT data and go back
                      _loadNFTData().then((_) {
                        Navigator.pop(
                          context,
                          true,
                        ); // Return true to indicate purchase
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      debugPrint('❌ Error buying NFT: $e');

      // Show error dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Purchase Failed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            _getBuyErrorMessage(e),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getBuyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user rejected') ||
        errorStr.contains('user denied')) {
      return 'Transaction was cancelled. Please try again.';
    } else if (errorStr.contains('insufficient funds')) {
      return 'Insufficient funds. Please add more ETH to your wallet.';
    } else if (errorStr.contains('not listed')) {
      return 'This NFT is no longer listed for sale.';
    } else if (errorStr.contains('cannot buy your own')) {
      return 'You cannot buy your own NFT.';
    } else if (errorStr.contains('insufficient payment')) {
      return 'Insufficient payment. Please send the correct amount.';
    } else {
      return 'Failed to purchase NFT: ${error.toString()}';
    }
  }

  void _onPlaceBid() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place Bid'),
        content: const Text('Bid functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onMakeOffer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Offer'),
        content: const Text('Offer functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _onListForSale() async {
    if (nft == null || _smartContractService == null) return;

    final currentUser = _smartContractService!.getCurrentUserAddress();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your wallet first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show listing dialog
    final priceStr = await showDialog<String>(
      context: context,
      builder: (context) => ListForSaleDialog(nft: nft!),
    );

    if (priceStr == null || !mounted) return;

    final priceEth = double.tryParse(priceStr);
    if (priceEth == null || priceEth <= 0) return;

    // Convert ETH to Wei
    final priceInWei = SmartContractService.ethToWei(priceEth);
    final contractAddress =
        nft!.contractAddress ?? _smartContractService!.nftContractAddress;

    // Check if marketplace is already approved (before showing any dialog)
    debugPrint('🔍 Checking marketplace approval status...');

    // Show checking dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Checking approval status...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final isTokenApproved = await _smartContractService!
          .isMarketplaceApprovedForToken(nft!.tokenId);
      final isApprovedForAll = await _smartContractService!
          .isMarketplaceApprovedForAll(currentUser);

      final needsApproval = !isTokenApproved && !isApprovedForAll;

      // Close checking dialog
      if (mounted) Navigator.pop(context);

      // Step 1: Approve marketplace (if needed)
      if (needsApproval) {
        debugPrint('🔐 Step 1: Approving marketplace...');

        // Show approval dialog
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Approving marketplace...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please confirm the transaction in your wallet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );

        final approveResult = await _smartContractService!.approveMarketplace(
          nft!.tokenId,
          currentUser,
        );

        // Close approval dialog first
        if (!mounted) return;
        Navigator.pop(context);

        // Check if approval was successful (not already approved)
        if (approveResult != 'already_approved' &&
            approveResult != 'already_approved_for_all') {
          // Wait for approval transaction to be mined
          debugPrint('⏳ Waiting for approval transaction to be mined...');

          // Show waiting dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Waiting for approval...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while the transaction is being processed',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Wait for approval to be confirmed on blockchain
          final approvalConfirmed = await _smartContractService!
              .waitForApprovalConfirmed(nft!.tokenId, currentUser);

          if (!approvalConfirmed) {
            debugPrint('⚠️ Approval not confirmed, but continuing anyway...');
          }

          // Close waiting dialog
          if (!mounted) return;
          Navigator.pop(context);
        }

        // Show listing dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Listing NFT...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please confirm the transaction in your wallet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        debugPrint('✅ Marketplace already approved, skipping approval step');

        // Show listing dialog directly
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Listing NFT...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please confirm the transaction in your wallet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Step 2: List NFT
      debugPrint('📝 Step 2: Listing NFT for sale...');
      final txHash = await _smartContractService!.listNFTForSale(
        contractAddress,
        nft!.tokenId,
        priceInWei,
        currentUser,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NFT Listed Successfully!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your NFT is now available for sale',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (txHash.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt,
                          size: 16,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTransactionHash(txHash),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
      );

      // Reload NFT data to show updated listing status
      await _loadNFTData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      debugPrint('❌ Error listing NFT: $e');

      // Show error dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Listing Failed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            _getErrorMessage(e),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onCancelListing() async {
    if (nft == null || _smartContractService == null) return;

    final currentUser = _smartContractService!.getCurrentUserAddress();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your wallet first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CancelListingDialog(nft: nft!),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Cancelling listing...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please confirm the transaction in your wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final contractAddress =
          nft!.contractAddress ?? _smartContractService!.nftContractAddress;

      debugPrint('📝 Cancelling listing for NFT #${nft!.tokenId}...');
      final txHash = await _smartContractService!.cancelNFTListing(
        contractAddress,
        nft!.tokenId,
        currentUser,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Listing Cancelled!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your NFT has been removed from the marketplace',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (txHash.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt,
                          size: 16,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTransactionHash(txHash),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
      );

      // Reload NFT data to show updated listing status
      await _loadNFTData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      debugPrint('❌ Error cancelling listing: $e');

      // Show error dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Cancel Failed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            _getCancelErrorMessage(e),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getCancelErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user rejected') ||
        errorStr.contains('user denied')) {
      return 'Transaction was cancelled. Please try again.';
    } else if (errorStr.contains('insufficient funds')) {
      return 'Insufficient funds for gas fees. Please add more ETH to your wallet.';
    } else if (errorStr.contains('not listed')) {
      return 'This NFT is not currently listed for sale.';
    } else if (errorStr.contains('not owner') ||
        errorStr.contains('not seller')) {
      return 'Only the seller can cancel this listing.';
    } else {
      return 'Failed to cancel listing: ${error.toString()}';
    }
  }

  String _formatTransactionHash(String txHash) {
    if (txHash.isEmpty) return 'TX: N/A';

    // Remove any quotes or extra characters
    final cleaned = txHash.replaceAll('"', '').trim();

    if (cleaned.length <= 18) {
      // If hash is too short, just show it as is
      return 'TX: $cleaned';
    }

    // Safely format: first 10 chars + ... + last 8 chars
    try {
      final start = cleaned.substring(0, 10);
      final end = cleaned.substring(cleaned.length - 8);
      return 'TX: $start...$end';
    } catch (e) {
      // Fallback if substring fails
      return 'TX: ${cleaned.length > 20 ? cleaned.substring(0, 20) + '...' : cleaned}';
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user rejected') ||
        errorStr.contains('user denied')) {
      return 'Transaction was cancelled. Please try again.';
    } else if (errorStr.contains('insufficient funds')) {
      return 'Insufficient funds for gas fees. Please add more ETH to your wallet.';
    } else if (errorStr.contains('already approved') ||
        errorStr.contains('already listed')) {
      return 'This NFT is already listed for sale.';
    } else if (errorStr.contains('not owner')) {
      return 'You are not the owner of this NFT.';
    } else {
      return 'Failed to list NFT: ${error.toString()}';
    }
  }
}
