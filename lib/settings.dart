import 'package:donationwallet/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String address = '';

  Future<void> _setup() async {
    final addr = await api.getReceivingAddress();

    setState(() {
      address = addr;
    });
  }


  void restartNakamoto() {
    api.restartNakamoto();
  }

  Future<void> _resetWallet() async {
    await api.resetWallet();
    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            restartNakamoto();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Restart nakamoto'),
        ),
        Text(address),
      ],
    );
  }
}
