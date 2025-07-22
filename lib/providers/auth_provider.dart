import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  static const _pinKey = 'user_pin';
  static const _sessionKey = 'session_active';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Session timeout logic
  static const Duration sessionTimeout = Duration(seconds: 30);
  DateTime? _lastActivity;
  DateTime? get lastActivity => _lastActivity;

  Future<bool> isPinSet() async {
    String? pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    _isAuthenticated = true;
    await _storage.write(key: _sessionKey, value: 'true');
    _updateActivity();
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    String? storedPin = await _storage.read(key: _pinKey);
    if (storedPin == pin) {
      _isAuthenticated = true;
      await _storage.write(key: _sessionKey, value: 'true');
      _updateActivity();
      notifyListeners();
      return true;
    } else {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    await _storage.write(key: _sessionKey, value: 'false');
    notifyListeners();
  }

  // Force logout (for session timeout or auto-lock)
  Future<void> forceLogout() async {
    _isAuthenticated = false;
    await _storage.write(key: _sessionKey, value: 'false');
    notifyListeners();
  }

  Future<bool> isSessionActive() async {
    String? session = await _storage.read(key: _sessionKey);
    return session == 'true';
  }

  // Update last activity timestamp
  void updateActivity() {
    _updateActivity();
  }

  void _updateActivity() {
    _lastActivity = DateTime.now();
  }

  // Check if session has timed out
  bool isSessionTimedOut() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) > sessionTimeout;
  }
}
