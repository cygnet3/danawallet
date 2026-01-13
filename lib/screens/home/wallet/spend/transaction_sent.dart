import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/repositories/contacts_repository.dart';
import 'package:danawallet/screens/home/contacts/add_contact_sheet.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionSentScreen extends StatefulWidget {
  final String txid;
  final Network network;

  const TransactionSentScreen({
    super.key,
    required this.txid,
    required this.network,
  });

  @override
  State<TransactionSentScreen> createState() => _TransactionSentScreenState();
}

class _TransactionSentScreenState extends State<TransactionSentScreen> {
  bool? _isRecipientInContacts;
  bool _isCheckingContacts = true;

  @override
  void initState() {
    super.initState();
    _checkIfRecipientInContacts();
  }

  Future<void> _checkIfRecipientInContacts() async {
    final form = RecipientForm();
    bool isInContacts = false;

    // Check by dana address if available
    if (form.recipientBip353 != null && form.recipientBip353!.isNotEmpty) {
      final contact = await ContactsRepository.instance
          .getContactByDanaAddress(form.recipientBip353!);
      if (contact != null) {
        isInContacts = true;
      }
    }

    // Check by SP address if not found and SP address is available
    if (!isInContacts &&
        form.recipientAddress != null &&
        form.recipientAddress!.isNotEmpty) {
      final contact = await ContactsRepository.instance
          .getContactBySpAddress(form.recipientAddress!);
      if (contact != null) {
        isInContacts = true;
      }
    }

    if (mounted) {
      setState(() {
        _isRecipientInContacts = isInContacts;
        _isCheckingContacts = false;
      });
    }
  }

  Future<void> _openAddContactSheet() async {
    final form = RecipientForm();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddContactSheet(
        initialDanaAddress: form.recipientBip353,
        initialSpAddress: form.recipientAddress,
      ),
    );

    if (result == true && mounted) {
      // Recheck if contact was added
      await _checkIfRecipientInContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    String estimatedTime = RecipientForm().selectedFee!.toEstimatedTime;

    return SpendSkeleton(
      showBackButton: false,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            CircleAvatar(
              backgroundColor: Bitcoin.green,
              radius: 30, // Adjust size as needed
              child: Image(
                image: const AssetImage("icons/2.0x/share.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.white,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text(
              "Transaction sent",
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Text(
              "Your transfer should be completed in $estimatedTime.",
              textAlign: TextAlign.center,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7),
            ),
          ]),
      footer: Column(
        children: [
          if (widget.network != Network.regtest)
            FooterButtonOutlined(
              title: 'View in block explorer',
              onPressed: () async {
                try {
                  String baseUrl;
                  switch (widget.network) {
                    case Network.mainnet:
                      baseUrl = 'https://mempool.space';
                      break;
                    case Network.testnet:
                      baseUrl = 'https://mempool.space/testnet';
                      break;
                    case Network.signet:
                      baseUrl = 'https://mempool.space/signet';
                      break;
                    case Network.regtest:
                      return; // Should not reach here due to if condition
                  }
                  final url = Uri.parse('$baseUrl/tx/${widget.txid}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open block explorer'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to open block explorer: $e'),
                      ),
                    );
                  }
                }
              },
            ),
          if (widget.network != Network.regtest)
            const SizedBox(
              height: 10.0,
            ),
          if (!_isCheckingContacts && _isRecipientInContacts == false)
            FooterButtonOutlined(
              title: 'Add to contact',
              onPressed: _openAddContactSheet,
            ),
          if (!_isCheckingContacts && _isRecipientInContacts == false)
            const SizedBox(
              height: 10.0,
            ),
          FooterButton(
              title: 'Done',
              onPressed: () {
                Navigator.pop(context);
              })
        ],
      ),
    );
  }
}
