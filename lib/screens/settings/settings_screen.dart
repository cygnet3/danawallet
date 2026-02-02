import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/settings/network_settings_screen.dart';
import 'package:danawallet/screens/settings/personalisation_settings_screen.dart';
import 'package:danawallet/screens/settings/settings_list_tile.dart';
import 'package:danawallet/screens/settings/settings_skeleton.dart';
import 'package:danawallet/screens/settings/wallet_settings_screen.dart';
import 'package:flutter/material.dart';

const String pageTitle = "Settings";
const String networkSettingsTitle = "Network settings";
const String networkSettingsSubtitle = "Scanning, data usage, chain selection";
const String walletSettingsTitle = "Wallet settings";
const String walletSettingsSubtitle = "Backup, restore or wipe wallet";
const String personalizationSettingsTitle = "Personalization settings";
const String personalizationSettingsSubtitle =
    "Set language, bitcoin unit, fiat currency & theme";

const IconData networkSettingsIcon = Icons.dns_outlined;
const IconData walletSettingsIcon = Icons.account_balance_wallet_outlined;
const IconData personalizationSettingsIcon = Icons.tune;

const Widget networkSettingScreen = NetworkSettingsScreen();
const Widget walletSettingsScreen = WalletSettingsScreen();
const Widget personalizationSettingsScreen = PersonalisationSettingsScreen();

/// Main settings screen showing all setting categories
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _onBuildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Text(
              'Dana wallet v$appVersion beta',
              style: TextStyle(
                fontSize: 14,
                color: Bitcoin.neutral5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Copyright (c) 2023 cygnet',
              style: TextStyle(
                fontSize: 14,
                color: Bitcoin.neutral5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsTiles = [
      SettingsListTile(
        icon: networkSettingsIcon,
        title: networkSettingsTitle,
        subtitle: networkSettingsSubtitle,
        onTap: () => goToScreen(context, networkSettingScreen),
      ),
      SettingsListTile(
        icon: walletSettingsIcon,
        title: walletSettingsTitle,
        subtitle: walletSettingsSubtitle,
        onTap: () => goToScreen(context, walletSettingsScreen),
      ),
      SettingsListTile(
        icon: personalizationSettingsIcon,
        title: personalizationSettingsTitle,
        subtitle: personalizationSettingsSubtitle,
        onTap: () => goToScreen(context, personalizationSettingsScreen),
      )
    ];

    return SettingsSkeleton(
      showBackButton: false,
      title: pageTitle,
      body: ListView.separated(
        itemCount: settingsTiles.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Bitcoin.neutral3,
          indent: 56,
        ),
        itemBuilder: (context, index) => settingsTiles[index],
      ),
      footer: _onBuildFooter(),
    );
  }
}
