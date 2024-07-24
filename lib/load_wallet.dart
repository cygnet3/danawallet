import 'dart:async';

import 'package:donationwallet/home.dart';
import 'package:donationwallet/rust/api/wallet.dart';
import 'package:donationwallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoadWalletScreen extends StatelessWidget {
  const LoadWalletScreen({super.key});

  Future<void> _setup(BuildContext context, String? mnemonic, String? scanKey,
      String? spendKey, int birthday) async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    try {
      await walletState.updateWalletStatus();
      walletState.walletLoaded = true;
      return;
    } catch (e) {
      print("Creating a new wallet");
    }

    try {
      final wallet = await setup(
        label: walletState.label,
        mnemonic: mnemonic,
        scanKey: scanKey,
        spendKey: spendKey,
        birthday: birthday,
        network: walletState.network,
      );
      await walletState.saveWalletToSecureStorage(wallet);
      await walletState.updateWalletStatus();
      walletState.walletLoaded = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _showKeysInputDialog(BuildContext context, bool watchOnly,
      Function(Exception? e) onSetupComplete) async {
    TextEditingController scanKeyController = TextEditingController();
    TextEditingController spendKeyController = TextEditingController();
    TextEditingController birthdayController = TextEditingController();
    String hint;

    if (watchOnly) {
      hint = "Spend public key";
    } else {
      hint = "Spend private key";
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Enter keys"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Use min size for the column
            children: [
              TextField(
                controller: scanKeyController,
                decoration: InputDecoration(
                  hintText: "Scan private key",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null) {
                        scanKeyController.text = data.text ?? '';
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10), // Spacing between text fields
              TextField(
                controller: spendKeyController,
                decoration: InputDecoration(
                  hintText: hint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null) {
                        spendKeyController.text = data.text ?? '';
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10), // Spacing between text fields
              TextField(
                controller: birthdayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Wallet birthday (in blocks)",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null) {
                        birthdayController.text = data.text ?? '';
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text("Submit"),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Process the input from the two text fields
                final scanKey = scanKeyController.text;
                final spendKey = spendKeyController.text;
                final birthday = int.parse(birthdayController.text);

                if (scanKey.isEmpty || spendKey.isEmpty) {
                  throw Error();
                }

                try {
                  await _setup(context, null, scanKey, spendKey, birthday);
                  onSetupComplete(null);
                } on Exception catch (e) {
                  onSetupComplete(e);
                } catch (e) {
                  rethrow;
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSeedInputDialog(
      BuildContext context, Function(Exception?) onSetupComplete) async {
    TextEditingController seedController = TextEditingController();
    TextEditingController birthdayController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Enter Seed"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Use min size for the column
            children: [
              TextField(
                controller: seedController,
                decoration: InputDecoration(
                  hintText: "Seed",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null) {
                        seedController.text = data.text ?? '';
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10), // Spacing between text fields
              TextField(
                controller: birthdayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Wallet birthday (in blocks)",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null) {
                        birthdayController.text = data.text ?? '';
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text("Submit"),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Process the input from the two text fields
                final mnemonic = seedController.text;
                final birthday = int.parse(birthdayController.text);
                try {
                  await _setup(context, mnemonic, null, null, birthday);
                  onSetupComplete(null);
                } on Exception catch (e) {
                  onSetupComplete(e);
                } catch (e) {
                  rethrow;
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Expanded(
              child: _buildButton(
                context,
                'Create New Wallet',
                () async {
                  final navigator = Navigator.of(context);
                  final walletState =
                      Provider.of<WalletState>(context, listen: false);
                  try {
                    await _setup(context, null, null, null, walletState.tip);
                  } catch (e) {
                    rethrow;
                  }
                  if (walletState.walletLoaded) {
                    navigator.pushReplacement(MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
                  }
                },
              ),
            ),
            Expanded(
              child: _buildButton(
                context,
                'Restore from seed',
                () async {
                  final navigator = Navigator.of(context);
                  final walletState =
                      Provider.of<WalletState>(context, listen: false);
                  await _showSeedInputDialog(context, (Exception? e) async {
                    if (e != null) {
                      throw e;
                    } else if (walletState.walletLoaded) {
                      navigator.pushReplacement(MaterialPageRoute(
                          builder: (context) => const HomeScreen()));
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: _buildButton(
                context,
                'Restore from keys',
                () async {
                  final navigator = Navigator.of(context);
                  final walletState =
                      Provider.of<WalletState>(context, listen: false);
                  await _showKeysInputDialog(context, false,
                      (Exception? e) async {
                    if (e != null) {
                      throw e;
                    } else if (walletState.walletLoaded) {
                      navigator.pushReplacement(MaterialPageRoute(
                          builder: (context) => const HomeScreen()));
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: _buildButton(
                context,
                'Watch-only',
                () async {
                  final navigator = Navigator.of(context);
                  final walletState =
                      Provider.of<WalletState>(context, listen: false);
                  await _showKeysInputDialog(context, true,
                      (Exception? e) async {
                    if (e != null) {
                      throw e;
                    } else if (walletState.walletLoaded) {
                      navigator.pushReplacement(MaterialPageRoute(
                          builder: (context) => const HomeScreen()));
                    }
                  });
                },
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          textStyle: Theme.of(context).textTheme.headlineLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          minimumSize: const Size(double.infinity, 60),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
