import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/screens/home/wallet/generate/generate_address.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/add_funds_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletSkeleton extends StatelessWidget {
  final bool showAddFundsWidget;
  final Widget txHistory;
  final Widget? footerButtons;

  const WalletSkeleton(
      {super.key,
      required this.showAddFundsWidget,
      required this.txHistory,
      this.footerButtons});

  AppBar buildAppBar(Network network) {
    return AppBar(
      forceMaterialTransparency: true,
      title: Row(
        children: [
          const Spacer(),
          SizedBox(
              height: 30.0,
              width: 30.0,
              child: Image(
                fit: BoxFit.contain,
                image: const AssetImage("icons/3.0x/bitcoin_circle.png",
                    package: "bitcoin_ui"),
                color: network.toColor,
              )),
        ],
      ),
    );
  }

  Widget buildScanProgress(ScanProgressNotifier scanProgress) {
    final inner = Row(
      children: [
        Text(
            'Scanning: ${(scanProgress.progress * 100.0).toStringAsFixed(0)} %  ',
            style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
        Expanded(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Bitcoin.blue),
                backgroundColor: Bitcoin.neutral4,
                value: scanProgress.progress,
                minHeight: 6.0,
              )),
        ),
        const SizedBox(
          width: 20,
        ),
        Image(
          width: 20.0,
          image: const AssetImage("icons/2.0x/caret_right.png",
              package: "bitcoin_ui"),
          color: Bitcoin.neutral7,
        )
      ],
    );

    return Visibility(
        visible: scanProgress.scanning,
        maintainAnimation: true,
        maintainSize: true,
        maintainState: true,
        child: inner);
  }

  Widget buildAmountDisplay(WalletState walletState, ApiAmount amount, bool hideAmount) {
    String btcAmount = walletState.hideAmount ? '*****' : amount.displayBtc();
    String fiatAmount = walletState.hideAmount ? '*****' : '\$ 0.00';

    return GestureDetector(
      onTap: () => walletState.toggleHideAmount(),
      child: Column(
        children: [
          Text(
            btcAmount,
            style: BitcoinTextStyle.body1(Bitcoin.neutral8).apply(
                fontSizeDelta: 3,
                fontFeatures: [const FontFeature.slashedZero()]),
          ),
          Text(
            fiatAmount,
            style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                .apply(fontFeatures: [const FontFeature.slashedZero()]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);
    final scanProgress = Provider.of<ScanProgressNotifier>(context);

    ApiAmount amount =
        ApiAmount(field0: walletState.amount + walletState.unconfirmedChange);

    return Scaffold(
        appBar: buildAppBar(walletState.network),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    buildScanProgress(scanProgress),
                    const SizedBox(height: 30.0),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildAmountDisplay(walletState, amount, false),
                              showAddFundsWidget
                                  ? AddFundsWidget(
                                      onTap: () => {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const GenerateAddressScreen()),
                                        )
                                      },
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                        Flexible(child: txHistory),
                        if (footerButtons != null) footerButtons!,
                        const SizedBox(
                          height: 20.0,
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
