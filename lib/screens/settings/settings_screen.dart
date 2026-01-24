import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/screens/settings/network_settings_screen.dart';
import 'package:danawallet/screens/settings/personalisation_settings_screen.dart';
import 'package:danawallet/screens/settings/settings_list_tile.dart';
import 'package:danawallet/screens/settings/settings_skeleton.dart';
import 'package:danawallet/screens/settings/wallet_settings_screen.dart';
import 'package:flutter/material.dart';

/// Main settings screen showing all setting categories
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _onNavigateToNetworkSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NetworkSettingsScreen(),
      ),
    );
  }

  void _onNavigateToWalletSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WalletSettingsScreen(),
      ),
    );
  }

  void _onNavigateToPersonalisationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalisationSettingsScreen(),
      ),
    );
  }

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
    return SettingsSkeleton(
      showBackButton: false,
      title: 'Settings',
      body: ListView.separated(
        itemCount: 3,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Bitcoin.neutral3,
          indent: 56,
        ),
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return SettingsListTile(
                icon: Icons.dns_outlined,
                title: 'Network settings',
                subtitle: 'Scanning, data usage, chain selection',
                onTap: () => _onNavigateToNetworkSettings(context),
              );
            case 1:
              return SettingsListTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallet settings',
                subtitle: 'Backup, restore or wipe wallet',
                onTap: () => _onNavigateToWalletSettings(context),
              );
            case 2:
              return SettingsListTile(
                icon: Icons.tune,
                title: 'Personalisation settings',
                subtitle: 'Set language, bitcoin unit, fiat currency & theme',
                onTap: () => _onNavigateToPersonalisationSettings(context),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      footer: _onBuildFooter(),
    );
  }
}

