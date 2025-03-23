import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'shop_menu_screen.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QRScanScreen extends StatefulWidget {
  @override
  _QRScanScreenState createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Decode QR code result
  Future<void> _onCodeScanned(String result) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Scanned QR Code Result: $result');

      final uri = Uri.tryParse(result);
      if (uri == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Invalid QR Code format.';
        });
        return;
      }

      final tableId = uri.queryParameters['id'];
      final shopId = uri.queryParameters['shop_id'];

      print('Parsed tableId: $tableId, shopId: $shopId');

      if (tableId == null || shopId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Invalid QR Code. Missing table ID or shop ID.';
        });
        return;
      }

      // Fetch shop and table data
      await _fetchShopAndTableData(shopId, tableId);
    } catch (e) {
      print('Error decoding QR Code: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to decode QR code. Please try again.';
      });
    }
  }

  // Fetch shop and table data from Laravel
  Future<void> _fetchShopAndTableData(String shopId, String tableId) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/scan-qr');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'shop_id': shopId, 'table_id': tableId}),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final shopData = responseData['shop'];
          final tableData = responseData['table'];

          _showConfirmationDialog(
            shopName: shopData['name'],
            shopLocation: shopData['location'],
            shopPhone: shopData['phone']
                .toString(), // Convert to string if it's an integer
            tableNumber: tableData['table_num'],
            shopId: shopId, // Pass shopId to navigate to the menu
            tableId: tableId,
          );
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Invalid QR Code.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to retrieve shop data. Please try again.';
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Pick QR code from gallery
  Future<void> _pickQRCodeFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final String? result =
            await QrCodeToolsPlugin.decodeFrom(pickedImage.path);

        if (result != null) {
          await _onCodeScanned(result);
        } else {
          setState(() {
            errorMessage =
                'No QR code could be detected in the selected image.';
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to decode QR code from image.';
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showConfirmationDialog(
      {required String shopName,
      required String shopLocation,
      required String shopPhone,
      required String tableNumber,
      required String shopId,
      required String tableId}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          title: Center(
            child: Text(
              'Confirm Shop',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.store, color: Colors.teal),
                title: Text(
                  shopName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Shop Name'),
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.red),
                title: Text(
                  shopLocation,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Location'),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text(
                  shopPhone,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Phone'),
              ),
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.blue),
                title: Text(
                  tableNumber,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Table Number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to the shop menu screen with the shopId
                _createCustomerTableAssociation(tableId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopMenuScreen(shopId: shopId),
                  ),
                );
              },
              child: Icon(
                Icons.check,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Button corners
                ),
                minimumSize: Size(10, 40), // Square button
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCustomerTableAssociation(String tableId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('customer_id');

      if (customerId == null) return;

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/associate-customer-table'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': customerId,
          'table_id': tableId,
        }),
      );

      print('Association Response: ${response.body}');
    } catch (e) {
      print('Error associating customer and table: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scan'),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: QRView(
              key: qrKey,
              onQRViewCreated: (controller) {
                this.controller = controller;
                controller.scannedDataStream.listen((scanData) {
                  _onCodeScanned(scanData.code ?? '');
                });
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _pickQRCodeFromGallery,
              child: const Text('Pick QR Code from Gallery'),
            ),
          ),
        ],
      ),
    );
  }
}
