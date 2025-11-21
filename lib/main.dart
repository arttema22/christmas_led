// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/subnet_check_screen.dart'; // Импортируем вашу основную страницу

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garland Search',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // home: const SubnetCheckScreen(), // Установите вашу основную страницу как home
      home: const SubnetCheckScreen(), // Замените на вашу первую страницу
    );
  }
}
