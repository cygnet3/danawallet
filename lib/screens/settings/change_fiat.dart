import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';

class ChangeFiatScreen extends StatefulWidget {
  final FiatCurrency currentCurrency;
  final ValueSetter<FiatCurrency> onConfirm;

  const ChangeFiatScreen(
      {super.key, required this.currentCurrency, required this.onConfirm});

  @override
  State<StatefulWidget> createState() => ChangeFiatScreenState();
}

class ChangeFiatScreenState extends State<ChangeFiatScreen> {
  FiatCurrency? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      itemCount: FiatCurrency.values.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(
          FiatCurrency.values[index].displayName(),
          style: BitcoinTextStyle.body3(Bitcoin.black),
        ),
        leading: Radio<FiatCurrency>(
          groupValue: _selected,
          value: FiatCurrency.values[index],
          onChanged: (FiatCurrency? value) {
            setState(() {
              _selected = value;
            });
          },
        ),
        onTap: () {
          setState(() {
            _selected = FiatCurrency.values[index];
          });
        },
      ),
    );

    final footer = FooterButton(
        title: "Confirm", onPressed: () => widget.onConfirm(_selected!));

    return SpendSkeleton(
        title: "Choose fiat currency",
        body: body,
        showBackButton: true,
        footer: footer);
  }
}
