import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/src/settings/controllers/settings_controller.dart';
import 'package:donationwallet/src/setup/screens/setup_wallet_screen.dart';
import 'package:donationwallet/src/utils/global_functions.dart';
import 'package:donationwallet/src/home/home_screen.dart';
import 'package:donationwallet/src/wallet/models/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  final settingsController = const SettingsController();

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BitcoinButtonOutlined(
          title: 'Show seed phrase',
          onPressed: () async {
            final walletState =
                Provider.of<WalletState>(context, listen: false);

            const title = 'Backup seed phrase';
            final text = await settingsController.getSeedPhrase(walletState) ??
                'Seed phrase unknown! Did you import from keys?';

            showAlertDialog(title, text);
          },
        ),
        BitcoinButtonOutlined(
          title: 'Set wallet birthday',
          onPressed: () async {
            final controller = TextEditingController();
            await settingsController.setBirthday(context, controller,
                (Exception? e) async {
              if (e != null) {
                throw e;
              } else {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
              }
            });
          },
        ),
        BitcoinButtonOutlined(
          title: 'Wipe wallet',
          onPressed: () async {
            final walletState =
                Provider.of<WalletState>(context, listen: false);
            await settingsController.removeWallet(walletState,
                (Exception? e) async {
              if (e != null) {
                throw e;
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SetupWalletScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            });
          },
        ),
      ],
    );
  }
}
