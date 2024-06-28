import 'package:donationwallet/src/data/models/label_model.dart';

class SPReceiver {
  final int version;
  final String network;
  final List<int> scanPubkey;
  final List<int> spendPubkey;
  final String changeLabel;
  final List<Label> labels;

  SPReceiver({
    required this.version,
    required this.network,
    required this.scanPubkey,
    required this.spendPubkey,
    required this.changeLabel,
    required this.labels,
  });

  factory SPReceiver.fromJson(Map<String, dynamic> json) {
    var labelsList = json['labels'] as List;
    List<Label> labels = labelsList.map((i) => Label.fromJson(i)).toList();

    return SPReceiver(
      version: json['version'],
      network: json['network'],
      scanPubkey: List<int>.from(json['scan_pubkey']),
      spendPubkey: List<int>.from(json['spend_pubkey']),
      changeLabel: json['change_label'],
      labels: labels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'network': network,
      'scan_pubkey': scanPubkey,
      'spend_pubkey': spendPubkey,
      'change_label': changeLabel,
      'labels': labels.map((e) => e.toJson()).toList(),
    };
  }
}
