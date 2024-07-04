import 'package:donationwallet/src/data/providers/chain_api.dart';
import 'package:donationwallet/src/data/providers/secure_storage.dart';
import 'package:donationwallet/src/data/repositories/chain_repository.dart';
import 'package:donationwallet/src/data/repositories/wallet_repository.dart';
import 'package:donationwallet/src/domain/usecases/create_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/delete_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/get_chain_tip_usecase.dart';
import 'package:donationwallet/src/domain/usecases/load_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/save_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/update_wallet_usecase.dart';
import 'package:donationwallet/generated/rust/frb_generated.dart';
import 'package:donationwallet/src/presentation/notifiers/chain_notifier.dart';
import 'package:donationwallet/src/presentation/notifiers/wallet_notifier.dart';
import 'package:donationwallet/src/app.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AndroidOptions getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    final storage = FlutterSecureStorage(aOptions: getAndroidOptions());
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletNotifier>(
            create: (_) => WalletNotifier(
                  SaveWalletUseCase(
                      WalletRepository(SecureStorageProvider(storage))),
                  LoadWalletUseCase(
                      WalletRepository(SecureStorageProvider(storage))),
                  DeleteWalletUseCase(
                      WalletRepository(SecureStorageProvider(storage))),
                  UpdateWalletUseCase(ChainRepository(ChainApiProvider())),
                  CreateWalletUseCase(
                      WalletRepository(SecureStorageProvider(storage))),
                )),
        ChangeNotifierProvider<ChainNotifier>(
            create: (_) => ChainNotifier(
                GetChainTipUseCase(ChainRepository(ChainApiProvider()))))
      ],
      child: const SilentPaymentApp(),
    );
  }
}
