import 'package:donationwallet/home.dart';
import 'package:donationwallet/storage.dart';
import 'package:flutter/material.dart';

class CustomWalletPage extends StatefulWidget {
  const CustomWalletPage({super.key});

  @override
  State<CustomWalletPage> createState() => _CustomWalletPage();
}

class _CustomWalletPage extends State<CustomWalletPage> {
  final scanSkControler = TextEditingController();
  final spendPkController = TextEditingController();
  final birthdayController = TextEditingController();

  @override
  void dispose() {
    scanSkControler.dispose();
    spendPkController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          height: 40.0,
          child: ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await SecureStorageService().initializeWithCustomSettings(
                  spendPkController.text,
                  scanSkControler.text,
                  birthdayController.text);
              navigator.pushReplacement(
                  MaterialPageRoute(builder: (context) => const MyHomePage()));
            },
            child: const Text('Continue'),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: scanSkControler,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'scan private key',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: spendPkController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'spend public key',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: birthdayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'birthday block',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
