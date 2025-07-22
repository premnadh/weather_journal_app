import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _isLoading = false;
  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final auth = context.read<AuthProvider>();
    bool isSet = await auth.isPinSet();
    setState(() {
      _isPinSet = isSet;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    String pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _error = 'PIN must be at least 4 digits.';
        _isLoading = false;
      });
      return;
    }
    if (_isPinSet) {
      bool success = await auth.verifyPin(pin);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _error = 'Incorrect PIN. Try again.';
          _isLoading = false;
        });
      }
    } else {
      await auth.setPin(pin);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isPinSet ? 'Enter PIN' : 'Set PIN')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: _isPinSet ? 'Enter your PIN' : 'Set a new PIN',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleSubmit(),
                onChanged: (_) {
                  // Reset session timer on typing PIN
                  resetSessionTimerCallback?.call();
                },
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleSubmit,
                      child: Text(_isPinSet ? 'Unlock' : 'Set PIN'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
