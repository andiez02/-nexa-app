import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Service class for interacting with the smart contract using Reown Appkit.
class SmartContractService {
  final ReownAppKitModal _appKitModal;
  final String _contractAddress = dotenv.env['NFT_CONTRACT_ADDRESS']!;

  SmartContractService(this._appKitModal);

  /// Initializes the service. With Reown Appkit, this is often simpler or
  /// not needed as the kit handles the underlying client.
  Future<void> init() async {
    // Initialization logic for Reown Appkit would go here if needed,
    // but often it's as simple as confirming the contract address.
    if (_contractAddress.isEmpty) {
      throw Exception(
        'Smart contract address not found in environment variables.',
      );
    }
  }

  /// Mints a new NFT by calling the smart contract via Reown Appkit.
  /// Returns the transaction hash if successful.
  Future<String> mintNFT(String recipientAddress, String tokenURI) async {
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

      // Encode function call data
      final contract = DeployedContract(
        ContractAbi.fromJson(
          jsonEncode([
            {
              "inputs": [
                {
                  "internalType": "address",
                  "name": "recipient",
                  "type": "address",
                },
                {
                  "internalType": "string",
                  "name": "tokenURI",
                  "type": "string",
                },
              ],
              "name": "mintNFT",
              "outputs": [
                {"internalType": "uint256", "name": "", "type": "uint256"},
              ],
              "stateMutability": "nonpayable",
              "type": "function",
            },
          ]),
          'MyNFT',
        ),
        EthereumAddress.fromHex(_contractAddress),
      );

      final function = contract.function('mintNFT');
      final data = function.encodeCall([
        EthereumAddress.fromHex(recipientAddress),
        tokenURI,
      ]);

      // Construct transaction parameters for eth_sendTransaction
      final transactionParams = {
        'from': recipientAddress,
        'to': _contractAddress,
        'data':
            '0x${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x30D40', // 200,000 gas limit (tối ưu cho mint NFT)
        'gasPrice': '0x77359400', // 2 Gwei (rất thấp trên Sepolia testnet)
      };

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
      throw Exception('Failed to send transaction: $e');
    }
  }
}
