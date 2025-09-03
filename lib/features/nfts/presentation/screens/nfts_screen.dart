import 'package:flutter/material.dart';
import 'package:nexa_app/app/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nexa_app/features/nfts/presentation/widgets/market.dart';
import 'package:nexa_app/features/nfts/presentation/widgets/mint_nft.dart';

class NftsScreen extends StatefulWidget {
  const NftsScreen({super.key});

  @override
  State<NftsScreen> createState() => _NftsScreenState();
}

class _NftsScreenState extends State<NftsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: TabBar(
          controller: _tabController,
          isScrollable: false,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          labelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: "Market"),
            Tab(text: "Mint NFT"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildMarketTab(), buildMintNFTTab()],
      ),
    );
  }
}
