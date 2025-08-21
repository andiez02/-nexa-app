import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants.dart';
import '../../../../app/routes.dart';
import '../../../wallet/wallet_provider.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

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
              Image.asset('assets/images/get_started_image.png', width: 400, height: 400),
              
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
                // textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray600,
                  height: 1.5,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Connect MetaMask button
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: walletProvider.isLoading 
                          ? null 
                          : () => _connectMetaMask(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.gray300,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: walletProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/metamask-icon.png'),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.connectMetaMask,
                                  style: GoogleFonts.inter(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _connectMetaMask(BuildContext context) async {
    final walletProvider = context.read<WalletProvider>();
    
    try {
      final success = await walletProvider.connectWallet();
      
      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kết nối ví thành công!',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          // Navigate to home
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              context.go(AppRoutes.home);
            }
          });
        }
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Không thể kết nối ví. Vui lòng thử lại!',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.error,
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
