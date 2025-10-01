import 'package:flutter/material.dart';

/// Simple dialog for wallet backup confirmation
class WalletBackupDialog extends StatelessWidget {
  final VoidCallback onComplete;

  const WalletBackupDialog({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.backup_outlined, color: Color(0xFFFF9500)),
          SizedBox(width: 12),
          Text('Backup Your Wallet'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'It\'s important to backup your wallet to ensure you can recover your funds if you lose access to this device.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6D6D70)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onComplete();
            // TODO: Navigate to backup screen
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFFF9500),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Backup Now'),
        ),
      ],
    );
  }
}

