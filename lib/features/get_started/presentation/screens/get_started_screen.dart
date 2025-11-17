import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nexa_app/features/wallet/wallet_provider.dart';
import '../../../../app/constants.dart';
import '../../../../app/routes.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize AppKit and auto-navigate if we already have a session
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.initAppKit(context);
      if (walletProvider.walletAddress != null) {
        if (!mounted) return;
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Image
              Image.asset(
                'assets/images/get_started_image.png',
                width: 400,
                height: 400,
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                AppStrings.getStartedTitle,
                // textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                AppStrings.getStartedSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray600,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _connectWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? AppColors.gray300
                        : AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.gray300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? Row(
                            key: const ValueKey('loading'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Connecting...',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('normal'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/metamask-icon.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.connectMetaMask,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectWallet() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final walletProvider = context.read<WalletProvider>();
      await walletProvider.connectToWallet(context);

      walletProvider.addListener(() {
        print('🥦 ~ walletProvider.walletAddress: ${walletProvider.walletAddress}');
        if (walletProvider.walletAddress != null) {
            context.go(AppRoutes.home);
        }
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Wallet connection initiated',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Connection failed. Please try again.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
