import 'dart:convert';
import 'dart:math';
import 'package:danawallet/data/models/dana_address_creation_request.dart';
import 'package:danawallet/data/models/dana_address_creation_response.dart';
import 'package:dart_bip353/dart_bip353.dart';
import 'package:dart_bip353/src/response_model.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NameServerRepository {
  final String baseUrl;
  final String domain;
  final String apiVersion;
  final http.Client _client;
  final Random _random = Random.secure();
  String? _userDanaAddress;

  NameServerRepository({
    required this.baseUrl,
    required this.domain,
    required this.apiVersion,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Generates a unique ID for requests without external dependencies
  /// Format: timestamp-randomhex (e.g., "1699889234567-a3f2c9d8")
  String _generateUniqueId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomHex = _random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return '$timestamp-$randomHex';
  }

  /// Cleans a dana address by removing invalid leading characters
  /// A valid dana address should be in format: username@domain
  /// Valid characters for username: lowercase letters, numbers, hyphens, periods, underscores
  /// This method strips any leading characters that aren't valid until it finds a valid start
  String? _cleanDanaAddress(String? address) {
    if (address == null || address.isEmpty) {
      return address;
    }

    // Valid characters for the start of a dana address (alphanumeric)
    final validStartChar = RegExp(r'^[a-z0-9]');
    // Valid characters for dana address (username@domain format)
    final validAddressPattern = RegExp(r'^[a-z0-9._-]+@[a-z0-9.-]+\.[a-z]+$', caseSensitive: false);

    // Find the first valid starting character
    int startIndex = 0;
    for (int i = 0; i < address.length; i++) {
      final char = address[i];
      if (validStartChar.hasMatch(char)) {
        startIndex = i;
        break;
      }
    }

    // Extract the substring starting from the first valid character
    String cleaned = address.substring(startIndex).trim();

    // If we removed leading characters, log it
    if (startIndex > 0) {
      Logger().w('Removed ${startIndex} leading invalid character(s) from dana address: "$address" -> "$cleaned"');
    }

    // Validate the cleaned address format
    if (!validAddressPattern.hasMatch(cleaned)) {
      Logger().w('Dana address format may be invalid after cleaning: "$cleaned" (original: "$address")');
      // Still return it, but log a warning - the caller should validate
    }

    return cleaned;
  }

  set userDanaAddress(String? value) {
    if (_userDanaAddress == null) {
      // Clean the address to remove any invalid leading characters (like mangled ₿ symbol)
      final cleanedValue = _cleanDanaAddress(value);
      _userDanaAddress = cleanedValue;
    } else {
      throw Exception('User dana address already set to $_userDanaAddress');
    }
  }

  String? get userDanaAddress => _userDanaAddress;

  void resetUserAddress() {
    _userDanaAddress = null;
  }

  /// Creates a dana address by calling the external name_server
  /// 
  /// [username] - The name to be used with the domain as a dana address
  /// [spAddress] - The Silent Payment address to associate with the dana address
  /// 
  /// Returns [DanaAddressCreationResponse] with the created address or error details
  Future<DanaAddressCreationResponse> registerDanaAddress({
    required String username,
    required String spAddress,
  }) async {
    final danaAddress = '$username@$domain';
    final requestId = _generateUniqueId(); // Generate ID once for all code paths

    // We try to resolve the address first to see if it already exists
    try {
      final data = await getAddressResolve(danaAddress);
      
      if (data == null) {
        // Address not registered yet, proceed with registration
        Logger().i('Address $danaAddress not found, proceeding with registration');
      } else if (data.silentpayment != null && data.silentpayment == spAddress) {
        // If we find our address, return success there's nothing more to do
        return DanaAddressCreationResponse(
          id: requestId,
          message: 'Address already registered',
          danaAddress: danaAddress,
          spAddress: data.silentpayment!,
        );
      } else if (data.silentpayment != null && data.silentpayment != spAddress) {
        // If we find another address, return error, user must try with a different username
        return DanaAddressCreationResponse(
          id: requestId,
          message: 'Dana address already in use',
          danaAddress: danaAddress,
          spAddress: data.silentpayment!,
        );
      } else if (data.silentpayment == null) {
        // We do have an entry with that dana address but no silent payment address. That's unlikely for now
        Logger().w('Found an entry for $danaAddress without a silent payment address');
        Logger().w('Proceeding with registration');
      }
    } catch (e) {
      // Network or parsing error - we'll let name server try and if it exists it will return an error
      Logger().e('Failed to resolve address $danaAddress: $e');
      Logger().w('Trying to proceed with registration');
    }

    try {
      final request = DanaAddressRegisterRequest(
        id: requestId,
        userName: username,
        domain: domain,
        spAddress: spAddress,
      );

      Logger().d('Registering dana address: $danaAddress with request ID: $requestId');
      final response = await _client.post(
        Uri.parse('$baseUrl/name/$apiVersion/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      Logger().d('Registration response status: ${response.statusCode}');
      Logger().d('Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the server response
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final responseData = DanaAddressCreationResponse.fromJson(decoded);
          
          // Validate that we got the expected fields
          if (responseData.danaAddress == null || responseData.spAddress == null) {
            Logger().e('Server returned success but missing required fields. Response: ${response.body}');
            return DanaAddressCreationResponse(
              id: requestId,
              message: 'Server response missing required fields: danaAddress=${responseData.danaAddress}, spAddress=${responseData.spAddress}',
              danaAddress: danaAddress,
              spAddress: spAddress,
            );
          }
          
          Logger().i('Successfully registered dana address: ${responseData.danaAddress}');
          return responseData;
        } catch (e, stackTrace) {
          Logger().e('Failed to parse successful response (${response.statusCode}): $e');
          Logger().e('Response body: ${response.body}');
          Logger().e('Stack trace: $stackTrace');
          return DanaAddressCreationResponse(
            id: requestId,
            message: 'Failed to parse server response: $e',
            danaAddress: danaAddress,
            spAddress: spAddress,
          );
        }
      } else {
        // Server returned an error status
        Logger().e('Registration failed with HTTP ${response.statusCode} ${response.reasonPhrase ?? "Unknown"}');
        Logger().e('Request URL: $baseUrl/$apiVersion/name/register');
        Logger().e('Response body: ${response.body}');
        
        // Try to parse as JSON error response
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final responseData = DanaAddressCreationResponse.fromJson(decoded);
          
          // If we got a valid error response with a message, use it
          if (responseData.message.isNotEmpty) {
            Logger().e('Server error message: ${responseData.message}');
            return responseData;
          } else {
            // Parsed but no message - create our own
            return DanaAddressCreationResponse(
              id: requestId,
              message: 'Server returned HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Unknown error"}',
              danaAddress: danaAddress,
              spAddress: spAddress,
            );
          }
        } catch (parseError) {
          // Failed to parse error response - likely HTML or non-JSON
          Logger().e('Failed to parse error response as JSON: $parseError');
          Logger().e('Response may be HTML or non-JSON format');
          
          // Create a clear error message based on status code
          String errorMessage;
          if (response.statusCode == 404) {
            errorMessage = 'Registration endpoint not found (404). Check API version and endpoint path.';
          } else if (response.statusCode >= 500) {
            errorMessage = 'Server error (${response.statusCode}): ${response.reasonPhrase ?? "Internal server error"}';
          } else if (response.statusCode == 400) {
            errorMessage = 'Bad request (400): Invalid registration data';
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            errorMessage = 'Authentication error (${response.statusCode}): Unauthorized';
          } else {
            errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Unknown error"}';
          }
          
          return DanaAddressCreationResponse(
            id: requestId,
            message: errorMessage,
            danaAddress: danaAddress,
            spAddress: spAddress,
          );
        }
      }
    } catch (e, stackTrace) {
      // Request failed (network error, timeout, etc.)
      Logger().e('Request failed for dana address $danaAddress: $e');
      Logger().e('Stack trace: $stackTrace');
      return DanaAddressCreationResponse(
        id: requestId,
        message: 'Request failed: $e',
        danaAddress: danaAddress,
        spAddress: spAddress,
      );
    }
  }

  /// Check if a dana address is available for registration
  /// Returns true if the dana address is not taken, false otherwise
  Future<bool> isDanaAddressAvailable(String username) async {
    try {
      final data = await getAddressResolve('$username@$domain');
      // If null or no silent payment, address is available
      return data == null || data.silentpayment == null;
    } catch (e) {
      // If we can't resolve due to network error, assume it's taken to be safe
      Logger().e('Error checking address availability: $e');
      return false;
    }
  }

  /// Resolves a dana address to its payment information via DNS
  /// 
  /// Returns [Bip353DnsResolveResponse] if the address exists and is valid
  /// Returns null if the DNS record doesn't exist (address not registered)
  /// Throws an exception for network errors, invalid responses, or malformed data
  Future<Bip353DnsResolveResponse?> getAddressResolve(String address) async {
    // Clean the address to remove any invalid leading characters (like mangled ₿ symbol)
    final cleanedAddress = _cleanDanaAddress(address);
    if (cleanedAddress == null || cleanedAddress.isEmpty) {
      throw ArgumentError("Invalid address: address is null or empty after cleaning");
    }

    final split = cleanedAddress.split("@");
    if (split.length != 2) {
      throw ArgumentError("Invalid address format: expected 'username@domain'");
    }

    final username = split[0];
    final domain = split[1];
    final query = Bip353.buildDnsQuery(username, domain);
    final url = "${Bip353.dnsResolver}?name=$query&type=TXT";

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {"Accept": "application/dns-json"},
      );

      Logger().d('DNS response: ${response.body}');

      // Check HTTP status code
      if (response.statusCode != 200) {
        throw Exception(
          'DNS query failed with status ${response.statusCode}: ${response.body}'
        );
      }

      // Parse JSON response
      final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw FormatException('Invalid JSON response from DNS server: $e');
      }

      // Check DNS response status
      // Status 0 = NOERROR (success)
      // Status 3 = NXDOMAIN (domain doesn't exist)
      final status = decoded["Status"] as int?;
      
      if (status == 3 || (status == 0 && decoded["Answer"] == null)) {
        // DNS record doesn't exist - this is not an error, just means address not registered
        return null;
      }
      
      if (status != 0) {
        throw Exception('DNS query returned error status: $status');
      }

      final answer = decoded["Answer"] as List<dynamic>?;
      if (answer == null || answer.isEmpty) {
        return null;
      }

      final firstRecord = answer.first as Map<String, dynamic>;
      final data = firstRecord["data"] as String;

      return Bip353DnsResolveResponse.fromRawQueryData(data);
    } on FormatException {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      // Network errors, timeouts, etc.
      throw Exception('Failed to resolve address $address: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
