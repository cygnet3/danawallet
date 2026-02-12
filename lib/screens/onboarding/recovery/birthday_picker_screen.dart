import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/back_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Screen for selecting the wallet creation date (birthday).
/// Returns the selected [DateTime] when user confirms, or null if user goes back.
class BirthdayPickerScreen extends StatefulWidget {
  const BirthdayPickerScreen({super.key});

  @override
  State<BirthdayPickerScreen> createState() => _BirthdayPickerScreenState();
}

class _BirthdayPickerScreenState extends State<BirthdayPickerScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Use UTC to avoid timezone issues with calendar dates
    final now = DateTime.now().toUtc();
    _selectedDate = DateTime.utc(now.year, now.month, now.day);
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final title = AutoSizeText(
      "Select wallet birthday",
      style: BitcoinTextStyle.title2(Colors.black)
          .copyWith(height: 1.8, fontFamily: 'Inter'),
      maxLines: 1,
    );

    final text = AutoSizeText(
      "Choose the date when your wallet was created. This will make restoration faster.",
      style: BitcoinTextStyle.body3(Bitcoin.neutral7).copyWith(
        fontFamily: 'Inter',
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const BackButtonWidget(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Adaptive.w(5),
            0,
            Adaptive.w(5),
            Adaptive.h(5),
          ),
          child: Column(
            children: [
              Column(
                children: [
                  title,
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Adaptive.h(3),
                      horizontal: Adaptive.w(2),
                    ),
                    child: text,
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime.utc(2009, 1, 3), // Bitcoin genesis
                    lastDate: DateTime.now().toUtc(),
                    currentDate: DateTime.now().toUtc(),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                ),
              ),
              FooterButton(title: "Continue", onPressed: _onConfirm),
            ],
          ),
        ),
      ),
    );
  }
}
