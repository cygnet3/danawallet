import 'dart:convert';
import 'package:danawallet/data/models/alias_creation_request.dart';
import 'package:danawallet/data/models/alias_creation_response.dart';
import 'package:dart_bip353/dart_bip353.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NameServerRepository {
  final String baseUrl;
  final String domain;
  final http.Client _client;
  late String? _userAlias;

  NameServerRepository({
    required this.baseUrl,
    required this.domain,
    http.Client? client,
  }) : _client = client ?? http.Client();

  set userAlias(String? value) {
    if (_userAlias == null) {
      _userAlias = value;
    } else {
      throw Exception('User alias already set to $_userAlias');
    }
  }

  String? get userAlias => _userAlias;

  void resetUserAddress() {
    _userAlias = null;
  }

  /// Creates an alias by calling the external name_server
  /// 
  /// [username] - The user defined name to be used with the domain as an alias
  /// [spAddress] - The Silent Payment address to associate with the alias
  /// 
  /// Returns [AliasCreationResponse] with the created address or error details
  Future<AliasCreationResponse> createAlias({
    required String username,
    required String spAddress,
  }) async {
    final aliasToCreate = '$username@$domain';

    try {
      final request = AliasCreationRequest(
        userName: username,
        domain: domain,
        spAddress: spAddress,
      );

      final response = await _client.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // We do nothing with the responseData for now, maybe later
        // final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return AliasCreationResponse(
          alias: aliasToCreate,
          spAddress: spAddress,
          success: true,
        );
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          String errorMessage;
          if (response.statusCode == 409) {
            errorMessage = 'Username already exists';
          } else {
            errorMessage = errorData['message'] ?? 'Unknown server error';
          }
          return AliasCreationResponse(
            alias: aliasToCreate,
            spAddress: spAddress,
            success: false,
            error: errorMessage,
          );
        } catch (_) {
          return AliasCreationResponse(
            alias: aliasToCreate,
            spAddress: spAddress,
            success: false,
            error: 'Server error: ${response.statusCode} ${response.reasonPhrase}',
          );
        }
      }
    } catch (e) {
      return AliasCreationResponse(
        alias: aliasToCreate,
        spAddress: spAddress,
        success: false,
        error: '$e'
      );
    }
  }

  Future<String> getSpAddressForUserAlias({required String userAlias}) async {
    try {
      final data = await Bip353.getAdressResolve(userAlias);
      if (data.silentpayment != null) {
        return data.silentpayment!;
      } else {
        throw Exception('Found an entry for $userAlias without a silent payment address');
      }
    } catch (e) {
      throw Exception('Failed to resolve address $userAlias: $e');
    }
  }

  /// Checks if a user alias is available for some domain
  /// 
  /// [alias] - The user bip 353 address (or "alias") to check
  /// 
  /// Returns true if available, false otherwise
  Future<bool> isUserAliasAvailable({
    required String alias,
  }) async {
    try {
      await getSpAddressForUserAlias(userAlias: alias);
      // If getAddressForUserName didn't throw, the userAlias is not available
      return false;
    } catch (e) {
      return true;
    }
  }

  void dispose() {
    _client.close();
  }
}
