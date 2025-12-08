import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// secure storage
const String _keyPinCode = "pincode";

// non secure storage
// this will likely replaced by an sql database in the future
const String _keyPinCodeFailedAttempts = "pincodefailedattempts";
const String _keyPinCodeLockoutUntil = "pincodelockoutuntil";

class PinCodeRepository {
  final secureStorage = const FlutterSecureStorage();
  final nonSecureStorage = SharedPreferencesAsync();

  // private constructor
  PinCodeRepository._();

  // singleton class
  static final instance = PinCodeRepository._();

  Future<void> reset() async {
    // delete secure storage
    await secureStorage.deleteAll();

    // delete non secure storage
    await nonSecureStorage.clear(allowList: {
      _keyPinCodeFailedAttempts,
      _keyPinCodeLockoutUntil,
    });
  }

  Future<String?> readPinCode() async {
    return await secureStorage.read(key: _keyPinCode);
  }

  Future<void> setPinCode(String pinCode) async {
    await secureStorage.write(key: _keyPinCode, value: pinCode);
  }

  Future<bool> isPinSet() async {
    return (await secureStorage.read(key: _keyPinCode)) != null;
  }

  Future<int> getFailedAttempts() async {
    return (await nonSecureStorage.getInt(_keyPinCodeFailedAttempts)) ?? 0;
  }

  Future<void> setFailedAttempts(int value) async {
    await nonSecureStorage.setInt(_keyPinCodeFailedAttempts, value);
  }

  Future<DateTime?> getLockoutUntil() async {
    final millisSinceEpoch =
        await nonSecureStorage.getInt(_keyPinCodeLockoutUntil);
    return (millisSinceEpoch == null)
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
  }

  Future<void> setLockoutUntil(DateTime value) async {
    await nonSecureStorage.setInt(
        _keyPinCodeLockoutUntil, value.millisecondsSinceEpoch);
  }

  Future<void> resetFailedAttempts() async {
    await nonSecureStorage
        .clear(allowList: {_keyPinCodeFailedAttempts, _keyPinCodeLockoutUntil});
  }
}
