import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';

enum ServiceStatus { available, unavailable, unknown }

class ExternalService {
  final String name;
  final String description;
  final ServiceStatus status;

  const ExternalService({
    required this.name,
    required this.description,
    required this.status,
  });
}

class ConnectionStatusService extends ChangeNotifier {
  /// Get the overall connection status
  static ServiceStatus getOverallStatus(
    ChainState chainState,
    FiatExchangeRateState fiatState,
    WalletState walletState,
  ) {
    final services = getAllServices(chainState, fiatState, walletState);

    // If any service is unavailable, show warning
    if (services
        .any((service) => service.status == ServiceStatus.unavailable)) {
      return ServiceStatus.unavailable;
    }

    // If all services are available, show success
    if (services
        .every((service) => service.status == ServiceStatus.available)) {
      return ServiceStatus.available;
    }

    // Otherwise, show unknown
    return ServiceStatus.unknown;
  }

  /// Get status message for the indicator
  static String getStatusMessage(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return 'Network available';
      case ServiceStatus.unavailable:
        return 'Network issues';
      case ServiceStatus.unknown:
        return 'Network status unknown';
    }
  }

  /// Get all external services with their current status
  static List<ExternalService> getAllServices(
    ChainState chainState,
    FiatExchangeRateState fiatState,
    WalletState walletState,
  ) {
    return [
      ExternalService(
        name: 'Blindbit Sync',
        description: 'Block scanning and chain synchronization',
        status: chainState.available
            ? ServiceStatus.available
            : ServiceStatus.unavailable,
      ),
      ExternalService(
        name: 'Exchange Rates',
        description: 'Fiat currency conversion rates',
        status: fiatState.exchangeRate != null
            ? ServiceStatus.available
            : ServiceStatus.unavailable,
      ),
      ExternalService(
        name: 'Fee Estimation',
        description: 'Recommended bitcoin network transaction fees',
        status: walletState.currentFeesEstimation != null
            ? ServiceStatus.available
            : ServiceStatus.unavailable,
      ),
    ];
  }
}
