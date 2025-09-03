import 'package:flutter/material.dart';
import 'package:nexa_app/app/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nexa_app/core/utils/helper.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../wallet_provider.dart';
import '../../../../app/routes.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        if (!walletProvider.isConnected) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(
              "Assets Management",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings, color: AppColors.black),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: "Connect wallet - ",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                        children: [
                          // NameSpace
                          TextSpan(
                            text:
                                walletProvider.session?.peer.metadata.name ??
                                '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 28,
                      color: AppColors.gray200,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/ethereum.png',
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shortenAddress(walletProvider.walletAddress),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // USDC Balance Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/ethereum.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "USDC Balance (Sepolia)",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<String>(
                        future: walletProvider.getUsdcBalance(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Loading...",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return Text(
                              "Lỗi: ${snapshot.error}",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            );
                          } else {
                            return Row(
                              children: [
                                Text(
                                  "${snapshot.data ?? '0'} USDC",
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(
                                      () {},
                                    ); // Refresh to reload balance
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(
                                    "Refresh",
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: _disconnect,
                  child: const Text("Disconnect"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _disconnect() async {
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.disconnect();
    if (mounted) {
      context.go(AppRoutes.getStarted);
    }
  }
}
