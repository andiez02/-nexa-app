/// Represents an NFT with all its metadata and blockchain information
class NFTModel {
  final String tokenId;
  final String name;
  final String description;
  final String imageUrl;
  final String tokenURI;
  final String owner;
  final String? contractAddress;
  final DateTime? createdAt;
  final Map<String, dynamic>? attributes;
  final String? collection;
  final double? price; // Price in ETH if listed for sale
  final bool isListed;
  final String? seller; // Current seller if listed
  final String? creator; // Address of the person who minted (created) the NFT

  const NFTModel({
    required this.tokenId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.tokenURI,
    required this.owner,
    this.contractAddress,
    this.createdAt,
    this.attributes,
    this.collection,
    this.price,
    this.isListed = false,
    this.seller,
    this.creator,
  });

  /// Creates NFTModel from JSON data (typically from IPFS metadata)
  factory NFTModel.fromJson(
    Map<String, dynamic> json, {
    required String tokenId,
    required String tokenURI,
    required String owner,
    String? contractAddress,
    double? price,
    bool isListed = false,
    String? seller,
    String? creator,
  }) {
    return NFTModel(
      tokenId: tokenId,
      name: json['name'] as String? ?? 'Unnamed NFT',
      description: json['description'] as String? ?? '',
      imageUrl: _processImageUrl(json['image'] as String? ?? ''),
      tokenURI: tokenURI,
      owner: owner,
      contractAddress: contractAddress,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      attributes: json['attributes'] as Map<String, dynamic>?,
      collection: json['collection'] as String?,
      price: price,
      isListed: isListed,
      seller: seller,
      creator: creator,
    );
  }

  /// Creates NFTModel from blockchain event data
  factory NFTModel.fromMintEvent({
    required String tokenId,
    required String tokenURI,
    required String owner,
    required String contractAddress,
    DateTime? timestamp,
    String? creator,
  }) {
    return NFTModel(
      tokenId: tokenId,
      name: 'NFT #$tokenId',
      description: 'Loading metadata...',
      imageUrl: '',
      tokenURI: tokenURI,
      owner: owner,
      contractAddress: contractAddress,
      createdAt: timestamp,
      isListed: false,
      creator:
          creator ?? owner, // If creator not provided, assume owner is creator
    );
  }

  /// Processes IPFS URLs to use proper gateway
  static String _processImageUrl(String imageUrl) {
    return processImageUrl(imageUrl);
  }

  /// Public method to process IPFS URLs to use proper gateway
  static String processImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return imageUrl;

    if (imageUrl.startsWith('ipfs://')) {
      // Use ipfs.io as primary gateway (more reliable than cloudflare)
      return imageUrl.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
    }

    // If already a gateway URL but using cloudflare (which may not work), try to convert
    if (imageUrl.contains('cloudflare-ipfs.com')) {
      return imageUrl.replaceFirst(
        'https://cloudflare-ipfs.com/ipfs/',
        'https://ipfs.io/ipfs/',
      );
    }

    return imageUrl;
  }

  /// Creates a copy with updated fields
  NFTModel copyWith({
    String? tokenId,
    String? name,
    String? description,
    String? imageUrl,
    String? tokenURI,
    String? owner,
    String? contractAddress,
    DateTime? createdAt,
    Map<String, dynamic>? attributes,
    String? collection,
    double? price,
    bool? isListed,
    String? seller,
    String? creator,
  }) {
    return NFTModel(
      tokenId: tokenId ?? this.tokenId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tokenURI: tokenURI ?? this.tokenURI,
      owner: owner ?? this.owner,
      contractAddress: contractAddress ?? this.contractAddress,
      createdAt: createdAt ?? this.createdAt,
      attributes: attributes ?? this.attributes,
      collection: collection ?? this.collection,
      price: price ?? this.price,
      isListed: isListed ?? this.isListed,
      seller: seller ?? this.seller,
      creator: creator ?? this.creator,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'tokenId': tokenId,
      'name': name,
      'description': description,
      'image': imageUrl,
      'tokenURI': tokenURI,
      'owner': owner,
      'contractAddress': contractAddress,
      'createdAt': createdAt?.toIso8601String(),
      'attributes': attributes,
      'collection': collection,
      'price': price,
      'isListed': isListed,
      'seller': seller,
      'creator': creator,
    };
  }

  /// Gets formatted price string
  String get formattedPrice {
    if (price == null) return 'Not for sale';
    return '${price!.toStringAsFixed(4)} ETH';
  }

  /// Gets short token ID for display
  String get shortTokenId {
    if (tokenId.length <= 8) return tokenId;
    return '${tokenId.substring(0, 4)}...${tokenId.substring(tokenId.length - 4)}';
  }

  /// Gets short owner address for display
  String get shortOwnerAddress {
    if (owner.length <= 8) return owner;
    return '${owner.substring(0, 6)}...${owner.substring(owner.length - 4)}';
  }

  /// Gets short creator address for display
  String get shortCreatorAddress {
    if (creator == null || creator!.isEmpty) return 'Unknown';
    if (creator!.length <= 8) return creator!;
    return '${creator!.substring(0, 6)}...${creator!.substring(creator!.length - 4)}';
  }

  @override
  String toString() {
    return 'NFTModel(tokenId: $tokenId, name: $name, owner: $owner, isListed: $isListed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NFTModel &&
        other.tokenId == tokenId &&
        other.contractAddress == contractAddress;
  }

  @override
  int get hashCode => tokenId.hashCode ^ contractAddress.hashCode;
}

/// Represents different categories of NFTs for the user
enum NFTCategory {
  collected, // NFTs owned by user but not created by them
  created, // NFTs created (minted) by user
  onSale, // NFTs listed for sale by user
}

extension NFTCategoryExtension on NFTCategory {
  String get displayName {
    switch (this) {
      case NFTCategory.collected:
        return 'Collected';
      case NFTCategory.created:
        return 'Created';
      case NFTCategory.onSale:
        return 'On Sale';
    }
  }
}
