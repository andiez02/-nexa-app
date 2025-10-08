import 'package:flutter/material.dart';

import '../../../../app/constants.dart';
import '../widgets/nft_hero_image.dart';
import '../widgets/nft_info_section.dart';
import '../widgets/nft_attributes.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/price_section.dart';
import '../widgets/action_buttons.dart';
import '../widgets/transaction_history.dart';

class NFTDetailScreen extends StatefulWidget {
  final String nftId;

  const NFTDetailScreen({
    super.key,
    required this.nftId,
  });

  @override
  State<NFTDetailScreen> createState() => _NFTDetailScreenState();
}

class _NFTDetailScreenState extends State<NFTDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isLiked = false;
  
  // Mock NFT data
  final Map<String, dynamic> nftData = {
    'id': '1234',
    'name': 'Cosmic Dreams #1234',
    'description': 'A mesmerizing journey through the cosmos, this piece represents the infinite possibilities of digital art and the boundless nature of human creativity.',
    'image': 'nft_image_1',
    'price': '2.5',
    'currency': 'ETH',
    'creator': {
      'name': 'ArtistDAO',
      'address': '0x1234567890123456789012345678901234567890',
      'avatar': 'A',
      'verified': true,
    },
    'owner': {
      'name': 'CryptoCollector',
      'address': '0x9876543210987654321098765432109876543210',
      'avatar': 'C',
      'verified': false,
    },
    'attributes': [
      {'trait_type': 'Background', 'value': 'Cosmic Blue'},
      {'trait_type': 'Eyes', 'value': 'Starlight'},
      {'trait_type': 'Rarity', 'value': 'Legendary'},
      {'trait_type': 'Power Level', 'value': '9500'},
    ],
    'blockchain': 'Ethereum',
    'tokenId': '#1234',
    'contract': '0xabcd...efgh',
    'views': '12.5k',
    'likes': '234',
    'isForSale': true,
    'saleType': 'fixed', // fixed, auction
    'auctionEndTime': null,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                NFTInfoSection(nftData: nftData),
                const SizedBox(height: 20),
                OwnerInfoCard(
                  creator: nftData['creator'],
                  owner: nftData['owner'],
                ),
                const SizedBox(height: 20),
                NFTAttributes(attributes: nftData['attributes']),
                const SizedBox(height: 20),
                PriceSection(
                  price: nftData['price'],
                  currency: nftData['currency'],
                  isForSale: nftData['isForSale'],
                  saleType: nftData['saleType'],
                ),
                const SizedBox(height: 20),
                ActionButtons(
                  isForSale: nftData['isForSale'],
                  saleType: nftData['saleType'],
                  onBuyNow: _onBuyNow,
                  onPlaceBid: _onPlaceBid,
                  onMakeOffer: _onMakeOffer,
                ),
                const SizedBox(height: 24),
                const TransactionHistory(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
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
          child: IconButton(
            icon: const Icon(Icons.share, color: AppColors.black),
            onPressed: _onShare,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: NFTHeroImage(
          imageUrl: 'assets/images/${nftData['image']}.png',
          views: nftData['views'],
          likes: nftData['likes'],
        ),
      ),
    );
  }

  void _onBuyNow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy NFT'),
        content: Text('Purchase ${nftData['name']} for ${nftData['price']} ${nftData['currency']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchase initiated!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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

  void _onShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}
