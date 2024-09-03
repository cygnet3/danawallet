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

// dust limit used in scanning. outputs < dust limit will not be scanned
const int defaultDustLimit = 1000;
