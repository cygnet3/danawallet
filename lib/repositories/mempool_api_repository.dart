import 'dart:convert';

import 'package:danawallet/constants.dart';
import 'package:http/http.dart' as http;
import 'package:danawallet/data/models/mempool_api_fees_recommended_model.dart';

class MempoolApiRepository {
  final String baseUrl;

  MempoolApiRepository({Network network = Network.mainnet})
        : baseUrl = 'https://mempool.space/${network != Network.mainnet ? '${network.name}/' : ''}api/v1';

  Future<RecommendedFeeResponse> getCurrentFeeRate() async {
    final response = await http.get(Uri.parse('$baseUrl/fees/recommended'));
    if (response.statusCode == 200) {
      try {
        return RecommendedFeeResponse.fromJson(jsonDecode(response.body));
      } catch (e) {
        throw Exception('Failed to parse recommended fees response: $e');
      }
    } else {
      throw Exception('Failed to get latest fee rates, response status: ${response.statusCode}');
    }
  }

}
