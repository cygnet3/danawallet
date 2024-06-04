import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/rust/api/simple.dart';
import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/main.dart';
import 'package:donationwallet/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _removeWallet(
      WalletState walletState, Function(Exception? e) callback) async {
    try {
      removeWallet(path: walletState.dir.path, label: walletState.label);
      await walletState.reset();
      callback(null);
    } on Exception catch (e) {
      callback(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _getSeedPhrase(WalletState walletState) async {
    try {
      return showMnemonic(
          path: walletState.dir.path, label: walletState.label);
    } catch (e) {
      displayNotification(e.toString());
      return null;
    }
  }

  Future<void> _setBirthday(BuildContext context,
      TextEditingController controller, Function(Exception? e) callback) async {
    showDialog<int>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Enter Birthday'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Enter wallet\'s birthday (numeric value)'),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(int.tryParse(value));
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(); // Close the dialog without saving
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(int.tryParse(controller.text));
                },
                child: const Text('OK'),
              ),
            ],
          );
        }).then((value) async {
      if (value != null) {
        final walletState = Provider.of<WalletState>(context, listen: false);
        try {
          await changeBirthday(
              path: walletState.dir.path,
              label: walletState.label,
              birthday: value);
          await resetWallet(
              path: walletState.dir.path, label: walletState.label);
          callback(null);
          await walletState.updateWalletStatus();
        } on Exception catch (e) {
          callback(e);
        } catch (e) {
          rethrow;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BitcoinButtonOutlined(
          title: 'Show seed phrase',
          onPressed: () async {
            final walletState =
                Provider.of<WalletState>(context, listen: false);

            const title = 'Backup seed phrase';
            final text = await _getSeedPhrase(walletState) ??
                'Seed phrase unknown! Did you import from keys?';

            showAlertDialog(title, text);
          },
        ),
        BitcoinButtonOutlined(
          title: 'Set wallet birthday',
          onPressed: () async {
            final controller = TextEditingController();
            await _setBirthday(context, controller, (Exception? e) async {
              if (e != null) {
                throw e;
              } else {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
              }
            });
          },
        ),
        BitcoinButtonOutlined(
          title: 'Wipe wallet',
          onPressed: () async {
            final walletState =
                Provider.of<WalletState>(context, listen: false);
            await _removeWallet(walletState, (Exception? e) async {
              if (e != null) {
                throw e;
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            });
          },
        ),
      ],
    );
  }
}
