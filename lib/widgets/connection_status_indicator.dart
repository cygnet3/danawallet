import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/services/connection_status_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/service_status_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChainState, FiatExchangeRateState, WalletState>(
      builder: (context, chainState, fiatState, walletState, child) {
        try {
          final overallStatus = ConnectionStatusService.getOverallStatus(
              chainState, fiatState, walletState);
          final statusMessage =
              ConnectionStatusService.getStatusMessage(overallStatus);

          return GestureDetector(
              onTap: () => _showServiceStatusDialog(
                  context, chainState, fiatState, walletState),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(overallStatus),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getBorderColor(overallStatus),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(overallStatus),
                      color: _getIconColor(overallStatus),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusMessage,
                      style:
                          BitcoinTextStyle.body5(_getTextColor(overallStatus)),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: _getTextColor(overallStatus),
                      size: 12,
                    ),
                  ],
                ),
              ));
        } catch (e) {
          // Fallback UI in case of errors
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Bitcoin.neutral4.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Bitcoin.neutral6.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Bitcoin.neutral6, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Status error',
                  style: BitcoinTextStyle.body5(Bitcoin.neutral6),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Color _getBackgroundColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Bitcoin.green.withOpacity(0.1);
      case ServiceStatus.unavailable:
        return Bitcoin.orange.withOpacity(0.1);
      case ServiceStatus.unknown:
        return Bitcoin.neutral4.withOpacity(0.1);
    }
  }

  Color _getBorderColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Bitcoin.green.withOpacity(0.3);
      case ServiceStatus.unavailable:
        return Bitcoin.orange.withOpacity(0.3);
      case ServiceStatus.unknown:
        return Bitcoin.neutral6.withOpacity(0.3);
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Icons.check_circle;
      case ServiceStatus.unavailable:
        return Icons.warning;
      case ServiceStatus.unknown:
        return Icons.help;
    }
  }

  Color _getIconColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Bitcoin.green;
      case ServiceStatus.unavailable:
        return Bitcoin.orange;
      case ServiceStatus.unknown:
        return Bitcoin.neutral6;
    }
  }

  Color _getTextColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Bitcoin.green;
      case ServiceStatus.unavailable:
        return Bitcoin.orange;
      case ServiceStatus.unknown:
        return Bitcoin.neutral6;
    }
  }

  void _showServiceStatusDialog(
    BuildContext context,
    ChainState chainState,
    FiatExchangeRateState fiatState,
    WalletState walletState,
  ) {
    try {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => ServiceStatusDialog(
          chainState: chainState,
          fiatState: fiatState,
          walletState: walletState,
        ),
      );
    } catch (e) {
      // Silently fail if dialog can't be shown
      debugPrint('Failed to show service status dialog: $e');
    }
  }
}
