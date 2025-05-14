// import 'package:bitcoin_ui/bitcoin_ui.dart';
// import 'package:danawallet/generated/rust/api/structs.dart';
// import 'package:danawallet/global_functions.dart';
// import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
// import 'package:danawallet/screens/home/wallet/spend/choose_recipient.dart';
// import 'package:danawallet/services/synchronization_service.dart';
// import 'package:danawallet/states/scan_progress_notifier.dart';
// import 'package:danawallet/states/wallet_state.dart';
// import 'package:danawallet/widgets/add_funds_widget.dart';
// import 'package:danawallet/widgets/receive_widget.dart';
// import 'package:danawallet/widgets/transaction_history.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:barcode_widget/barcode_widget.dart';
//
// class WalletScreen extends StatefulWidget {
//   const WalletScreen({super.key});
//
//   @override
//   WalletScreenState createState() => WalletScreenState();
// }
//
// class WalletScreenState extends State<WalletScreen> {
//   bool hideAmount = false;
//
//   void _showReceiveDialog(BuildContext context, String address) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Your address'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SingleChildScrollView(
//                 child: BarcodeWidget(data: address, barcode: Barcode.qrCode()),
//               ),
//               const SizedBox(height: 20),
//               SelectableText(address),
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Close'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget buildTransactionOverview(List<ApiRecordedTransaction> transactions) {
//     if (transactions.isEmpty) {
//       // the user has not made any transactions yet
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text('No transactions yet.\n',
//               textAlign: TextAlign.center,
//               style: BitcoinTextStyle.body3(Bitcoin.neutral6)
//                   .copyWith(fontFamily: 'Inter')),
//           Text('Fund your wallet to get started!',
//               textAlign: TextAlign.center,
//               style: BitcoinTextStyle.body3(Bitcoin.neutral6)
//                   .copyWith(fontFamily: 'Inter')),
//         ],
//       );
//
//       // history = Center(
//       //     child: Text('No transactions yet.',
//       //         style: BitcoinTextStyle.body3(Bitcoin.neutral6)));
//     } else {
//       final history = TransactionHistoryWidget(transactions: transactions);
//       return Column(children: [
//         Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               'Recent transactions',
//               style: BitcoinTextStyle.body2(Bitcoin.neutral8)
//                   .apply(fontWeightDelta: 2),
//             )),
//         LimitedBox(maxHeight: 240, child: history),
//       ]);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WalletSkeleton(showBottomButtons: true);
//   }
// }
