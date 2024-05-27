// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.82.6.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;

part 'bridge_definitions.freezed.dart';

abstract class SpBackend {
  Stream<LogEntry> createLogStream(
      {required LogLevel level, required bool logDependencies, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateLogStreamConstMeta;

  Stream<SyncStatus> createSyncStream({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateSyncStreamConstMeta;

  Stream<ScanProgress> createScanProgressStream({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateScanProgressStreamConstMeta;

  Stream<int> createAmountStream({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateAmountStreamConstMeta;

  Future<bool> walletExists(
      {required String label, required String filesDir, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kWalletExistsConstMeta;

  Future<String> setup(
      {required String label,
      required String filesDir,
      required WalletType walletType,
      required int birthday,
      required bool isTestnet,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kSetupConstMeta;

  /// Change wallet birthday
  /// Since this method doesn't touch the known outputs
  /// the caller is responsible for resetting the wallet to its new birthday
  Future<void> changeBirthday(
      {required String path,
      required String label,
      required int birthday,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kChangeBirthdayConstMeta;

  /// Reset the last_scan of the wallet to its birthday, removing all outpoints
  Future<void> resetWallet(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kResetWalletConstMeta;

  Future<void> removeWallet(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kRemoveWalletConstMeta;

  Future<void> syncBlockchain({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kSyncBlockchainConstMeta;

  Future<void> scanToTip(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kScanToTipConstMeta;

  Future<WalletStatus> getWalletInfo(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kGetWalletInfoConstMeta;

  Future<String> getReceivingAddress(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kGetReceivingAddressConstMeta;

  Future<List<OwnedOutput>> getSpendableOutputs(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kGetSpendableOutputsConstMeta;

  Future<List<OwnedOutput>> getOutputs(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kGetOutputsConstMeta;

  Future<String> createNewPsbt(
      {required String label,
      required String path,
      required List<OwnedOutput> inputs,
      required List<Recipient> recipients,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateNewPsbtConstMeta;

  Future<String> addFeeForFeeRate(
      {required String psbt,
      required int feeRate,
      required String payer,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kAddFeeForFeeRateConstMeta;

  Future<String> fillSpOutputs(
      {required String path,
      required String label,
      required String psbt,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kFillSpOutputsConstMeta;

  Future<String> signPsbt(
      {required String path,
      required String label,
      required String psbt,
      required bool finalize,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kSignPsbtConstMeta;

  Future<String> extractTxFromPsbt({required String psbt, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kExtractTxFromPsbtConstMeta;

  Future<String> broadcastTx({required String tx, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kBroadcastTxConstMeta;

  Future<void> markTransactionInputsAsSpent(
      {required String path,
      required String label,
      required String tx,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kMarkTransactionInputsAsSpentConstMeta;

  Future<String?> showMnemonic(
      {required String path, required String label, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kShowMnemonicConstMeta;
}

class LogEntry {
  final int timeMillis;
  final String level;
  final String tag;
  final String msg;

  const LogEntry({
    required this.timeMillis,
    required this.level,
    required this.tag,
    required this.msg,
  });
}

enum LogLevel {
  Debug,
  Info,
  Warn,
  Error,
  Off,
}

@freezed
sealed class OutputSpendStatus with _$OutputSpendStatus {
  const factory OutputSpendStatus.unspent() = OutputSpendStatus_Unspent;
  const factory OutputSpendStatus.spent(
    String field0,
  ) = OutputSpendStatus_Spent;
  const factory OutputSpendStatus.mined(
    String field0,
  ) = OutputSpendStatus_Mined;
}

class OwnedOutput {
  final String txoutpoint;
  final int blockheight;
  final String tweak;
  final int amount;
  final String script;
  final String? label;
  final OutputSpendStatus spendStatus;

  const OwnedOutput({
    required this.txoutpoint,
    required this.blockheight,
    required this.tweak,
    required this.amount,
    required this.script,
    this.label,
    required this.spendStatus,
  });
}

class Recipient {
  final String address;
  final int amount;
  final int nbOutputs;

  const Recipient({
    required this.address,
    required this.amount,
    required this.nbOutputs,
  });
}

class ScanProgress {
  final int start;
  final int current;
  final int end;

  const ScanProgress({
    required this.start,
    required this.current,
    required this.end,
  });
}

class SyncStatus {
  final int blockheight;

  const SyncStatus({
    required this.blockheight,
  });
}

class WalletStatus {
  final int amount;
  final int birthday;
  final int scanHeight;

  const WalletStatus({
    required this.amount,
    required this.birthday,
    required this.scanHeight,
  });
}

@freezed
sealed class WalletType with _$WalletType {
  const factory WalletType.new() = WalletType_New;
  const factory WalletType.mnemonic(
    String field0,
  ) = WalletType_Mnemonic;
  const factory WalletType.privateKeys(
    String field0,
    String field1,
  ) = WalletType_PrivateKeys;
  const factory WalletType.readOnly(
    String field0,
    String field1,
  ) = WalletType_ReadOnly;
}