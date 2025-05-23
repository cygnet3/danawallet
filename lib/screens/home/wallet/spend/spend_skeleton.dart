import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/back_button.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SpendSkeleton extends StatelessWidget {
  final bool showBackButton;
  final String? title;
  final Widget body;
  final Widget? footer;
  const SpendSkeleton(
      {super.key,
      this.title,
      required this.body,
      this.footer,
      required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    final padding = Adaptive.h(2.4);
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: showBackButton ? const BackButtonWidget() : null,
        ),
        body: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                if (title != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title!,
                        style: BitcoinTextStyle.title4(Bitcoin.black)),
                  ),
                Expanded(child: body),
                if (footer != null) footer!,
              ],
            )));
  }
}
