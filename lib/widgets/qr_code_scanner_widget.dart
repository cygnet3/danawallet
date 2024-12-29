import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerWidget extends StatelessWidget {
  final Function(String) onQRCodeScanned; // Callback to pass scanned QR code
  final VoidCallback onCancel; // Callback for cancel/close action

  const QRCodeScannerWidget({
    Key? key,
    required this.onQRCodeScanned,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the platform supports the camera
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Scanner'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
      body: MobileScanner(
        onDetect: (capture) {
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null) {
              onQRCodeScanned(barcode.rawValue!);
              break; // Exit after detecting the first valid QR code
            }
          }
        },
      ),
    );
  }
}
