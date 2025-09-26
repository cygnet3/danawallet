import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/services/connection_status_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';

class ServiceStatusDialog extends StatelessWidget {
  final ChainState chainState;
  final FiatExchangeRateState fiatState;
  final WalletState walletState;

  const ServiceStatusDialog({
    super.key,
    required this.chainState,
    required this.fiatState,
    required this.walletState,
  });

  @override
  Widget build(BuildContext context) {
    final services = ConnectionStatusService.getAllServices(chainState, fiatState, walletState);
    final overallStatus = ConnectionStatusService.getOverallStatus(chainState, fiatState, walletState);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getStatusIcon(overallStatus),
            color: _getStatusColor(overallStatus),
            size: 20,
          ),
          const SizedBox(width: 8),
            Text(
              'Service Status',
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'External services status:',
              style: BitcoinTextStyle.body2(Bitcoin.neutral7),
            ),
            const SizedBox(height: 16),
            ...services.map((service) => _buildServiceItem(service)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: BitcoinTextStyle.body2(Bitcoin.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(ExternalService service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getServiceIcon(service.status),
            color: _getServiceColor(service.status),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: BitcoinTextStyle.body3(Bitcoin.black),
                ),
                const SizedBox(height: 2),
                Text(
                  service.description,
                  style: BitcoinTextStyle.body5(Bitcoin.neutral6),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(service.status),
                  style: BitcoinTextStyle.body5(_getServiceColor(service.status)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  IconData _getServiceIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Icons.check_circle_outline;
      case ServiceStatus.unavailable:
        return Icons.error_outline;
      case ServiceStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Bitcoin.green;
      case ServiceStatus.unavailable:
        return Bitcoin.orange;
      case ServiceStatus.unknown:
        return Bitcoin.neutral6;
    }
  }

  Color _getServiceColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return Bitcoin.green;
      case ServiceStatus.unavailable:
        return Bitcoin.orange;
      case ServiceStatus.unknown:
        return Bitcoin.neutral6;
    }
  }

  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return 'Available';
      case ServiceStatus.unavailable:
        return 'Unavailable';
      case ServiceStatus.unknown:
        return 'Unknown';
    }
  }
}