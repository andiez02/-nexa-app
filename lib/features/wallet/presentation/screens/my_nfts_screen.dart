import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBalances();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        if (!provider.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.gray50,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to wallet...'),
                ],
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
          Tab(text: 'Collected'),
          Tab(text: 'Created'),
          Tab(text: 'On Sale'),
        ],
      ),
    );
  }

  void _onMintNFT() {
    context.go('/mint');
  }
}
