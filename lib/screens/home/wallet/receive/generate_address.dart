import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/data/enums/public_address_choice.dart';
import 'package:danawallet/screens/home/wallet/receive/show_address.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/back_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class GenerateAddressScreen extends StatefulWidget {
  const GenerateAddressScreen({super.key});

  @override
  State<GenerateAddressScreen> createState() => GenerateAddressScreenState();
}

class GenerateAddressScreenState extends State<GenerateAddressScreen> {
  PublicAddressChoice? _selectedValue;
  final List<PublicAddressChoice> choices = [
    PublicAddressChoice.hrf,
  ];

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context, listen: false);

    final footer = Column(
      children: [
        if (_selectedValue != null && _selectedValue != PublicAddressChoice.hrf)
          Text("please pick 'Oslo Freedom Forum' for this Demo",
              style: BitcoinTextStyle.body4(Colors.red)),
        FooterButton(
            enabled: _selectedValue == PublicAddressChoice.hrf,
            title: 'Create',
            onPressed: () {
              walletState.setAddressCreated();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ShowAddressScreen(address: walletState.address)));
            }),
      ],
    );

    final body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create a new Deposit Account',
              textAlign: TextAlign.center,
              style: BitcoinTextStyle.title4(Bitcoin.neutral8)),
          const SizedBox(
            height: 20,
          ),
          Text('What will you be using this new account for?',
              style: BitcoinTextStyle.body3(Bitcoin.neutral8)
                  .copyWith(fontFamily: 'Inter')),
          const SizedBox(
            height: 20,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2<PublicAddressChoice>(
              isExpanded: true,
              hint: Text(
                'Select Item',
                style: BitcoinTextStyle.body3(Bitcoin.neutral5)
                    .copyWith(fontFamily: 'Inter'),
              ),
              items: choices
                  .map((PublicAddressChoice choice) =>
                      DropdownMenuItem<PublicAddressChoice>(
                          value: choice,
                          child: Text.rich(TextSpan(children: [
                            WidgetSpan(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: choice.icon))),
                            TextSpan(
                                text: choice.toName,
                                style: BitcoinTextStyle.body3(Colors.black)
                                    .copyWith(fontFamily: 'Inter')),
                          ]))))
                  .toList(),
              value: _selectedValue,
              onChanged: (PublicAddressChoice? value) {
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

    final insetTop = Adaptive.h(2.1);
    final insetBottom = Adaptive.h(4.7);
    final insetHorizontal = Adaptive.w(6.1);

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const BackButtonWidget(),
        ),
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
