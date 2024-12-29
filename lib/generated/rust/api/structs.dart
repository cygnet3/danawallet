// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.3.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import '../lib.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;
part 'structs.freezed.dart';

// These types are ignored because they are not used by any `pub` functions: `ApiRecipientAddress`
// These function are ignored because they are on traits that is not defined in current crate (put an empty `#[frb]` on it to unignore): `clone`, `clone`, `clone`, `clone`, `clone`, `clone`, `clone`, `clone`, `eq`, `eq`, `eq`, `eq`, `eq`, `eq`, `eq`, `eq`, `fmt`, `fmt`, `fmt`, `fmt`, `fmt`, `fmt`, `fmt`, `fmt`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `from`, `try_from`

class Amount {
  final BigInt field0;

  const Amount({
    required this.field0,
  });

  BigInt toInt() => RustLib.instance.api.crateApiStructsAmountToInt(
        that: this,
      );

  @override
  int get hashCode => field0.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Amount &&
          runtimeType == other.runtimeType &&
          field0 == other.field0;
}

@freezed
sealed class ApiOutputSpendStatus with _$ApiOutputSpendStatus {
  const ApiOutputSpendStatus._();

  const factory ApiOutputSpendStatus.unspent() = ApiOutputSpendStatus_Unspent;
  const factory ApiOutputSpendStatus.spent(
    String field0,
  ) = ApiOutputSpendStatus_Spent;
  const factory ApiOutputSpendStatus.mined(
    String field0,
  ) = ApiOutputSpendStatus_Mined;
}

class ApiOwnedOutput {
  final int blockheight;
  final U8Array32 tweak;
  final Amount amount;
  final String script;
  final String? label;
  final ApiOutputSpendStatus spendStatus;

  const ApiOwnedOutput({
    required this.blockheight,
    required this.tweak,
    required this.amount,
    required this.script,
    this.label,
    required this.spendStatus,
  });

  @override
  int get hashCode =>
      blockheight.hashCode ^
      tweak.hashCode ^
      amount.hashCode ^
      script.hashCode ^
      label.hashCode ^
      spendStatus.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiOwnedOutput &&
          runtimeType == other.runtimeType &&
          blockheight == other.blockheight &&
          tweak == other.tweak &&
          amount == other.amount &&
          script == other.script &&
          label == other.label &&
          spendStatus == other.spendStatus;
}

class ApiRecipient {
  final String address;
  final Amount amount;
  final int nbOutputs;
  final List<String> outputs;

  const ApiRecipient({
    required this.address,
    required this.amount,
    required this.nbOutputs,
    required this.outputs,
  });

  @override
  int get hashCode =>
      address.hashCode ^
      amount.hashCode ^
      nbOutputs.hashCode ^
      outputs.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiRecipient &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          amount == other.amount &&
          nbOutputs == other.nbOutputs &&
          outputs == other.outputs;
}

@freezed
sealed class ApiRecordedTransaction with _$ApiRecordedTransaction {
  const ApiRecordedTransaction._();

  const factory ApiRecordedTransaction.incoming(
    ApiRecordedTransactionIncoming field0,
  ) = ApiRecordedTransaction_Incoming;
  const factory ApiRecordedTransaction.outgoing(
    ApiRecordedTransactionOutgoing field0,
  ) = ApiRecordedTransaction_Outgoing;
}

class ApiRecordedTransactionIncoming {
  final String txid;
  final Amount amount;
  final int? confirmedAt;

  const ApiRecordedTransactionIncoming({
    required this.txid,
    required this.amount,
    this.confirmedAt,
  });

  String toString() => RustLib.instance.api
          .crateApiStructsApiRecordedTransactionIncomingToString(
        that: this,
      );

  @override
  int get hashCode => txid.hashCode ^ amount.hashCode ^ confirmedAt.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiRecordedTransactionIncoming &&
          runtimeType == other.runtimeType &&
          txid == other.txid &&
          amount == other.amount &&
          confirmedAt == other.confirmedAt;
}

class ApiRecordedTransactionOutgoing {
  final String txid;
  final List<String> spentOutpoints;
  final List<ApiRecipient> recipients;
  final int? confirmedAt;
  final Amount change;

