// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:donationwallet/ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Silent payments'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int amount = 0;
  int tipheight = 0;
  int scanheight = 0;
  int peercount = 0;

  String spaddress = '';

  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    api.createLogStream().listen((event) {
      print('RUST: ${event.msg}');
    });

    api.createScanProgressStream().listen(((event) {
      int start = event.start;
      int current = event.current;
      int end = event.end;
      double scanned = (current - start).toDouble();
      double total = (end - start).toDouble();
      double progress = scanned / total;
      if (current == end) {
        progress = 0.0;
      }
      setState(() {
        this.progress = progress;
        scanheight = current;
      });
    }));

    api.createAmountStream().listen((event) {
      setState(() {
        amount = event;
      });
    });

    final Directory appDocumentsDir = await getApplicationSupportDirectory();

    // this sets up everything except nakamoto
    await api.setup(filesDir: appDocumentsDir.path);

    final amt = await api.getAmount();
    setState(() {
      amount = amt;
    });

    // this starts nakamoto, will block forever
    api.startNakamoto(filesDir: appDocumentsDir.path);
  }

  void _updateWalletInfo() async {
    print('getting wallet info');
    final info = await api.getWalletInfo();
    final spaddress = await api.getReceivingAddress();

    setState(() {
      scanheight = info.scanHeight;
      tipheight = info.blockTip;
      amount = info.amount;
      this.spaddress = spaddress;
    });

    print('scan height ${info.scanHeight}');
    print('block height ${info.blockTip}');
  }

  Future<void> _scanBlocks(int amount) async {
    await api.scanNextNBlocks(n: amount);
  }

  Future<void> _resetWallet() async {
    await api.resetWallet();
    SystemNavigator.pop();
  }

  Future<void> _scanToTip() async {
    await api.scanToTip();
  }

  void _getPeerCount() async {
    final peercount = await api.getPeerCount();

    setState(() {
      this.peercount = peercount;
    });
  }

  Widget showScanText() {
    final toScan = tipheight - scanheight;

    if (scanheight == 0) {
      return Text('Press \'update peer count\'',
          style: Theme.of(context).textTheme.headlineSmall);
    } else if (toScan == 0) {
      return Text('Up to date!',
          style: Theme.of(context).textTheme.headlineSmall);
    } else {
      return Text(
        'New blocks: $toScan',
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }
  }

  Widget getAddress() {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth * 0.95,
      child: Text(
        'Address:\n$spaddress',
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _resetWallet,
            child: const Text(
              'Reset wallet',
              style: TextStyle(),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                _getPeerCount();
                _updateWalletInfo();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Update peer count'),
            ),
            const SizedBox(
              height: 10,
            ),
            Text('Nakamoto peer count: $peercount'),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 40,
                    ),
                    Text(
                      'Amount: $amount',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    showScanText(),
                    const SizedBox(
                      height: 20.0,
                    ),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Visibility(
                        visible: progress != 0.0,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6.0,
                        ),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(
              height: 10.0,
            ),
            ElevatedButton(
              onPressed: peercount == 0
                  ? null
                  : () async {
                      await _scanToTip();
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('scan to tip'),
            ),
            const SizedBox(
              height: 10,
            ),
            // Text('Scan height: $scanheight'),
            // Text('Chain height: $tipheight'),
            // getAddress(),
            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
