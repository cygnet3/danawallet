import 'package:donationwallet/rust/frb_generated.dart';

import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/home.dart';
import 'package:donationwallet/states/chain_state.dart';
import 'package:donationwallet/states/wallet_state.dart';
import 'package:donationwallet/states/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final walletState = WalletState();
  await walletState.initialize();
  final themeNotifier = ThemeNotifier("signet");
  final chainState = ChainState();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider.value(value: chainState),
      ],
      child: const SilentPaymentApp(),
    ),
  );
}

class SilentPaymentApp extends StatelessWidget {
  const SilentPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Donation wallet',
      navigatorKey: globalNavigatorKey,
      theme: themeNotifier.themeData,
      home: const HomeScreen(),
    );
  }
}
