// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.3.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'history.dart';
import 'outputs.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'wallet.dart';

// These function are ignored because they are on traits that is not defined in current crate (put an empty `#[frb]` on it to unignore): `clone`, `clone`, `clone`, `fmt`, `fmt`, `fmt`

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<DanaBackup>>
abstract class DanaBackup implements RustOpaqueInterface {
  SettingsBackup get settings;

  WalletBackup get wallet;

  set settings(SettingsBackup settings);

  set wallet(WalletBackup wallet);

  static DanaBackup decode({required String encodedBackup}) =>
      RustLib.instance.api
          .crateApiBackupDanaBackupDecode(encodedBackup: encodedBackup);

  String encode();

  factory DanaBackup(
          {required WalletBackup wallet, required SettingsBackup settings}) =>
      RustLib.instance.api
          .crateApiBackupDanaBackupNew(wallet: wallet, settings: settings);
}

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<WalletBackup>>
abstract class WalletBackup implements RustOpaqueInterface {
  int get birthday;

  int get lastScan;

  String get network;

  OwnedOutputs get ownedOutputs;

  ApiScanKey get scanKey;

  String? get seedPhrase;

  ApiSpendKey get spendKey;

  TxHistory get txHistory;

  set birthday(int birthday);

  set lastScan(int lastScan);

  set network(String network);

  set ownedOutputs(OwnedOutputs ownedOutputs);

  set scanKey(ApiScanKey scanKey);

  set seedPhrase(String? seedPhrase);

  set spendKey(ApiSpendKey spendKey);

  set txHistory(TxHistory txHistory);

  factory WalletBackup(
          {required SpWallet wallet,
          required String network,
          required TxHistory txHistory,
          required OwnedOutputs ownedOutputs,
          String? seedPhrase,
          required int lastScan}) =>
      RustLib.instance.api.crateApiBackupWalletBackupNew(
          wallet: wallet,
          network: network,
          txHistory: txHistory,
          ownedOutputs: ownedOutputs,
          seedPhrase: seedPhrase,
          lastScan: lastScan);
}

class SettingsBackup {
  final String blindbitUrl;
  final int dustLimit;

  const SettingsBackup.raw({
    required this.blindbitUrl,
    required this.dustLimit,
  });

  factory SettingsBackup(
          {required String blindbitUrl, required int dustLimit}) =>
      RustLib.instance.api.crateApiBackupSettingsBackupNew(
          blindbitUrl: blindbitUrl, dustLimit: dustLimit);

  @override
  int get hashCode => blindbitUrl.hashCode ^ dustLimit.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsBackup &&
          runtimeType == other.runtimeType &&
          blindbitUrl == other.blindbitUrl &&
          dustLimit == other.dustLimit;
}
