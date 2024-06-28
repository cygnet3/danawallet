import 'package:donationwallet/generated/rust/api/simple.dart';

class WalletEntity {
  final String label;
  final String address;
  final String network;
  BigInt balance = BigInt.zero;
  int birthday = 0;
  int lastScan = 0;
  Map<String, OwnedOutput> ownedOutputs = {};

  WalletEntity({
    required this.label,
    required this.address,
    required this.network,
    BigInt? balance,
    int? birthday,
    int? lastScan,
    Map<String, OwnedOutput>? ownedOutputs,
  });

  factory WalletEntity.fromJson(Map<String, dynamic> json) {
    return WalletEntity(
      label: json['label'] as String,
      address: json['address'] as String,
      network: json['network'] as String,
      balance: json.containsKey('balance')
          ? BigInt.parse(json['balance'] as String)
          : null,
      birthday: json['birthday'] as int?,
      lastScan: json['lastScan'] as int?,
      ownedOutputs: (json['ownedOutputs'] as Map<String, dynamic>?)
              ?.map((key, value) {
            final outputJson = value as Map<String, dynamic>;
            return MapEntry(
              key,
              OwnedOutput(
                blockheight: outputJson['blockheight'] as int,
                tweak: outputJson['tweak'] as String,
                amount: Amount(
                    field0:
                        BigInt.parse(outputJson['amount']['field0'] as String)),
                script: outputJson['script'] as String,
                label: outputJson['label'] as String?,
                spendStatus: parseSpendStatus(
                    outputJson['spendStatus'] as Map<String, dynamic>),
              ),
            );
          }) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'address': address,
      'network': network,
      'balance': balance.toString(),
      'birthday': birthday,
      'lastScan': lastScan,
      'ownedOutputs': ownedOutputs.map((key, value) {
        return MapEntry(
          key,
          {
            'blockheight': value.blockheight,
            'tweak': value.tweak,
            'amount': {'field0': value.amount.field0.toString()},
            'script': value.script,
            'label': value.label,
            'spendStatus': spendStatusToJson(value.spendStatus),
          },
        );
      }),
    };
  }

  static OutputSpendStatus parseSpendStatus(Map<String, dynamic> json) {
    if (json['type'] == 'unspent') {
      return OutputSpendStatus.unspent();
    } else if (json['type'] == 'spent') {
      return OutputSpendStatus.spent(json['field0'] as String);
    } else if (json['type'] == 'mined') {
      return OutputSpendStatus.mined(json['field0'] as String);
    } else {
      throw Exception('Unknown OutputSpendStatus type');
    }
  }

  static Map<String, dynamic> spendStatusToJson(OutputSpendStatus status) {
    return status.when(
      unspent: () => {'type': 'unspent'},
      spent: (field0) => {'type': 'spent', 'field0': field0},
      mined: (field0) => {'type': 'mined', 'field0': field0},
    );
  }
}
