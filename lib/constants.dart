import 'package:flutter/services.dart';

// The default blindbit backend used
const String defaultMainnet = "https://silentpayments.dev/blindbit/mainnet";
const String defaultTestnet = "https://silentpayments.dev/blindbit/testnet";
const String defaultSignet = "https://silentpayments.dev/blindbit/signet";
const String defaultRegtest = "https://silentpayments.dev/blindbit/regtest";

// Default birthdays used in case we can't get the block height from blindbit
// These values are pretty arbitrary, they can be updated for newer heights later
const int defaultMainnetBirthday = 850000;
const int defaultTestnetBirthday = 2900000;
const int defaultSignetBirthday = 200000;
const int defaultRegtestBirthday = 80000;

// default dust limit. this is used in syncing, as well as sending
// for syncing, amounts < dust limit will be ignored
// for sending, the user needs to send a minimum of >= dust
const int defaultDustLimit = 1000;

// colors
const Color danaBlue = Color.fromARGB(255, 10, 109, 214);

// example address, used in onboarding flow
const String exampleAddress =
    "sp1qq0cygnetgn3rz2kla5cp05nj5uetlsrzez0l4p8g7wehf7ldr93lcqadw65upymwzvp5ed38l8ur2rznd6934xh95msevwrdwtrpk372hyz4vr6g";

// example mnemonic
const String exampleMnemonic =
    "gloom police month stamp viable claim hospital heart alcohol off ocean ghost";

// BIP39 words list - loaded from file for easier verification and maintenance
List<String> _bip39Words = [];

/// Loads BIP39 words from the text file
Future<void> loadBip39Words() async {
  if (_bip39Words.isNotEmpty) return; // Already loaded

  final String wordsText = await rootBundle.loadString('assets/english.txt');
  _bip39Words = wordsText
      .split('\n')
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty)
      .toList();
}

/// Gets the BIP39 words list. Call loadBip39Words() first to ensure it's loaded.
List<String> get bip39Words {
  if (_bip39Words.isEmpty) {
    throw StateError('BIP39 words not loaded. Call loadBip39Words() first.');
  }
  return _bip39Words;
}
