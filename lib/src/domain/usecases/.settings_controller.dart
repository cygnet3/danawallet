import 'package:donationwallet/rust/api/simple.dart';
import 'package:donationwallet/src/presentation/notifiers/wallet_notifier.dart';
import 'package:donationwallet/src/utils/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsController {
  const SettingsController();

  Future<void> removeWallet(
      WalletState walletState, Function(Exception? e) callback) async {
    try {
      await walletState.rmWalletFromSecureStorage();
      await walletState.reset();
      callback(null);
    } on Exception catch (e) {
      callback(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getSeedPhrase(WalletState walletState) async {
    try {
      final wallet = await walletState.getWalletFromSecureStorage();
      return showMnemonic(encodedWallet: wallet);
    } catch (e) {
      displayNotification(e.toString());
      return null;
    }
  }

  Future<void> setBirthday(BuildContext context,
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
          final wallet = await walletState.getWalletFromSecureStorage();
          final updatedWallet =
              changeBirthday(encodedWallet: wallet, birthday: value);
          walletState.saveWalletToSecureStorage(updatedWallet);
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
}
