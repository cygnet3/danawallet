import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: RichText(
            text: TextSpan(
          children: [
            const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image(
                  image:
                      AssetImage("icons/caret_left.png", package: "bitcoin_ui"),
                )),
            TextSpan(
              text: 'Back',
              style: BitcoinTextStyle.title5(Bitcoin.black)
                  .apply(fontFamily: 'Space Grotesk'),
            ),
          ],
        )),
      ),
    );
  }
}
