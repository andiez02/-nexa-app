import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Service class for interacting with the smart contracts using Reown Appkit.
class SmartContractService {
  final ReownAppKitModal _appKitModal;
  // Use environment variables if available, otherwise use test addresses
  final String _nftContractAddress =
      dotenv.env['NFT_CONTRACT_ADDRESS'] ??
      '0x1234567890123456789012345678901234567890'; // Test address - replace with actual
  final String _marketplaceContractAddress =
      dotenv.env['MARKETPLACE_CONTRACT_ADDRESS'] ??
      '0x0987654321098765432109876543210987654321'; // Test address - replace with actual

  // Getters for contract addresses (needed by NFT service)
  String get nftContractAddress => _nftContractAddress;
  String get marketplaceContractAddress => _marketplaceContractAddress;

  // Cache for loaded ABIs
  Map<String, dynamic>? _nftAbi;
  Map<String, dynamic>? _marketplaceAbi;

  SmartContractService(this._appKitModal);

  /// Getters for contract addresses
  /// Initializes the service by loading ABIs and validating contract addresses.
  Future<void> init() async {
    debugPrint('🔧 Initializing SmartContractService...');
    debugPrint('📍 NFT Contract: $_nftContractAddress');
    debugPrint('📍 Marketplace Contract: $_marketplaceContractAddress');

    // Validate contract addresses
    if (_nftContractAddress.isEmpty ||
        _nftContractAddress == '0x1234567890123456789012345678901234567890') {
      debugPrint(
        '⚠️ Using test NFT contract address. Please set NFT_CONTRACT_ADDRESS in .env file',
      );
    }
    if (_marketplaceContractAddress.isEmpty ||
        _marketplaceContractAddress ==
            '0x0987654321098765432109876543210987654321') {
      debugPrint(
        '⚠️ Using test marketplace contract address. Please set MARKETPLACE_CONTRACT_ADDRESS in .env file',
      );
    }

    // Load ABIs from assets
    try {
      await _loadABIs();
      debugPrint('✅ SmartContractService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to load ABIs: $e');
      throw e;
    }
  }

  /// Loads contract ABIs from asset files
  Future<void> _loadABIs() async {
    try {
      // Load NFT ABI
      final nftAbiString = await rootBundle.loadString(
        'assets/abi/NexaNFT.json',
      );
      _nftAbi = jsonDecode(nftAbiString);

      // Load Marketplace ABI
      final marketplaceAbiString = await rootBundle.loadString(
        'assets/abi/NexaMarketplace.json',
      );
      _marketplaceAbi = jsonDecode(marketplaceAbiString);
    } catch (e) {
      throw Exception('Failed to load contract ABIs: $e');
    }
  }

  /// Creates a deployed contract instance using loaded ABI
  DeployedContract _createContract({
    required String contractType, // 'nft' or 'marketplace'
    required String contractAddress,
  }) {
    Map<String, dynamic>? contractAbi;
    String contractName;

    if (contractType == 'nft') {
      contractAbi = _nftAbi;
      contractName = 'NexaNFT';
    } else if (contractType == 'marketplace') {
      contractAbi = _marketplaceAbi;
      contractName = 'NexaMarketplace';
    } else {
      throw Exception('Invalid contract type: $contractType');
    }

    if (contractAbi == null) {
      throw Exception('ABI not loaded for contract type: $contractType');
    }

    return DeployedContract(
      ContractAbi.fromJson(jsonEncode(contractAbi['abi']), contractName),
      EthereumAddress.fromHex(contractAddress),
    );
  }

