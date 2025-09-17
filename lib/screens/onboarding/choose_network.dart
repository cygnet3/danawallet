import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';

class ChooseNetworkScreen extends StatefulWidget {
  const ChooseNetworkScreen({super.key});

  @override
  State<StatefulWidget> createState() => ChooseNetworkScreenState();
}

class ChooseNetworkScreenState extends State<ChooseNetworkScreen> {
  final choices = [Network.mainnet, Network.signet, Network.regtest];
  Network? _selected;

  @override
  void initState() {
    super.initState();
    _selected = Network.getNetworkForFlavor;
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      itemCount: choices.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(
          choices[index].toString(),
          style: BitcoinTextStyle.body3(Bitcoin.black),
        ),
        leading: Radio<Network>(
          groupValue: _selected,
          value: choices[index],
          onChanged: (Network? value) {
            setState(() {
              _selected = value;
            });
          },
        ),
        onTap: () {
          setState(() {
            _selected = choices[index];
          });
        },
      ),
    );

    final footer = FooterButton(
        title: "Confirm",
        onPressed: () => Navigator.of(context).pop(_selected));

    return SpendSkeleton(
        title: "Choose network",
        body: body,
        showBackButton: true,
        footer: footer);
  }
}
