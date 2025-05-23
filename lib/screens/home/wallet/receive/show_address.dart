import 'package:barcode_widget/barcode_widget.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

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
            Text("Your receive address for Oslo Freedom Forum!",
                style: BitcoinTextStyle.title4(Bitcoin.neutral8)),
            const SizedBox(
              height: 20,
            ),
            Text(
                "This is your receive address for Oslo Freedom Forum.\n\nWhen you receive payments to this address, the app will detect them as payments related to Oslo Freedom Forum.",
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

    final insetTop = Adaptive.h(10);
    final insetBottom = Adaptive.h(4.7);
    final insetHorizontal = Adaptive.w(6.1);

    return Scaffold(
        body: Padding(
            padding: EdgeInsets.fromLTRB(
                insetHorizontal, insetTop, insetHorizontal, insetBottom),
            child: Column(
              children: [
                Expanded(child: body),
                footer,
              ],
            )));
  }
}
