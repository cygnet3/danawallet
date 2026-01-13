import 'dart:io';

import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/main.dart';
import 'package:danawallet/repositories/contacts_repository.dart';
import 'package:danawallet/repositories/database_helper.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/onboarding/dana_address_setup.dart';
import 'package:danawallet/screens/onboarding/introduction.dart';
import 'package:danawallet/services/contacts_service.dart';
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
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await LoggingService.create();

  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize contacts database
  await DatabaseHelper.instance.database;
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

    if (await walletState.checkDanaAddressRegistrationNeeded()) {
      landingPage = const DanaAddressSetupScreen();
    } else {
      // We have a dana address, ensure user contact exists
      if (walletState.danaAddress != null) {
        try {
          final existingContact = await ContactsRepository.instance
              .getContactByDanaAddress(walletState.danaAddress!);
          if (existingContact == null) {
            await ContactsService.instance.addContactByDanaAddress(
              danaAddress: walletState.danaAddress!,
              network: walletState.network,
              nym: 'you',
            );
            Logger().i('Created user contact in database');
          }
        } catch (e) {
          // Contact might already exist or network error - safe to ignore
          Logger().w('Failed to create user contact: $e');
        }
      }
      landingPage = const PinGuard();
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
