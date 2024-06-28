import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

void showReceiveDialog(BuildContext context, String address) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Your address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              child: BarcodeWidget(data: address, barcode: Barcode.qrCode()),
            ),
            const SizedBox(height: 20),
            SelectableText(address),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
