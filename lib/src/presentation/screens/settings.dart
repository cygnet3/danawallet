import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/src/presentation/notifiers/wallet_notifier.dart';
import 'package:donationwallet/src/utils/constants.dart';
import 'package:donationwallet/src/utils/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  // final settingsController = const SettingsController();

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletNotifier = Provider.of<WalletNotifier>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BitcoinButtonOutlined(
          title: 'Show seed phrase',
          onPressed: () async {
            // final walletState =
            //     Provider.of<WalletState>(context, listen: false);

            // const title = 'Backup seed phrase';
            // final text = await settingsController.getSeedPhrase(walletState) ??
            //     'Seed phrase unknown! Did you import from keys?';

            // showAlertDialog(title, text);
          },
        ),
        BitcoinButtonOutlined(
          title: 'Set wallet birthday',
          onPressed: () async {
            // final controller = TextEditingController();
            // await settingsController.setBirthday(context, controller,
            //     (Exception? e) async {
            //   if (e != null) {
            //     throw e;
            //   } else {
            //     Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => const HomeScreen()));
            //   }
            // });
          },
        ),
        BitcoinButtonOutlined(
          title: 'Wipe wallet',
          onPressed: () {
            walletNotifier.rmWallet(defaultLabel);
          },
        ),
      ],
    );
  }
}
