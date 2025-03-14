// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.9.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../../frb_generated.dart';
import '../wallet.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;
part 'setup.freezed.dart';

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<WalletSetupResult>>
abstract class WalletSetupResult implements RustOpaqueInterface {
  String? get mnemonic;

  ApiScanKey get scanKey;

  ApiSpendKey get spendKey;

  set mnemonic(String? mnemonic);

  set scanKey(ApiScanKey scanKey);

  set spendKey(ApiSpendKey spendKey);
}

class WalletSetupArgs {
  final WalletSetupType setupType;
  final String network;

  const WalletSetupArgs({
    required this.setupType,
    required this.network,
  });

  @override
  int get hashCode => setupType.hashCode ^ network.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletSetupArgs &&
          runtimeType == other.runtimeType &&
          setupType == other.setupType &&
          network == other.network;
}

@freezed
sealed class WalletSetupType with _$WalletSetupType {
  const WalletSetupType._();

  const factory WalletSetupType.newWallet() = WalletSetupType_NewWallet;
  const factory WalletSetupType.mnemonic(
    String field0,
  ) = WalletSetupType_Mnemonic;
  const factory WalletSetupType.full(
    String field0,
    String field1,
  ) = WalletSetupType_Full;
  const factory WalletSetupType.watchOnly(
    String field0,
    String field1,
  ) = WalletSetupType_WatchOnly;
}
