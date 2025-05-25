import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';

class AddFundsWidget extends StatelessWidget {
  final void Function() onTap;

  const AddFundsWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Container(
            height: 70,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xff0A6DD6),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
                child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const CircularIcon(
                radius: 20,
                iconPath: "assets/icons/wallet.svg",
              ),
              title: Text('Set up your first address!',
                  style: BitcoinTextStyle.body4(Bitcoin.neutral8)),
              trailing: Image(
                image: const AssetImage("icons/caret_right.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.neutral7,
              ),
            ))));
  }
}
