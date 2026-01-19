import 'package:danawallet/data/models/bip353_address.dart';

class PrefixSearchResponse {
  final String id;
  final String message;
  final List<Bip353Address> danaAddresses;
  final int count;
  final int totalCount;

  const PrefixSearchResponse({
    required this.id,
    required this.message,
    required this.danaAddresses,
    required this.count,
    required this.totalCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'dana_addresses': danaAddresses,
      'count': count,
      'total_count': totalCount,
    };
  }

  factory PrefixSearchResponse.fromJson(Map<String, dynamic> json) {
    final danaAddressList = json['dana_addresses'] as List<dynamic>?;
    return PrefixSearchResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      danaAddresses: danaAddressList != null
          ? danaAddressList
              .map((e) => Bip353Address.fromString(e as String))
              .toList()
          : [],
      count: json['count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}
