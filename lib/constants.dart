import 'dart:ui';

import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';

enum Network {
  mainnet,
  testnet,
  signet,
  regtest;

  @override
  String toString() {
    switch (this) {
      case Network.mainnet:
        return 'Mainnet';
      case Network.testnet:
        return 'Testnet';
      case Network.signet:
        return 'Signet';
      case Network.regtest:
        return 'Regtest';
    }
  }

  String getDefaultBlindbitUrl() {
    switch (this) {
      case Network.mainnet:
        if (isDevEnv() && const String.fromEnvironment("MAINNET_URL") != "") {
          return const String.fromEnvironment("MAINNET_URL");
        } else {
          return defaultMainnet;
        }
      case Network.testnet:
        if (isDevEnv() && const String.fromEnvironment("TESTNET_URL") != "") {
          return const String.fromEnvironment("TESTNET_URL");
        } else {
          return defaultTestnet;
        }
      case Network.signet:
        if (isDevEnv() && const String.fromEnvironment("SIGNET_URL") != "") {
          return const String.fromEnvironment("SIGNET_URL");
        } else {
          return defaultSignet;
        }
      case Network.regtest:
        if (isDevEnv() && const String.fromEnvironment("REGTEST_URL") != "") {
          return const String.fromEnvironment("REGTEST_URL");
        } else {
          return defaultRegtest;
        }
    }
  }

  String get toBitcoinNetwork {
    switch (this) {
      case Network.mainnet:
        return 'main';
      case Network.testnet:
        return 'test';
      case Network.signet:
        return 'signet';
      case Network.regtest:
        return 'regtest';
    }
  }

  Color get toColor {
    switch (this) {
      case Network.mainnet:
        return Bitcoin.orange;
      case Network.testnet:
        return Bitcoin.green;
      case Network.signet:
        return Bitcoin.purple;
      case Network.regtest:
        return Bitcoin.blue;
    }
  }

  int get defaultBirthday {
    switch (this) {
      case Network.mainnet:
        return defaultMainnetBirthday;
      case Network.testnet:
        return defaultTestnetBirthday;
      case Network.signet:
        return defaultSignetBirthday;
      case Network.regtest:
        return defaultRegtestBirthday;
    }
  }

  static Network fromBitcoinNetwork(String network) {
    switch (network) {
      case 'main':
        return Network.mainnet;
      case 'test':
        return Network.testnet;
      case 'signet':
        return Network.signet;
      case 'regtest':
        return Network.regtest;
      default:
        throw Exception('unknown network');
    }
  }
}

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
const int defaultRegtestBirthday = 0;

// dust limit used in scanning. outputs < dust limit will not be scanned
const int defaultDustLimit = 1000;

// example address, used in onboarding flow
const String exampleAddress =
    "sp1qq0cygnetgn3rz2kla5cp05nj5uetlsrzez0l4p8g7wehf7ldr93lcqadw65upymwzvp5ed38l8ur2rznd6934xh95msevwrdwtrpk372hyz4vr6g";
