import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';
import '../../../../data/models/nft_model.dart';
import '../../../../data/services/nft_service.dart';
import '../../../../core/services/smart_contract_service.dart';
import '../../wallet_provider.dart';
import '../widgets/balance_card_widget.dart';
import '../widgets/nft_tabs_section.dart';

class MyNFTsScreen extends StatefulWidget {
  const MyNFTsScreen({super.key});

  @override
  State<MyNFTsScreen> createState() => _MyNFTsScreenState();
}

class _MyNFTsScreenState extends State<MyNFTsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String ethBalance = '0.000000';
  String usdcBalance = '0.000000';
  bool isLoadingBalances = true;

  // NFT related state
  Map<NFTCategory, List<NFTModel>> nftData = {
    NFTCategory.collected: [],
    NFTCategory.created: [],
    NFTCategory.onSale: [],
  };
  bool isLoadingNFTs = false;
  NFTService? _nftService;

  // Cache for NFT data to avoid refetching when switching tabs
  DateTime? _nftDataCacheTime;
  String? _cachedUserAddress;
  static const Duration _nftDataCacheExpiry = Duration(
    minutes: 5,
  ); // Cache for 5 minutes

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs: My NFT and On Sale
    _tabController = TabController(length: 2, vsync: this);
    // Always initialize NFT service first, then load balances
    _initializeNFTService();
    _loadBalances();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check wallet state on first build, not on every dependency change
    // This prevents refetching when switching tabs
    if (_nftService == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkWalletStateAndRefresh();
      });
    }
  }

  void _checkWalletStateAndRefresh() {
    final provider = context.read<WalletProvider>();
    final currentAddress = provider.walletAddress;

    // Check if wallet address changed (user switched wallet)
    final addressChanged =
        currentAddress != null && currentAddress != _cachedUserAddress;

    if (provider.isConnected) {
      // Wallet just connected or address changed, reload everything
      if (addressChanged || _nftService == null) {
        _loadBalances();
        _initializeNFTService();
      }
    } else {
      // Wallet disconnected, still show cached NFTs if available
      if (_nftService == null ||
          (nftData[NFTCategory.created]?.isEmpty == true &&
              nftData[NFTCategory.collected]?.isEmpty == true)) {
        _initializeNFTService();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    if (!mounted) return;
    final provider = context.read<WalletProvider>();

    setState(() => isLoadingBalances = true);

    final results = await Future.wait([
      provider.getEthBalance(),
      provider.getUsdcBalance(),
    ]);

    if (mounted) {
      setState(() {
        ethBalance = results[0];
        usdcBalance = results[1];
        isLoadingBalances = false;
      });
    }
  }

  Future<void> _initializeNFTService() async {
    try {
      final walletProvider = context.read<WalletProvider>();

      if (walletProvider.appKitModal != null) {
        // Initialize smart contract service
        final smartContractService = SmartContractService(
          walletProvider.appKitModal!,
        );

        try {
          await smartContractService.init();
          print('✅ SmartContractService initialized successfully');
        } catch (e) {
          print('⚠️ SmartContractService init failed: $e');
          // Continue anyway - service might still work for some operations
        }

        _nftService = NFTService(smartContractService);
        await _loadNFTs();
      } else {
        print('❌ No appKitModal available - cannot initialize NFT service');
        setState(() => isLoadingNFTs = false);
      }
    } catch (e) {
      print('❌ Error initializing NFT service: $e');
      setState(() => isLoadingNFTs = false);
    }
  }

  Future<void> _loadNFTs({bool forceRefresh = false}) async {
    if (_nftService == null || !mounted) return;

    final walletProvider = context.read<WalletProvider>();
    final userAddress = walletProvider.walletAddress;

    if (userAddress == null || userAddress.isEmpty) {
      print('⚠️ No user address available - cannot fetch NFTs');
      setState(() => isLoadingNFTs = false);
      return;
    }

    // Check cache first (unless force refresh)
    if (!forceRefresh &&
        _nftDataCacheTime != null &&
        _cachedUserAddress == userAddress) {
      final cacheAge = DateTime.now().difference(_nftDataCacheTime!);
      if (cacheAge < _nftDataCacheExpiry) {
        print('✅ Using cached NFT data (age: ${cacheAge.inSeconds}s)');
        // Data is already in nftData, just return
        setState(() => isLoadingNFTs = false);
        return;
      } else {
        print(
          '⏰ NFT cache expired (age: ${cacheAge.inSeconds}s), refreshing...',
        );
      }
    }

    // Check if user address changed
    if (_cachedUserAddress != null && _cachedUserAddress != userAddress) {
      print('🔄 User address changed, clearing cache and fetching new data');
      forceRefresh = true;
    }

    print('🔄 Loading NFTs for user: $userAddress');

    setState(() => isLoadingNFTs = true);

    try {
      final result = await _nftService!.fetchUserNFTs(userAddress);
      print('📊 NFT fetch result: $result');

      if (mounted) {
        setState(() {
          nftData = result;
          isLoadingNFTs = false;
          // Update cache
          _nftDataCacheTime = DateTime.now();
          _cachedUserAddress = userAddress;
        });

        final totalNFTs =
            (result[NFTCategory.created]?.length ?? 0) +
            (result[NFTCategory.collected]?.length ?? 0) +
            (result[NFTCategory.onSale]?.length ?? 0);

        print('✅ Loaded $totalNFTs NFTs:');
        print('  - Created: ${result[NFTCategory.created]?.length ?? 0}');
        print('  - Collected: ${result[NFTCategory.collected]?.length ?? 0}');
        print('  - On Sale: ${result[NFTCategory.onSale]?.length ?? 0}');
        print(
          '💾 Cached NFT data for ${_nftDataCacheExpiry.inMinutes} minutes',
        );
      }
    } catch (e) {
      print('❌ Error loading NFTs: $e');
      if (mounted) {
        setState(() => isLoadingNFTs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        // Show connection prompt if wallet is not connected
        if (!provider.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.gray50,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.gray200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wallet,
                        size: 60,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connect Your Wallet',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect your wallet to view and manage your NFTs',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.gray500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => provider.connectToWallet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Connect Wallet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.gray50,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(provider),
                const SizedBox(height: 20),
                BalanceCardWidget(
                  ethBalance: ethBalance,
                  usdcBalance: usdcBalance,
                  isLoading: isLoadingBalances,
                  onRefresh: _loadBalances,
                ),
                const SizedBox(height: 24),
                _buildTabBar(),
                Expanded(
                  child: NFTTabsSection(
                    tabController: _tabController,
                    nftData: nftData,
                    isLoading: isLoadingNFTs,
                    onRefresh: () => _loadNFTs(forceRefresh: true),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _onMintNFT,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Mint NFT',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(WalletProvider provider) {
    final address = provider.walletAddress ?? '';
    final shortAddress = address.isNotEmpty
        ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Wallet',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              if (shortAddress.isNotEmpty)
                Text(
                  shortAddress,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings,
              color: AppColors.gray600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        splashFactory: NoSplash.splashFactory,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.gray600,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'My NFT'),
          Tab(text: 'On Sale'),
        ],
      ),
    );
  }

  void _onMintNFT() async {
    // Navigate to mint screen and refresh when returning
    final result = await context.push('/mint');

    // If user successfully minted an NFT, refresh the list
    if (result == true) {
      await _loadNFTs(forceRefresh: true);
    }
  }
}
