import 'dart:convert';

import 'package:donationwallet/src/data/providers/secure_storage.dart';
import 'package:donationwallet/src/domain/entities/wallet_entity.dart';
import 'package:donationwallet/src/data/models/sp_wallet_model.dart';
import 'package:logger/logger.dart';

class WalletRepository {
  final SecureStorageProvider secureStorageProvider;

  WalletRepository(this.secureStorageProvider);

  WalletEntity convertSpWalletToWalletEntity(SpWallet spWallet) {
    return WalletEntity(
      label: spWallet.client.label,
      address: "", // we need to add it later
      network: spWallet.client.spReceiver.network,
      balance: BigInt.zero, // we compute that from all the outputs
      birthday: spWallet.outputs.birthday,
      lastScan: spWallet.outputs.lastScan,
      ownedOutputs: spWallet.outputs.outputs,
    );
  }

  Future<void> saveWallet(String key, SpWallet spWallet) async {
    try {
      await secureStorageProvider.saveWalletToSecureStorage(
          key, jsonEncode(spWallet));
    } catch (e) {
      throw Exception("Failed to save wallet to secure storage");
    }
  }

  Future<WalletEntity> getWallet(String label) async {
    try {
      final json =
          await secureStorageProvider.getWalletFromSecureStorage(label);
      final spWallet =
          SpWallet.fromJson(jsonDecode(json) as Map<String, dynamic>);
      return convertSpWalletToWalletEntity(spWallet);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getRawWallet(String label) async {
    try {
      return await secureStorageProvider.getWalletFromSecureStorage(label);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rmWallet(String label) async {
    try {
      return await secureStorageProvider.rmWalletFromSecureStorage(label);
    } catch (e) {
      rethrow;
    }
  }
}
