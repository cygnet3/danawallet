import 'package:donationwallet/ffi.dart';
import 'package:donationwallet/main.dart';
import 'package:donationwallet/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _removeWallet(
      WalletState walletState, Function(Exception? e) callback) async {
    try {
      await api.removeWallet(
          path: walletState.dir.path, label: walletState.label);
      callback(null);
    } on Exception catch (e) {
      callback(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ElevatedButton(
        //   onPressed: () async {
        //     api.restartNakamoto();
        //   },
        //   style: ElevatedButton.styleFrom(
        //     minimumSize: const Size(double.infinity, 50),
        //   ),
        //   child: const Text('Restart nakamoto'),
        // ),
        // ElevatedButton(
        //   onPressed: () async {
        //     await api.resetWallet();
        //     await api.restartNakamoto();
        //   },
        //   style: ElevatedButton.styleFrom(
        //     minimumSize: const Size(double.infinity, 50),
        //   ),
        //   child: const Text('Reset wallet to birthday'),
        // ),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Wipe wallet'),
        ),
      ],
    );
  }
}
