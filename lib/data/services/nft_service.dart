import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/nft_model.dart';
import '../../core/services/smart_contract_service.dart';

/// Service for managing NFT data from blockchain and IPFS
class NFTService {
  final SmartContractService _smartContractService;

  // Cache for NFT metadata to avoid repeated IPFS calls
  final Map<String, NFTModel> _nftCache = {};
  final Map<String, Map<String, dynamic>> _metadataCache = {}; // Raw JSON cache
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, DateTime> _failedRequests =
      {}; // Track failed requests to avoid immediate retry
  static const Duration _cacheExpiry = Duration(
    hours: 24,
  ); // Cache for 24 hours
  static const Duration _failedRequestCooldown = Duration(
    minutes: 5,
  ); // Wait 5 min before retry

  // Cache for listed NFTs (shorter expiry since listings can change)
  List<NFTModel>? _cachedListedNFTs;
  DateTime? _listedNFTsCacheTime;
  static const Duration _listedNFTsCacheExpiry = Duration(
    minutes: 2,
  ); // Cache for 2 minutes (listings can change frequently)

  static const int _maxListedTokensToCheck = 80;
  static const int _listedFetchBatchSize = 8;

  // Multiple IPFS gateways for fallback
  static const List<String> _ipfsGateways = [
    'https://gateway.pinata.cloud/ipfs/',
    'https://ipfs.io/ipfs/',
    'https://cloudflare-ipfs.com/ipfs/',
    'https://dweb.link/ipfs/',
  ];

  // Rate limiting: delay between requests
  DateTime? _lastRequestTime;
  static const Duration _minRequestDelay = Duration(
    milliseconds: 200,
  ); // 200ms between requests

  NFTService(this._smartContractService);

  /// Fetches all NFTs for a given user address
  Future<Map<NFTCategory, List<NFTModel>>> fetchUserNFTs(
    String userAddress,
  ) async {
    debugPrint('🚀 Starting fetchUserNFTs for: $userAddress');

    try {
      // Check if we have a valid user address
      if (userAddress.isEmpty) {
        debugPrint('❌ Empty user address provided');
        return _getEmptyNFTMap();
      }

      // Always try to fetch real data, even if wallet not connected yet
      final currentUser = _smartContractService.getCurrentUserAddress();
      debugPrint('👤 Current connected user: $currentUser');

      if (currentUser == null) {
        debugPrint(
          '⚠️ No wallet connected, but still attempting to fetch NFT data',
        );
      }

      final results = await Future.wait([
        _fetchCreatedNFTs(userAddress),
        _fetchOwnedNFTs(userAddress),
        _fetchListedNFTs(userAddress),
      ]);

      final nftMap = {
        NFTCategory.created: results[0],
        NFTCategory.collected: results[1],
        NFTCategory.onSale: results[2],
      };

      final totalNFTs =
          results[0].length + results[1].length + results[2].length;
      debugPrint('✅ Successfully fetched $totalNFTs NFTs');

      return nftMap;
    } catch (e) {
      debugPrint('❌ Error fetching user NFTs: $e');
      debugPrint('📝 Stack trace: ${StackTrace.current}');

      // Return empty data on error instead of mock data
      debugPrint('🔄 Returning empty NFT data due to blockchain error');
      return _getEmptyNFTMap();
    }
  }

