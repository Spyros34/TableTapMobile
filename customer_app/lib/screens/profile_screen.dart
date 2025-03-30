import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  String? errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controllers for customer information
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController tkController = TextEditingController();

  // Controllers for changing password
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Payment cards controllers and list
  List<String> cards = [];
  final TextEditingController newCardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchCards();
  }

  // Helper method to build a styled TextFormField with validation
  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _fetchProfile() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id');
    if (customerId == null) {
      setState(() {
        errorMessage = 'Customer not logged in.';
        isLoading = false;
      });
      return;
    }
    final url = Uri.parse('http://127.0.0.1:8000/get-profile');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'customer_id': customerId}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final customer = data['customer'];
        setState(() {
          nameController.text = customer['name'] ?? '';
          surnameController.text = customer['surname'] ?? '';
          usernameController.text = customer['username'] ?? '';
          emailController.text = customer['email'] ?? '';
          addressController.text = customer['address'] ?? '';
          cityController.text = customer['city'] ?? '';
          regionController.text = customer['region'] ?? '';
          tkController.text = customer['tk'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Failed to load profile.';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = 'Failed to load profile.';
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
        'customer_id'); // or prefs.clear() if you want to remove all stored data
    // Navigate to the login screen (ensure you have defined the route '/login' in your MaterialApp)
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _changePassword() async {
    // Validate the password change form first
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id');
    if (customerId == null) return;
    final url = Uri.parse('http://127.0.0.1:8000/change-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': customerId,
          'current_password': currentPasswordController.text,
          'new_password': newPasswordController.text,
        }),
      );
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(data['message'] ?? 'Password changed successfully.')),
          );
          // Clear password fields
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected response format.')),
          );
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(data['message'] ?? 'Current password is incorrect.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchCards() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id');
    if (customerId == null) return;
    final url = Uri.parse('http://127.0.0.1:8000/get-credit-cards');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'customer_id': customerId}),
    );
    debugPrint('Credit Card API Response: ${response.body}');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          // Expecting a list of card numbers
          cards = List<String>.from(data['credit_cards']);
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id');
    if (customerId == null) return;
    final url = Uri.parse('http://127.0.0.1:8000/update-profile');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': customerId,
          'name': nameController.text,
          'surname': surnameController.text,
          'username': usernameController.text,
          'email': emailController.text,
          'address': addressController.text,
          'city': cityController.text,
          'region': regionController.text,
          'tk': tkController.text,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Profile updated.')));
        } catch (e) {
          // JSON decoding failed; response might be HTML or malformed
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unexpected response format.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addCard() async {
    // Validate the card number manually using the same regex
    final cardNumber = newCardController.text;
    if (cardNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card number is required.')));
      return;
    }
    if (!RegExp(r'^\d{13,19}$').hasMatch(cardNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Card number must be between 13 and 19 digits.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id');
    if (customerId == null) return;
    final url = Uri.parse('http://127.0.0.1:8000/add-card');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': customerId,
        'card_number': cardNumber,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      await _fetchCards();
      newCardController.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Card added.')));
  }

  Future<void> _deleteCard(String cardNumber) async {
    // Check if there's only one card left
    if (cards.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one card must remain.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id');
    if (customerId == null) return;
    final url = Uri.parse('http://127.0.0.1:8000/delete-card');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': customerId,
        'card_number': cardNumber,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      await _fetchCards();
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Card deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Profile'), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Personal Information Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal),
                            ),
                            const SizedBox(height: 16),
                            _buildTextFormField(
                              label: 'Name',
                              controller: nameController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required.';
                                }
                                if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(value)) {
                                  return 'Name can only contain letters and spaces.';
                                }
                                if (value.length > 255) {
                                  return 'Name must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'Surname',
                              controller: surnameController,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !RegExp(r'^[A-Za-z\s]*$').hasMatch(value)) {
                                  return 'Surname can only contain letters and spaces.';
                                }
                                if (value != null && value.length > 255) {
                                  return 'Surname must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'Username',
                              controller: usernameController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username is required.';
                                }
                                // Check that the username only contains letters, numbers, dash (-), and dot (.)
                                if (!RegExp(r'^[A-Za-z0-9\.\-]+$')
                                    .hasMatch(value)) {
                                  return 'Username can only contain letters, numbers, dash (-) and dot (.)';
                                }
                                if (value.length > 255) {
                                  return 'Username must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'Email',
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required.';
                                }
                                if (!RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value)) {
                                  return 'Enter a valid email.';
                                }
                                if (value.length > 255) {
                                  return 'Email must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'Address',
                              controller: addressController,
                              validator: (value) {
                                if (value != null && value.length > 255) {
                                  return 'Address must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'City',
                              controller: cityController,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !RegExp(r'^[A-Za-z\s]+$').hasMatch(value)) {
                                  return 'City can only contain letters and spaces.';
                                }
                                if (value != null && value.length > 255) {
                                  return 'City must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'Region',
                              controller: regionController,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !RegExp(r'^[A-Za-z\s]+$').hasMatch(value)) {
                                  return 'Region can only contain letters and spaces.';
                                }
                                if (value != null && value.length > 255) {
                                  return 'Region must be less than 255 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'TK',
                              controller: tkController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'TK must contain only digits.';
                                }
                                if (value != null && value.length > 10) {
                                  return 'TK must be less than 10 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 12.0),
                                ),
                                child: const Text('Update Profile',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Payment Cards Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Cards',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cards.length,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return ListTile(
                                  leading: const Icon(Icons.credit_card,
                                      color: Colors.teal),
                                  title: Text(card),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteCard(card),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              label: 'New Card Number',
                              controller: newCardController,
                              keyboardType: TextInputType.number,
                              // Adding validator to ensure only digits and length between 13 and 19
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Card number is required.';
                                }
                                if (!RegExp(r'^\d{13,19}$').hasMatch(value)) {
                                  return 'Card number must be between 13 and 19 digits.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ElevatedButton(
                                onPressed: _addCard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 12.0),
                                ),
                                child: const Text('Add Card',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Change Password Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Form(
                        key: _passwordFormKey,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Change Password',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                label: 'Current Password',
                                controller: currentPasswordController,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Current password is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextFormField(
                                label: 'New Password',
                                controller: newPasswordController,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'New password is required.';
                                  }
                                  if (value.length < 8) {
                                    return 'New password must be at least 8 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextFormField(
                                label: 'Confirm New Password',
                                controller: confirmPasswordController,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please confirm your new password.';
                                  }
                                  if (value != newPasswordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0, vertical: 12.0),
                                  ),
                                  child: const Text('Change Password',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red, // or another color to signify sign out
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                      child: const Text('Sign Out',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