  /// Mints a new NFT by calling the smart contract via Reown Appkit.
  /// Optionally surfaces a preview of the request via [onPreview] before sending.
  /// Returns the transaction hash if successful.
  Future<String> mintNFT(
    String recipientAddress,
    String tokenURI, {
    void Function(Map<String, dynamic> request)? onPreview,
  }) async {
    // Validate inputs
    if (recipientAddress.isEmpty || tokenURI.isEmpty) {
      throw Exception('Recipient address and token URI cannot be empty.');
    }

    try {
      // Get the Web3App instance from Reown AppKit
      final web3App = _appKitModal.appKit;

      if (web3App == null) {
        throw Exception(
          'Web3App not initialized. Please connect wallet first.',
        );
      }

      // Create NFT contract using loaded ABI
      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('mint');
      final data = function.encodeCall([
        EthereumAddress.fromHex(recipientAddress),
        tokenURI,
      ]);

      // Construct transaction parameters for eth_sendTransaction
      final transactionParams = {
        'from': recipientAddress,
        'to': _nftContractAddress,
        'data':
            '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x30D40', // 200,000 gas limit (tối ưu cho mint NFT)
        'gasPrice': '0x77359400', // 2 Gwei (rất thấp trên Sepolia testnet)
      };

      // Surface preview to UI before sending
      onPreview?.call({
        'chainId': 'eip155:11155111',
        'request': {
          'method': 'eth_sendTransaction',
          'params': [transactionParams],
        },
      });

      // Proactively open the connected wallet via its native redirect to foreground it
      try {
        final native = _appKitModal.session?.getSessionRedirect()?.native;
        if (native != null && native.isNotEmpty) {
          await launchUrlString(native, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}

      // Send transaction through connected wallet
      final result = await web3App.request(
        topic: web3App.getActiveSessions().keys.first,
        chainId: 'eip155:11155111',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transactionParams],
        ),
      );

      return result.toString();
    } catch (e) {
      throw Exception('Failed to mint NFT: $e');
    }
  }

