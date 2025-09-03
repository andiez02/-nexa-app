import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:convert';

class PinataService {
  // Constants for Pinata API URLs
  final String pinataPinFileUrl =
      'https://api.pinata.cloud/pinning/pinFileToIPFS';
  final String pinataPinJsonUrl =
      'https://api.pinata.cloud/pinning/pinJSONToIPFS';

  // Get API keys from environment variables
  final String pinataApiKey = dotenv.env['PINATA_API_KEY']!;
  final String pinataApiSecret = dotenv.env['PINATA_SECRET_API_KEY']!;

  /// Uploads a file to Pinata IPFS.
  /// Returns the IPFS hash (CID) if successful, otherwise throws an exception.
  Future<String> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(pinataPinFileUrl);
      final request = http.MultipartRequest('POST', uri)
        ..headers['pinata_api_key'] = pinataApiKey
        ..headers['pinata_secret_api_key'] = pinataApiSecret
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['IpfsHash'];
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Pinata: $e');
    }
  }

  /// Uploads metadata JSON to Pinata IPFS.
  /// Returns the IPFS hash (CID) if successful, otherwise throws an exception.
  Future<String> uploadMetadata(
    String name,
    String description,
    String imageCid,
  ) async {
    final metadata = {
      'name': name,
      'description': description,
      'image': 'ipfs://$imageCid',
    };

    try {
      final response = await http.post(
        Uri.parse(pinataPinJsonUrl),
        headers: {
          'Content-Type': 'application/json',
          'pinata_api_key': pinataApiKey,
          'pinata_secret_api_key': pinataApiSecret,
        },
        body: jsonEncode(metadata),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['IpfsHash'];
      } else {
        throw Exception('Failed to upload metadata: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred during metadata upload: $e');
    }
  }
}
