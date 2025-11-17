import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';
import 'package:provider/provider.dart';
import '../../../wallet/wallet_provider.dart';
import '../../../../core/services/pinata_service.dart';
import '../../../../core/services/smart_contract_service.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/upload_area.dart';
import '../widgets/mint_form.dart';
// Blockchain selection removed for Sepolia-only

class MintNFTScreen extends StatefulWidget {
  const MintNFTScreen({super.key});

  @override
  State<MintNFTScreen> createState() => _MintNFTScreenState();
}

class _MintNFTScreenState extends State<MintNFTScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  // Collection removed; Sepolia-only
  String? uploadedImagePath;
  String? _imageCid;
  String? _metadataCid;
  // Properties removed; Sepolia-only
  bool isLoading = false;
  Map<String, dynamic>? _txPreview;
  bool _walletOpened = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload area
              UploadArea(
                imagePath: uploadedImagePath,
                onImageSelected: (path) =>
                    setState(() => uploadedImagePath = path),
              ),

              const SizedBox(height: 20),

              // Form fields (name, description only)
              MintForm(
                nameController: _nameController,
                descriptionController: _descriptionController,
              ),

              const SizedBox(height: 20),

              if (_txPreview != null) _buildTxPreviewCard(_txPreview!),

              // Mint button
              const SizedBox(height: 16),
              _buildMintButton(),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.black),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Mint NFT',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.bug_report,
            color: AppColors.gray600,
            size: 20,
          ),
          onPressed: _showDebugInfo,
          tooltip: 'Debug Information',
        ),
      ],
    );
  }

  // Removed _buildFeeEstimate per request (show fees inside preview only)

  Widget _buildMintButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _mintNFT,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Mint Now',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTxPreviewCard(Map<String, dynamic> preview) {
    final request = preview['request'] as Map<String, dynamic>? ?? {};
    final params =
        (request['params'] as List?)?.first as Map<String, dynamic>? ?? {};
    final from = params['from'] as String? ?? '';
    final to = params['to'] as String? ?? '';
    final gasHex = params['gas'] as String?;
    final gasPriceHex = params['gasPrice'] as String?;
    final gas = _parseHexToBigInt(gasHex);
    final gasPriceWei = _parseHexToBigInt(gasPriceHex);
    final feeWei = gas != null && gasPriceWei != null
        ? gas * gasPriceWei
        : null;
    final feeEth = feeWei != null ? _weiToEth(feeWei) : null;
    final method = request['method'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transaction Preview',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Text(
                  'ETH Sepolia',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEAEAEA)),
          const SizedBox(height: 12),
          _kv('Method', method),
          _kv('From', from),
          _kv('To', to),
          _kv(
            'Fee (ETH Sepolia)',
            feeEth != null ? '${feeEth.toStringAsFixed(6)} ETH' : '-',
          ),
          if (_metadataCid != null) _kv('TokenURI', 'ipfs://$_metadataCid'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: GoogleFonts.inter(
                color: AppColors.gray600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.35,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers to format gas and gas price
  BigInt? _parseHexToBigInt(String? hex) {
    try {
      if (hex == null || hex.isEmpty) return null;
      final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
      if (clean.isEmpty) return BigInt.zero;
      return BigInt.parse(clean, radix: 16);
    } catch (_) {
      return null;
    }
  }

  double _weiToEth(BigInt wei) {
    return wei.toDouble() / 1e18;
  }

  /// Validates all prerequisites before minting
  Future<String?> _validateMintPrerequisites() async {
    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      // Check wallet connection
      if (!walletProvider.isConnected || walletProvider.walletAddress == null) {
        return 'Wallet not connected properly';
      }

      // Check ETH balance for gas fees
      try {
        final balance = await walletProvider.getEthBalance();
        final balanceDouble = double.tryParse(balance) ?? 0.0;
        if (balanceDouble < 0.001) {
          // Minimum 0.001 ETH for gas
          return 'Insufficient ETH balance for gas fees. Need at least 0.001 ETH.';
        }
      } catch (e) {
        print('Warning: Could not check ETH balance: $e');
      }

      // Note: Environment variables will be validated during SmartContractService.init()
      // Required: NFT_CONTRACT_ADDRESS, MARKETPLACE_CONTRACT_ADDRESS

      return null; // No validation errors
    } catch (e) {
      return 'Validation failed: $e';
    }
  }

  /// Shows a debug info dialog for troubleshooting
  void _showDebugInfo() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Wallet Connected: ${walletProvider.isConnected}'),
              Text('Wallet Address: ${walletProvider.walletAddress ?? 'None'}'),
              Text('App Kit Modal: ${walletProvider.appKitModal != null}'),
              const SizedBox(height: 10),
              Text('Image CID: $_imageCid'),
              Text('Metadata CID: $_metadataCid'),
              const SizedBox(height: 10),
              const Text('Environment Variables:'),
              const Text('- NFT_CONTRACT_ADDRESS: Check .env file'),
              const Text('- MARKETPLACE_CONTRACT_ADDRESS: Check .env file'),
              const Text('- PINATA_API_KEY: Check .env file'),
              const Text('- PINATA_SECRET_API_KEY: Check .env file'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _mintNFT() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (uploadedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Run comprehensive validation
    print('🔍 Running pre-mint validation...');
    final validationError = await _validateMintPrerequisites();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Debug Info',
            textColor: Colors.white,
            onPressed: _showDebugInfo,
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print('📸 Starting NFT mint process...');

      // Step 1: Upload image to Pinata
      print('📤 Step 1: Uploading image to Pinata...');
      final pinata = PinataService();
      _imageCid = await pinata.uploadImage(File(uploadedImagePath!));
      print('✅ Image uploaded: $_imageCid');

      // Step 2: Upload metadata to Pinata
      print('📤 Step 2: Uploading metadata to Pinata...');
      _metadataCid = await pinata.uploadMetadata(
        _nameController.text,
        _descriptionController.text,
        'ipfs://$_imageCid',
      );
      print('✅ Metadata uploaded: $_metadataCid');

      // Step 3: Get wallet provider and validate connection
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      if (walletProvider.appKitModal == null) {
        throw Exception('AppKit Modal not initialized');
      }

      if (walletProvider.walletAddress == null) {
        throw Exception('Wallet address not found');
      }
      final recipientAddress = walletProvider.walletAddress!;
      print('👛 Wallet address: $recipientAddress');

      // Step 4: Initialize smart contract service
      print('🔗 Step 3: Initializing smart contract service...');
      final smartContractService = SmartContractService(
        walletProvider.appKitModal!,
      );

      try {
        await smartContractService.init();
        print('✅ Smart contract service initialized');
      } catch (e) {
        throw Exception('Failed to initialize smart contract service: $e');
      }

      // Step 5: Prepare transaction
      final tokenURI = 'ipfs://$_metadataCid';
      print('🎯 Token URI: $tokenURI');
      print('📧 Recipient: $recipientAddress');

      // Step 6: Execute mint transaction
      print('🚀 Step 4: Executing mint transaction...');

      final txHash = await smartContractService.mintNFT(
        recipientAddress,
        tokenURI,
        onPreview: (req) {
          print('👀 Transaction preview received');
          setState(() => _txPreview = req);
          _launchWalletIfPossible();
        },
      );

      print('✅ Transaction successful: $txHash');

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Your NFT "${_nameController.text}" has been minted successfully!\nTX: ${txHash.substring(0, 10)}...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.pop(true); // Close mint screen and return success
              },
              child: const Text('View in Wallet'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Mint NFT failed: $e');

      String errorMessage;

      if (e.toString().contains('User rejected')) {
        errorMessage = 'Transaction was rejected by user';
      } else if (e.toString().contains('insufficient funds')) {
        errorMessage = 'Insufficient funds for gas fees';
      } else if (e.toString().contains('Failed to load contract ABIs')) {
        errorMessage =
            'Contract ABI files not found. Please check assets folder.';
      } else if (e.toString().contains('NFT contract address not found')) {
        errorMessage =
            'NFT contract address not configured. Please check environment variables.';
      } else if (e.toString().contains(
        'Marketplace contract address not found',
      )) {
        errorMessage =
            'Marketplace contract address not configured. Please check environment variables.';
      } else if (e.toString().contains('Web3App not initialized')) {
        errorMessage = 'Wallet connection lost. Please reconnect your wallet.';
      } else if (e.toString().contains('AppKit Modal not initialized')) {
        errorMessage =
            'Wallet not properly initialized. Please restart the app.';
      } else if (e.toString().contains('Wallet address not found')) {
        errorMessage =
            'Could not get wallet address. Please reconnect your wallet.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Pinata')) {
        errorMessage =
            'Failed to upload to IPFS. Please check your internet connection.';
      } else {
        // Generic error with more details for debugging
        errorMessage = 'Failed to mint NFT: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Error',
              textColor: Colors.white,
              onPressed: () {
                // Copy error to clipboard for debugging
                // Clipboard.setData(ClipboardData(text: e.toString()));
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _launchWalletIfPossible() async {
    if (_walletOpened) return;
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final native = walletProvider.appKitModal?.session
        ?.getSessionRedirect()
        ?.native;
    if (native != null && native.isNotEmpty) {
      try {
        // slight delay to allow UI to render preview before switching apps
        await Future.delayed(const Duration(milliseconds: 150));
        await launchUrlString(native, mode: LaunchMode.externalApplication);
        _walletOpened = true;
      } catch (_) {}
    }
  }
}
