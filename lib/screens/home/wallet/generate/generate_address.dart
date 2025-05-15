import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/screens/home/wallet/generate/show_address.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/back_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenerateAddressScreen extends StatefulWidget {
  const GenerateAddressScreen({super.key});

  @override
  State<GenerateAddressScreen> createState() => GenerateAddressScreenState();
}

class GenerateAddressScreenState extends State<GenerateAddressScreen> {
  String? _selectedValue;
  final List<String> items = [
    'Twitter/X',
    'Nostr',
    'Your website',
    'Oslo Freedom Forum'
  ];

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: false);

    final footer = FooterButton(
        title: 'Generate public address',
        onPressed: () {
          walletState.setAddressCreated();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ShowAddressScreen(address: walletState.address)));
        });

    final body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get a public address for...',
              textAlign: TextAlign.center,
              style: BitcoinTextStyle.title4(Bitcoin.neutral8)),
          const SizedBox(
            height: 40,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                'Select Item',
                style: BitcoinTextStyle.body3(Bitcoin.neutral5)
                    .copyWith(fontFamily: 'Inter'),
              ),
              items: items
                  .map((String item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item,
                            style: BitcoinTextStyle.body3(Colors.black)
                                .copyWith(fontFamily: 'Inter')),
                      ))
                  .toList(),
              value: _selectedValue,
              onChanged: (String? value) {
                setState(() {
                  _selectedValue = value;
                });
              },
              buttonStyleData: ButtonStyleData(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: danaBlue,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 56,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const BackButtonWidget(),
        ),
        body: Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 45),
            child: Column(
              children: [
                Expanded(child: body),
                footer,
              ],
            )));
  }
}
