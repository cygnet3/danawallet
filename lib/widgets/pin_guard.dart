import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/onboarding/introduction.dart';
import 'package:danawallet/screens/pin/pin_setup_screen.dart';
import 'package:danawallet/screens/pin/pin_verification_screen.dart';
import 'package:danawallet/services/pin_service.dart';
import 'package:flutter/material.dart';

class PinGuard extends StatefulWidget {
  final bool walletLoaded;

  const PinGuard({super.key, required this.walletLoaded});

  @override
  State<PinGuard> createState() => _PinGuardState();
}

class _PinGuardState extends State<PinGuard> {
  bool _isPinSet = false;
  bool _isLoading = true;
  bool _pinVerified = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    if (widget.walletLoaded) {
      final pinSet = await PinService.isPinSet();
      setState(() {
        _isPinSet = pinSet;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPinSet() {
    setState(() {
      _isPinSet = true;
    });
  }

  void _onPinVerified() {
    setState(() {
      _pinVerified = true;
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

    // If no wallet is loaded, show introduction
    if (!widget.walletLoaded) {
      return const IntroductionScreen();
    }

    // If wallet is loaded and PIN is verified, show home screen
    if (_pinVerified) {
      return const HomeScreen();
    }

    // If wallet is loaded but no PIN is set, show PIN setup
    if (!_isPinSet) {
      return PinSetupScreen(onPinSet: _onPinSet);
    }

    // If wallet is loaded and PIN is set, show PIN verification
    return PinVerificationScreen(
      onPinVerified: _onPinVerified,
    );
  }
}
