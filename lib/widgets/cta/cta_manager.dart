import 'package:danawallet/data/models/cta_item.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/widgets/cta/cta_carousel.dart';
import 'package:danawallet/widgets/cta/cta_state_manager.dart';
import 'package:danawallet/widgets/cta/cta_tile.dart';
import 'package:danawallet/widgets/cta/dialogs/alias_creation_dialog.dart';
import 'package:danawallet/widgets/cta/dialogs/wallet_backup_dialog.dart';
import 'package:flutter/material.dart';

/// CTA Manager - manages which CTAs to show
class CtaManager extends StatefulWidget {
  const CtaManager({super.key});

  @override
  State<CtaManager> createState() => _CtaManagerState();
}

class _CtaManagerState extends State<CtaManager> {
  Set<String> _completedCtas = {};
  Set<String> _dismissedCtas = {};
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final completedCtas = await CtaStateManager.getCompletedCtas();
    final dismissedCtas = await CtaStateManager.getDismissedCtas();
    
    setState(() {
      _completedCtas = completedCtas;
      _dismissedCtas = dismissedCtas;
      _isLoaded = true;
    });
  }

  Future<void> _saveState() async {
    await CtaStateManager.setCompletedCtas(_completedCtas);
    await CtaStateManager.setDismissedCtas(_dismissedCtas);
  }

  Future<List<CtaItem>> _getAvailableCtas() async {
    final List<CtaItem> allCtas = [
      CtaItem(
        id: 'address_creation',
        title: 'Create Your Address',
        icon: Icons.email_outlined,
        color: const Color(0xFF007AFF),
        dialogBuilder: (context, onComplete) =>
            AliasCreationDialog(onComplete: onComplete),
      ),
      CtaItem(
        id: 'wallet_backup',
        title: 'Backup Your Wallet',
        icon: Icons.backup_outlined,
        color: const Color(0xFFFF9500),
        dialogBuilder: (context, onComplete) =>
            WalletBackupDialog(onComplete: onComplete),
      ),
    ];

    // Filter out address creation if user already has an alias
    final existingAlias = await SettingsRepository.instance.getUserAlias();
    if (existingAlias != null) {
      allCtas.removeWhere((cta) => cta.id == 'address_creation');
    }

    return allCtas.where((cta) =>
        !_completedCtas.contains(cta.id) &&
        !_dismissedCtas.contains(cta.id)
    ).toList();
  }

  void _onDismiss(String ctaId) {
    setState(() {
      _dismissedCtas.add(ctaId);
    });
    _saveState();
  }

  void _onComplete(String ctaId) {
    setState(() {
      _completedCtas.add(ctaId);
    });
    _saveState();
  }

  void _showDialog(CtaItem cta) {
    showDialog(
      context: context,
      builder: (context) => cta.dialogBuilder(
        context,
        () => _onComplete(cta.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<CtaItem>>(
      future: _getAvailableCtas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final ctas = snapshot.data!;
        
        if (ctas.isEmpty) {
          return const SizedBox.shrink();
        }

        if (ctas.length == 1) {
          final cta = ctas.first;
          return CtaTile(
            title: cta.title,
            icon: cta.icon,
            color: cta.color,
            onTap: () => _showDialog(cta),
            onDismiss: cta.isDismissible ? () => _onDismiss(cta.id) : null,
          );
        }

        return CtaCarousel(
          ctas: ctas.map((cta) => CtaTile(
            title: cta.title,
            icon: cta.icon,
            color: cta.color,
            onTap: () => _showDialog(cta),
            onDismiss: cta.isDismissible ? () => _onDismiss(cta.id) : null,
          )).toList(),
        );
      },
    );
  }
}

