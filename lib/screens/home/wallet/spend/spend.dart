import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recommended_fee_model.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/outputs.dart';
import 'package:danawallet/screens/home/wallet/spend/summary_widget.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/spend_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:dart_bip353/dart_bip353.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:danawallet/widgets/qr_code_scanner_widget.dart';

class SpendScreen extends StatefulWidget {
  const SpendScreen({super.key});

  @override
  SpendScreenState createState() => SpendScreenState();
}

class SpendScreenState extends State<SpendScreen> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  RecommendedFeeResponse recommendedFees = RecommendedFeeResponse.empty();
  bool _isSending = false;
  String? _sendErrorText;
  String? _addressErrorText;
  String? _amountErrorText;

  int selectedFeeIndex = 2;

  late final MempoolApiRepository mempoolApiRepository;

  @override
  void initState() {
    super.initState();
    getCurrentFeeRates();
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRCodeScannerWidget(),
      ),
    );
    if (result is String && result != "") {
      setState(() {
        addressController.text = result;
        _addressErrorText = null; // Clear any previous error
      });
    }
  }

  Future<void> getCurrentFeeRates() async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    mempoolApiRepository = MempoolApiRepository(network: walletState.network);
    try {
      final response = await mempoolApiRepository.getCurrentFeeRate();
      setState(() {
        recommendedFees = response;
      });
    } catch (e) {
      setState(() {
        _sendErrorText = 'Failed to load fee rates';
      });
    }
  }

  int getSelectedFee() {
    switch (selectedFeeIndex) {
      case 0:
        return recommendedFees.nextBlockFee;
      case 1:
        return recommendedFees.halfHourFee;
      case 2:
        return recommendedFees.hourFee;
      case 3:
        return recommendedFees.dayFee;
      default:
        return recommendedFees.hourFee;
    }
  }

  Future<void> onSpendButtonPressed(
      WalletState walletState, SpendState spendState) async {
    {
      setState(() {
        _isSending = true;
        _sendErrorText = null;
        _amountErrorText = null;
        _addressErrorText = null;
      });

      spendState.recipients.clear();

      String address = addressController.text;
      BigInt amount;
      try {
        amount = BigInt.from(int.parse(amountController.text));
      } on FormatException {
        setState(() {
          _isSending = false;
          _amountErrorText = 'Invalid amount';
        });
        return;
      }

      final int fees = getSelectedFee();
      if (fees == 0) {
        setState(() {
          _isSending = false;
          _sendErrorText = "0 fees selected";
        });
        return;
      }

      if (address.contains('@')) {
        // we interpret the address as a bip353 address
        try {
          final data = await Bip353.getAdressResolve(address);
          if (data.silentpayment != null) {
            address = data.silentpayment!;
          }
        } catch (e) {
          setState(() {
            _isSending = false;
            _addressErrorText = 'Failed to look up address';
          });
          return;
        }
      }

      spendState.addRecipients(address, amount, 1);

      try {
        final txid = await spendState.createSpendTx(walletState, fees);

        if (mounted) {
          // navigate to main screen
          Navigator.popUntil(context, (route) => route.isFirst);

          showAlertDialog('Transaction successfully sent', txid);
        }
      } catch (e) {
        setState(() {
          _isSending = false;
          _sendErrorText = exceptionToString(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spendState = Provider.of<SpendState>(context, listen: true);
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: true);

    final selectedOutputs = spendState.selectedOutputs;
    final availableBalance = walletState.amount;
    final blocksToScan = chainState.tip - walletState.lastScan;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // removes back btn
        title: const Text('New Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            TextField(
              controller: addressController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Recipient',
                hintText: 'satoshi@bitcoin.org, sp1q..., bc1q...',
                errorText: _addressErrorText,
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null) {
                        addressController.text = data.text ?? '';
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQRCode,
                  ),
                ]),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    'Available Balance: $availableBalance',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (blocksToScan != 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Warning: $blocksToScan block(s) to scan, balance might be inaccurate.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color.fromARGB(185, 251, 138, 0),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Amount',
                errorText: _amountErrorText,
                suffixText: 'sats',
                suffixIcon: TextButton(
                  onPressed: () {
                    setState(() {
                      amountController.text = availableBalance.toString();
                      spendState.selectAllAvailableOutputs(
                          walletState.getSpendableOutputs());
                    });
                  },
                  child: const Text('Max'),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            Text(
              'Fee Rate: ${getSelectedFee()} sat/vbyte',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Slider(
              value: selectedFeeIndex.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              label: [
                'Next block',
                'Half Hour',
                'Hour',
                'Day',
              ][selectedFeeIndex],
              onChanged: (value) {
                setState(() {
                  selectedFeeIndex = value.toInt();
                });
              },
            ),
            const Spacer(),
            SummaryWidget(
                displayText: selectedOutputs.isEmpty
                    ? "Tap here to choose which coin to spend"
                    : "Spending ${selectedOutputs.length} output(s) for a total of ${spendState.outputSelectionTotalAmt()} sats available",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const OutputsScreen()),
                  );
                }),
            const Spacer(),
            BitcoinButtonFilled(
              cornerRadius: 10,
              onPressed: () => onSpendButtonPressed(walletState, spendState),
              title: 'Spend',
            ),
            const SizedBox(height: 10.0),
            BitcoinButtonFilled(
              cornerRadius: 10,
              onPressed: Navigator.of(context).pop,
              title: 'Cancel',
            ),
            if (_sendErrorText != null)
              Center(child: Text('Error: $_sendErrorText')),
            if (_isSending) const Center(child: CircularProgressIndicator()),
            const Spacer()
          ],
        ),
      ),
    );
  }
}
