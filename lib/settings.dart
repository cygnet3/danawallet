import 'package:donationwallet/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});


  void restartNakamoto() {
  }

  Future<void> _resetWallet() async {
    await api.resetWallet();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async {
            api.restartNakamoto();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Restart nakamoto'),
        ),
      ],
    );
  }
}