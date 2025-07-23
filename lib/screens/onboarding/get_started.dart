import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/screens/onboarding/recovery/seed_phrase.dart';
import 'package:danawallet/services/backup_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  Future<void> onRestoreFile(BuildContext context) async {
    try {
      final walletState = Provider.of<WalletState>(context, listen: false);
      final chainState = Provider.of<ChainState>(context, listen: false);
      final scanProgress =
          Provider.of<ScanProgressNotifier>(context, listen: false);
      final encryptedBackup = await BackupService.getEncryptedBackupFromFile();

      if (encryptedBackup != null) {
        final controller = TextEditingController();

        final password = await showInputAlertDialog(
            controller,
            TextInputType.text,
            'Backup password',
            'provide password for backup',
            showReset: false);

        if (password is String) {
          await BackupService.restoreFromEncryptedBackup(
              encryptedBackup, password);

          await walletState.initialize();
          final network = walletState.network;
          final blindbitUrl =
              await SettingsRepository.instance.getBlindbitUrl();
          await chainState.initialize(network, blindbitUrl!);
          chainState.startSyncService(walletState, scanProgress);
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false);
          }
        }
      }
    } catch (e) {
      if (e is InvalidNetworkException) {
        displayNotification("Backup file is for a different network");
      } else {
        displayNotification("restore failed, wrong password?");
      }
    }
  }

  Future<void> onCreateNewWallet(BuildContext context) async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final scanProgress =
        Provider.of<ScanProgressNotifier>(context, listen: false);

    // Get network from flavor
    Network network = Network.getNetworkForFlavor;

    await SettingsRepository.instance.defaultSettings(network);
    final blindbitUrl = network.getDefaultBlindbitUrl();

    await chainState.initialize(network, blindbitUrl);

    await walletState.createNewWallet(chainState);

    chainState.startSyncService(walletState, scanProgress);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false);
    }
  }

  Future<void> onRestoreMnemonic(BuildContext context) async {
    // load bip39 words from asset file
    final String wordsText = await rootBundle.loadString('assets/english.txt');
    final bip39Words = wordsText
        .split('\n')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();

    // go to input seed phrase screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SeedPhraseScreen(
                  bip39Words: bip39Words,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            SizedBox(
              height: Adaptive.h(5),
            ),
            const CircularIcon(
                iconPath: "assets/icons/rocket-large.svg",
                iconHeight: 44,
                radius: 50),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Get started!",
              style: BitcoinTextStyle.title2(Colors.black)
                  .copyWith(height: 1.8, fontFamily: 'Inter'),
            )
          ],
        ),
      ],
    );

    final footer = Column(
      children: [
        if (isDevEnv)
          FooterButtonOutlined(
              title: 'Restore (file backup)',
              onPressed: () => onRestoreFile(context)),
        const SizedBox(
          height: 15,
        ),
        FooterButtonOutlined(
            title: 'Restore', onPressed: () => onRestoreMnemonic(context)),
        const SizedBox(
          height: 15,
        ),
        FooterButton(
            title: 'Create new wallet',
            onPressed: () => onCreateNewWallet(context)),
      ],
    );
    return OnboardingSkeleton(body: body, footer: footer);
  }
}
