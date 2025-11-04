import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const String _pinHashKey = "pin_hash";
  static const String _pinSaltKey = "pin_salt";
  static const String _failedAttemptsKey = "pin_failed_attempts";
  static const String _lockoutUntilKey = "pin_lockout_until";
  
  // Exponential backoff: 2^(attempts-1) seconds
  // attempts: 1=1s, 2=2s, 3=4s, 4=8s, 5=16s, 6=32s, 7=64s, 8=128s, 9=256s, 10=512s, 11=1024s, etc.
  static const int _maxLockoutSeconds = 43200; // 12 hours cap

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

  /// Calculates lockout duration in seconds based on failed attempts
  /// Uses exponential backoff: 2^(attempts-1) seconds, capped at 12 hours
  static int _calculateLockoutSeconds(int failedAttempts) {
    if (failedAttempts == 0) return 0;
    
    // 2^(attempts-1) seconds: 1→1s, 2→2s, 3→4s, 4→8s, 5→16s, etc.
    final seconds = pow(2, failedAttempts - 1).toInt();
    
    // Cap at 12 hours (43200 seconds)
    return seconds > _maxLockoutSeconds ? _maxLockoutSeconds : seconds;
  }

  /// Increments failed attempts and sets lockout timestamp
  static Future<void> incrementFailedAttempts() async {
    final currentAttempts = await getFailedAttempts();
    final newAttempts = currentAttempts + 1;
    
    await _storage.write(key: _failedAttemptsKey, value: newAttempts.toString());
    
    // Calculate lockout duration and set lockout timestamp
    final lockoutSeconds = _calculateLockoutSeconds(newAttempts);
    final lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));
    await _storage.write(
      key: _lockoutUntilKey, 
      value: lockoutUntil.millisecondsSinceEpoch.toString()
    );
  }

  /// Resets failed attempts counter (called on successful PIN verification)
  static Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  /// Gets the timestamp until which the wallet is locked
  static Future<DateTime?> getLockoutUntil() async {
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr == null) return null;
    
    final timestamp = int.tryParse(lockoutStr);
    if (timestamp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Checks if wallet is currently locked due to failed attempts
  /// Returns the remaining lockout duration if locked, null otherwise
  static Future<Duration?> getRemainingLockoutDuration() async {
    final lockoutUntil = await getLockoutUntil();
    if (lockoutUntil == null) return null;
    
    final now = DateTime.now();
    if (now.isBefore(lockoutUntil)) {
      return lockoutUntil.difference(now);
    }
    
    // Lockout period has passed
    return null;
  }

  /// Checks if wallet is currently locked (simpler boolean check)
  static Future<bool> isWalletLocked() async {
    final remaining = await getRemainingLockoutDuration();
    return remaining != null && remaining.inSeconds > 0;
  }
}
