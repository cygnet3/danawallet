import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/screens/onboarding/donation_sources.dart';
import 'package:danawallet/services/backup_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:danawallet/widgets/info_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Future<void> onRestoreWallet(BuildContext context) async {
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
                text:
                    "Start receiving donations within seconds!",
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
        FooterButtonOutlined(
            title: 'Restore', onPressed: () => onRestoreWallet(context)),
        const SizedBox(
          height: 15,
        ),
        FooterButton(
            title: 'Proceed',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const DonationSourcesScreen()))),
      ],
    );

    return OnboardingSkeleton(body: body, footer: footer);
  }
}
