import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';

class InfoWidget extends StatelessWidget {
  final String iconPath;
  final String title;
  final String text;
  final AutoSizeGroup group;

  const InfoWidget(
      {super.key,
      required this.iconPath,
      required this.title,
      required this.text,
      required this.group});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircularIcon(
          radius: 25,
          iconPath: iconPath,
        ),
        const SizedBox(
          width: 20,
        ),
        Flexible(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: BitcoinTextStyle.title4(Bitcoin.black)
                  .copyWith(fontFamily: "Inter", height: 2.0),
            ),
            AutoSizeText(
              text,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7)
                  .copyWith(fontFamily: "Inter"),
              maxLines: 2,
              group: group,
            ),
          ],
        ))
      ],
    );
  }
}
