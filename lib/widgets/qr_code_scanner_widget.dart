import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerWidget extends StatefulWidget {
  const QRCodeScannerWidget({
    super.key,
  });

  @override
  QrCodeScannerWidgetState createState() => QrCodeScannerWidgetState();
}

class QrCodeScannerWidgetState extends State<QRCodeScannerWidget> {
  bool found = false;

  @override
  void initState() {
    super.initState();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    // 'handleBarcode' may be called multiple times, so we check if we
    // have already found a result
    if (found) {
      return;
    }

    for (final barcode in barcodes.barcodes) {
      if (!found && barcode.rawValue != null) {
        found = true;
        // return result using context.pop
        Navigator.of(context).pop(barcode.rawValue!);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the platform supports the camera
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Scanner'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: Navigator.of(context).pop,
          ),
        ),
        body: const Center(
          child: Text(
            'QR Code scanning is not supported on this platform.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Use MobileScanner for supported platforms
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: Navigator.of(context).pop),
      ),
      body: MobileScanner(
        onDetect: _handleBarcode,
      ),
    );
  }
}
