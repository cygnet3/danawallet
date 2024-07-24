import 'dart:async';

import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/load_wallet.dart';
import 'package:donationwallet/states/wallet_state.dart';
import 'package:donationwallet/tx_history.dart';
import 'package:donationwallet/wallet.dart';
import 'package:donationwallet/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  int _selectedIndex = 0;
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
    try {
      await walletState.updateWalletStatus();
      walletState.walletLoaded = true;
    } catch (e) {
      walletState.walletLoaded = false;
    }
    setState(() {
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final walletState = Provider.of<WalletState>(context);
    if (!walletState.walletLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wallet creation/restoration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const LoadWalletScreen(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Silent Payments'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Image(
                  image: const AssetImage("icons/wallet.png",
                      package: "bitcoin_ui"),
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
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          onTap: _onItemTapped,
        ),
      );
    }
  }
}
