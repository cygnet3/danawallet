import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onPinSet;

  const PinSetupScreen({super.key, required this.onPinSet});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (_pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await PinService.setPin(_pinController.text);
      widget.onPinSet();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to set PIN. Please try again.';
        _isLoading = false;
      });
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
                'Set up PIN',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Bitcoin.black,
                ),
              ),
              SizedBox(height: 2.h),

              // Description
              Text(
                'Create a 4-digit PIN to secure your wallet',
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
                    'Enter PIN',
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
                      hintText: 'Enter 4-6 digit PIN',
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
                  ),
                ],
              ),
              SizedBox(height: 3.h),

              // Confirm PIN Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm PIN',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Bitcoin.black,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: _obscureConfirmPin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Confirm your PIN',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPin
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Bitcoin.neutral7,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPin = !_obscureConfirmPin;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Bitcoin.neutral5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: danaBlue, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Bitcoin.red.withOpacity(0.1),
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

              // Setup Button
              SizedBox(
                width: double.infinity,
                child: BitcoinButtonFilled(
                  body: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoading ? 'Setting up...' : 'Set PIN',
                        style: BitcoinTextStyle.body3(Bitcoin.white),
                      ),
                    ],
                  ),
                  onPressed: _isLoading ? null : _setupPin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
