import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:async';

class WalletProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  SessionData? _session;
  bool _isInitialized = false;

  SessionData? get session => _session;
  bool get isConnected => _session != null;
  ReownAppKitModal? get appKitModal => _appKitModal;

  static const String projectId = 'be2f3ed58f943aa53db990ddff2a31b5';

  // Sepolia testnet configuration
  static const String sepoliaChainId = '11155111';
  static const String sepoliaRpcUrls =
      'https://ethereum-sepolia-rpc.publicnode.com';
  // USDC contract address on Sepolia testnet
  static const String usdcContractAddress =
      '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';

  Future<void> initAppKit(BuildContext context) async {
    if (_isInitialized) {
      return;
    }

    final appKit = await ReownAppKit.createInstance(
      logLevel: LogLevel.debug,
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'Nexa App',
        description: 'Nexa App for NFT',
        url: 'https://github.com/andiez02/-nexa-app',
        icons: [
          'https://github.com/andiez02/-nexa-app/blob/main/assets/images/icon.jpg',
        ],
        redirect: Redirect(
          native: 'nexanft://wallet-callback',
          universal: 'https://github.com/andiez02/-nexa-app/wallet-callback',
          linkMode: false,
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }
    _appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
      featuredWalletIds: {
        // MetaMask id
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96',
        // Rainbow Wallet ID
        '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369',
      },
      includedWalletIds: {
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96',
        '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369',
      },
    );

    await _appKitModal?.init();
    // Attempt to restore any existing active session persisted by AppKit
    final wallet = _appKitModal?.appKit;
    if (wallet != null) {
      final activeSessions = wallet.getActiveSessions();
      if (activeSessions.isNotEmpty) {
        _session = activeSessions.values.first;
        notifyListeners();
      }
    }
    
    appKit.onSessionConnect.subscribe((event) {
      _session = event.session;
      notifyListeners();
    });

    appKit.onSessionDelete.subscribe((event) {
      _session = null;
      notifyListeners();
    });

    _isInitialized = true;
  }

  Future<void> connectToWallet(BuildContext context) async {
    await initAppKit(context);

    try {
      // Check if already connected
      if (_session != null) {
        return;
      }

      // Open modal and wait a bit
      _appKitModal?.openModalView();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> disconnect() async {
    if (_session != null) {
      await _appKitModal?.appKit?.disconnectSession(
        topic: _session!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
      );
      _session = null;
    }
    // Reset state for fresh reconnection
    _resetAppKitState();
    notifyListeners();
  }

  void _resetAppKitState() {
    _appKitModal = null;
    _isInitialized = false;
  }

  String? get walletAddress {
    if (_session == null) return null;
    return _session!.namespaces["eip155"]?.accounts.first.split(":").last;
  }

  /// Get Sepolia ETH balance
  Future<String> getEthBalance() async {
    try {
      if (walletAddress == null) {
        return '0';
      }

      final client = Client();

      try {
        final response = await client
            .post(
              Uri.parse(sepoliaRpcUrls),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'jsonrpc': '2.0',
                'method': 'eth_getBalance',
                'params': [walletAddress, 'latest'],
                'id': 1,
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          if (jsonResponse['error'] != null) {
            debugPrint('❌ JSON-RPC Error: ${jsonResponse['error']}');
          }

          final String? result = jsonResponse['result'];

          if (result != null && result != '0x' && result != '0x0') {
            try {
              // Remove 0x prefix and parse hex to BigInt
              String cleanHex = result.toLowerCase();
              if (cleanHex.startsWith('0x')) {
                cleanHex = cleanHex.substring(2);
              }

              final BigInt balance = BigInt.parse(cleanHex, radix: 16);
              final double ethBalance =
                  balance.toDouble() / 1e18; // ETH has 18 decimals

              debugPrint('✅ ETH Balance: $ethBalance');
              client.close();
              return ethBalance.toStringAsFixed(6);
            } catch (parseError) {
              debugPrint('❌ Parse error for result "$result": $parseError');
            }
          } else {
            debugPrint('💡 Zero ETH balance');
            client.close();
            return '0.000000';
          }
        } else {
          debugPrint('❌ HTTP ${response.statusCode}');
          client.close();
          return '0';
        }
      } catch (e) {
        debugPrint('❌ Error getting ETH balance: $e');
        client.close();
        return '0';
      }

      client.close();
      return '0';
    } catch (e) {
      debugPrint('❌ Error getting ETH balance: $e');
      return '0';
    }
  }

  /// Lấy số dư USDC trên Sepolia testnet
  Future<String> getUsdcBalance() async {
    try {
      if (walletAddress == null) {
        return '0';
      }

      // ERC20 balanceOf function signature
      const String balanceOfSignature = '0x70a08231';

      // Encode wallet address (remove 0x and pad to 32 bytes)
      final String addressParam = walletAddress!.substring(2).padLeft(64, '0');
      final String data = balanceOfSignature + addressParam;

      // Try multiple RPC endpoints for better reliability
      final client = Client();

      try {
        final response = await client
            .post(
              Uri.parse(sepoliaRpcUrls),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'jsonrpc': '2.0',
                'method': 'eth_call',
                'params': [
                  {'to': usdcContractAddress, 'data': data},
                  'latest',
                ],
                'id': 1,
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          // Check for JSON-RPC error
          if (jsonResponse['error'] != null) {
            debugPrint(
              '❌ JSON-RPC Error from $sepoliaRpcUrls: ${jsonResponse['error']}',
            );
          }

          final String? result = jsonResponse['result'];

          if (result != null && result != '0x' && result != '0x0') {
            try {
              debugPrint('🔍 Raw result: $result');

              // Remove 0x prefix if present and clean the string
              String cleanHex = result.toLowerCase();
              if (cleanHex.startsWith('0x')) {
                cleanHex = cleanHex.substring(2);
              }

              // Parse as hex to BigInt
              final BigInt balance = BigInt.parse(cleanHex, radix: 16);
              final double usdcBalance =
                  balance.toDouble() / 1000000; // USDC has 6 decimals

              debugPrint('✅ USDC Balance: $usdcBalance (from $sepoliaRpcUrls)');
              client.close();
              return usdcBalance.toStringAsFixed(6);
            } catch (parseError) {
              debugPrint('❌ Parse error for result "$result": $parseError');
            }
          } else {
            debugPrint('💡 Zero balance from $sepoliaRpcUrls');
            client.close();
            return '0.000000';
          }
        } else {
          debugPrint('❌ HTTP ${response.statusCode} from $sepoliaRpcUrls');
          client.close();
          return '0';
        }
      } catch (e) {
        debugPrint('❌ Error with $sepoliaRpcUrls: $e');
        client.close();
        return '0';
      }

      client.close();
      return '0';
    } catch (e) {
      debugPrint('❌ Error getting USDC balance: $e');
      return '0';
    }
  }
}
