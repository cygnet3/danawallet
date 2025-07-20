import 'package:barcode_widget/barcode_widget.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  bool toggleQr = false;
  bool isCreatingWallet = true;
  String? walletAddress;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _createWallet();
  }

  Future<void> _createWallet() async {
    try {
      final walletState = Provider.of<WalletState>(context, listen: false);
      final chainState = Provider.of<ChainState>(context, listen: false);
      final scanProgress =
          Provider.of<ScanProgressNotifier>(context, listen: false);

      // Get network from flavor
      Network network = Network.getNetworkForFlavor;

      await SettingsRepository.instance.defaultSettings(network);
      final blindbitUrl = network.getDefaultBlindbitUrl();

      await chainState.initialize(network, blindbitUrl);

      await walletState.createNewWallet(chainState);

      chainState.startSyncService(walletState, scanProgress);

      if (mounted) {
        setState(() {
          isCreatingWallet = false;
          walletAddress = walletState.address;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCreatingWallet = false;
          errorMessage = "Failed to create wallet: ${e.toString()}";
        });
      }
    }
  }

  Future<void> copyToClipboard() async {
    if (walletAddress != null) {
      await Clipboard.setData(ClipboardData(text: walletAddress!));
    }
  }

  void shareAddress() async {
    if (walletAddress != null) {
      await SharePlus.instance.share(ShareParams(text: walletAddress!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCreatingWallet) {
      return OnboardingSkeleton(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Bitcoin.blue,
            ),
            SizedBox(height: Adaptive.h(3)),
            Text(
              "Creating your wallet...",
              style: BitcoinTextStyle.title4(Colors.black)
                  .copyWith(fontFamily: 'Inter'),
            ),
          ],
        ),
        footer: const SizedBox.shrink(),
      );
    }

    if (errorMessage != null) {
      return OnboardingSkeleton(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error",
              style: BitcoinTextStyle.title4(Bitcoin.red)
                  .copyWith(fontFamily: 'Inter'),
            ),
            SizedBox(height: Adaptive.h(2)),
            Text(
              errorMessage!,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7)
                  .copyWith(fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        footer: FooterButton(
          title: "Try Again",
          onPressed: () {
            setState(() {
              isCreatingWallet = true;
              errorMessage = null;
            });
            _createWallet();
          },
        ),
      );
    }

    if (walletAddress == null) {
      return OnboardingSkeleton(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "No wallet address available",
              style: BitcoinTextStyle.title4(Bitcoin.red)
                  .copyWith(fontFamily: 'Inter'),
            ),
          ],
        ),
        footer: const SizedBox.shrink(),
      );
    }

    final address = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "tap to copy",
          style: BitcoinTextStyle.body5(Bitcoin.neutral5)
              .copyWith(fontFamily: "Inter"),
        ),
        addressAsRichText(walletAddress!, 18)
      ],
    );

    final qrCode =
        BarcodeWidget(data: walletAddress!, barcode: Barcode.qrCode());

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Fund your wallet",
                style: BitcoinTextStyle.title4(Bitcoin.neutral8)),
            const SizedBox(
              height: 20,
            ),
            Text("Get some money on and start giving!",
                style: BitcoinTextStyle.body3(Bitcoin.neutral8)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: copyToClipboard,
          child: Container(
              decoration: ShapeDecoration(
                color: Bitcoin.neutral2,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: toggleQr ? qrCode : address,
              )),
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );

    final footer = Column(
      children: [
        FooterButtonOutlined(
            title: toggleQr ? "Show address" : "Show QR code",
            onPressed: () => setState(() {
                  toggleQr = !toggleQr;
                })),
        const SizedBox(
          height: 15,
        ),
        Row(
          children: [
            Flexible(
                child: FooterButtonOutlined(
                    title: "Share", onPressed: shareAddress)),
            const SizedBox(
              width: 15,
            ),
            Flexible(
                child: FooterButtonOutlined(
                    title: "Copy", onPressed: copyToClipboard)),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        FooterButton(
          title: "Done!",
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false);
          },
        )
      ],
    );

    return OnboardingSkeleton(
      body: body,
      footer: footer,
    );
  }
} 