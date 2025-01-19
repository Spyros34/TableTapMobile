import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;

  // Getter to check if the user is authenticated
  bool get isAuthenticated => _isAuthenticated;

  // Getter for the user's email
  String? get userEmail => _userEmail;

  // Login method
  Future<void> login(String email, String password) async {
    try {
      // Simulating an API call (Replace this with your real API logic)
      await Future.delayed(Duration(seconds: 2));

      // Validate email and password (mock logic for demonstration)
      if (email == 'customer@example.com' && password == 'password123') {
        _isAuthenticated = true;
        _userEmail = email;
        notifyListeners();
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Signup method
  Future<void> signup(String email, String password) async {
    try {
      // Simulating an API call (Replace this with your real API logic)
      await Future.delayed(Duration(seconds: 2));

      // Assuming signup is successful
      _isAuthenticated = true;
      _userEmail = email;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Logout method
  void logout() {
    _isAuthenticated = false;
    _userEmail = null;
    notifyListeners();
  }

  // Reset Password method
  Future<void> resetPassword(String email) async {
    try {
      // Simulating an API call (Replace this with your real API logic)
      await Future.delayed(Duration(seconds: 2));
      // Assuming reset password is successful
      debugPrint('Password reset link sent to $email');
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
