import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/states/home_state.dart';
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
    final homeState = Provider.of<HomeState>(context, listen: true);

    return Scaffold(
      body: IndexedStack(
        index: homeState.selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image(
                image: const AssetImage("icons/flip_vertical.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.neutral7),
            activeIcon: Image(
                image: const AssetImage("icons/flip_vertical.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.blue),
            label: 'Transact',
          ),
          BottomNavigationBarItem(
            icon: Image(
              image:
                  const AssetImage("icons/contacts.png", package: "bitcoin_ui"),
              color: Bitcoin.neutral7,
            ),
            activeIcon: Image(
                image: const AssetImage("icons/contacts.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.blue),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Image(
                image:
                    const AssetImage("icons/gear.png", package: "bitcoin_ui"),
                color: Bitcoin.neutral7),
            activeIcon: Image(
                image:
                    const AssetImage("icons/gear.png", package: "bitcoin_ui"),
                color: Bitcoin.blue),
            label: 'Settings',
          ),
        ],
        currentIndex: homeState.selectedIndex,
        selectedItemColor: Bitcoin.blue,
        onTap: homeState.setIndex,
      ),
    );
  }
}
