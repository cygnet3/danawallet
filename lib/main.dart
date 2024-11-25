import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/screens/create/create_wallet.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/services/logging_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/spend_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/states/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await LoggingService.create();
  final walletState = WalletState();
  final scanNotifier = await ScanProgressNotifier.create();
  final chainState = ChainState();
  final themeNotifier = ThemeNotifier();

  final bool walletLoaded;
  try {
    walletLoaded = await walletState.initialize();
  } catch (e) {
    // todo: show an error screen when wallet is present but fails to load
    rethrow;
  }

  if (walletLoaded) {
    await chainState.initialize();
    themeNotifier.setTheme(walletState.network);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: scanNotifier),
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider.value(value: chainState),
        ChangeNotifierProvider.value(value: SpendState()),
        ChangeNotifierProvider.value(value: HomeState()),
        ProxyProvider<WalletState, MempoolApiRepository>(
          update: (_, walletState, __) => MempoolApiRepository(network: walletState.network),
        ),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: true);

    return MaterialApp(
      title: 'Dana wallet',
      navigatorKey: globalNavigatorKey,
      theme: themeNotifier.themeData,
      home: walletLoaded ? const HomeScreen() : const CreateWalletScreen(),
    );
  }
}
