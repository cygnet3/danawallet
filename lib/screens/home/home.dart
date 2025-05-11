import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/wallet_setup_phase.dart';
import 'package:danawallet/screens/home/contacts/contacts.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_full.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_address_created.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_new.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/screens/home/settings/settings.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeState = Provider.of<HomeState>(context, listen: true);

    // return a different screen based on the wallet seup phase
    final walletScreen = Selector<WalletState, WalletSetupPhase>(
        selector: (context, walletState) => walletState.currentState,
        builder: (context, data, child) {
          switch (data) {
            case WalletSetupPhase.firstTime:
              return const WalletScreenNew();
            case WalletSetupPhase.addressCreated:
              return const WalletScreenAddressCreated();
            case WalletSetupPhase.full:
              return const WalletScreenFull();
          }
        });

    List<Widget> widgetOptions = [
      walletScreen,
      const ContactsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: homeState.selectedIndex,
        children: widgetOptions,
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
