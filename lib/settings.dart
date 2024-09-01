import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/home.dart';
import 'package:donationwallet/generated/rust/api/wallet.dart';
import 'package:donationwallet/services/settings_service.dart';
import 'package:donationwallet/states/chain_state.dart';
import 'package:donationwallet/states/spend_state.dart';
import 'package:donationwallet/states/theme_notifier.dart';
import 'package:donationwallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _removeWallet(
    WalletState walletState,
    ChainState chainState,
    SpendState spendSelectionState,
    ThemeNotifier themeNotifier,
  ) async {
    try {
      await walletState.rmWalletFromSecureStorage();
      await walletState.reset();

      SettingsService().resetBlindbitUrl();
      spendSelectionState.reset();
      chainState.reset();
      themeNotifier.setTheme(null);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _getSeedPhrase(WalletState walletState) async {
    try {
      final wallet = await walletState.getWalletFromSecureStorage();
      return showMnemonic(encodedWallet: wallet);
    } catch (e) {
      displayNotification(e.toString());
      return null;
    }
  }

  Future<void> _setBirthday(BuildContext context,
      TextEditingController controller, Function(Exception? e) callback) async {
    showInputAlertDialog(controller, TextInputType.number, 'Enter Birthday',
            'Enter wallet\'s birthday (numeric value)')
        .then((value) async {
      if (value != null && int.tryParse(value) != null) {
        final walletState = Provider.of<WalletState>(context, listen: false);
        try {
          final wallet = await walletState.getWalletFromSecureStorage();
          final updatedWallet =
              changeBirthday(encodedWallet: wallet, birthday: int.parse(value));
          walletState.saveWalletToSecureStorage(updatedWallet);
          callback(null);
          await walletState.updateWalletStatus();
        } on Exception catch (e) {
          callback(e);
        } catch (e) {
          rethrow;
        }
      }
    });
  }

  Future<void> _setBlindbitUrl(
      BuildContext context, TextEditingController controller) async {
    SettingsService settings = SettingsService();
    controller.text = await settings.getBlindbitUrl() ?? '';

    showInputAlertDialog(controller, TextInputType.url, 'Set blindbit url',
            'Only blindbit is currently supported')
        .then((value) async {
      if (value != null) {
        settings.setBlindbitUrl(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final spendState = Provider.of<SpendState>(context, listen: false);
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BitcoinButtonOutlined(
            title: 'Show seed phrase',
            onPressed: () async {
              const title = 'Backup seed phrase';
              final text = await _getSeedPhrase(walletState) ??
                  'Seed phrase unknown! Did you import from keys?';

              showAlertDialog(title, text);
            },
          ),
          BitcoinButtonOutlined(
            title: 'Set wallet birthday',
            onPressed: () async {
              final controller = TextEditingController();
              await _setBirthday(context, controller, (Exception? e) async {
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
            title: 'Change backend url',
            onPressed: () {
              final controller = TextEditingController();
              _setBlindbitUrl(context, controller);
            },
          ),
          BitcoinButtonOutlined(
            title: 'Wipe wallet',
            onPressed: () => _removeWallet(
                walletState, chainState, spendState, themeNotifier),
          ),
        ],
      ),
    );
  }
}
