import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/main.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/services/logging_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await LoggingService.create();
  final walletState = await WalletState.create();
  final scanNotifier = await ScanProgressNotifier.create();
  final chainState = ChainState();

  final bool walletLoaded;
  try {
    walletLoaded = await walletState.initialize();
  } catch (e) {
    // todo: show an error screen when wallet is present but fails to load
    rethrow;
  }

  // if a blindbit url is given, override the saved url
  const blindbitUrl = String.fromEnvironment("BLINDBIT_URL");
  if (blindbitUrl != '') {
    await SettingsRepository.instance.setBlindbitUrl(blindbitUrl);
  }

  if (walletLoaded) {
    final network = walletState.network;
    final blindbitUrl = await SettingsRepository.instance.getBlindbitUrl();
    await chainState.initialize(network, blindbitUrl!);
    chainState.startSyncService(walletState, scanNotifier);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: scanNotifier),
        ChangeNotifierProvider.value(value: chainState),
        ChangeNotifierProvider.value(value: HomeState()),
      ],
      child: SilentPaymentApp(walletLoaded: walletLoaded),
    ),
  );
}
