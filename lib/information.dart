import 'dart:async';

import 'package:donationwallet/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  String address = '';
  int scanheight = 0;
  int blockheight = 0;
  int birthday = 0;

  Timer? _timer;

  Future<void> _setup() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final addr = await api.getReceivingAddress();
    final birthday = await api.getBirthday();
    final walletinfo = await api.getWalletInfo();

    setState(() {
      address = addr;
      this.birthday = birthday;
      scanheight = walletinfo.scanHeight;
      blockheight = walletinfo.blockTip;
    });
  }

  @override
  void initState() {
    super.initState();
    _setup();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
        final info = await api.getWalletInfo();

        setState(() {
          scanheight = info.scanHeight;
          blockheight = info.blockTip;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SizedBox(
        width: screenWidth * 0.90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              'Silent payments address:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              address,
              textAlign: TextAlign.center,
              softWrap: true,
            ),
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
              },
            ),
            const Spacer(),
            Text(
              'Wallet birthday:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('$birthday'),
            const Spacer(),
            Text(
              'Scan height:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('$scanheight'),
            const Spacer(),
            Text(
              'Tip height:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('$blockheight'),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
