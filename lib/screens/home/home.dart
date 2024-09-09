import 'dart:async';

import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/create/create_wallet.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/theme_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/screens/home/history/tx_history.dart';
import 'package:danawallet/screens/home/wallet/wallet.dart';
import 'package:danawallet/screens/home/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  final List<Widget> _widgetOptions = [
    const WalletScreen(),
    const TxHistoryscreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkWallet();
  }

  Future<void> _checkWallet() async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    try {
      await walletState.updateWalletStatus();
      await chainState.initialize();
      themeNotifier.setTheme(walletState.network);

      walletState.walletLoaded = true;
    } catch (e) {
      walletState.walletLoaded = false;
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: true);
    final homeState = Provider.of<HomeState>(context, listen: true);

    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!walletState.walletLoaded) {
      // go to create wallet screen
      return const CreateWalletScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Silent Payments'),
            const Spacer(),
            Text(walletState.network.toString()),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: homeState.selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image(
                image:
                    const AssetImage("icons/wallet.png", package: "bitcoin_ui"),
                color: Bitcoin.neutral3Dark),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Image(
                image: const AssetImage("icons/transactions.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.neutral3Dark),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Image(
                image:
                    const AssetImage("icons/gear.png", package: "bitcoin_ui"),
                color: Bitcoin.neutral3Dark),
            label: 'Settings',
          ),
        ],
        currentIndex: homeState.selectedIndex,
        selectedItemColor: Colors.green,
        onTap: homeState.setIndex,
      ),
    );
  }
}
