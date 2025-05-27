import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:danawallet/screens/home/wallet/receive/show_address.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletScreenAddressCreated extends StatelessWidget {
  const WalletScreenAddressCreated({super.key});

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: false);

    final txHistory = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('No transactions yet.',
            textAlign: TextAlign.center,
            style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                .copyWith(fontFamily: 'Inter')),
      ],
    );

    final footerButton = FooterButton(
      title: 'Show address',
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ShowAddressScreen(address: walletState.address))),
      prefixImage: const AssetImage("icons/receive.png", package: "bitcoin_ui"),
    );

    // final footerButton = BitcoinButtonFilled(
    //   tintColor: danaBlue,
    //   body: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    //     Padding(
    //         padding: const EdgeInsets.only(right: 10.0),
    //         child: Image(
    //           image:
    //               const AssetImage("icons/receive.png", package: "bitcoin_ui"),
    //           color: Bitcoin.white,
    //         )),
    //     Text(
    //       'Show address',
    //       style: BitcoinTextStyle.body3(Bitcoin.white),
    //     ),
    //   ]),
    //   cornerRadius: 6,
    //   onPressed: () => Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //           builder: (context) =>
    //               ShowAddressScreen(address: walletState.address))),
    // );

    return WalletSkeleton(
      callToActionWidget: null,
      txHistory: txHistory,
      footerButtons: footerButton,
    );
  }
}
