import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/screens/home/history/tx_history.dart';
import 'package:danawallet/screens/home/wallet/wallet.dart';
import 'package:danawallet/screens/home/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  static const List<Widget> _widgetOptions = [
    WalletScreen(),
    TxHistoryscreen(),
    SettingsScreen(),
  ];

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final homeState = Provider.of<HomeState>(context, listen: true);

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
