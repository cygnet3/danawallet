import 'package:donationwallet/ffi.dart';
import 'package:flutter/material.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  String address = '';

  Future<void> _setup() async {
    final addr = await api.getReceivingAddress();

    setState(() {
      address = addr;
    });
  }

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Silent payments address: \n $address'),
      ],
    );
  }
}
