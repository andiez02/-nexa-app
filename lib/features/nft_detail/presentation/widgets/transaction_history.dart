import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  // Mock transaction data
  final List<Map<String, dynamic>> transactions = const [
    {
      'type': 'Sale',
      'price': '2.5 ETH',
      'from': '0x1234...5678',
      'to': '0x9876...4321',
      'date': '2 hours ago',
      'txHash': '0xabcd...efgh',
      'icon': Icons.sell,
      'color': AppColors.success,
    },
    {
      'type': 'Transfer',
      'price': '—',
      'from': '0x5555...6666',
      'to': '0x1234...5678',
      'date': '1 day ago',
      'txHash': '0xijkl...mnop',
      'icon': Icons.swap_horiz,
      'color': AppColors.info,
    },
    {
      'type': 'Mint',
      'price': '—',
      'from': '0x0000...0000',
      'to': '0x5555...6666',
      'date': '3 days ago',
      'txHash': '0xqrst...uvwx',
      'icon': Icons.create,
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Icon(
                  Icons.history,
                  color: AppColors.gray500,
                  size: 20,
                ),
              ],
            ),
          ),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildTransactionItem(transactions[index]),
          ),
          
          // View all button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {},
              child: Text(
                'View all transactions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Transaction type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (transaction['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: transaction['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Transaction info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      transaction['type'],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    if (transaction['price'] != '—') ...[
                      const Spacer(),
                      Text(
                        transaction['price'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'From ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                    Text(
                      transaction['from'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    Text(
                      ' to ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                    Text(
                      transaction['to'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['date'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          
          // External link icon
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.open_in_new,
              color: AppColors.gray400,
              size: 16,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
