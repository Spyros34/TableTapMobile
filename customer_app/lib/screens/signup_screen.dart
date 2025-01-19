import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController creditCardController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController tkController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  Map<String, String> errorMessages = {};

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessages = {};
    });

    final String name = nameController.text.trim();
    final String surname = surnameController.text.trim();
    final String username = usernameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();
    final String creditCard = creditCardController.text.trim();
    final String address = addressController.text.trim();
    final String city = cityController.text.trim();
    final String region = regionController.text.trim();
    final String tk = tkController.text.trim();

    final url = 'http://127.0.0.1:8000/customer/register'; // Backend route
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'name': name,
          'surname': surname,
          'username': username,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
          'credit_card': creditCard,
          'address': address,
          'city': city,
          'region': region,
          'tk': tk,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) {
        _showSuccessDialog('Account created successfully! You can now log in.');
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        if (responseData['errors'] != null) {
          setState(() {
            errorMessages =
                (responseData['errors'] as Map<String, dynamic>).map(
              (key, value) =>
                  MapEntry(key, (value as List<dynamic>).join('\n')),
            );
          });
        }
      } else {
        _showErrorDialog('Registration failed. Please try again.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('An error occurred: $e');
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context)
                  .pushReplacementNamed('/login'); // Redirect to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget buildErrorText(String field) {
    if (errorMessages.containsKey(field)) {
      return Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Text(
          errorMessages[field]!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create a new account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          buildTextField('Name', nameController, 'name'),
                          const SizedBox(height: 15),
                          buildTextField(
                              'Surname', surnameController, 'surname'),
                          const SizedBox(height: 15),
                          buildTextField(
                              'Username', usernameController, 'username'),
                          const SizedBox(height: 15),
                          buildTextField('Email', emailController, 'email',
                              isEmail: true),
                          const SizedBox(height: 15),
                          buildPasswordField(
                              'Password', passwordController, 'password'),
                          const SizedBox(height: 15),
                          buildPasswordField(
                              'Confirm Password',
                              confirmPasswordController,
                              'password_confirmation'),
                          const SizedBox(height: 15),
                          buildTextField('Credit Card', creditCardController,
                              'credit_card',
                              isNumeric: true),
                          const SizedBox(height: 15),
                          buildTextField(
                              'Address', addressController, 'address'),
                          const SizedBox(height: 15),
                          buildTextField('City', cityController, 'city'),
                          const SizedBox(height: 15),
                          buildTextField('Region', regionController, 'region'),
                          const SizedBox(height: 15),
                          buildTextField('TK', tkController, 'tk',
                              isNumeric: true),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _registerUser,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, String field,
      {bool isEmail = false, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            if (isNumeric && !RegExp(r'^\d+$').hasMatch(value)) {
              return '$label must contain only numbers';
            }
            return null;
          },
        ),
        buildErrorText(field),
      ],
    );
  }

  Widget buildPasswordField(
      String label, TextEditingController controller, String field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            if (value.length < 8) {
              return '$label must be at least 8 characters';
            }
            return null;
          },
        ),
        buildErrorText(field),
      ],
    );
  }
}
