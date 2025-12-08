import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class PinVerificationScreen extends StatefulWidget {
  final VoidCallback onPinVerified;

  const PinVerificationScreen({
    super.key,
    required this.onPinVerified,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    // Check if currently locked out
    final lockoutDuration = await PinService.getRemainingLockoutDuration();
    if (lockoutDuration != null && lockoutDuration.inSeconds > 0) {
      setState(() {
        _errorMessage =
            'Please wait ${_formatDuration(lockoutDuration)} before trying again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isValid = await PinService.verifyPin(_pinController.text);

      if (isValid) {
        // Reset failed attempts on successful verification
        await PinService.resetFailedAttempts();
        widget.onPinVerified();
      } else {
        // Increment failed attempts and get new lockout duration
        await PinService.incrementFailedAttempts();
        final newLockout = await PinService.getRemainingLockoutDuration();

        setState(() {
          _isLoading = false;

          if (newLockout != null && newLockout.inSeconds > 0) {
            _errorMessage =
                'Incorrect PIN. Wait ${_formatDuration(newLockout)} before trying again.';
          } else {
            _errorMessage = 'Incorrect PIN. Please try again.';
          }
        });
        _pinController.clear();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify PIN. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
      }
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      if (seconds > 0 && minutes < 5) {
        // Show seconds only for short durations
        return '$minutes minute${minutes > 1 ? 's' : ''} $seconds second${seconds > 1 ? 's' : ''}';
      }
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final seconds = duration.inSeconds;
      return '$seconds second${seconds > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: danaBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 10.w,
                ),
              ),
              SizedBox(height: 4.h),

              // Title
              Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Bitcoin.black,
                ),
              ),
              SizedBox(height: 2.h),

              // Description
              Text(
                'Enter your PIN to access your wallet',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Bitcoin.neutral7,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),

              // PIN Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Bitcoin.black,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter your PIN',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility : Icons.visibility_off,
                          color: Bitcoin.neutral7,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Bitcoin.neutral5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: danaBlue, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _verifyPin(),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Bitcoin.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Bitcoin.red, size: 4.w),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Bitcoin.red,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 4.h),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: BitcoinButtonFilled(
                  body: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoading ? 'Verifying...' : 'Verify PIN',
                        style: BitcoinTextStyle.body3(Bitcoin.white),
                      ),
                    ],
                  ),
                  onPressed: _isLoading ? null : _verifyPin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
