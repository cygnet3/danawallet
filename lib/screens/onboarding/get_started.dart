import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/services/backup_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

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
      displayNotification("restore failed, wrong password?");
    }
  }

  Future<void> onCreateNewWallet(BuildContext context) async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final scanProgress =
        Provider.of<ScanProgressNotifier>(context, listen: false);

    // always regtest for now
    Network selectedNetwork = Network.regtest;

    await SettingsRepository.instance.defaultSettings(selectedNetwork);
    final blindbitUrl = selectedNetwork.getDefaultBlindbitUrl();

    await chainState.initialize(selectedNetwork, blindbitUrl);

    await walletState.createNewWallet(chainState);

    chainState.startSyncService(walletState, scanProgress);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false);
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
                iconPath: "assets/icons/rocket.svg",
                iconHeight: 44,
                radius: 50),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Get started!",
              style: BitcoinTextStyle.title2(Colors.black)
                  .copyWith(height: 1.8, fontFamily: 'Inter'),
            ),
            const SizedBox(
              height: 10,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                    text:
                        "To learn more about our privacy-preserving addresses,",
                    style: BitcoinTextStyle.body3(Bitcoin.neutral7).copyWith(
                      fontFamily: 'Inter',
                    )),
                TextSpan(
                  text: ' Click here',
                  style: BitcoinTextStyle.body3(Colors.blue).copyWith(
                    fontFamily: 'Inter',
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrlString(
                        'https://silentpayments.xyz/docs/explained/'),
                ),
              ]),
            )
          ],
        ),
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
            title: 'Create new wallet',
            onPressed: () => onCreateNewWallet(context)),
      ],
    );
    return OnboardingSkeleton(body: body, footer: footer);
  }
}
