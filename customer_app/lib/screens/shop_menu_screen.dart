import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShopMenuScreen extends StatefulWidget {
  final String shopId;

  const ShopMenuScreen({required this.shopId, Key? key}) : super(key: key);

  @override
  _ShopMenuScreenState createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> products = [];
  String? errorMessage;

  List<String> userCards = [];
  String selectedPaymentMethod = "Cash";
  String selectedCard = "";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/get-products');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'shop_id': widget.shopId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<Map<String, dynamic>> fetchedProducts =
              List<Map<String, dynamic>>.from(responseData['products']);

          setState(() {
            products = fetchedProducts.map((product) {
              return {
                ...product,
                'count': 0,
              };
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                responseData['message'] ?? 'Failed to fetch products.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch products. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCreditCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('customer_id');

      if (customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer ID not found. Please log in again.'),
          ),
        );
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/get-credit-cards');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'customer_id': customerId}),
      );

      debugPrint('Credit Card API Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> fetchedCards = responseData['credit_cards'];

          setState(() {
            userCards = fetchedCards.map((card) => card.toString()).toList();
            selectedCard = userCards.isNotEmpty ? userCards.first : "";
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'No cards found.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch credit cards.')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching credit cards: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching credit cards.')),
      );
    }
  }

  void _addToCart(int index) {
    setState(() {
      products[index]['count'] += 1;
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (products[index]['count'] > 0) {
        products[index]['count'] -= 1;
      }
    });
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final bool isAvailable = product['quantity'] > 0;
    final int productCount = product['count'];
    final double price = double.tryParse(product['price'].toString()) ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: isAvailable ? Colors.teal.shade50 : Colors.grey.shade300,
              ),
              child: Center(
                child: Icon(
                  isAvailable ? Icons.fastfood : Icons.block,
                  color: isAvailable ? Colors.teal : Colors.grey,
                  size: 40.0,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    product['description'] ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: isAvailable
                          ? Colors.grey.shade700
                          : Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.teal : Colors.grey,
                        ),
                      ),
                      if (isAvailable)
                        Row(
                          children: [
                            if (productCount > 0)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeFromCart(index),
                              ),
                            Text(
                              productCount.toString(),
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Colors.teal,
                              ),
                              onPressed: () => _addToCart(index),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartDialog() async {
    await _fetchCreditCards(); // Ensure credit cards are fetched before showing the dialog

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final cartItems =
            products.where((product) => product['count'] > 0).toList();
        final double totalPrice = cartItems.fold(
          0,
          (sum, item) =>
              sum +
              (item['count'] *
                  (double.tryParse(item['price'].toString()) ?? 0.0)),
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your Cart',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final product = cartItems[index];
                        final double itemPrice =
                            (double.tryParse(product['price'].toString()) ??
                                    0.0) *
                                product['count'];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: Text(
                                '${product['count']}x',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.teal),
                              ),
                            ),
                            title: Text(
                              product['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('\$${itemPrice.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  const Text(
                    'Payment Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('Cash'),
                    leading: Radio<String>(
                      value: 'Cash',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setModalState(() {
                          selectedPaymentMethod = value!;
                          selectedCard = ""; // Reset card selection for cash
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Card'),
                    leading: Radio<String>(
                      value: 'Card',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setModalState(() {
                          selectedPaymentMethod = value!;
                          selectedCard =
                              userCards.isNotEmpty ? userCards.first : "";
                        });
                      },
                    ),
                  ),
                  if (selectedPaymentMethod == 'Card' &&
                      userCards.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Select a Card',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedCard,
                      hint: const Text('Select a Card'),
                      items: userCards
                          .map((card) => DropdownMenuItem(
                                value: card,
                                child: Text(card),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedCard = value!;
                        });
                      },
                    ),
                  ],
                  if (selectedPaymentMethod == 'Card' && userCards.isEmpty)
                    const Text(
                      'No saved cards available. Please add a card.',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _placeOrder(totalPrice, cartItems);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    child: const Center(
                      child: Text(
                        'Place Order',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _placeOrder(
      double totalPrice, List<Map<String, dynamic>> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('customer_id');

      if (customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer ID not found. Please log in again.'),
          ),
        );
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/place-order');

      // Ensure each item has product_id, quantity, and price
      final List<Map<String, dynamic>> formattedItems = cartItems.map((item) {
        return {
          'product_id': item.containsKey('id')
              ? item['id']
              : item['product_id'], // Ensure product_id is extracted correctly
          'quantity': item['count'],
          'price': item['price']
        };
      }).toList();

      final requestBody = json.encode({
        'customer_id': customerId,
        'shop_id': widget.shopId,
        'total_price': totalPrice,
        'payment_method': selectedPaymentMethod,
        'selected_card': selectedPaymentMethod == 'Card' ? selectedCard : null,
        'items': formattedItems, // Properly formatted items list
      });

      debugPrint('Sending Order Payload: $requestBody'); // Log the request

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('Order API Response: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
          ),
        );
        setState(() {
          for (var item in products) {
            item['count'] = 0; // Reset cart
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['message'] ?? 'Order failed. Please try again.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Order error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error placing order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _showCartDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index], index);
                  },
                ),
    );
  }
}
