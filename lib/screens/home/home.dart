import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/screens/home/contacts/contacts.dart';
import 'package:danawallet/screens/home/wallet/wallet.dart';
import 'package:danawallet/screens/home/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  /// If non-null, shows a hint to add this address as a contact on load.
  final PaymentAddress? sentAddress;

  const HomeScreen({Key? key, this.sentAddress}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.sentAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Create new contact'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateContactScreen(
                              newAddress: widget.sentAddress!)),
                    );
                  },
                ),
                // ListTile(
                //   leading: Icon(Icons.person_search),
                //   title: Text('Add to existing contact'),
                //   onTap: () {
                //     Navigator.pop(ctx);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (_) => SelectContactScreen(address: widget.sentAddress!)),
                //     );
                //   },
                // ),
              ],
            ),
          ),
        );
      });
    }
  }

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
