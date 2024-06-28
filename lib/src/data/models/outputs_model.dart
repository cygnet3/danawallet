import 'package:donationwallet/generated/rust/api/simple.dart';

class Outputs {
  final List<int> walletFingerprint;
  final int birthday;
  final int lastScan;
  final Map<String, OwnedOutput> outputs;

  Outputs({
    required this.walletFingerprint,
    required this.birthday,
    required this.lastScan,
    required this.outputs,
  });

  factory Outputs.fromJson(Map<String, dynamic> json) {
    var outputsMap = json['outputs'] as Map<String, dynamic>;
    Map<String, OwnedOutput> outputs = outputsMap.map(
      (key, value) => MapEntry(key, value),
    );

    return Outputs(
      walletFingerprint: List<int>.from(json['wallet_fingerprint']),
      birthday: json['birthday'],
      lastScan: json['last_scan'],
      outputs: outputs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_fingerprint': walletFingerprint,
      'birthday': birthday,
      'last_scan': lastScan,
      'outputs': outputs,
    };
  }
}
