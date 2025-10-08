import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class FilterBar extends StatefulWidget {
  final String selectedCategory;
  final String selectedBlockchain;
  final double minPrice;
  final double maxPrice;
  final Function(String) onCategoryChanged;
  final Function(String) onBlockchainChanged;
  final Function(double, double) onPriceChanged;

  const FilterBar({
    super.key,
    required this.selectedCategory,
    required this.selectedBlockchain,
    required this.minPrice,
    required this.maxPrice,
    required this.onCategoryChanged,
    required this.onBlockchainChanged,
    required this.onPriceChanged,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final List<String> categories = [
    'All', 'Art', 'Music', 'Gaming', 'Sports', 'Photography', 'Collectibles'
  ];
  
  final List<String> blockchains = [
    'All', 'Ethereum', 'Polygon', 'Binance', 'Solana'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category filters
        _buildCategoryFilter(),
        const SizedBox(height: 12),
        // Quick filters
        _buildQuickFilters(),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = widget.selectedCategory == category;
          
          return GestureDetector(
            onTap: () => widget.onCategoryChanged(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray300,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.gray700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Blockchain filter
          _buildFilterChip(
            icon: Icons.public,
            label: widget.selectedBlockchain,
            onTap: _showBlockchainFilter,
          ),
          const SizedBox(width: 8),
          
          // Price filter
          _buildFilterChip(
            icon: Icons.attach_money,
            label: 'Price',
            onTap: _showPriceFilter,
          ),
          const SizedBox(width: 8),
          
          // More filters
          _buildFilterChip(
            icon: Icons.filter_list,
            label: 'More',
            onTap: _showMoreFilters,
          ),
          
          const Spacer(),
          
          // Sort button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, color: AppColors.gray600, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Sort',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gray600, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockchainFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Blockchain',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...blockchains.map((blockchain) => ListTile(
              title: Text(blockchain),
              trailing: widget.selectedBlockchain == blockchain
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                widget.onBlockchainChanged(blockchain);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showPriceFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coming soon!'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('More Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Advanced filters coming soon!'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
