import 'package:donationwallet/src/data/models/sp_client_model.dart';
import 'package:donationwallet/src/data/models/outputs_model.dart';
import 'package:logger/logger.dart';

class SpWallet {
  final SpClient client;
  final Outputs outputs;

  SpWallet({
    required this.client,
    required this.outputs,
  });

  factory SpWallet.fromJson(Map<String, dynamic> json) {
    try {
      final client = SpClient.fromJson(json['client']);
      final outputs = Outputs.fromJson(json['outputs']);
      return SpWallet(client: client, outputs: outputs);
    } catch (e, stackTrace) {
      Logger().e("Failed to convert $json to SpWallet: $e, $stackTrace");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'client': client.toJson(),
      'outputs': outputs.toJson(),
    };
  }
}
