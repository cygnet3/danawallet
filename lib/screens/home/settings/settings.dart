import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/onboarding/introduction.dart';
import 'package:danawallet/screens/recovery/view_mnemonic_screen.dart';
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

  Future<void> _setLastScan(BuildContext context) async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final homeState = Provider.of<HomeState>(context, listen: false);

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

  Future<void> _setBlindbitUrl(BuildContext context) async {
    final wallet = Provider.of<WalletState>(context, listen: false);
    SettingsRepository settings = SettingsRepository.instance;
    final chainState = Provider.of<ChainState>(context, listen: false);
    final controller = TextEditingController();
    controller.text = await settings.getBlindbitUrl() ?? '';

    final value = await showInputAlertDialog(controller, TextInputType.url,
        'Set blindbit url', 'Only blindbit is currently supported');

    final network = wallet.network;

    String? url;
    if (value is bool && value) {
      url = network.getDefaultBlindbitUrl();
    } else if (value is String) {
      url = value;
    }

    if (url != null) {
      try {
        final success = await chainState.updateBlindbitUrl(url);
        if (success) {
          await settings.setBlindbitUrl(url);
        } else {
          displayNotification("Wrong network for blindbit server");
        }
      } catch (e) {
        displayNotification(exceptionToString(e));
      }
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
    final confirmed = await showConfirmationAlertDialog('Confirm deletion',
        "Are you sure you want to wipe your wallet? Without a backup, you will lose your funds!");

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
                builder: (context) => const IntroductionScreen()));
      }
    }
  }

  void onShowMnemonic(BuildContext context) async {
    final wallet = Provider.of<WalletState>(context, listen: false);
    final mnemonic = await wallet.getSeedPhraseFromSecureStorage();

    if (context.mounted) {
      if (mnemonic != null) {
        goToScreen(context, ViewMnemonicScreen(mnemonic: mnemonic));
      } else {
        showAlertDialog("Seed phrase unknown",
            "Seed phrase unknown! Did you import from keys?");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BitcoinButtonOutlined(
              title: 'Show seed phrase',
              onPressed: () => onShowMnemonic(context)),
          if (isDevEnv)
            BitcoinButtonOutlined(
                title: 'Set scan height',
                onPressed: () => _setLastScan(context)),
          BitcoinButtonOutlined(
            title: 'Set backend url',
            onPressed: () {
              _setBlindbitUrl(context);
            },
          ),
          if (isDevEnv)
            BitcoinButtonOutlined(
              title: 'Set dust threshold',
              onPressed: () {
                _setDustLimit(context);
              },
            ),
          if (isDevEnv)
            BitcoinButtonOutlined(
              title: 'File backup wallet',
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