  /// Lists an NFT for sale on the marketplace.
  /// Returns the transaction hash if successful.
  Future<String> listNFTForSale(
    String nftContractAddress,
    String tokenId,
    String priceInWei,
    String userAddress, {
    void Function(Map<String, dynamic> request)? onPreview,
  }) async {
    // Validate inputs
    if (nftContractAddress.isEmpty ||
        tokenId.isEmpty ||
        priceInWei.isEmpty ||
        userAddress.isEmpty) {
      throw Exception('All parameters cannot be empty.');
    }

    try {
      final web3App = _appKitModal.appKit;
      if (web3App == null) {
        throw Exception(
          'Web3App not initialized. Please connect wallet first.',
        );
      }

      // Create marketplace contract using loaded ABI
      final contract = _createContract(
        contractType: 'marketplace',
        contractAddress: _marketplaceContractAddress,
      );

      final function = contract.function('listItem');
      final data = function.encodeCall([
        EthereumAddress.fromHex(nftContractAddress),
        BigInt.parse(tokenId),
        BigInt.parse(priceInWei),
      ]);

      final transactionParams = {
        'from': userAddress,
        'to': _marketplaceContractAddress,
        'value': '0x0', // No ETH value for listing
        'data':
            '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x30D40', // 200,000 gas limit
        'gasPrice': '0x77359400', // 2 Gwei
      };

      onPreview?.call({
        'chainId': 'eip155:11155111',
        'request': {
          'method': 'eth_sendTransaction',
          'params': [transactionParams],
        },
      });

      // Get active session topic
      final sessions = web3App.getActiveSessions();
      if (sessions.isEmpty) {
        throw Exception('No active wallet session found');
      }
      final topic = sessions.keys.first;

      // Launch wallet app first
      try {
        final native = _appKitModal.session?.getSessionRedirect()?.native;
        if (native != null && native.isNotEmpty) {
          await launchUrlString(native, mode: LaunchMode.externalApplication);
          // Wait a bit for wallet to open
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('⚠️ Could not launch wallet app: $e');
      }

      debugPrint('📤 Sending listing transaction request...');
      debugPrint('📋 Transaction params: $transactionParams');

      final result = await web3App.request(
        topic: topic,
        chainId: 'eip155:11155111',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transactionParams],
        ),
      );

      debugPrint('✅ Listing transaction result: $result');

      return result.toString();
    } catch (e) {
      throw Exception('Failed to list NFT: $e');
    }
  }

  /// Buys an NFT from the marketplace.
  /// Returns the transaction hash if successful.
  Future<String> buyNFT(
    String nftContractAddress,
    String tokenId,
    String priceInWei,
    String userAddress, {
    void Function(Map<String, dynamic> request)? onPreview,
  }) async {
    // Validate inputs
    if (nftContractAddress.isEmpty ||
        tokenId.isEmpty ||
        priceInWei.isEmpty ||
        userAddress.isEmpty) {
      throw Exception('All parameters cannot be empty.');
    }

    try {
      final web3App = _appKitModal.appKit;
      if (web3App == null) {
        throw Exception(
          'Web3App not initialized. Please connect wallet first.',
        );
      }

      // Create marketplace contract using loaded ABI
      final contract = _createContract(
        contractType: 'marketplace',
        contractAddress: _marketplaceContractAddress,
      );

      final function = contract.function('buyItem');
      final data = function.encodeCall([
        EthereumAddress.fromHex(nftContractAddress),
        BigInt.parse(tokenId),
      ]);

      final transactionParams = {
        'from': userAddress,
        'to': _marketplaceContractAddress,
        'value':
            '0x${BigInt.parse(priceInWei).toRadixString(16)}', // Send ETH with transaction
        'data':
            '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x30D40', // 200,000 gas limit
        'gasPrice': '0x77359400', // 2 Gwei
      };

      onPreview?.call({
        'chainId': 'eip155:11155111',
        'request': {
          'method': 'eth_sendTransaction',
          'params': [transactionParams],
        },
      });

      // Get active session topic
      final sessions = web3App.getActiveSessions();
      if (sessions.isEmpty) {
        throw Exception('No active wallet session found');
      }
      final topic = sessions.keys.first;

      // Launch wallet app first
      try {
        final native = _appKitModal.session?.getSessionRedirect()?.native;
        if (native != null && native.isNotEmpty) {
          await launchUrlString(native, mode: LaunchMode.externalApplication);
          // Wait a bit for wallet to open
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('⚠️ Could not launch wallet app: $e');
      }

      debugPrint('📤 Sending buy transaction request...');
      debugPrint('📋 Transaction params: $transactionParams');

      final result = await web3App.request(
        topic: topic,
        chainId: 'eip155:11155111',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transactionParams],
        ),
      );

      debugPrint('✅ Buy transaction result: $result');

      return result.toString();
    } catch (e) {
      throw Exception('Failed to buy NFT: $e');
    }
  }

  /// Cancels an NFT listing on the marketplace.
  /// Returns the transaction hash if successful.
  Future<String> cancelNFTListing(
    String nftContractAddress,
    String tokenId,
    String userAddress, {
    void Function(Map<String, dynamic> request)? onPreview,
  }) async {
    // Validate inputs
    if (nftContractAddress.isEmpty || tokenId.isEmpty || userAddress.isEmpty) {
      throw Exception('All parameters cannot be empty.');
    }

    try {
      final web3App = _appKitModal.appKit;
      if (web3App == null) {
        throw Exception(
          'Web3App not initialized. Please connect wallet first.',
        );
      }

      // Create marketplace contract using loaded ABI
      final contract = _createContract(
        contractType: 'marketplace',
        contractAddress: _marketplaceContractAddress,
      );

      final function = contract.function('cancelListing');
      final data = function.encodeCall([
        EthereumAddress.fromHex(nftContractAddress),
        BigInt.parse(tokenId),
      ]);

      final transactionParams = {
        'from': userAddress,
        'to': _marketplaceContractAddress,
        'value': '0x0', // No ETH value for cancel
        'data':
            '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x30D40', // 200,000 gas limit
        'gasPrice': '0x77359400', // 2 Gwei
      };

      onPreview?.call({
        'chainId': 'eip155:11155111',
        'request': {
          'method': 'eth_sendTransaction',
          'params': [transactionParams],
        },
      });

      // Get active session topic
      final sessions = web3App.getActiveSessions();
      if (sessions.isEmpty) {
        throw Exception('No active wallet session found');
      }
      final topic = sessions.keys.first;

      // Launch wallet app first
      try {
        final native = _appKitModal.session?.getSessionRedirect()?.native;
        if (native != null && native.isNotEmpty) {
          await launchUrlString(native, mode: LaunchMode.externalApplication);
          // Wait a bit for wallet to open
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('⚠️ Could not launch wallet app: $e');
      }

      debugPrint('📤 Sending cancel listing transaction request...');
      debugPrint('📋 Transaction params: $transactionParams');

      final result = await web3App.request(
        topic: topic,
        chainId: 'eip155:11155111',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transactionParams],
        ),
      );

      debugPrint('✅ Cancel listing transaction result: $result');

      return result.toString();
    } catch (e) {
      throw Exception('Failed to cancel listing: $e');
    }
  }

  /// Gets listing information for an NFT from the marketplace.
  /// Returns a Map with price, seller, and active status.
  Future<Map<String, dynamic>> getNFTListing(
    String nftContractAddress,
    String tokenId,
  ) async {
    // Validate inputs
    if (nftContractAddress.isEmpty || tokenId.isEmpty) {
      throw Exception('NFT contract address and token ID cannot be empty.');
    }

    try {
      debugPrint('🔍 Getting NFT listing for token $tokenId...');

      // Create marketplace contract using loaded ABI
      final contract = _createContract(
        contractType: 'marketplace',
        contractAddress: _marketplaceContractAddress,
      );

      final function = contract.function('getListing');
      final data = function.encodeCall([
        EthereumAddress.fromHex(nftContractAddress),
        BigInt.parse(tokenId),
      ]);

      final callData =
          '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      debugPrint('📞 Making RPC call to get listing: $callData');

      // Use direct RPC call instead of wallet session for view functions
      final result = await _makeDirectRPCCall('eth_call', [
        {'to': _marketplaceContractAddress, 'data': callData},
        'latest',
      ]);

      debugPrint('📄 Raw listing result: $result');
      return {'success': true, 'data': result};
    } catch (e) {
      debugPrint('❌ Failed to get NFT listing: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Gets the owner of an NFT token
  Future<String> getNFTOwner(String tokenId) async {
    if (tokenId.isEmpty) {
      throw Exception('Token ID cannot be empty.');
    }

    try {
      debugPrint('👤 Getting NFT owner for token $tokenId...');

      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('ownerOf');
      final data = function.encodeCall([BigInt.parse(tokenId)]);

      final callData =
          '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      // Use direct RPC call instead of wallet session
      final result = await _makeDirectRPCCall('eth_call', [
        {'to': _nftContractAddress, 'data': callData},
        'latest',
      ]);

      debugPrint('👤 NFT owner result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Failed to get NFT owner: $e');
      throw Exception('Failed to get NFT owner: $e');
    }
  }

  /// Gets the total supply of NFTs
  Future<String> getNFTTotalSupply() async {
    try {
      debugPrint('📊 Getting NFT total supply...');

      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('totalSupply');
      final data = function.encodeCall([]);

      final callData =
          '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      // Use direct RPC call instead of wallet session
      final result = await _makeDirectRPCCall('eth_call', [
        {'to': _nftContractAddress, 'data': callData},
        'latest',
      ]);

      debugPrint('📊 NFT total supply result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Failed to get NFT total supply: $e');
      throw Exception('Failed to get NFT total supply: $e');
    }
  }

  /// Gets the token URI for an NFT
  Future<String> getNFTTokenURI(String tokenId) async {
    if (tokenId.isEmpty) {
      throw Exception('Token ID cannot be empty.');
    }

    try {
      debugPrint('🔗 Getting NFT token URI for token $tokenId...');

      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('tokenURI');
      final data = function.encodeCall([BigInt.parse(tokenId)]);

      final callData =
          '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      // Use direct RPC call instead of wallet session
      final result = await _makeDirectRPCCall('eth_call', [
        {'to': _nftContractAddress, 'data': callData},
        'latest',
      ]);

      debugPrint('🔗 NFT token URI result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Failed to get NFT token URI: $e');
      throw Exception('Failed to get NFT token URI: $e');
    }
  }

  /// Checks if marketplace is approved for a specific token
  Future<bool> isMarketplaceApprovedForToken(String tokenId) async {
    if (tokenId.isEmpty) {
      throw Exception('Token ID cannot be empty.');
    }

    try {
      debugPrint('🔍 Checking approval for token $tokenId...');

      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('getApproved');
      final data = function.encodeCall([BigInt.parse(tokenId)]);

      final callData =
          '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      final result = await _makeDirectRPCCall('eth_call', [
        {'to': _nftContractAddress, 'data': callData},
        'latest',
      ]);

      // Parse result - getApproved returns address (20 bytes = 40 hex chars + 24 padding)
      final approvedAddress = _parseAddressFromResult(result);
      final isApproved =
          approvedAddress.toLowerCase() ==
              _marketplaceContractAddress.toLowerCase() &&
          approvedAddress != '0x0000000000000000000000000000000000000000';

      debugPrint(
        '✅ Approval check: $isApproved (approved: $approvedAddress, marketplace: $_marketplaceContractAddress)',
      );
      return isApproved;
    } catch (e) {
      debugPrint('❌ Failed to check approval: $e');
      return false;
    }
  }

  /// Checks if marketplace is approved for all tokens of an owner
  Future<bool> isMarketplaceApprovedForAll(String ownerAddress) async {
    if (ownerAddress.isEmpty) {
      throw Exception('Owner address cannot be empty.');
    }

    try {
      debugPrint('🔍 Checking isApprovedForAll for owner $ownerAddress...');

      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('isApprovedForAll');
      final data = function.encodeCall([
        EthereumAddress.fromHex(ownerAddress),
        EthereumAddress.fromHex(_marketplaceContractAddress),
      ]);

      final callData =
          '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      final result = await _makeDirectRPCCall('eth_call', [
        {'to': _nftContractAddress, 'data': callData},
        'latest',
      ]);

      // Parse boolean result (last byte)
      final cleaned = result.startsWith('0x') ? result.substring(2) : result;
      final lastByte = cleaned.length >= 2
          ? cleaned.substring(cleaned.length - 2)
          : '00';
      final isApproved = int.parse(lastByte, radix: 16) > 0;

      debugPrint('✅ isApprovedForAll: $isApproved');
      return isApproved;
    } catch (e) {
      debugPrint('❌ Failed to check isApprovedForAll: $e');
      return false;
    }
  }

  /// Gets the creator (minter) address of an NFT by querying TokenMinted event
  /// TokenMinted(uint256 indexed tokenId, address indexed to, string tokenURI)
  Future<String?> getNFTCreator(String tokenId) async {
    if (tokenId.isEmpty) {
      throw Exception('Token ID cannot be empty.');
    }

    try {
      debugPrint('🔍 Getting NFT creator for token $tokenId...');

      // TokenMinted event signature: TokenMinted(uint256 indexed tokenId, address indexed to, string tokenURI)
      // Event signature hash: keccak256("TokenMinted(uint256,address,string)")
      // Calculated: 0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f
      const tokenMintedEventSignature =
          '0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f';

      // Encode tokenId as uint256 (64 hex chars = 32 bytes)
      final tokenIdBigInt = BigInt.parse(tokenId);
      final tokenIdHex = tokenIdBigInt.toRadixString(16).padLeft(64, '0');

      // Get current block number to limit query range
      // Most RPC nodes limit to 50000 blocks, so we'll query from latest - 40000
      String fromBlock = 'earliest'; // Default fallback
      try {
        final currentBlockHex = await _makeDirectRPCCall('eth_blockNumber', []);
        if (currentBlockHex.isNotEmpty && currentBlockHex != 'null') {
          final currentBlock = BigInt.parse(
            currentBlockHex.startsWith('0x')
                ? currentBlockHex.substring(2)
                : currentBlockHex,
            radix: 16,
          );
          // Query from 40000 blocks ago (safe limit under 50000)
          final fromBlockNum = currentBlock - BigInt.from(40000);
          if (fromBlockNum > BigInt.zero) {
            fromBlock = '0x${fromBlockNum.toRadixString(16)}';
            debugPrint(
              '📊 Querying from block: $fromBlock (current: $currentBlockHex)',
            );
          } else {
            fromBlock = '0x0';
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not get current block, using earliest: $e');
        // fromBlock already set to 'earliest' as default
      }

      // Query logs - TokenMinted event
      // Topics: [eventSignature, tokenId, to]
      final logs = await _makeDirectRPCCall('eth_getLogs', [
        {
          'address': _nftContractAddress,
          'topics': [
            tokenMintedEventSignature,
            '0x$tokenIdHex', // tokenId (indexed)
            null, // to address (indexed, but we want any)
          ],
          'fromBlock': fromBlock,
          'toBlock': 'latest',
        },
      ]);

      debugPrint('📋 TokenMinted event logs result: $logs');

      // Parse logs to find the mint event
      if (logs.isNotEmpty && logs != 'null' && !logs.contains('null')) {
        try {
          final logsList = jsonDecode(logs) as List;
          if (logsList.isNotEmpty) {
            // Get the first TokenMinted event (should be the only one for this tokenId)
            final firstLog = logsList[0] as Map<String, dynamic>;
            final topics = firstLog['topics'] as List;

            // topics[0] = event signature
            // topics[1] = tokenId (indexed)
            // topics[2] = to address (indexed) - this is the creator/minter
            if (topics.length >= 3) {
              final toAddressHex = topics[2] as String;
              // Remove 0x prefix and pad to 40 chars (20 bytes)
              String cleaned = toAddressHex.startsWith('0x')
                  ? toAddressHex.substring(2)
                  : toAddressHex;
              // Take last 40 chars (address is 20 bytes = 40 hex chars)
              if (cleaned.length >= 40) {
                final address = '0x${cleaned.substring(cleaned.length - 40)}';
                debugPrint(
                  '✅ NFT creator found from TokenMinted event: $address',
                );
                return address;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing TokenMinted logs: $e');
        }
      }

      // Fallback: Try Transfer event with from = 0x0000... (mint event)
      debugPrint(
        '⚠️ TokenMinted event not found, trying Transfer event fallback...',
      );
      const transferEventSignature =
          '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
      const zeroAddress =
          '0000000000000000000000000000000000000000000000000000000000000000';

      final transferLogs = await _makeDirectRPCCall('eth_getLogs', [
        {
          'address': _nftContractAddress,
          'topics': [
            transferEventSignature,
            '0x$zeroAddress', // from = 0x0000... means mint
            null, // to can be any address
            '0x$tokenIdHex', // tokenId
          ],
          'fromBlock': fromBlock,
          'toBlock': 'latest',
        },
      ]);

      if (transferLogs.isNotEmpty &&
          transferLogs != 'null' &&
          !transferLogs.contains('null')) {
        try {
          final logsList = jsonDecode(transferLogs) as List;
          if (logsList.isNotEmpty) {
            final firstLog = logsList[0] as Map<String, dynamic>;
            final topics = firstLog['topics'] as List;

            if (topics.length >= 3) {
              final toAddressHex = topics[2] as String;
              String cleaned = toAddressHex.startsWith('0x')
                  ? toAddressHex.substring(2)
                  : toAddressHex;
              if (cleaned.length >= 40) {
                final address = '0x${cleaned.substring(cleaned.length - 40)}';
                debugPrint('✅ NFT creator found from Transfer event: $address');
                return address;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing Transfer logs: $e');
        }
      }

      debugPrint('⚠️ No mint event found for token $tokenId');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get NFT creator: $e');
      return null; // Return null instead of throwing to allow graceful fallback
    }
  }

  /// Helper to parse address from hex result
  String _parseAddressFromResult(String result) {
    try {
      String cleaned = result.startsWith('0x') ? result.substring(2) : result;
      if (cleaned.length >= 40) {
        return '0x${cleaned.substring(cleaned.length - 40)}';
      }
      return result;
    } catch (e) {
      return result;
    }
  }

  /// Waits for a transaction to be mined by checking transaction receipt
  Future<bool> waitForTransactionMined(
    String txHash, {
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    try {
      debugPrint('⏳ Waiting for transaction to be mined: $txHash');

      // Clean txHash
      final cleanedHash = txHash.replaceAll('"', '').trim();

      for (int i = 0; i < maxAttempts; i++) {
        try {
          final result = await _makeDirectRPCCall('eth_getTransactionReceipt', [
            cleanedHash,
          ]);

          // If result is not empty and not 'null', transaction is mined
          if (result.isNotEmpty &&
              result != 'null' &&
              !result.contains('null')) {
            debugPrint('✅ Transaction mined after ${i + 1} attempts');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Error checking transaction receipt: $e');
        }

        // Wait before next check
        await Future.delayed(interval);
        debugPrint('⏳ Still waiting... (${i + 1}/$maxAttempts)');
      }

      debugPrint('⚠️ Transaction not mined after $maxAttempts attempts');
      return false;
    } catch (e) {
      debugPrint('❌ Error waiting for transaction: $e');
      return false;
    }
  }

  /// Waits for approval to be confirmed by checking approval status
  Future<bool> waitForApprovalConfirmed(
    String tokenId,
    String userAddress, {
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    try {
      debugPrint('⏳ Waiting for approval to be confirmed...');

      for (int i = 0; i < maxAttempts; i++) {
        // Check if approved
        final isTokenApproved = await isMarketplaceApprovedForToken(tokenId);
        final isApprovedForAll = await isMarketplaceApprovedForAll(userAddress);

        if (isTokenApproved || isApprovedForAll) {
          debugPrint('✅ Approval confirmed after ${i + 1} attempts');
          return true;
        }

        // Wait before next check
        await Future.delayed(interval);
        debugPrint('⏳ Still waiting for approval... (${i + 1}/$maxAttempts)');
      }

      debugPrint('⚠️ Approval not confirmed after $maxAttempts attempts');
      return false;
    } catch (e) {
      debugPrint('❌ Error waiting for approval: $e');
      return false;
    }
  }

  /// Approves the marketplace to transfer NFTs on behalf of the owner
  Future<String> approveMarketplace(
    String tokenId,
    String userAddress, {
    void Function(Map<String, dynamic> request)? onPreview,
  }) async {
    if (tokenId.isEmpty || userAddress.isEmpty) {
      throw Exception('Token ID and user address cannot be empty.');
    }

    try {
      // Check if already approved
      final isTokenApproved = await isMarketplaceApprovedForToken(tokenId);
      if (isTokenApproved) {
        debugPrint('✅ Marketplace already approved for token $tokenId');
        return 'already_approved';
      }

      // Check if approved for all
      final isApprovedForAll = await isMarketplaceApprovedForAll(userAddress);
      if (isApprovedForAll) {
        debugPrint('✅ Marketplace already approved for all tokens');
        return 'already_approved_for_all';
      }

      final web3App = _appKitModal.appKit;
      if (web3App == null) {
        throw Exception(
          'Web3App not initialized. Please connect wallet first.',
        );
      }

      final contract = _createContract(
        contractType: 'nft',
        contractAddress: _nftContractAddress,
      );

      final function = contract.function('approve');
      final data = function.encodeCall([
        EthereumAddress.fromHex(_marketplaceContractAddress),
        BigInt.parse(tokenId),
      ]);

      final transactionParams = {
        'from': userAddress,
        'to': _nftContractAddress,
        'value': '0x0', // No ETH value for approval
        'data':
            '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x186A0', // 100,000 gas limit for approval
        'gasPrice': '0x77359400', // 2 Gwei
      };

      onPreview?.call({
        'chainId': 'eip155:11155111',
        'request': {
          'method': 'eth_sendTransaction',
          'params': [transactionParams],
        },
      });

      // Get active session topic
      final sessions = web3App.getActiveSessions();
      if (sessions.isEmpty) {
        throw Exception('No active wallet session found');
      }
      final topic = sessions.keys.first;

      // Launch wallet app first
      try {
        final native = _appKitModal.session?.getSessionRedirect()?.native;
        if (native != null && native.isNotEmpty) {
          await launchUrlString(native, mode: LaunchMode.externalApplication);
          // Wait a bit for wallet to open
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('⚠️ Could not launch wallet app: $e');
      }

      debugPrint('📤 Sending approval transaction request...');
      debugPrint('📋 Transaction params: $transactionParams');

      final result = await web3App.request(
        topic: topic,
        chainId: 'eip155:11155111',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transactionParams],
        ),
      );

      debugPrint('✅ Approval transaction result: $result');

      return result.toString();
    } catch (e) {
      throw Exception('Failed to approve marketplace: $e');
    }
  }

  /// Gets the marketplace fee percentage
  Future<String> getMarketplaceFee() async {
    try {
      final web3App = _appKitModal.appKit;
      if (web3App == null) {
        throw Exception(
          'Web3App not initialized. Please connect wallet first.',
        );
      }

      final contract = _createContract(
        contractType: 'marketplace',
        contractAddress: _marketplaceContractAddress,
      );

      final function = contract.function('marketplaceFee');
      final data = function.encodeCall([]);

      final result = await web3App.request(
        topic: web3App.getActiveSessions().keys.first,
        chainId: 'eip155:11155111',
        request: SessionRequestParams(
          method: 'eth_call',
          params: [
            {
              'to': _marketplaceContractAddress,
              'data':
                  '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
            },
            'latest',
          ],
        ),
      );

      return result.toString();
    } catch (e) {
      throw Exception('Failed to get marketplace fee: $e');
    }
  }

  /// Utility method to get current user address from wallet session
  String? getCurrentUserAddress() {
    final session = _appKitModal.session;
    if (session == null) return null;
    return session.namespaces?["eip155"]?.accounts.first.split(":").last;
  }

  /// Get NFT contract address
  String getNFTContractAddress() {
    return _nftContractAddress;
  }

  /// Utility method to convert Wei to ETH
  static double weiToEth(String weiAmount) {
    try {
      final wei = BigInt.parse(weiAmount);
      return wei / BigInt.from(10).pow(18);
    } catch (e) {
      throw Exception('Invalid Wei amount: $e');
    }
  }

  /// Utility method to convert ETH to Wei
  static String ethToWei(double ethAmount) {
    try {
      final wei = BigInt.from((ethAmount * 1e18).round());
      return wei.toString();
    } catch (e) {
      throw Exception('Invalid ETH amount: $e');
    }
  }

  /// Makes direct RPC call to blockchain without requiring wallet session
  /// This is useful for view functions that don't need wallet connection
  Future<String> _makeDirectRPCCall(String method, List<dynamic> params) async {
    try {
      // Use public Sepolia RPC endpoint
      const String sepoliaRpcUrl =
          'https://ethereum-sepolia-rpc.publicnode.com';

      final requestBody = {
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
        'id': 1,
      };

      debugPrint('🌐 Making RPC call: $method');
      debugPrint('📤 Request params: $params');

      final response = await http
          .post(
            Uri.parse(sepoliaRpcUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['error'] != null) {
          debugPrint('❌ RPC Error: ${jsonResponse['error']}');
          throw Exception('RPC Error: ${jsonResponse['error']}');
        }

        final result = jsonResponse['result']?.toString() ?? '0x0';
        debugPrint('📥 RPC result: $result');
        return result;
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Direct RPC call failed: $e');
      throw e;
    }
  }
}
