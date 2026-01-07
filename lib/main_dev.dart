import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/main.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/onboarding/dana_address_setup.dart';
import 'package:danawallet/screens/onboarding/introduction.dart';
import 'package:danawallet/services/dana_address_service.dart';
import 'package:danawallet/services/logging_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/pin_guard.dart';
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

  Widget landingPage;
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

    if (await walletState.tryLoadingDanaAddress()) {
      // succeeded in loading address, go to home page
      landingPage = const PinGuard();
    } else {
      final suggestedUsername = await walletState.createSuggestedUsername();
      final danaAddressDomain = await DanaAddressService().danaAddressDomain;

      landingPage = DanaAddressSetupScreen(
          suggestedUsername: suggestedUsername, domain: danaAddressDomain);
    }
  } else {
    // no wallet is loaded, so we go to the introduction screen
    landingPage = const IntroductionScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: scanNotifier),
        ChangeNotifierProvider.value(value: chainState),
        ChangeNotifierProvider.value(value: HomeState()),
        ChangeNotifierProvider.value(value: fiatExchangeRate),
      ],
      child: SilentPaymentApp(landingPage: landingPage),
    ),
  );
}