  /// Fetches NFTs created (minted) by the user
  Future<List<NFTModel>> _fetchCreatedNFTs(String userAddress) async {
    try {
      debugPrint('🔍 Fetching created NFTs for $userAddress');

      // Always attempt to fetch, the smart contract service will handle connection issues

      // Get total supply to know how many NFTs exist
      final totalSupplyStr = await _smartContractService.getNFTTotalSupply();
      final totalSupply = _parseBigIntFromHex(totalSupplyStr);

      debugPrint('📊 Total NFT supply: $totalSupply');

      if (totalSupply == 0) {
        debugPrint('📭 No NFTs exist yet');
        return [];
      }

      final createdNFTs = <NFTModel>[];

      // Check each token to see if it was minted to the user address
      // This is a simplified approach - in production you'd use events/subgraph
      for (int i = 1; i <= totalSupply && i <= 50; i++) {
        // Limit to 50 for performance
        try {
          final tokenId = i.toString();
          debugPrint('🔍 Checking token #$tokenId');

          final ownerStr = await _smartContractService.getNFTOwner(tokenId);
          final owner = _parseAddressFromResult(ownerStr);

          debugPrint('👤 Token #$tokenId owner: $owner');
          debugPrint('🎯 User address: $userAddress');

          // Check if this NFT was originally minted to user
          // For now we assume if user owns it and it's a low token ID, they created it
          // In production, you'd check mint events or store creation data
          if (owner.toLowerCase() == userAddress.toLowerCase()) {
            debugPrint('✅ Found NFT owned by user: Token #$tokenId');

            // Get token URI and load metadata
            final tokenUriStr = await _smartContractService.getNFTTokenURI(
              tokenId,
            );
            final tokenUri = _parseStringFromResult(tokenUriStr);

            debugPrint('🔗 Token URI for #$tokenId: $tokenUri');

            final nft = await _loadNFTMetadata(
              tokenId: tokenId,
              tokenURI: tokenUri,
              owner: owner,
            );

            if (nft != null) {
              createdNFTs.add(nft);
              debugPrint('✅ Successfully loaded NFT: ${nft.name}');
            } else {
              debugPrint('❌ Failed to load metadata for token #$tokenId');
            }
          } else {
            debugPrint('⏭️ Token #$tokenId not owned by user');
          }
        } catch (e) {
          debugPrint('⚠️ Error checking token $i: $e');
          // Continue to next token
        }
      }

      debugPrint('📝 Found ${createdNFTs.length} created NFTs');
      return createdNFTs;
    } catch (e) {
      debugPrint('❌ Error fetching created NFTs: $e');
      debugPrint('📝 Error details: ${e.toString()}');
      return [];
    }
  }

