import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MenuScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  const MenuScreen({required this.shop, Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      // Fetch products for this shop.
      final url = Uri.parse('http://127.0.0.1:8000/get-products');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'shop_id': widget.shop['id'].toString()}),
      );
      debugPrint('Menu API Response: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['products'];
          setState(() {
            // Save products as is. (Ensure each product has "availability" and "quantity".)
            products = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to load menu.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load menu. Please try again.';
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    // A product is available if 'availability' equals 1 and quantity > 0.
    final bool isAvailable =
        (product['availability'] == 1) && ((product['quantity'] ?? 0) > 0);
    final double price = double.tryParse(product['price'].toString()) ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        title: Text(
          product['name'] ?? 'Unnamed Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Price: \$${price.toStringAsFixed(2)} | Available: ${isAvailable ? product['quantity'] : 'Out of stock'}',
        ),
        trailing: isAvailable
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop['name'] ?? 'Menu'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
    );
  }
}
