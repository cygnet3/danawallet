import 'package:barcode_widget/barcode_widget.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShowAddressScreen extends StatefulWidget {
  final String address;

  const ShowAddressScreen({super.key, required this.address});

  @override
  State<ShowAddressScreen> createState() => ShowAddressScreenState();
}

class ShowAddressScreenState extends State<ShowAddressScreen> {
  bool toggleQr = false;

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.address));
  }

  void shareAddress() async {
    await SharePlus.instance.share(ShareParams(text: widget.address));
  }

  @override
  Widget build(BuildContext context) {
    final address = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "tap to copy",
          style: BitcoinTextStyle.body5(Bitcoin.neutral5)
              .copyWith(fontFamily: "Inter"),
        ),
        addressAsRichText(widget.address, 18)
      ],
    );

    final qrCode =
        BarcodeWidget(data: widget.address, barcode: Barcode.qrCode());

    final body = Column(
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your receive address",
                style: BitcoinTextStyle.title4(Bitcoin.neutral8)),
            const SizedBox(
              height: 20,
            ),
            Text("You can share this address on your social media.",
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
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        )
      ],
    );

    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.fromLTRB(25, 060, 25, 45),
            child: Column(
              children: [
                Expanded(child: body),
                footer,
              ],
            )));
  }
}
