import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/generated/rust/frb_generated.dart';
import 'package:donationwallet/presentation/states/wallet_state.dart';

import 'package:donationwallet/utils/global_functions.dart';
import 'package:donationwallet/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final walletState = WalletState();
  await walletState.initialize();
  runApp(
    ChangeNotifierProvider.value(
      value: walletState,
      child: const SilentPaymentApp(),
    ),
  );
}

class SilentPaymentApp extends StatelessWidget {
  const SilentPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation wallet',
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Bitcoin.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
