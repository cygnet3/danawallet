import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

enum FeeRate { fast, normal, slow, custom }

class FeeSelector extends StatefulWidget {
  const FeeSelector({super.key});

  @override
  State<FeeSelector> createState() {
    return FeeSelectorState();
  }
}

class FeeSelectorState extends State<FeeSelector> {
  FeeRate? _feerate = FeeRate.normal;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        title: Row(
          children: [
            Text(
              'Fast',
              style: BitcoinTextStyle.body3(Bitcoin.black),
            ),
            const Spacer(),
            Text('10-30 minutes', style: BitcoinTextStyle.body3(Bitcoin.black)),
          ],
        ),
        subtitle: Row(
          children: [
            Text('~7000 sats', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
            const Spacer(),
            Text('~0.70 €', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
          ],
        ),
        leading: Radio<FeeRate>(
          groupValue: _feerate,
          value: FeeRate.fast,
          onChanged: (FeeRate? value) {
            setState(() {
              _feerate = value;
            });
          },
        ),
      ),
      const Divider(),
      ListTile(
        title: Row(
          children: [
            Text(
              'Normal',
              style: BitcoinTextStyle.body3(Bitcoin.black),
            ),
            const Spacer(),
            Text('30-60 minutes', style: BitcoinTextStyle.body3(Bitcoin.black)),
          ],
        ),
        subtitle: Row(
          children: [
            Text('~3000 sats', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
            const Spacer(),
            Text('~0.30 €', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
          ],
        ),
        leading: Radio<FeeRate>(
          groupValue: _feerate,
          value: FeeRate.normal,
          onChanged: (FeeRate? value) {
            setState(() {
              _feerate = value;
            });
          },
        ),
      ),
      const Divider(),
      ListTile(
        title: Row(
          children: [
            Text(
              'Slow',
              style: BitcoinTextStyle.body3(Bitcoin.black),
            ),
            const Spacer(),
            Text('1+ hour', style: BitcoinTextStyle.body3(Bitcoin.black)),
          ],
        ),
        subtitle: Row(
          children: [
            Text('~1000 sats', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
            const Spacer(),
            Text('~0.20 €', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
          ],
        ),
        leading: Radio<FeeRate>(
          groupValue: _feerate,
          value: FeeRate.slow,
          onChanged: (FeeRate? value) {
            setState(() {
              _feerate = value;
            });
          },
        ),
      ),
      const Divider(),
      ListTile(
        title: Text(
          'Custom',
          style: BitcoinTextStyle.body3(Bitcoin.black),
        ),
        leading: Radio<FeeRate>(
          groupValue: _feerate,
          value: FeeRate.custom,
          onChanged: (FeeRate? value) {
            setState(() {
              _feerate = value;
            });
          },
        ),
        trailing: const Image(
          image: AssetImage("icons/caret_right.png", package: "bitcoin_ui"),
        ),
      ),
      const Divider(),
    ]);
  }
}
