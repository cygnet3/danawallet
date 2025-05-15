import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShowAddressScreen extends StatelessWidget {
  final String address;

  const ShowAddressScreen({super.key, required this.address});

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: address));
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text("Your public address for Oslo Freedom Forum!",
                style: BitcoinTextStyle.title4(Bitcoin.neutral8)),
                const SizedBox(height: 20,),
            Text(
                "This is your public address for Oslo Freedom Forum.\n\nWhen you receive payments to this address, the app will detect them as payments related to Oslo Freedom Forum.",
                style: BitcoinTextStyle.body3(Bitcoin.neutral8)),
          ],
        ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "tap to copy",
                      style: BitcoinTextStyle.body5(Bitcoin.neutral5)
                          .copyWith(fontFamily: "Inter"),
                    ),
                    addressAsRichText(address, 18),
                  ],
                )),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );

    final footer = Column(
      children: [
        FooterButtonOutlined(title: "Show QR code", onPressed: () => ()),
        const SizedBox(
          height: 15,
        ),
        Row(
          children: [
            Flexible(
                child:
                    FooterButtonOutlined(title: "Share", onPressed: () => ())),
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
