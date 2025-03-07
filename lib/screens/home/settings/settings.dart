import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/create/create_wallet.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/services/backup_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _removeWallet(
    WalletState walletState,
    ChainState chainState,
    ScanProgressNotifier scanProgress,
    HomeState homeState,
  ) async {
    try {
      await scanProgress.interruptScan();
      await walletState.reset();

      await SettingsRepository.instance.resetAll();
      chainState.reset();
      homeState.reset();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _setLastScan(BuildContext context, WalletState walletState,
      HomeState homeState) async {
    TextEditingController controller = TextEditingController();
    final scanHeight = await showInputAlertDialog(
        controller,
        TextInputType.number,
        'Enter scan height',
        'Enter current scan height (numeric value)');
    if (scanHeight is int) {
      await walletState.resetToScanHeight(scanHeight);
      homeState.showMainScreen();
    } else if (scanHeight is bool && scanHeight) {
      // we reset the scan height to the wallet birthday
      final birthday = walletState.birthday;
      await walletState.resetToScanHeight(birthday);
      homeState.showMainScreen();
    }
  }

  Future<void> _setBlindbitUrl(BuildContext context, Network network) async {
    SettingsRepository settings = SettingsRepository.instance;
    final controller = TextEditingController();
    controller.text = await settings.getBlindbitUrl() ?? '';

    final value = await showInputAlertDialog(controller, TextInputType.url,
        'Set blindbit url', 'Only blindbit is currently supported');
    if (value is bool && value) {
      final defaultBlindbitUrl = network.getDefaultBlindbitUrl();
      await settings.setBlindbitUrl(defaultBlindbitUrl);
    } else if (value is String) {
      await settings.setBlindbitUrl(value);
    }
  }

  Future<void> _setDustLimit(BuildContext context) async {
    SettingsRepository settings = SettingsRepository.instance;
    final controller = TextEditingController();
    final dustLimit = await settings.getDustLimit();
    if (dustLimit != null) {
      controller.text = dustLimit.toString();
    } else {
      controller.text = '';
    }

    final value = await showInputAlertDialog(controller, TextInputType.number,
        'Set dust limit', 'Payments below this value are ignored');

    if (value is int) {
      await settings.setDustLimit(value);
    } else if (value is bool && value) {
      await settings.setDustLimit(defaultDustLimit);
    }
  }

  Future<void> _backupWalletButtonPressed() async {
    final controller = TextEditingController();

    final password = await showInputAlertDialog(controller, TextInputType.text,
        'Set backup password', 'set password for backup file',
        showReset: false);

    // todo: validate the password is secure
    if (password is String) {
      try {
        await BackupService.backupToFile(password);
      } catch (e) {
        displayNotification("backup failed");
      }
    }
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
      final scanProgress =
          Provider.of<ScanProgressNotifier>(context, listen: false);

      await _removeWallet(walletState, chainState, scanProgress, homeState);
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
              final text = await walletState.getSeedPhraseFromSecureStorage() ??
                  'Seed phrase unknown! Did you import from keys?';

              showAlertDialog(title, text);
            },
          ),
          if (isDevEnv())
            BitcoinButtonOutlined(
                title: 'Set scan height',
                onPressed: () => _setLastScan(context, walletState, homeState)),
          if (isDevEnv())
            BitcoinButtonOutlined(
              title: 'Set backend url',
              onPressed: () {
                _setBlindbitUrl(context, walletState.network);
              },
            ),
          if (isDevEnv())
            BitcoinButtonOutlined(
              title: 'Set dust threshold',
              onPressed: () {
                _setDustLimit(context);
              },
            ),
          BitcoinButtonOutlined(
            title: 'Backup wallet',
            onPressed: () {
              _backupWalletButtonPressed();
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