  /// Fetches NFTs owned but not necessarily created by the user
  Future<List<NFTModel>> _fetchOwnedNFTs(String userAddress) async {
    try {
      debugPrint('📦 Fetching owned/collected NFTs for $userAddress');

      // Always attempt to fetch, the smart contract service will handle connection issues

      // Get total supply to know how many NFTs exist
      final totalSupplyStr = await _smartContractService.getNFTTotalSupply();
      final totalSupply = _parseBigIntFromHex(totalSupplyStr);

      debugPrint('📊 Total NFT supply for owned check: $totalSupply');

      final ownedNFTs = <NFTModel>[];

      // Check each token to see if user owns it (but consider it "collected" not "created")
      // This is different from created - here we assume tokens with higher IDs are collected
      for (int i = 1; i <= totalSupply && i <= 50; i++) {
        try {
          final tokenId = i.toString();
          final ownerStr = await _smartContractService.getNFTOwner(tokenId);
          final owner = _parseAddressFromResult(ownerStr);

          if (owner.toLowerCase() == userAddress.toLowerCase()) {
            // For demo purposes, consider tokens > 10 as "collected"
            // In production, you'd track mint history or use events
            if (i > 10) {
              debugPrint('📦 Found collected NFT: Token #$tokenId');

              final tokenUriStr = await _smartContractService.getNFTTokenURI(
                tokenId,
              );
              final tokenUri = _parseStringFromResult(tokenUriStr);

              final nft = await _loadNFTMetadata(
                tokenId: tokenId,
                tokenURI: tokenUri,
                owner: owner,
              );

              if (nft != null) {
                ownedNFTs.add(nft);
                debugPrint('✅ Successfully loaded collected NFT: ${nft.name}');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error checking owned token $i: $e');
          // Continue to next token
        }
      }

      debugPrint('📦 Found ${ownedNFTs.length} collected NFTs');
      return ownedNFTs;
    } catch (e) {
      debugPrint('❌ Error fetching owned NFTs: $e');
      return [];
    }
  }

  /// Fetches all NFTs listed for sale on the marketplace (for explore page)
  Future<List<NFTModel>> fetchAllListedNFTs({
    String? currentUserAddress,
  }) async {
    try {
      // Check cache first
      if (_cachedListedNFTs != null && _listedNFTsCacheTime != null) {
        final cacheAge = DateTime.now().difference(_listedNFTsCacheTime!);
        if (cacheAge < _listedNFTsCacheExpiry) {
          debugPrint(
            '✅ Using cached listed NFTs (age: ${cacheAge.inSeconds}s)',
          );
          // Update owner info if current user address provided
          if (currentUserAddress != null) {
            return _cachedListedNFTs!.map((nft) {
              // Keep original seller info, just return cached NFT
              return nft;
            }).toList();
          }
          return _cachedListedNFTs!;
        } else {
          debugPrint(
            '⏰ Listed NFTs cache expired (age: ${cacheAge.inSeconds}s), refreshing...',
          );
        }
      }

      debugPrint('🏪 Fetching all listed NFTs from marketplace');
      debugPrint(
        '📍 NFT Contract: ${_smartContractService.nftContractAddress}',
      );
      debugPrint(
        '📍 Marketplace Contract: ${_smartContractService.marketplaceContractAddress}',
      );

      final listedNFTs = <NFTModel>[];

      // Get total supply to check existing NFTs
      final totalSupplyStr = await _smartContractService.getNFTTotalSupply();
      final totalSupply = _parseBigIntFromHex(totalSupplyStr);
      debugPrint('📊 Total NFT supply: $totalSupply');

      if (totalSupply == 0) {
        _cachedListedNFTs = [];
        _listedNFTsCacheTime = DateTime.now();
        return [];
      }

      final startTokenId = max(1, totalSupply - _maxListedTokensToCheck + 1);
      final tokenIds = <String>[];
      for (int id = totalSupply; id >= startTokenId; id--) {
        tokenIds.add(id.toString());
      }

      for (final batch in _chunkList(tokenIds, _listedFetchBatchSize)) {
        final results = await Future.wait(
          batch.map(_loadListedNFTSafely),
          eagerError: false,
        );
        listedNFTs.addAll(results.whereType<NFTModel>());
      }

      debugPrint('🏪 Found ${listedNFTs.length} listed NFTs total');

      // Cache the result
      _cachedListedNFTs = listedNFTs;
      _listedNFTsCacheTime = DateTime.now();
      debugPrint(
        '💾 Cached listed NFTs for ${_listedNFTsCacheExpiry.inMinutes} minutes',
      );

      return listedNFTs;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching all listed NFTs: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetches NFTs listed for sale by the user
  Future<List<NFTModel>> _fetchListedNFTs(String userAddress) async {
    try {
      debugPrint('🏪 Fetching listed NFTs for $userAddress');

      // Always attempt to fetch, the smart contract service will handle connection issues

      final listedNFTs = <NFTModel>[];

      // Get total supply to check all existing NFTs
      final totalSupplyStr = await _smartContractService.getNFTTotalSupply();
      final totalSupply = _parseBigIntFromHex(totalSupplyStr);

      // Check each NFT to see if it's listed by this user
      for (int i = 1; i <= totalSupply && i <= 50; i++) {
        try {
          final tokenId = i.toString();

          // Get listing info from marketplace contract
          final listingResult = await _smartContractService.getNFTListing(
            _smartContractService.nftContractAddress,
            tokenId,
          );

          if (listingResult['success'] == true &&
              listingResult['data'] != null) {
            final listingData = _parseListingResult(
              listingResult['data'] as String,
            );

            // Check if listing is active and seller matches user
            if (listingData['active'] == true &&
                listingData['seller']?.toLowerCase() ==
                    userAddress.toLowerCase()) {
              debugPrint('🏪 Found listed NFT: Token #$tokenId');

              // Get NFT metadata
              final tokenUriStr = await _smartContractService.getNFTTokenURI(
                tokenId,
              );
              final tokenUri = _parseStringFromResult(tokenUriStr);

              final ownerStr = await _smartContractService.getNFTOwner(tokenId);
              final owner = _parseAddressFromResult(ownerStr);

              final nft = await _loadNFTMetadata(
                tokenId: tokenId,
                tokenURI: tokenUri,
                owner: owner,
              );

              if (nft != null) {
                // Add listing price to NFT
                final priceInWei = listingData['price'] as int?;
                final priceInEth = priceInWei != null
                    ? priceInWei / 1e18
                    : null;

                final listedNFT = nft.copyWith(
                  price: priceInEth,
                  isListed: true,
                  seller: userAddress,
                );

                listedNFTs.add(listedNFT);
                debugPrint(
                  '✅ Successfully loaded listed NFT: ${nft.name} for ${priceInEth?.toStringAsFixed(4)} ETH',
                );
              }
            }
          } else {
            debugPrint(
              '⚠️ No valid listing data for token #$tokenId: $listingResult',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error checking listing for token $i: $e');
          // Continue to next token
        }
      }

      debugPrint('🏪 Found ${listedNFTs.length} listed NFTs');
      return listedNFTs;
    } catch (e) {
      debugPrint('❌ Error fetching listed NFTs: $e');
      return [];
    }
  }

  /// Loads NFT metadata from IPFS and creates NFTModel
  Future<NFTModel?> _loadNFTMetadata({
    required String tokenId,
    required String tokenURI,
    required String owner,
    String? creator,
  }) async {
    try {
      // Use tokenId as primary cache key (more reliable)
      final cacheKey = tokenId;

      // Check cache first
      if (_nftCache.containsKey(cacheKey)) {
        final cachedTime = _cacheTimestamps[cacheKey];
        if (cachedTime != null &&
            DateTime.now().difference(cachedTime) < _cacheExpiry) {
          debugPrint('✅ Using cached metadata for token $tokenId');
          final cachedNft = _nftCache[cacheKey]!;

          // Fix imageUrl if it uses cloudflare gateway (which may not work)
          String fixedImageUrl = cachedNft.imageUrl;
          if (fixedImageUrl.contains('cloudflare-ipfs.com')) {
            // Convert cloudflare URL to ipfs.io
            fixedImageUrl = fixedImageUrl.replaceFirst(
              'https://cloudflare-ipfs.com/ipfs/',
              'https://ipfs.io/ipfs/',
            );
            debugPrint('🔧 Fixed imageUrl from cloudflare to ipfs.io');
          } else if (fixedImageUrl.startsWith('ipfs://')) {
            // Process ipfs:// URL to use ipfs.io gateway
            fixedImageUrl = NFTModel.processImageUrl(fixedImageUrl);
          }

          return cachedNft.copyWith(
            owner: owner,
            imageUrl: fixedImageUrl,
            creator: creator ?? cachedNft.creator,
          );
        }
      }

      // Check if we recently failed to fetch this token (rate limit protection)
      if (_failedRequests.containsKey(cacheKey)) {
        final failedTime = _failedRequests[cacheKey]!;
        if (DateTime.now().difference(failedTime) < _failedRequestCooldown) {
          debugPrint(
            '⏸️ Skipping token $tokenId (recently failed, cooldown active)',
          );
          return null;
        }
        // Cooldown expired, remove from failed requests
        _failedRequests.remove(cacheKey);
      }

      // Rate limiting: add delay between requests
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastRequestTime!,
        );
        if (timeSinceLastRequest < _minRequestDelay) {
          await Future.delayed(_minRequestDelay - timeSinceLastRequest);
        }
      }
      _lastRequestTime = DateTime.now();

      debugPrint('📥 Loading metadata for token $tokenId from $tokenURI');

      // Check raw metadata cache first
      Map<String, dynamic>? metadata;
      if (_metadataCache.containsKey(cacheKey)) {
        final cachedTime = _cacheTimestamps[cacheKey];
        if (cachedTime != null &&
            DateTime.now().difference(cachedTime) < _cacheExpiry) {
          metadata = _metadataCache[cacheKey];
          debugPrint('✅ Using cached raw metadata for token $tokenId');
        }
      }

      // If not in cache, fetch from IPFS with retry logic
      if (metadata == null) {
        metadata = await _fetchMetadataWithRetry(tokenURI, cacheKey);
        if (metadata == null) {
          // Mark as failed to avoid immediate retry
          _failedRequests[cacheKey] = DateTime.now();
          return null;
        }

        // Cache raw metadata
        _metadataCache[cacheKey] = metadata;
      }

      // Create NFTModel from metadata
      final nft = NFTModel.fromJson(
        metadata,
        tokenId: tokenId,
        tokenURI: tokenURI,
        owner: owner,
        contractAddress: _smartContractService.nftContractAddress,
        creator: creator,
      );

      // Cache the result
      _nftCache[cacheKey] = nft;
      _cacheTimestamps[cacheKey] = DateTime.now();

      debugPrint('✅ Loaded NFT: ${nft.name}');
      return nft;
    } catch (e) {
      debugPrint('❌ Error loading NFT metadata: $e');
      return null;
    }
  }

  /// Fetches metadata from IPFS with retry logic and multiple gateways
  Future<Map<String, dynamic>?> _fetchMetadataWithRetry(
    String tokenURI,
    String cacheKey,
  ) async {
    // Extract IPFS hash from URI
    String ipfsHash = tokenURI;
    if (tokenURI.startsWith('ipfs://')) {
      ipfsHash = tokenURI.substring(7); // Remove 'ipfs://' prefix
    } else if (tokenURI.contains('/ipfs/')) {
      ipfsHash = tokenURI.split('/ipfs/').last;
    }

    // Try each gateway with retry logic
    for (final gateway in _ipfsGateways) {
      final metadataUrl = '$gateway$ipfsHash';

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          // Exponential backoff: 0s, 1s, 2s
          if (attempt > 0) {
            final delay = Duration(seconds: attempt);
            debugPrint(
              '⏳ Retry attempt $attempt after ${delay.inSeconds}s delay...',
            );
            await Future.delayed(delay);
          }

          final response = await http
              .get(
                Uri.parse(metadataUrl),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent': 'NexaApp/1.0',
                },
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final metadata = jsonDecode(response.body) as Map<String, dynamic>;
            debugPrint('✅ Successfully fetched metadata from $gateway');
            return metadata;
          } else if (response.statusCode == 429) {
            // Rate limit - wait longer and try next gateway
            debugPrint(
              '⚠️ Rate limit (429) from $gateway, trying next gateway...',
            );
            if (attempt < 2) {
              // Wait longer for rate limit
              await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            }
            break; // Try next gateway
          } else {
            debugPrint('⚠️ HTTP ${response.statusCode} from $gateway');
            if (attempt == 2) break; // Last attempt failed, try next gateway
          }
        } catch (e) {
          debugPrint(
            '❌ Error fetching from $gateway (attempt ${attempt + 1}): $e',
          );
          if (attempt == 2) {
            // Last attempt failed, try next gateway
            continue;
          }
        }
      }
    }

    debugPrint('❌ Failed to fetch metadata from all gateways');
    return null;
  }

  /// Refreshes a specific NFT's data
  Future<NFTModel?> refreshNFT(String tokenId) async {
    try {
      final ownerStr = await _smartContractService.getNFTOwner(tokenId);
      final owner = _parseAddressFromResult(ownerStr);

      final tokenUriStr = await _smartContractService.getNFTTokenURI(tokenId);
      final tokenUri = _parseStringFromResult(tokenUriStr);

      // Clear cache for this NFT
      clearTokenCache(tokenId);

      return await _loadNFTMetadata(
        tokenId: tokenId,
        tokenURI: tokenUri,
        owner: owner,
      );
    } catch (e) {
      debugPrint('Error refreshing NFT $tokenId: $e');
      return null;
    }
  }

  /// Clears the metadata cache
  void clearCache() {
    _nftCache.clear();
    _metadataCache.clear();
    _cacheTimestamps.clear();
    _failedRequests.clear();
    _lastRequestTime = null;
    _cachedListedNFTs = null;
    _listedNFTsCacheTime = null;
  }

  /// Clears cache for a specific token
  void clearTokenCache(String tokenId) {
    _nftCache.remove(tokenId);
    _metadataCache.remove(tokenId);
    _cacheTimestamps.remove(tokenId);
    _failedRequests.remove(tokenId);
  }

  /// Clears the listed NFTs cache (useful when listing/canceling/buying)
  void clearListedNFTsCache() {
    _cachedListedNFTs = null;
    _listedNFTsCacheTime = null;
    debugPrint('🗑️ Cleared listed NFTs cache');
  }

  /// Helper method to parse BigInt from contract response
  int _parseBigIntFromHex(String hexResult) {
    try {
      // Remove 0x prefix if present
      String cleaned = hexResult.startsWith('0x')
          ? hexResult.substring(2)
          : hexResult;
      if (cleaned.isEmpty) return 0;
      return int.parse(cleaned, radix: 16);
    } catch (e) {
      debugPrint('Error parsing BigInt from $hexResult: $e');
      return 0;
    }
  }

  /// Helper method to parse address from contract response
  String _parseAddressFromResult(String result) {
    try {
      // Contract calls return hex-encoded data
      // For address, we need to extract the last 20 bytes (40 hex chars)
      String cleaned = result.startsWith('0x') ? result.substring(2) : result;

      if (cleaned.length >= 40) {
        // Take last 40 characters and add 0x prefix
        return '0x${cleaned.substring(cleaned.length - 40)}';
      }

      return result; // Return as-is if format is unexpected
    } catch (e) {
      debugPrint('Error parsing address from $result: $e');
      return result;
    }
  }

  /// Helper method to parse string from contract response
  String _parseStringFromResult(String result) {
    try {
      debugPrint('🔍 Parsing string result: $result');

      // Remove 0x prefix if present
      String cleaned = result.startsWith('0x') ? result.substring(2) : result;

      if (cleaned.isEmpty || cleaned.length < 64) {
        debugPrint('⚠️ Invalid string result format');
        return result;
      }

      // ABI-encoded string format:
      // First 32 bytes (64 chars) = offset (usually 0x20 = 32)
      // Next 32 bytes (64 chars) = length
      // Remaining bytes = actual string data (hex-encoded)

      // Skip offset (first 64 chars)
      final lengthHex = cleaned.substring(64, 128);
      final length = int.tryParse(lengthHex, radix: 16) ?? 0;

      debugPrint('📏 String length: $length');

      if (length == 0) {
        debugPrint('⚠️ Zero length string');
        return '';
      }

      // Extract string data (starts at position 128)
      final stringDataHex = cleaned.substring(128);

      // Convert hex to bytes, then to string
      final stringBytes = <int>[];
      for (
        int i = 0;
        i < stringDataHex.length && stringBytes.length < length;
        i += 2
      ) {
        if (i + 1 < stringDataHex.length) {
          final byteHex = stringDataHex.substring(i, i + 2);
          final byte = int.tryParse(byteHex, radix: 16);
          if (byte != null && byte != 0) {
            // Skip null bytes
            stringBytes.add(byte);
          }
        }
      }

      final decodedString = String.fromCharCodes(stringBytes);
      debugPrint('✅ Decoded string: $decodedString');

      return decodedString;
    } catch (e) {
      debugPrint('❌ Error parsing string from $result: $e');
      return result; // Return original if parsing fails
    }
  }

  /// Helper method to parse marketplace listing result
  /// getListing returns (uint256 price, address seller, bool active)
  Map<String, dynamic> _parseListingResult(String hexResult) {
    try {
      debugPrint('🔍 Parsing listing result: $hexResult');

      // Remove 0x prefix if present
      String cleaned = hexResult.startsWith('0x')
          ? hexResult.substring(2)
          : hexResult;

      if (cleaned.isEmpty || cleaned == '0' || cleaned.length < 64) {
        // No listing or invalid data
        return {
          'price': 0,
          'seller': '0x0000000000000000000000000000000000000000',
          'active': false,
        };
      }

      // Parse the encoded data
      // First 32 bytes (64 chars) = price (uint256)
      // Next 32 bytes (64 chars) = seller address (last 20 bytes)
      // Last 32 bytes (64 chars) = active boolean (last byte)

      final priceHex = cleaned.substring(0, 64);
      final sellerHex = cleaned.substring(64, 128);
      final activeHex = cleaned.substring(128, 192);

      // Parse price
      final priceInt = int.tryParse(priceHex, radix: 16) ?? 0;

      // Parse seller address (last 20 bytes = 40 chars)
      final sellerAddress = sellerHex.length >= 40
          ? '0x${sellerHex.substring(sellerHex.length - 40)}'
          : '0x0000000000000000000000000000000000000000';

      // Parse active flag (last byte)
      final activeInt =
          int.tryParse(activeHex.substring(activeHex.length - 2), radix: 16) ??
          0;
      final isActive = activeInt > 0;

      final result = {
        'price': priceInt,
        'seller': sellerAddress,
        'active': isActive,
      };

      debugPrint('✅ Parsed listing: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error parsing listing result: $e');
      return {
        'price': 0,
        'seller': '0x0000000000000000000000000000000000000000',
        'active': false,
      };
    }
  }

  /// Returns empty NFT map
  Map<NFTCategory, List<NFTModel>> _getEmptyNFTMap() {
    return {
      NFTCategory.created: [],
      NFTCategory.collected: [],
      NFTCategory.onSale: [],
    };
  }

  /// Fetches a single NFT by its tokenId
  /// [skipCreator] if true, skips fetching creator from events (uses owner as creator) for faster loading
  Future<NFTModel?> fetchNFTById(
    String tokenId, {
    bool skipCreator = false,
  }) async {
    try {
      debugPrint('🔍 Fetching NFT by tokenId: $tokenId');

      // Check cache first
      final cacheKey = 'nft_$tokenId';
      if (_nftCache.containsKey(cacheKey)) {
        final cacheTime = _cacheTimestamps[cacheKey];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < _cacheExpiry) {
          debugPrint('📱 Returning cached NFT for tokenId: $tokenId');
          return _nftCache[cacheKey];
        }
      }

      // Get NFT owner
      final ownerStr = await _smartContractService.getNFTOwner(tokenId);
      final owner = _parseAddressFromResult(ownerStr);

      debugPrint('👤 NFT #$tokenId owner: $owner');

      if (owner.isEmpty ||
          owner == '0x0000000000000000000000000000000000000000') {
        debugPrint('❌ NFT #$tokenId does not exist or has no owner');
        return null;
      }

      // Get token URI
      final tokenURIStr = await _smartContractService.getNFTTokenURI(tokenId);
      final tokenURI = _parseStringFromResult(tokenURIStr);

      debugPrint('🔗 NFT #$tokenId tokenURI: $tokenURI');

      if (tokenURI.isEmpty) {
        debugPrint('❌ No tokenURI found for NFT #$tokenId');
        return null;
      }

      // Get listing info
      final contractAddress = _smartContractService.getNFTContractAddress();
      final listingResult = await _smartContractService.getNFTListing(
        contractAddress,
        tokenId,
      );
      debugPrint('🏷️ Listing result for NFT #$tokenId: $listingResult');

      double? price;
      bool isListed = false;
      String? seller;

      if (listingResult['success'] == true && listingResult['data'] != null) {
        // Parse the hex string result into a Map
        final listingData = _parseListingResult(
          listingResult['data'] as String,
        );
        final priceWei = listingData['price'] as int? ?? 0;
        final listingSeller = listingData['seller'] as String? ?? '';
        final active = listingData['active'] == true;

        if (active &&
            priceWei > 0 &&
            listingSeller.isNotEmpty &&
            listingSeller != '0x0000000000000000000000000000000000000000') {
          price = priceWei / 1e18; // Convert Wei to ETH
          isListed = true;
          seller = listingSeller;
          debugPrint('💰 NFT #$tokenId is listed for $price ETH by $seller');
        }
      }

      // Get creator (minter) address
      String? creator;
      if (skipCreator) {
        // Skip fetching creator from events for faster loading
        // Use owner as creator (usually the minter is the first owner)
        creator = owner;
        debugPrint(
          '⚡ Skipping creator fetch, using owner as creator: $creator',
        );
      } else {
        try {
          creator = await _smartContractService.getNFTCreator(tokenId);
          debugPrint('👨‍🎨 NFT #$tokenId creator: $creator');

          // If creator not found from events, use owner as fallback
          // (usually the minter is the first owner)
          if (creator == null || creator.isEmpty) {
            creator = owner;
            debugPrint(
              '⚠️ Creator not found from events, using owner as fallback: $creator',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Failed to get creator for NFT #$tokenId: $e');
          // Use owner as fallback if fetch fails
          creator = owner;
          debugPrint('⚠️ Using owner as creator fallback: $creator');
        }
      }

      // Load metadata
      final nftWithMetadata = await _loadNFTMetadata(
        tokenId: tokenId,
        tokenURI: tokenURI,
        owner: owner,
        creator: creator,
      );

      if (nftWithMetadata == null) {
        debugPrint('❌ Failed to load metadata for NFT #$tokenId');
        return null;
      }

      // Update with listing info
      final finalNft = nftWithMetadata.copyWith(
        price: price,
        isListed: isListed,
        seller: seller,
        creator: creator,
      );

      // Cache the result
      _nftCache[cacheKey] = finalNft;
      _cacheTimestamps[cacheKey] = DateTime.now();

      debugPrint('✅ Successfully fetched NFT #$tokenId: ${finalNft.name}');
      return finalNft;
    } catch (e) {
      debugPrint('❌ Error fetching NFT #$tokenId: $e');
      return null;
    }
  }

  Future<NFTModel?> _loadListedNFTSafely(String tokenId) async {
    try {
      return await _loadListedNFT(tokenId);
    } catch (e) {
      debugPrint('⚠️ Failed to load listed NFT #$tokenId: $e');
      return null;
    }
  }

  Future<NFTModel?> _loadListedNFT(String tokenId) async {
    final listingResult = await _smartContractService.getNFTListing(
      _smartContractService.nftContractAddress,
      tokenId,
    );

    if (listingResult['success'] != true || listingResult['data'] == null) {
      return null;
    }

    final listingData = _parseListingResult(listingResult['data'] as String);

    if (listingData['active'] != true) {
      return null;
    }

    final tokenUriStr = await _smartContractService.getNFTTokenURI(tokenId);
    final tokenUri = _parseStringFromResult(tokenUriStr);

    final ownerStr = await _smartContractService.getNFTOwner(tokenId);
    final owner = _parseAddressFromResult(ownerStr);

    final nft = await _loadNFTMetadata(
      tokenId: tokenId,
      tokenURI: tokenUri,
      owner: owner,
    );

    if (nft == null) return null;

    final priceInWei = listingData['price'] as int?;
    final priceInEth = priceInWei != null ? priceInWei / 1e18 : null;
    final seller = listingData['seller'] as String? ?? '';

    return nft.copyWith(price: priceInEth, isListed: true, seller: seller);
  }

  List<List<T>> _chunkList<T>(List<T> items, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      final end = min(i + chunkSize, items.length);
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }
}
