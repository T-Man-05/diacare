import 'package:flutter/material.dart';
// 1. Import your new separated screen file
import 'pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 2. Use the LoginScreen class for the home
      home: const LoginScreen(), // Renamed MyHomePage to LoginScreen
      debugShowCheckedModeBanner: false,
    );
  }
}