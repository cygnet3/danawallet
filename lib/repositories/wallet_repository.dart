import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletRepository {
  final String keyWalletBlob = "default";
  final secureStorage = const FlutterSecureStorage();

  WalletRepository();

  Future<String?> readWalletBlob() async {
    return await secureStorage.read(key: keyWalletBlob);
  }

  Future<void> saveWalletBlob(String wallet) async {
    await secureStorage.write(key: keyWalletBlob, value: wallet);
  }

  Future<void> deleteWalletBlob() async {
    await secureStorage.write(key: keyWalletBlob, value: null);
  }
}