  const ApiRecordedTransactionOutgoing({
    required this.txid,
    required this.spentOutpoints,
    required this.recipients,
    this.confirmedAt,
    required this.change,
  });

  String toString() => RustLib.instance.api
          .crateApiStructsApiRecordedTransactionOutgoingToString(
        that: this,
      );

  @override
  int get hashCode =>
      txid.hashCode ^
      spentOutpoints.hashCode ^
      recipients.hashCode ^
      confirmedAt.hashCode ^
      change.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiRecordedTransactionOutgoing &&
          runtimeType == other.runtimeType &&
          txid == other.txid &&
          spentOutpoints == other.spentOutpoints &&
          recipients == other.recipients &&
          confirmedAt == other.confirmedAt &&
          change == other.change;
}

class ApiSetupResult {
  final String walletBlob;
  final String? mnemonic;

  const ApiSetupResult({
    required this.walletBlob,
    this.mnemonic,
  });

  @override
  int get hashCode => walletBlob.hashCode ^ mnemonic.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiSetupResult &&
          runtimeType == other.runtimeType &&
          walletBlob == other.walletBlob &&
          mnemonic == other.mnemonic;
}

class ApiSetupWalletArgs {
  final ApiSetupWalletType setupType;
  final int birthday;
  final String network;

  const ApiSetupWalletArgs({
    required this.setupType,
    required this.birthday,
    required this.network,
  });

  @override
  int get hashCode => setupType.hashCode ^ birthday.hashCode ^ network.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiSetupWalletArgs &&
          runtimeType == other.runtimeType &&
          setupType == other.setupType &&
          birthday == other.birthday &&
          network == other.network;
}

@freezed
sealed class ApiSetupWalletType with _$ApiSetupWalletType {
  const ApiSetupWalletType._();

  const factory ApiSetupWalletType.newWallet() = ApiSetupWalletType_NewWallet;
  const factory ApiSetupWalletType.mnemonic(
    String field0,
  ) = ApiSetupWalletType_Mnemonic;
  const factory ApiSetupWalletType.full(
    String field0,
    String field1,
  ) = ApiSetupWalletType_Full;
  const factory ApiSetupWalletType.watchOnly(
    String field0,
    String field1,
  ) = ApiSetupWalletType_WatchOnly;
}

class ApiSilentPaymentUnsignedTransaction {
  final List<(String, ApiOwnedOutput)> selectedUtxos;
  final List<ApiRecipient> recipients;
  final U8Array32 partialSecret;
  final String? unsignedTx;
  final String network;

  const ApiSilentPaymentUnsignedTransaction({
    required this.selectedUtxos,
    required this.recipients,
    required this.partialSecret,
    this.unsignedTx,
    required this.network,
  });

  @override
  int get hashCode =>
      selectedUtxos.hashCode ^
      recipients.hashCode ^
      partialSecret.hashCode ^
      unsignedTx.hashCode ^
      network.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiSilentPaymentUnsignedTransaction &&
          runtimeType == other.runtimeType &&
          selectedUtxos == other.selectedUtxos &&
          recipients == other.recipients &&
          partialSecret == other.partialSecret &&
          unsignedTx == other.unsignedTx &&
          network == other.network;
}

class ApiWalletStatus {
  final String address;
  final String? network;
  final String changeAddress;
  final BigInt balance;
  final int birthday;
  final int lastScan;
  final Map<String, ApiOwnedOutput> outputs;
  final List<ApiRecordedTransaction> txHistory;

  const ApiWalletStatus({
    required this.address,
    this.network,
    required this.changeAddress,
    required this.balance,
    required this.birthday,
    required this.lastScan,
    required this.outputs,
    required this.txHistory,
  });

  @override
  int get hashCode =>
      address.hashCode ^
      network.hashCode ^
      changeAddress.hashCode ^
      balance.hashCode ^
      birthday.hashCode ^
      lastScan.hashCode ^
      outputs.hashCode ^
      txHistory.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiWalletStatus &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          network == other.network &&
          changeAddress == other.changeAddress &&
          balance == other.balance &&
          birthday == other.birthday &&
          lastScan == other.lastScan &&
          outputs == other.outputs &&
          txHistory == other.txHistory;
}
