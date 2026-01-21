import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/global_functions.dart';
import 'package:flutter/services.dart';

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

  String get defaultBlindbitUrl {
    switch (this) {
      case Network.mainnet:
        if (isDevEnv && const String.fromEnvironment("MAINNET_URL") != "") {
          return const String.fromEnvironment("MAINNET_URL");
        } else {
          return defaultMainnet;
        }
      case Network.testnet:
        if (isDevEnv && const String.fromEnvironment("TESTNET_URL") != "") {
          return const String.fromEnvironment("TESTNET_URL");
        } else {
          return defaultTestnet;
        }
      case Network.signet:
        if (isDevEnv && const String.fromEnvironment("SIGNET_URL") != "") {
          return const String.fromEnvironment("SIGNET_URL");
        } else {
          return defaultSignet;
        }
      case Network.regtest:
        if (isDevEnv && const String.fromEnvironment("REGTEST_URL") != "") {
          return const String.fromEnvironment("REGTEST_URL");
        } else {
          return defaultRegtest;
        }
    }
  }

  String get toCoreArg {
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

  static Network fromCoreArg(String network) {
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

  static Network get getNetworkForFlavor {
    switch (appFlavor) {
      case 'live':
        return Network.mainnet;
      case 'signet':
        return Network.signet;
      // dev flavor defaults to regtest
      case 'dev':
        return Network.regtest;
      default:
        throw UnknownFlavorException();
    }
  }
}
