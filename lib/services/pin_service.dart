import 'dart:math';
import 'package:danawallet/repositories/pin_code_repository.dart';

final PinCodeRepository _pinCodeRepository = PinCodeRepository.instance;

class PinService {
  // Exponential backoff: 2^(attempts-1) seconds
  // attempts: 1=1s, 2=2s, 3=4s, 4=8s, 5=16s, 6=32s, 7=64s, 8=128s, 9=256s, 10=512s, 11=1024s, etc.
  static const int _maxLockoutSeconds = 43200; // 12 hours cap

  /// Sets a new PIN (stores hashed version)
  static Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }

    await _pinCodeRepository.setPinCode(pin);
  }

  /// Verifies a PIN against stored hash
  static Future<bool> verifyPin(String pin) async {
    final storedPin = await _pinCodeRepository.readPinCode();

    if (storedPin == null) {
      return false;
    }

    return storedPin == pin;
  }

  /// Checks if a PIN is currently set
  static Future<bool> isPinSet() async {
    return await _pinCodeRepository.isPinSet();
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
    final currentAttempts = await _pinCodeRepository.getFailedAttempts();
    final newAttempts = currentAttempts + 1;

    await _pinCodeRepository.setFailedAttempts(newAttempts);

    // Calculate lockout duration and set lockout timestamp
    final lockoutSeconds = _calculateLockoutSeconds(newAttempts);
    final lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));

    await _pinCodeRepository.setLockoutUntil(lockoutUntil);
  }

  /// Resets failed attempts counter (called on successful PIN verification)
  static Future<void> resetFailedAttempts() async {
    await _pinCodeRepository.resetFailedAttempts();
  }

  /// Gets the timestamp until which the wallet is locked
  static Future<DateTime?> getLockoutUntil() async {
    return await _pinCodeRepository.getLockoutUntil();
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
