import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const String _pinHashKey = "pin_hash";
  static const String _pinSaltKey = "pin_salt";
  static const String _failedAttemptsKey = "pin_failed_attempts";
  static const int _maxFailedAttempts = 5;

  /// Generates a random salt for PIN hashing
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashes a PIN with salt using SHA-256
  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sets a new PIN (stores hashed version)
  static Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }
    
    final salt = _generateSalt();
    final hashedPin = _hashPin(pin, salt);
    
    await _storage.write(key: _pinHashKey, value: hashedPin);
    await _storage.write(key: _pinSaltKey, value: salt);
  }

  /// Verifies a PIN against stored hash
  static Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final storedSalt = await _storage.read(key: _pinSaltKey);
    
    if (storedHash == null || storedSalt == null) {
      return false;
    }
    
    final hashedPin = _hashPin(pin, storedSalt);
    return hashedPin == storedHash;
  }

  /// Checks if a PIN is currently set
  static Future<bool> isPinSet() async {
    final storedHash = await _storage.read(key: _pinHashKey);
    return storedHash != null;
  }

  /// Removes the stored PIN
  static Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  /// Changes an existing PIN (requires current PIN verification)
  static Future<bool> changePin(String currentPin, String newPin) async {
    if (newPin.length < 4) {
      throw ArgumentError('New PIN must be at least 4 digits');
    }
    
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      return false;
    }
    
    await setPin(newPin);
    return true;
  }

  /// Gets the current number of failed attempts
  static Future<int> getFailedAttempts() async {
    final attempts = await _storage.read(key: _failedAttemptsKey);
    return attempts != null ? int.tryParse(attempts) ?? 0 : 0;
  }

  /// Increments failed attempts and returns true if max attempts reached
  static Future<bool> incrementFailedAttempts() async {
    final currentAttempts = await getFailedAttempts();
    final newAttempts = currentAttempts + 1;
    
    await _storage.write(key: _failedAttemptsKey, value: newAttempts.toString());
    
    return newAttempts >= _maxFailedAttempts;
  }

  /// Resets failed attempts counter (called on successful PIN verification)
  static Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
  }

  /// Clears all wallet data (called when max attempts reached)
  static Future<void> clearWalletData() async {
    // Clear PIN data
    await removePin();
    
    // Clear failed attempts counter
    await _storage.delete(key: _failedAttemptsKey);
    
    // Note: Wallet data clearing will be handled by the calling code
    // using WalletRepository.reset() and SettingsRepository.resetAll()
  }

  /// Checks if wallet is locked due to too many failed attempts
  static Future<bool> isWalletLocked() async {
    final attempts = await getFailedAttempts();
    return attempts >= _maxFailedAttempts;
  }
}
