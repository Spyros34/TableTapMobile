import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/qrscan_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/basket_screen.dart';
import 'screens/shop_directory_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Customer App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/qrscan': (context) => QRScanScreen(),
          '/menu': (context) => MenuScreen(),
          '/basket': (context) => BasketScreen(),
          '/shop_directory': (context) => ShopDirectoryScreen(),
          '/profile': (context) => ProfileScreen(),
        },
      ),
    );
  }
}
