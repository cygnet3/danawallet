import 'dart:convert';

import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/data/models/mempool_prices_response.dart';
import 'package:danawallet/services/fee_api_converter.dart';
import 'package:http/http.dart' as http;
import 'package:danawallet/data/models/recommended_fee_model.dart';
import 'package:danawallet/services/mempool_fee_api_converter.dart';

class MempoolApiRepository {
  final String baseUrl;
  final FeeConverter converter;

  MempoolApiRepository({Network network = Network.mainnet})
      : baseUrl =
            'https://mempool.space/${network != Network.mainnet ? '${network.name}/' : ''}api/v1',
        converter = MempoolApiFeeConverter();

  Future<RecommendedFeeResponse> getCurrentFeeRate() async {
    final response = await http.get(Uri.parse('$baseUrl/fees/recommended'));
    if (response.statusCode == 200) {
      try {
        return converter.convert(jsonDecode(response.body));
      } catch (e) {
        throw Exception('Failed to parse recommended fees response: $e');
      }
    } else {
      throw Exception(
          'Failed to get latest fee rates, response status: ${response.statusCode}');
    }
  }

  Future<MempoolPricesResponse> getExchangeRate() async {
    final response = await http.get(Uri.parse('$baseUrl/prices'));
    if (response.statusCode == 200) {
      try {
        return MempoolPricesResponse.fromJson(jsonDecode(response.body));
      } catch (e) {
        throw Exception('Unexpected format: $e');
      }
    } else {
      throw Exception('Unexpected status code: ${response.statusCode}');
    }
  }
}
