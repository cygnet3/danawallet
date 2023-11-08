import 'dart:async';
import 'dart:io';

import 'package:donationwallet/ffi.dart';
import 'package:donationwallet/storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int balance = 0;
  int tipheight = 0;
  int scanheight = 0;
  int peercount = 0;
  Timer? _timer;

  String spaddress = '';

  bool scanning = false;
  double progress = 0.0;

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
        if (!scanning) {
          final peercount = await api.getPeerCount();
          final info = await api.getWalletInfo();

          setState(() {
            scanheight = info.scanHeight;
            tipheight = info.blockTip;
            balance = info.amount;
            this.peercount = peercount;
          });
        }
      });
    });
  }

  Future<void> updateWalletInfo() async {
    final info = await api.getWalletInfo();
    setState(() {
      scanheight = info.scanHeight;
      tipheight = info.blockTip;
    });
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
        balance = event;
      });
    });

    final Directory appDocumentsDir = await getApplicationSupportDirectory();

    SecureStorageService secureStorage = SecureStorageService();
    final scanSk = (await secureStorage.read(key: 'scan_sk'))!;
    final spendPk = (await secureStorage.read(key: 'spend_pk'))!;
    final isTestnet = (await secureStorage.read(key: 'is_testnet'))! == 'true';
    final birthday = int.parse((await secureStorage.read(key: 'birthday'))!);

    // this sets up everything except nakamoto
    await api.setup(
      filesDir: appDocumentsDir.path,
      scanSk: scanSk,
      spendPk: spendPk,
      isTestnet: isTestnet,
      birthday: birthday,
    );

    final amt = await api.getWalletBalance();
    setState(() {
      balance = amt;
    });

    // this starts nakamoto, will block forever (or until client is restarted)
    api.startNakamoto();
  }

  Future<void> _scanToTip() async {
    scanning = true;
    await updateWalletInfo();
    await api.scanToTip();
    scanning = false;
  }

  Widget showScanText() {
    final toScan = tipheight - scanheight;

    String text;
    if (scanheight == 0 || peercount == 0) {
      text = 'Waiting for peers';
    } else if (toScan == 0) {
      text = 'Up to date!';
    } else {
      text = 'New blocks: $toScan';
    }

    return Text(
      text,
      style: Theme.of(context).textTheme.displaySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Text('Nakamoto peer count: $peercount'),
          const SizedBox(
            height: 80,
          ),
          Text(
            'Balance: $balance',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const Spacer(),
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
          const SizedBox(
            height: 20.0,
          ),
          showScanText(),
          const Spacer(),
          ElevatedButton(
            onPressed: peercount == 0 || tipheight < scanheight
                ? null
                : () async {
                    await _scanToTip();
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Scan for payments'),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
