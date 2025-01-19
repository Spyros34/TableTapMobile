import 'package:flutter/material.dart';

class BasketScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basket'),
      ),
      body: Center(
        child: Text(
          'Basket Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
