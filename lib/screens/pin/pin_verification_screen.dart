import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class PinVerificationScreen extends StatefulWidget {
  final VoidCallback onPinVerified;
  final VoidCallback onWalletCleared;

  const PinVerificationScreen({
    super.key,
    required this.onPinVerified,
    required this.onWalletCleared,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePin = true;
  int _attempts = 0;
  bool _isWalletLocked = false;

  @override
  void initState() {
    super.initState();
    _checkWalletLockStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkWalletLockStatus() async {
    final isLocked = await PinService.isWalletLocked();
    final attempts = await PinService.getFailedAttempts();
    
    setState(() {
      _isWalletLocked = isLocked;
      _attempts = attempts;
    });
  }

  Future<void> _verifyPin() async {
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
        // Increment failed attempts
        final maxAttemptsReached = await PinService.incrementFailedAttempts();
        
        setState(() {
          _attempts++;
          _isLoading = false;
          
          if (maxAttemptsReached) {
            _isWalletLocked = true;
            _errorMessage = 'Too many failed attempts. Wallet data has been cleared for security.';
          } else {
            _errorMessage = 'Incorrect PIN. ${5 - _attempts} attempts remaining.';
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

  Future<void> _clearWalletAndRestore() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wallet Data'),
        content: const Text(
          'This will permanently delete all wallet data. You will need to restore from backup. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Wallet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear wallet data and notify parent
      await PinService.clearWalletData();
      widget.onWalletCleared();
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
              
              // Verify Button or Clear Wallet Button
              SizedBox(
                width: double.infinity,
                child: _isWalletLocked
                    ? BitcoinButtonFilled(
                        body: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Clear Wallet & Restore',
                              style: BitcoinTextStyle.body3(Bitcoin.white),
                            ),
                          ],
                        ),
                        onPressed: _clearWalletAndRestore,
                      )
                    : BitcoinButtonFilled(
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
