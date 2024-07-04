import 'package:donationwallet/src/presentation/notifiers/chain_notifier.dart';
import 'package:donationwallet/src/presentation/notifiers/wallet_notifier.dart';
import 'package:donationwallet/src/presentation/screens/home_screen.dart';
import 'package:donationwallet/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupWalletScreen extends StatelessWidget {
  const SetupWalletScreen({super.key});

  // Future<void> _showKeysInputDialog(BuildContext context, bool watchOnly,
  //     Function(Exception? e) onSetupComplete) async {
  //   TextEditingController scanKeyController = TextEditingController();
  //   TextEditingController spendKeyController = TextEditingController();
  //   TextEditingController birthdayController = TextEditingController();
  //   String hint;

  //   if (watchOnly) {
  //     hint = "Spend public key";
  //   } else {
  //     hint = "Spend private key";
  //   }

  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         title: const Text("Enter keys"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min, // Use min size for the column
  //           children: [
  //             TextField(
  //               controller: scanKeyController,
  //               decoration: InputDecoration(
  //                 hintText: "Scan private key",
  //                 suffixIcon: IconButton(
  //                   icon: const Icon(Icons.paste),
  //                   onPressed: () async {
  //                     ClipboardData? data =
  //                         await Clipboard.getData(Clipboard.kTextPlain);
  //                     if (data != null) {
  //                       scanKeyController.text = data.text ?? '';
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 10), // Spacing between text fields
  //             TextField(
  //               controller: spendKeyController,
  //               decoration: InputDecoration(
  //                 hintText: hint,
  //                 suffixIcon: IconButton(
  //                   icon: const Icon(Icons.paste),
  //                   onPressed: () async {
  //                     ClipboardData? data =
  //                         await Clipboard.getData(Clipboard.kTextPlain);
  //                     if (data != null) {
  //                       spendKeyController.text = data.text ?? '';
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 10), // Spacing between text fields
  //             TextField(
  //               controller: birthdayController,
  //               keyboardType: TextInputType.number,
  //               decoration: InputDecoration(
  //                 hintText: "Wallet birthday (in blocks)",
  //                 suffixIcon: IconButton(
  //                   icon: const Icon(Icons.paste),
  //                   onPressed: () async {
  //                     ClipboardData? data =
  //                         await Clipboard.getData(Clipboard.kTextPlain);
  //                     if (data != null) {
  //                       birthdayController.text = data.text ?? '';
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("Cancel"),
  //             onPressed: () {
  //               Navigator.of(dialogContext).pop(); // Close the dialog
  //             },
  //           ),
  //           TextButton(
  //             child: const Text("Submit"),
  //             onPressed: () async {
  //               Navigator.of(dialogContext).pop(); // Close the dialog
  //               // Process the input from the two text fields
  //               final scanKey = scanKeyController.text;
  //               final spendKey = spendKeyController.text;
  //               final birthday = int.parse(birthdayController.text);

  //               if (scanKey.isEmpty || spendKey.isEmpty) {
  //                 throw Error();
  //               }

  //               final walletNotifier = Provider.of<WalletNotifier>(context, listen: false);
  //               try {
  //                 await _setup(walletNotifier, null, scanKey, spendKey, birthday, defaultNetwork);
  //                 onSetupComplete(null);
  //               } on Exception catch (e) {
  //                 onSetupComplete(e);
  //               } catch (e) {
  //                 rethrow;
  //               }
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Future<void> _showSeedInputDialog(
  //     BuildContext context, Function(Exception?) onSetupComplete) async {
  //   TextEditingController seedController = TextEditingController();
  //   TextEditingController birthdayController = TextEditingController();

  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         title: const Text("Enter Seed"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min, // Use min size for the column
  //           children: [
  //             TextField(
  //               controller: seedController,
  //               decoration: InputDecoration(
  //                 hintText: "Seed",
  //                 suffixIcon: IconButton(
  //                   icon: const Icon(Icons.paste),
  //                   onPressed: () async {
  //                     ClipboardData? data =
  //                         await Clipboard.getData(Clipboard.kTextPlain);
  //                     if (data != null) {
  //                       seedController.text = data.text ?? '';
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 10), // Spacing between text fields
  //             TextField(
  //               controller: birthdayController,
  //               keyboardType: TextInputType.number,
  //               decoration: InputDecoration(
  //                 hintText: "Wallet birthday (in blocks)",
  //                 suffixIcon: IconButton(
  //                   icon: const Icon(Icons.paste),
  //                   onPressed: () async {
  //                     ClipboardData? data =
  //                         await Clipboard.getData(Clipboard.kTextPlain);
  //                     if (data != null) {
  //                       birthdayController.text = data.text ?? '';
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("Cancel"),
  //             onPressed: () {
  //               Navigator.of(dialogContext).pop(); // Close the dialog
  //             },
  //           ),
  //           TextButton(
  //             child: const Text("Submit"),
  //             onPressed: () async {
  //               Navigator.of(dialogContext).pop(); // Close the dialog
  //               // Process the input from the two text fields
  //               final mnemonic = seedController.text;
  //               final birthday = int.parse(birthdayController.text);
  //               final walletNotifier = Provider.of<WalletNotifier>(context, listen: false);
  //               try {
  //                 await _setup(walletNotifier, mnemonic, null, null, birthday, defaultNetwork);
  //                 onSetupComplete(null);
  //               } on Exception catch (e) {
  //                 onSetupComplete(e);
  //               } catch (e) {
  //                 rethrow;
  //               }
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final walletNotifier = Provider.of<WalletNotifier>(context);
    final chainNotifier = Provider.of<ChainNotifier>(context);

    // final walletNotifier = context.watch()<WalletNotifier>();
    // final chainNotifier = context.watch()<ChainNotifier>();

    // if wallet exists, go to home screen
    if (walletNotifier.wallet != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet creation/restoration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: _buildButton(context, 'Create new Wallet', () async {
              final tip = chainNotifier.tip;
              await walletNotifier.createWallet(
                  defaultLabel, defaultNetwork, tip);
              // goToHomeScreen();
            })),

            // const Spacer(),
            // Consumer<WalletNotifier>(builder: (context, walletNotifier, child) {
            //   return Expanded(
            //       child: _buildButton(context, 'Create New Wallet', () async {
            //     createWallet(context);
            //   }));
            // }),
          ],
        ),
      ),
    );
    // Expanded(
    //   child: _buildButton(
    //     context,
    //     'Restore from seed',
    //     () async {
    //       final navigator = Navigator.of(context);
    //       final walletNotifier =
    //           Provider.of<WalletNotifier>(context, listen: false);
    //       await _showSeedInputDialog(context, (Exception? e) async {
    //         if (e != null) {
    //           throw e;
    //         } else if (walletNotifier.wallet != null) {
    //           navigator.pushReplacement(MaterialPageRoute(
    //               builder: (context) => const HomeScreen()));
    //         }
    //       });
    //     },
    //   ),
    // ),
    // Expanded(
    //   child: _buildButton(
    //     context,
    //     'Restore from keys',
    //     () async {
    //       final navigator = Navigator.of(context);
    //       final walletNotifier =
    //           Provider.of<WalletNotifier>(context, listen: false);
    //       await _showKeysInputDialog(context, false,
    //           (Exception? e) async {
    //         if (e != null) {
    //           throw e;
    //         } else if (walletNotifier.wallet != null) {
    //           navigator.pushReplacement(MaterialPageRoute(
    //               builder: (context) => const HomeScreen()));
    //         }
    //       });
    //     },
    //   ),
    // ),
    // Expanded(
    //   child: _buildButton(
    //     context,
    //     'Watch-only',
    //     () async {
    //       final navigator = Navigator.of(context);
    //       final walletNotifier =
    //           Provider.of<WalletNotifier>(context, listen: false);
    //       await _showKeysInputDialog(context, true,
    //           (Exception? e) async {
    //         if (e != null) {
    //           throw e;
    //         } else if (walletNotifier.wallet != null) {
    //           navigator.pushReplacement(MaterialPageRoute(
    //               builder: (context) => const HomeScreen()));
    //         }
    //       });
    //     },
    //   ),
    // ),
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

// Future<void> createWallet(BuildContext context) async {
//   final tip = Provider.of<ChainNotifier>(context, listen: false).tip;
//   await walletNotifier.createWalletUseCase(defaultLabel, defaultNetwork, tip);
//   if (walletNotifier.wallet != null) {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => HomeScreen()),
//     );
//   }
// }
