import 'package:flutter/material.dart';
import 'screens/subnet_check_screen.dart';

void main() {
  runApp(const GarlandSearchApp());
}

class GarlandSearchApp extends StatelessWidget {
  const GarlandSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garland Search',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SubnetCheckScreen(),
    );
  }
}
