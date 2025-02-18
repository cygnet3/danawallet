import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/create/create_wallet.dart';
import 'package:danawallet/screens/home/home.dart';
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
  final walletState = WalletState();
  final scanNotifier = await ScanProgressNotifier.create();
  final chainState = ChainState();

  final bool walletLoaded;
  try {
    walletLoaded = await walletState.initialize();
  } catch (e) {
    // todo: show an error screen when wallet is present but fails to load
    rethrow;
  }

  if (walletLoaded) {
    await chainState.initialize();
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

class SilentPaymentApp extends StatelessWidget {
  final bool walletLoaded;

  const SilentPaymentApp({super.key, required this.walletLoaded});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Dana wallet development',
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Bitcoin.blue),
        useMaterial3: true,
        fontFamily: 'Space Grotesk',
      ),
      home: walletLoaded ? const HomeScreen() : const CreateWalletScreen(),
    );
  }
}
