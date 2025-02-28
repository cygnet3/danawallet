// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.3.0.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/chain.dart';
import 'api/history.dart';
import 'api/outputs.dart';
import 'api/stream.dart';
import 'api/structs.dart';
import 'api/wallet.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'frb_generated.dart';
import 'lib.dart';
import 'logger.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'stream.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  CrossPlatformFinalizerArg
      get rust_arc_decrement_strong_count_OwnedOutputsPtr => wire
          ._rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputsPtr;

  CrossPlatformFinalizerArg get rust_arc_decrement_strong_count_SpWalletPtr => wire
      ._rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWalletPtr;

  CrossPlatformFinalizerArg get rust_arc_decrement_strong_count_TxHistoryPtr =>
      wire._rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistoryPtr;

  @protected
  AnyhowException dco_decode_AnyhowException(dynamic raw);

  @protected
  OwnedOutputs
      dco_decode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  SpWallet
      dco_decode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          dynamic raw);

  @protected
  TxHistory
      dco_decode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  OwnedOutputs
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  SpWallet
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          dynamic raw);

  @protected
  TxHistory
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  OwnedOutputs
      dco_decode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  TxHistory
      dco_decode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  OwnedOutputs
      dco_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  SpWallet
      dco_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          dynamic raw);

  @protected
  TxHistory
      dco_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  Map<String, ApiOwnedOutput> dco_decode_Map_String_api_owned_output(
      dynamic raw);

  @protected
  OwnedOutputs
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  SpWallet
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          dynamic raw);

  @protected
  TxHistory
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  RustStreamSink<LogEntry> dco_decode_StreamSink_log_entry_Sse(dynamic raw);

  @protected
  RustStreamSink<ScanProgress> dco_decode_StreamSink_scan_progress_Sse(
      dynamic raw);

  @protected
  RustStreamSink<ScanResult> dco_decode_StreamSink_scan_result_Sse(dynamic raw);

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  ApiAmount dco_decode_api_amount(dynamic raw);

  @protected
  ApiOutputSpendStatus dco_decode_api_output_spend_status(dynamic raw);

  @protected
  ApiOwnedOutput dco_decode_api_owned_output(dynamic raw);

  @protected
  ApiRecipient dco_decode_api_recipient(dynamic raw);

  @protected
  ApiRecordedTransaction dco_decode_api_recorded_transaction(dynamic raw);

  @protected
  ApiRecordedTransactionIncoming dco_decode_api_recorded_transaction_incoming(
      dynamic raw);

  @protected
  ApiRecordedTransactionOutgoing dco_decode_api_recorded_transaction_outgoing(
      dynamic raw);

  @protected
  ApiSetupResult dco_decode_api_setup_result(dynamic raw);

  @protected
  ApiSetupWalletArgs dco_decode_api_setup_wallet_args(dynamic raw);

  @protected
  ApiSetupWalletType dco_decode_api_setup_wallet_type(dynamic raw);

  @protected
  ApiSilentPaymentUnsignedTransaction
      dco_decode_api_silent_payment_unsigned_transaction(dynamic raw);

  @protected
  bool dco_decode_bool(dynamic raw);

  @protected
  OwnedOutputs
      dco_decode_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  TxHistory
      dco_decode_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  ApiAmount dco_decode_box_autoadd_api_amount(dynamic raw);

  @protected
  ApiRecordedTransactionIncoming
      dco_decode_box_autoadd_api_recorded_transaction_incoming(dynamic raw);

  @protected
  ApiRecordedTransactionOutgoing
      dco_decode_box_autoadd_api_recorded_transaction_outgoing(dynamic raw);

  @protected
  ApiSetupWalletArgs dco_decode_box_autoadd_api_setup_wallet_args(dynamic raw);

  @protected
  ApiSilentPaymentUnsignedTransaction
      dco_decode_box_autoadd_api_silent_payment_unsigned_transaction(
          dynamic raw);

  @protected
  int dco_decode_box_autoadd_u_32(dynamic raw);

  @protected
  double dco_decode_f_32(dynamic raw);

  @protected
  int dco_decode_i_32(dynamic raw);

  @protected
  PlatformInt64 dco_decode_i_64(dynamic raw);

  @protected
  List<String> dco_decode_list_String(dynamic raw);

  @protected
  List<ApiRecipient> dco_decode_list_api_recipient(dynamic raw);

  @protected
  List<ApiRecordedTransaction> dco_decode_list_api_recorded_transaction(
      dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw);

  @protected
  List<(String, ApiOwnedOutput)> dco_decode_list_record_string_api_owned_output(
      dynamic raw);

  @protected
  LogEntry dco_decode_log_entry(dynamic raw);

  @protected
  LogLevel dco_decode_log_level(dynamic raw);

  @protected
  String? dco_decode_opt_String(dynamic raw);

  @protected
  OwnedOutputs?
      dco_decode_opt_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          dynamic raw);

  @protected
  TxHistory?
      dco_decode_opt_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          dynamic raw);

  @protected
  int? dco_decode_opt_box_autoadd_u_32(dynamic raw);

  @protected
  (String, ApiOwnedOutput) dco_decode_record_string_api_owned_output(
      dynamic raw);

  @protected
  ScanProgress dco_decode_scan_progress(dynamic raw);

  @protected
  ScanResult dco_decode_scan_result(dynamic raw);

  @protected
  int dco_decode_u_32(dynamic raw);

  @protected
  BigInt dco_decode_u_64(dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  U8Array32 dco_decode_u_8_array_32(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  BigInt dco_decode_usize(dynamic raw);

  @protected
  AnyhowException sse_decode_AnyhowException(SseDeserializer deserializer);

  @protected
  OwnedOutputs
      sse_decode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  SpWallet
      sse_decode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SseDeserializer deserializer);

  @protected
  TxHistory
      sse_decode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  OwnedOutputs
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  SpWallet
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SseDeserializer deserializer);

  @protected
  TxHistory
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  OwnedOutputs
      sse_decode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  TxHistory
      sse_decode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  OwnedOutputs
      sse_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  SpWallet
      sse_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SseDeserializer deserializer);

  @protected
  TxHistory
      sse_decode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  Map<String, ApiOwnedOutput> sse_decode_Map_String_api_owned_output(
      SseDeserializer deserializer);

  @protected
  OwnedOutputs
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  SpWallet
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SseDeserializer deserializer);

  @protected
  TxHistory
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  RustStreamSink<LogEntry> sse_decode_StreamSink_log_entry_Sse(
      SseDeserializer deserializer);

  @protected
  RustStreamSink<ScanProgress> sse_decode_StreamSink_scan_progress_Sse(
      SseDeserializer deserializer);

  @protected
  RustStreamSink<ScanResult> sse_decode_StreamSink_scan_result_Sse(
      SseDeserializer deserializer);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  ApiAmount sse_decode_api_amount(SseDeserializer deserializer);

  @protected
  ApiOutputSpendStatus sse_decode_api_output_spend_status(
      SseDeserializer deserializer);

  @protected
  ApiOwnedOutput sse_decode_api_owned_output(SseDeserializer deserializer);

  @protected
  ApiRecipient sse_decode_api_recipient(SseDeserializer deserializer);

  @protected
  ApiRecordedTransaction sse_decode_api_recorded_transaction(
      SseDeserializer deserializer);

  @protected
  ApiRecordedTransactionIncoming sse_decode_api_recorded_transaction_incoming(
      SseDeserializer deserializer);

  @protected
  ApiRecordedTransactionOutgoing sse_decode_api_recorded_transaction_outgoing(
      SseDeserializer deserializer);

  @protected
  ApiSetupResult sse_decode_api_setup_result(SseDeserializer deserializer);

  @protected
  ApiSetupWalletArgs sse_decode_api_setup_wallet_args(
      SseDeserializer deserializer);

  @protected
  ApiSetupWalletType sse_decode_api_setup_wallet_type(
      SseDeserializer deserializer);

  @protected
  ApiSilentPaymentUnsignedTransaction
      sse_decode_api_silent_payment_unsigned_transaction(
          SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  OwnedOutputs
      sse_decode_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  TxHistory
      sse_decode_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  ApiAmount sse_decode_box_autoadd_api_amount(SseDeserializer deserializer);

  @protected
  ApiRecordedTransactionIncoming
      sse_decode_box_autoadd_api_recorded_transaction_incoming(
          SseDeserializer deserializer);

  @protected
  ApiRecordedTransactionOutgoing
      sse_decode_box_autoadd_api_recorded_transaction_outgoing(
          SseDeserializer deserializer);

  @protected
  ApiSetupWalletArgs sse_decode_box_autoadd_api_setup_wallet_args(
      SseDeserializer deserializer);

  @protected
  ApiSilentPaymentUnsignedTransaction
      sse_decode_box_autoadd_api_silent_payment_unsigned_transaction(
          SseDeserializer deserializer);

  @protected
  int sse_decode_box_autoadd_u_32(SseDeserializer deserializer);

  @protected
  double sse_decode_f_32(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  PlatformInt64 sse_decode_i_64(SseDeserializer deserializer);

  @protected
  List<String> sse_decode_list_String(SseDeserializer deserializer);

  @protected
  List<ApiRecipient> sse_decode_list_api_recipient(
      SseDeserializer deserializer);

  @protected
  List<ApiRecordedTransaction> sse_decode_list_api_recorded_transaction(
      SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  List<(String, ApiOwnedOutput)> sse_decode_list_record_string_api_owned_output(
      SseDeserializer deserializer);

  @protected
  LogEntry sse_decode_log_entry(SseDeserializer deserializer);

  @protected
  LogLevel sse_decode_log_level(SseDeserializer deserializer);

  @protected
  String? sse_decode_opt_String(SseDeserializer deserializer);

  @protected
  OwnedOutputs?
      sse_decode_opt_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          SseDeserializer deserializer);

  @protected
  TxHistory?
      sse_decode_opt_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          SseDeserializer deserializer);

  @protected
  int? sse_decode_opt_box_autoadd_u_32(SseDeserializer deserializer);

  @protected
  (String, ApiOwnedOutput) sse_decode_record_string_api_owned_output(
      SseDeserializer deserializer);

  @protected
  ScanProgress sse_decode_scan_progress(SseDeserializer deserializer);

  @protected
  ScanResult sse_decode_scan_result(SseDeserializer deserializer);

  @protected
  int sse_decode_u_32(SseDeserializer deserializer);

  @protected
  BigInt sse_decode_u_64(SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  U8Array32 sse_decode_u_8_array_32(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  BigInt sse_decode_usize(SseDeserializer deserializer);

  @protected
  void sse_encode_AnyhowException(
      AnyhowException self, SseSerializer serializer);

  @protected
  void
      sse_encode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs self, SseSerializer serializer);

  @protected
  void
      sse_encode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SpWallet self, SseSerializer serializer);

  @protected
  void
      sse_encode_AutoExplicit_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SpWallet self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SpWallet self, SseSerializer serializer);

  @protected
  void
      sse_encode_Auto_Ref_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory self, SseSerializer serializer);

  @protected
  void sse_encode_Map_String_api_owned_output(
      Map<String, ApiOwnedOutput> self, SseSerializer serializer);

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs self, SseSerializer serializer);

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
          SpWallet self, SseSerializer serializer);

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory self, SseSerializer serializer);

  @protected
  void sse_encode_StreamSink_log_entry_Sse(
      RustStreamSink<LogEntry> self, SseSerializer serializer);

  @protected
  void sse_encode_StreamSink_scan_progress_Sse(
      RustStreamSink<ScanProgress> self, SseSerializer serializer);

  @protected
  void sse_encode_StreamSink_scan_result_Sse(
      RustStreamSink<ScanResult> self, SseSerializer serializer);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_api_amount(ApiAmount self, SseSerializer serializer);

  @protected
  void sse_encode_api_output_spend_status(
      ApiOutputSpendStatus self, SseSerializer serializer);

  @protected
  void sse_encode_api_owned_output(
      ApiOwnedOutput self, SseSerializer serializer);

  @protected
  void sse_encode_api_recipient(ApiRecipient self, SseSerializer serializer);

  @protected
  void sse_encode_api_recorded_transaction(
      ApiRecordedTransaction self, SseSerializer serializer);

  @protected
  void sse_encode_api_recorded_transaction_incoming(
      ApiRecordedTransactionIncoming self, SseSerializer serializer);

  @protected
  void sse_encode_api_recorded_transaction_outgoing(
      ApiRecordedTransactionOutgoing self, SseSerializer serializer);

  @protected
  void sse_encode_api_setup_result(
      ApiSetupResult self, SseSerializer serializer);

  @protected
  void sse_encode_api_setup_wallet_args(
      ApiSetupWalletArgs self, SseSerializer serializer);

  @protected
  void sse_encode_api_setup_wallet_type(
      ApiSetupWalletType self, SseSerializer serializer);

  @protected
  void sse_encode_api_silent_payment_unsigned_transaction(
      ApiSilentPaymentUnsignedTransaction self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);

  @protected
  void
      sse_encode_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs self, SseSerializer serializer);

  @protected
  void
      sse_encode_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_api_amount(
      ApiAmount self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_api_recorded_transaction_incoming(
      ApiRecordedTransactionIncoming self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_api_recorded_transaction_outgoing(
      ApiRecordedTransactionOutgoing self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_api_setup_wallet_args(
      ApiSetupWalletArgs self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_api_silent_payment_unsigned_transaction(
      ApiSilentPaymentUnsignedTransaction self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_u_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_f_32(double self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_i_64(PlatformInt64 self, SseSerializer serializer);

  @protected
  void sse_encode_list_String(List<String> self, SseSerializer serializer);

  @protected
  void sse_encode_list_api_recipient(
      List<ApiRecipient> self, SseSerializer serializer);

  @protected
  void sse_encode_list_api_recorded_transaction(
      List<ApiRecordedTransaction> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer);

  @protected
  void sse_encode_list_record_string_api_owned_output(
      List<(String, ApiOwnedOutput)> self, SseSerializer serializer);

  @protected
  void sse_encode_log_entry(LogEntry self, SseSerializer serializer);

  @protected
  void sse_encode_log_level(LogLevel self, SseSerializer serializer);

  @protected
  void sse_encode_opt_String(String? self, SseSerializer serializer);

  @protected
  void
      sse_encode_opt_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
          OwnedOutputs? self, SseSerializer serializer);

  @protected
  void
      sse_encode_opt_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
          TxHistory? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_u_32(int? self, SseSerializer serializer);

  @protected
  void sse_encode_record_string_api_owned_output(
      (String, ApiOwnedOutput) self, SseSerializer serializer);

  @protected
  void sse_encode_scan_progress(ScanProgress self, SseSerializer serializer);

  @protected
  void sse_encode_scan_result(ScanResult self, SseSerializer serializer);

  @protected
  void sse_encode_u_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_u_64(BigInt self, SseSerializer serializer);

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer);

  @protected
  void sse_encode_u_8_array_32(U8Array32 self, SseSerializer serializer);

  @protected
  void sse_encode_unit(void self, SseSerializer serializer);

  @protected
  void sse_encode_usize(BigInt self, SseSerializer serializer);
}

// Section: wire_class

class RustLibWire implements BaseWire {
  factory RustLibWire.fromExternalLibrary(ExternalLibrary lib) =>
      RustLibWire(lib.ffiDynamicLibrary);

  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  RustLibWire(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  void
      rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
      ptr,
    );
  }

  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_danawallet_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs');
  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs =
      _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputsPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void
      rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs(
      ptr,
    );
  }

  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_danawallet_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs');
  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputs =
      _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerOwnedOutputsPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void
      rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
      ptr,
    );
  }

  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWalletPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_danawallet_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet');
  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet =
      _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWalletPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void
      rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet(
      ptr,
    );
  }

  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWalletPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_danawallet_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet');
  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWallet =
      _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSpWalletPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void
      rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
      ptr,
    );
  }

  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistoryPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_danawallet_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory');
  late final _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory =
      _rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistoryPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void
      rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory(
      ptr,
    );
  }

  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistoryPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'frbgen_danawallet_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory');
  late final _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistory =
      _rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerTxHistoryPtr
          .asFunction<void Function(ffi.Pointer<ffi.Void>)>();
}
