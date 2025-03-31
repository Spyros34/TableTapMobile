import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'main_screen.dart'; // Import MainScreen
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> _loginUser() async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = 'http://127.0.0.1:8000/customer/login';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('customer')) {
          final customerData = responseData['customer'];

          // Save customer data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('customer_id', customerData['id'].toString());
          await prefs.setString('customer_name', customerData['name']);
          await prefs.setString('customer_username', customerData['username']);

          // Navigate to MainScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          _showErrorDialog('Unexpected response format.');
        }
      } else {
        final responseData = json.decode(response.body);
        _showErrorDialog(responseData['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Connection error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                constraints:
                                    const BoxConstraints(maxWidth: 400),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Welcome Back!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Log in to your account',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    CustomTextField(
                                      controller: usernameController,
                                      hintText: 'Username',
                                      icon: Icons.person_outline,
                                    ),
                                    const SizedBox(height: 20),
                                    CustomTextField(
                                      controller: passwordController,
                                      hintText: 'Password',
                                      icon: Icons.lock_outline,
                                      obscureText: obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    ElevatedButton(
                                      onPressed: _loginUser,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    // Forgot Password Button
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ForgotPasswordScreen()),
                                        );
                                      },
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SignupScreen()),
                                        );
                                      },
                                      child: const Text(
                                        "Don't have an account? Sign up",
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
