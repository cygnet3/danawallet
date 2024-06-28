import 'package:flutter/material.dart';
import 'package:donationwallet/src/utils/global_functions.dart';
import 'package:donationwallet/src/presentation/screens/home_screen.dart';
import 'package:donationwallet/src/presentation/theme/app_theme.dart';

class SilentPaymentApp extends StatelessWidget {
  const SilentPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation Wallet',
      navigatorKey: globalNavigatorKey,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
