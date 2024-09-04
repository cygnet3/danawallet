import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/spend_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/states/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final walletState = WalletState();
  await walletState.initialize();
  final themeNotifier = ThemeNotifier();
  final chainState = ChainState();
  final spendState = SpendState();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider.value(value: chainState),
        ChangeNotifierProvider.value(value: spendState),
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
      title: 'Dana wallet',
      navigatorKey: globalNavigatorKey,
      theme: themeNotifier.themeData,
      home: const HomeScreen(),
    );
  }
}
