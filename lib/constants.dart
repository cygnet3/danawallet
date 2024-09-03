enum Network {
  mainnet,
  testnet,
  signet;

  @override
  String toString() {
    switch (this) {
      case Network.mainnet:
        return 'Mainnet';
      case Network.testnet:
        return 'Testnet';
      case Network.signet:
        return 'Signet';
    }
  }

  String getDefaultBlindbitUrl() {
    switch (this) {
      case Network.mainnet:
        return defaultMainnet;
      case Network.testnet:
        return defaultTestnet;
      case Network.signet:
        return defaultSignet;
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
      default:
        throw Exception('unknown network');
    }
  }
}

// The default blindbit backend used
const String defaultMainnet = "https://silentpayments.dev/blindbit/mainnet";
const String defaultTestnet = "https://silentpayments.dev/blindbit/testnet";
const String defaultSignet = "https://silentpayments.dev/blindbit/signet";

// Default birthdays used in case we can't get the block height from blindbit
// These values are pretty arbitrary, they can be updated for newer heights later
const int defaultMainnetBirthday = 850000;
const int defaultTestnetBirthday = 2900000;
const int defaultSignetBirthday = 200000;

// dust limit used in scanning. outputs < dust limit will not be scanned
const int defaultDustLimit = 1000;
