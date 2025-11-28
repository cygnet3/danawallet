import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/main.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/repositories/name_server_repository.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/services/logging_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await LoggingService.create();
  final walletState = await WalletState.create();
  final scanNotifier = await ScanProgressNotifier.create();
  final chainState = ChainState();
  final fiatExchangeRate = await FiatExchangeRateState.create();

  // Try to update exchange rate, but don't crash if it fails
  try {
    await fiatExchangeRate.updateExchangeRate();
  } catch (e) {
    Logger().w('Failed to update exchange rate during startup: $e');
    // Continue with no data - UI will handle it
  }

  await precacheImages();

  final bool walletLoaded;
  try {
    walletLoaded = await walletState.initialize();
  } catch (e) {
    // todo: show an error screen when wallet is present but fails to load
    rethrow;
  }

  // if a blindbit url is given, override the saved url
  const blindbitUrl = String.fromEnvironment("BLINDBIT_URL");
  if (blindbitUrl != '') {
    await SettingsRepository.instance.setBlindbitUrl(blindbitUrl);
  }

  if (walletLoaded) {
    final network = walletState.network;
    final blindbitUrl = await SettingsRepository.instance.getBlindbitUrl() ??
        network.defaultBlindbitUrl;

    chainState.initialize(network);

    // Continue without chain sync - wallet still usable for local operations
    final connected = await chainState.connect(blindbitUrl);
    if (!connected) {
      Logger().w("Failed to connect");
    }

    chainState.startSyncService(walletState, scanNotifier, true);
  }

  // Create NameServerRepository instance
  final nameServerRepository = NameServerRepository(baseUrl: defaultNameServer, domain: defaultDomain, apiVersion: nameServerApiVersion);
 
  // Load the dana address from storage if it exists
  bool danaAddressCreated = false;
  String? suggestedUsername;
  if (walletLoaded) {
    final storedDanaAddress = await SettingsRepository.instance.getDanaAddress();
    if (storedDanaAddress != null) {
      nameServerRepository.userDanaAddress = storedDanaAddress;
      Logger().i('Loaded dana address from storage: $storedDanaAddress');
      danaAddressCreated = true;
    } else {
      // Wallet exists but no dana address - lookup dana addresses
      final danaAddresses = await nameServerRepository.lookupDanaAddresses(walletState.address);
      if (danaAddresses.isNotEmpty) {
        nameServerRepository.userDanaAddress = danaAddresses.first; // use the first dana address found
        Logger().i('Loaded dana address from lookup: ${nameServerRepository.userDanaAddress}'); // log the first dana address found
        danaAddressCreated = true;
      } else {
        // Wallet exists but no dana address - generate a suggested username
        try {
          suggestedUsername = await walletState.generateAvailableDanaAddress(
            nameServerRepository: nameServerRepository,
            maxRetries: 5,
          );
        } catch (e) {
          Logger().e('Error generating suggested dana address: $e');
          // Continue without suggested username - user can create their own
        }
      }
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: scanNotifier),
        ChangeNotifierProvider.value(value: chainState),
        ChangeNotifierProvider.value(value: HomeState()),
        ChangeNotifierProvider.value(value: fiatExchangeRate),
        Provider<NameServerRepository>.value(value: nameServerRepository),
      ],
      child: SilentPaymentApp(walletLoaded: walletLoaded, danaAddressCreated: danaAddressCreated, suggestedUsername: suggestedUsername),
    ),
  );
}
