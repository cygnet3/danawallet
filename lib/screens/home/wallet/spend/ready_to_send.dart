import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/screens/home/wallet/spend/transaction_sent.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReadyToSendScreen extends StatefulWidget {
  const ReadyToSendScreen({super.key});

  @override
  ReadyToSendScreenState createState() => ReadyToSendScreenState();
}

class ReadyToSendScreenState extends State<ReadyToSendScreen> {
  bool _isSending = false;
  String? _sendErrorText;

  Future<void> onPressSend() async {
    setState(() {
      _isSending = true;
      _sendErrorText = null;
    });

    try {
      final walletState = Provider.of<WalletState>(context, listen: false);
      final unsignedTx = RecipientForm().unsignedTx!;

      await walletState.signAndBroadcastUnsignedTx(unsignedTx);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const TransactionSentScreen()),
            (Route<dynamic> route) => false);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _sendErrorText = exceptionToString(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    RecipientForm recipient = RecipientForm();

    String displayRecipient;
    TextStyle displayRecipientStyle = BitcoinTextStyle.title5(Bitcoin.neutral8);
    if (recipient.recipientBip353 != null) {
      displayRecipient = recipient.recipientBip353!;
    } else {
      final maxWidth = MediaQuery.of(context).size.width * 0.85;

      displayRecipient = displayAddress(
          recipient.recipientAddress!, displayRecipientStyle, maxWidth);
    }

    String displayAmount = recipient.amount!.displaySats();

    String displayArrivalTime = recipient.fee!.toEstimatedTime;

    String displayEstimatedFee =
        recipient.unsignedTx!.getFeeAmount().displaySats();

    return SpendSkeleton(
        showBackButton: true,
        title: 'Ready to send?',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 50.0,
            ),
            Row(
              children: [
                Text(
                  'To',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  displayRecipient,
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Amount',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  displayAmount,
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Arrival time',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  displayArrivalTime,
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Fee',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  displayEstimatedFee,
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
          ],
        ),
        footer: Column(
          children: [
            if (_sendErrorText != null) Text(_sendErrorText!),
            const SizedBox(
              height: 10.0,
            ),
            if (isDevEnv())
              FooterButtonOutlined(title: 'See details', onPressed: () => ()),
            const SizedBox(
              height: 10.0,
            ),
            FooterButton(
              title: 'Send',
              onPressed: onPressSend,
              isLoading: _isSending,
            ),
          ],
        ));
  }
}
