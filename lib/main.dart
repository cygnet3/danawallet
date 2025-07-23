import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/frb_generated.dart';

import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/onboarding/introduction.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/services/logging_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/home_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await LoggingService.create();
  final walletState = await WalletState.create();
  final scanNotifier = await ScanProgressNotifier.create();
  final chainState = ChainState();

  await precacheImages();

  final bool walletLoaded;
  try {
    walletLoaded = await walletState.initialize();
  } catch (e) {
    // todo: show an error screen when wallet is present but fails to load
    rethrow;
  }

  if (walletLoaded) {
    final network = walletState.network;
    final blindbitUrl = await SettingsRepository.instance.getBlindbitUrl();
    await chainState.initialize(network, blindbitUrl!);
    chainState.startSyncService(walletState, scanNotifier);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletState),
        ChangeNotifierProvider.value(value: scanNotifier),
        ChangeNotifierProvider.value(value: chainState),
        ChangeNotifierProvider.value(value: HomeState()),
      ],
      child: SilentPaymentApp(walletLoaded: walletLoaded),
    ),
  );
}

class SilentPaymentApp extends StatelessWidget {
  final bool walletLoaded;

  const SilentPaymentApp({super.key, required this.walletLoaded});

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'Dana wallet',
        navigatorKey: globalNavigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: danaBlue),
          useMaterial3: true,
          fontFamily: 'Space Grotesk',
        ),
        home: walletLoaded ? const HomeScreen() : const IntroductionScreen(),
      );
    });
  }
}

Future<void> precacheImages() async {
  await precacheSvgPicture("assets/icons/address-book.svg");
  await precacheSvgPicture("assets/icons/boxes.svg");
  await precacheSvgPicture("assets/icons/contact.svg");
  await precacheSvgPicture("assets/icons/hidden.svg");
  await precacheSvgPicture("assets/icons/rocket.svg");
  await precacheSvgPicture("assets/icons/rocket-large.svg");
  await precacheSvgPicture("assets/icons/sparkle.svg");
}

Future precacheSvgPicture(String svgPath) async {
  final logo = SvgAssetLoader(svgPath);
  await svg.cache.putIfAbsent(logo.cacheKey(null), () => logo.loadBytes(null));
}
