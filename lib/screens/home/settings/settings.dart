import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/create/create_wallet.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/spend_state.dart';
import 'package:danawallet/states/theme_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _removeWallet(
    WalletState walletState,
    ChainState chainState,
    SpendState spendSelectionState,
    ThemeNotifier themeNotifier,
    ScanProgressNotifier scanProgress,
    HomeState homeState,
  ) async {
    try {
      await scanProgress.interruptScan();
      await walletState.reset();

      await SettingsRepository().resetAll();
      spendSelectionState.reset();
      chainState.reset();
      homeState.reset();
      themeNotifier.setTheme(null);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _setBirthday(BuildContext context, WalletState walletState,
      HomeState homeState) async {
    TextEditingController controller = TextEditingController();
    final birthday = await showInputAlertDialog(
        controller,
        TextInputType.number,
        'Enter Birthday',
        'Enter wallet\'s birthday (numeric value)');

    if (birthday != null && int.tryParse(birthday) != null) {
      try {
        await walletState.updateWalletBirthday(int.parse(birthday));
        homeState.showMainScreen();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> _setBlindbitUrl(BuildContext context) async {
    SettingsRepository settings = SettingsRepository();
    final controller = TextEditingController();
    controller.text = await settings.getBlindbitUrl() ?? '';

    showInputAlertDialog(controller, TextInputType.url, 'Set blindbit url',
            'Only blindbit is currently supported')
        .then((value) async {
      if (value != null) {
        await settings.setBlindbitUrl(value);
      }
    });
  }

  Future<void> _changeDustLimit(BuildContext context) async {
    SettingsRepository settings = SettingsRepository();
    final controller = TextEditingController();
    final dustLimit = await settings.getDustLimit();
    if (dustLimit != null) {
      controller.text = dustLimit.toString();
    } else {
      controller.text = '';
    }

    showInputAlertDialog(controller, TextInputType.number, 'Set dust limit',
            'Payments below this value are ignored')
        .then((value) async {
      if (value != null && int.tryParse(value) != null) {
        await settings.setDustLimit(int.parse(value));
      }
    });
  }

  Future<void> _wipeWalletButtonPressed(BuildContext context) async {
    final confirmed = await showConfirmationAlertDialog(
        'Confirm deletion', """Are you sure you want to wipe your wallet?
Make sure you have a backup of your seed phrase.
Without a backup, your funds willl be lost!""");

    if (confirmed && context.mounted) {
      final walletState = Provider.of<WalletState>(context, listen: false);
      final homeState = Provider.of<HomeState>(context, listen: false);

      final chainState = Provider.of<ChainState>(context, listen: false);
      final spendState = Provider.of<SpendState>(context, listen: false);
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      final scanProgress =
          Provider.of<ScanProgressNotifier>(context, listen: false);

      await _removeWallet(walletState, chainState, spendState, themeNotifier,
          scanProgress, homeState);
      if (context.mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateWalletScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final homeState = Provider.of<HomeState>(context, listen: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BitcoinButtonOutlined(
            title: 'Show seed phrase',
            onPressed: () async {
              const title = 'Backup seed phrase';
              final text = await walletState.getSeedPhrase() ??
                  'Seed phrase unknown! Did you import from keys?';

              showAlertDialog(title, text);
            },
          ),
          BitcoinButtonOutlined(
              title: 'Set wallet birthday',
              onPressed: () => _setBirthday(context, walletState, homeState)),
          BitcoinButtonOutlined(
            title: 'Set backend url',
            onPressed: () {
              _setBlindbitUrl(context);
            },
          ),
          BitcoinButtonOutlined(
            title: 'Set dust threshold',
            onPressed: () {
              _changeDustLimit(context);
            },
          ),
          BitcoinButtonOutlined(
            title: 'Wipe wallet',
            onPressed: () => _wipeWalletButtonPressed(context),
          )
        ],
      ),
    );
  }
}
