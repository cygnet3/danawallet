import 'dart:async';

import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  CreateWalletScreenState createState() => CreateWalletScreenState();
}

class CreateWalletScreenState extends State<CreateWalletScreen> {
  Network _selectedNetwork = Network.signet;

  @override
  void initState() {
    super.initState();
  }

  void _updateNetwork(Network? newValue) {
    if (newValue == null) {
      throw Exception("Trying to update network with null value");
    }

    setState(() {
      _selectedNetwork = newValue;
    });
  }

  Future<void> _setupWallet(
      ApiSetupWalletType setupWalletType, int? birthday) async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);

    // todo settings has to be initialized before chainstate, make this independent
    await SettingsRepository().defaultSettings(_selectedNetwork);

    await chainState.initialize();

    // todo check this only happens when creating new wallet
    if (birthday == null) {
      try {
        birthday = chainState.tip;
      } catch (e) {
        // at first we used a default birthday, but i'd rather we fail
        rethrow;
      }
    }

    final args = ApiSetupWalletArgs(
        setupType: setupWalletType,
        birthday: birthday,
        network: _selectedNetwork.toBitcoinNetwork);

    try {
      final setupResult = SpWallet.setupWallet(setupArgs: args);
      await walletState.createNewWallet(
          setupResult.wallet, setupResult.mnemonic, _selectedNetwork);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createNewWallet() async {
    const setupWalletType = ApiSetupWalletType.newWallet();

    await _setupWallet(setupWalletType, null);
  }

  Future<void> _importFromSeed(String mnemonic) async {
    final setupWalletType = ApiSetupWalletType.mnemonic(mnemonic);

    // When recovering, we select the default birthday for this selected network.
    // This should be a 'safe' default, meaning most users will be able to scan
    // starting from this birthday and find all of their funds.
    // If users require a different birthday, they should edit it
    // in the settings page.
    final birthday = _selectedNetwork.defaultBirthday;

    await _setupWallet(setupWalletType, birthday);
  }

  Future<void> _showSeedInputDialog() async {
    TextEditingController seedController = TextEditingController();

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
                try {
                  await _importFromSeed(mnemonic);
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
        appBar: AppBar(
          title: const Text('Wallet creation/restoration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  'Select a Network',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButton<Network>(
                  hint: const Text('Select a network'),
                  value: _selectedNetwork,
                  onChanged: (Network? newValue) {
                    _updateNetwork(newValue);
                  },
                  items: [
                    Network.mainnet,
                    Network.signet,
                  ].map((Network network) {
                    return DropdownMenuItem<Network>(
                        value: network, child: Text(network.toString()));
                  }).toList(),
                ),
                Visibility(
                  visible: _selectedNetwork == Network.mainnet,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'When using mainnet: please be aware that Dana is still in an experimental state. We do not take responsibility for lost funds.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: _buildButton(
                    context,
                    'Create New Wallet',
                    () async {
                      try {
                        await _createNewWallet();
                      } catch (e) {
                        rethrow;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _buildButton(
                    context,
                    'Restore from seed',
                    () {
                      _showSeedInputDialog();
                    },
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ));
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
