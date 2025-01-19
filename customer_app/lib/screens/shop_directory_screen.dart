import 'package:flutter/material.dart';

class ShopDirectoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Directory'),
      ),
      body: Center(
        child: Text(
          'Shop Directory Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
