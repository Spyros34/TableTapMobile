import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'menu_screen.dart'; // Screen to show the shop's menu

class ShopDirectoryScreen extends StatefulWidget {
  const ShopDirectoryScreen({Key? key}) : super(key: key);

  @override
  _ShopDirectoryScreenState createState() => _ShopDirectoryScreenState();
}

class _ShopDirectoryScreenState extends State<ShopDirectoryScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> shops = [];

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    try {
      // Use your API endpoint; here we assume it's defined in your API routes
      final url = Uri.parse('http://127.0.0.1:8000/get-shops');
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['shops'];
          setState(() {
            shops = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to load shops.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load shops. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Directory'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop details
                            Text(
                              shop['brand'] ?? 'Unnamed Shop',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '${shop['address'] ?? ''}, ${shop['city'] ?? ''}, ${shop['region'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Phone: ${shop['phone_number']?.toString() ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Type: ${shop['type'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to the shop menu screen with the shop id
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MenuScreen(
                                        shop: shop,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text('View Menu'),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
