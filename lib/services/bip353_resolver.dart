import 'dart:convert';

import 'package:danawallet/data/enums/network.dart';
import 'package:dart_bip353/dart_bip353.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
// ignore: implementation_imports
import 'package:dart_bip353/src/response_model.dart';

class Bip353Resolver {
  /// Cleans a dana address by removing invalid leading characters
  /// A valid dana address should be in format: username@domain
  /// Valid characters for username: lowercase letters, numbers, hyphens, periods, underscores
  /// This method strips any leading characters that aren't valid until it finds a valid start
  static String cleanAndValidateBip353Address(String address) {
    if (address.isEmpty) {
      throw Exception("empty address");
    }

    // Valid characters for the start of a dana address (alphanumeric)
    final validStartChar = RegExp(r'^[a-z0-9]');
    // Valid characters for dana address (username@domain format)
    final validAddressPattern =
        RegExp(r'^[a-z0-9._-]+@[a-z0-9.-]+\.[a-z]+$', caseSensitive: false);

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
      Logger().w(
          'Removed $startIndex leading invalid character(s) from dana address: "$address" -> "$cleaned"');
    }

    // Validate the cleaned address format
    if (validAddressPattern.hasMatch(cleaned)) {
      return cleaned;
    } else {
      throw Exception("Invalid address format");
    }
  }

  static Future<bool> isBip353AddressPresent(
      String username, String domain, Network network) async {
    try {
      final spAddress = await resolve(username, domain, network);
      // If null or no silent payment, address is available
      return spAddress == null;
    } catch (e) {
      // If we can't resolve due to network error, assume it's taken to be safe
      Logger().e('Error checking address availability: $e');
      return false;
    }
  }

  /// Resolves a dana address to its payment information via DNS
  ///
  /// Returns [String] if the address exists and is valid
  /// Returns null if the DNS record doesn't exist (address not registered)
  /// Throws an exception for network errors, invalid responses, or malformed data
  static Future<String?> resolve(
      String username, String domain, Network network) async {
    if (network == Network.regtest) {
      throw Exception("regtest not allowed");
    }

    final query = Bip353.buildDnsQuery(username, domain);
    final url = "${Bip353.dnsResolver}?name=$query&type=TXT";

    try {
      final response = await http.Client().get(
        Uri.parse(url),
        headers: {"Accept": "application/dns-json"},
      );

      Logger().d('DNS response: ${response.body}');

      // Check HTTP status code
      if (response.statusCode != 200) {
        throw Exception(
            'DNS query failed with status ${response.statusCode}: ${response.body}');
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

      final parsed = Bip353DnsResolveResponse.fromRawQueryData(data);
      if (network == Network.mainnet && parsed.silentpayment != null) {
        return parsed.silentpayment;
      } else if ((network == Network.testnet || network == Network.signet) &&
          parsed.testsilentpayment != null) {
        return parsed.testsilentpayment;
      } else {
        // if we have a dns entry but no silent payment record, throw an error
        throw Exception("Record exists, but no silent payment entry");
      }
    } on FormatException {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      // Network errors, timeouts, etc.
      throw Exception('Failed to resolve address $username@$domain: $e');
    }
  }

  static Future<String?> resolveFromAddress(
      String address, Network network) async {
    final cleaned = cleanAndValidateBip353Address(address);
    final parts = cleaned.split('@');
    if (parts.length != 2) {
      throw Exception("Invalid bip353: $address");
    }

    final username = parts[0];
    final domain = parts[1];

    return await resolve(username, domain, network);
  }
}
