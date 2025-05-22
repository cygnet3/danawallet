import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class FooterButton extends StatelessWidget {
  final String title;
  final AssetImage? prefixImage;
  final VoidCallback? onPressed;
  final bool isLoading;

  const FooterButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.prefixImage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return BitcoinButtonFilled(
      body: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (prefixImage != null)
          Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Image(
                image: prefixImage!,
                color: Bitcoin.white,
              )),
        Text(
          title,
          style: BitcoinTextStyle.body2(Bitcoin.white),
        ),
      ]),
      onPressed: onPressed,
      cornerRadius: 5.0,
      tintColor: const Color.fromARGB(255, 10, 109, 214),
      isLoading: isLoading,
    );
  }
}
