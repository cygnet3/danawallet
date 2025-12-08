import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/pin/pin_setup_screen.dart';
import 'package:danawallet/screens/pin/pin_verification_screen.dart';
import 'package:danawallet/services/pin_service.dart';
import 'package:flutter/material.dart';

// In our current setup, the home screen is always the protected screen.
// In the future, we can make this adjustable by passing the protected screen in the constructor.
const Widget _protectedScreen = HomeScreen();

class PinGuard extends StatefulWidget {
  const PinGuard({super.key});

  @override
  State<PinGuard> createState() => _PinGuardState();
}

class _PinGuardState extends State<PinGuard> {
  bool _isPinSet = false;
  bool _isLoading = true;
  bool _isPinVerified = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final isPinSet = await PinService.isPinSet();
    setState(() {
      _isPinSet = isPinSet;
      _isLoading = false;
    });
  }

  void _onPinSet() {
    setState(() {
      _isPinSet = true;
      _isPinVerified = true; // we just set the pin, so it's verified
    });
  }

  void _onPinVerified() {
    setState(() {
      _isPinVerified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If PIN is verified, return the protected screen
    if (_isPinVerified) {
      return _protectedScreen;
    }

    // If no PIN is set, show PIN setup
    if (!_isPinSet) {
      return PinSetupScreen(onPinSet: _onPinSet);
    }

    // if PIN is set but not verfied, show PIN verification screen
    return PinVerificationScreen(
      onPinVerified: _onPinVerified,
    );
  }
}
