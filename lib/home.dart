import 'dart:async';

import 'package:donationwallet/ffi.dart';
import 'package:donationwallet/load_wallet.dart';
import 'package:donationwallet/main.dart';
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
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkWallet();
  }

  Future<void> _checkWallet() async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    if (await api.walletExists(
        label: walletState.label, filesDir: walletState.dir.path)) {
      walletState.walletLoaded = true;
      walletState.getAddress();
    } else {
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
          title: const Text('Silent payments'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.wallet),
              label: 'Wallet',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.info_outline),
            //   label: 'Info',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
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
