import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';

class ChangeBitcoinUnitScreen extends StatefulWidget {
  final BitcoinUnit currentUnit;
  final ValueSetter<BitcoinUnit> onConfirm;

  const ChangeBitcoinUnitScreen(
      {super.key, required this.currentUnit, required this.onConfirm});

  @override
  State<StatefulWidget> createState() => ChangeBitcoinUnitScreenState();
}

class ChangeBitcoinUnitScreenState extends State<ChangeBitcoinUnitScreen> {
  BitcoinUnit? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUnit;
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      itemCount: BitcoinUnit.values.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(
          BitcoinUnit.values[index].displayName(),
          style: BitcoinTextStyle.body3(Bitcoin.black),
        ),
        leading: Radio<BitcoinUnit>(
          groupValue: _selected,
          value: BitcoinUnit.values[index],
          onChanged: (BitcoinUnit? value) {
            setState(() {
              _selected = value;
            });
          },
        ),
        onTap: () {
          setState(() {
            _selected = BitcoinUnit.values[index];
          });
        },
      ),
    );

    final footer = FooterButton(
        title: "Confirm", onPressed: () => widget.onConfirm(_selected!));

    return SpendSkeleton(
        title: "Choose Bitcoin unit",
        body: body,
        showBackButton: true,
        footer: footer);
  }
}
