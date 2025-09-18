import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/onboarding/choose_network.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/screens/onboarding/recovery/seed_phrase.dart';
import 'package:danawallet/services/backup_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:danawallet/widgets/info_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
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
    Network network;
    // in dev environment, allow user to choose network
    if (isDevEnv) {
      network = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ChooseNetworkScreen()));
    } else {
      // Get network from flavor
      network = Network.getNetworkForFlavor;
    }

    if (!context.mounted) {
      return;
    }

    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final scanProgress =
        Provider.of<ScanProgressNotifier>(context, listen: false);

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
    Network network;
    // in dev environment, allow user to choose network
    if (isDevEnv) {
      network = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ChooseNetworkScreen()));
    } else {
      // Get network from flavor
      network = Network.getNetworkForFlavor;
    }

    if (!context.mounted) {
      return;
    }

    // load bip39 words from asset file
    final String wordsText =
        await rootBundle.loadString('assets/mnemonic/english.txt');
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
                  network: network,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var autoSizeGroup = AutoSizeGroup();
    final body = Column(
      children: [
        Image(
          width: Adaptive.h(14),
          image: const AssetImage(
            "assets/icons/dana_outline.png",
          ),
          color: Bitcoin.black,
        ),
        SizedBox(
          height: Adaptive.h(1),
        ),
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InfoWidget(
                iconPath: "assets/icons/rocket.svg",
                title: "Effortless donations",
                text: "Start receiving donations within seconds!",
                group: autoSizeGroup),
            InfoWidget(
                iconPath: "assets/icons/hidden.svg",
                title: "Privacy by default",
                text:
                    "Bitcoin donations needed servers & intimidating infrastructure. Not anymore!",
                group: autoSizeGroup),
            InfoWidget(
                iconPath: "assets/icons/contact.svg",
                title: "Donation accounts",
                text: "Keep track of your donations easily.",
                group: autoSizeGroup),
            const SizedBox(),
            const SizedBox(),
          ],
        ))
      ],
    );

    final footer = Column(
      children: [
        if (isDevEnv)
          FooterButtonOutlined(
              title: 'Restore (file backup)',
              onPressed: () => onRestoreFile(context)),
        if (isDevEnv)
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
