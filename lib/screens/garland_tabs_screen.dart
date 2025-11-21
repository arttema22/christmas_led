// lib/screens/garland_tabs_screen.dart
import 'package:flutter/material.dart';
import '../models/garland_device.dart';
import '../models/garland_settings.dart';
import 'garland_effects_screen.dart';
import 'garland_settings_screen.dart';
import 'garland_calibration_screen.dart';

class GarlandTabsScreen extends StatefulWidget {
  final GarlandDevice device;
  final Future<void> Function(GarlandSettings)? onSettingsChanged;

  const GarlandTabsScreen({
    super.key,
    required this.device,
    this.onSettingsChanged,
  });

  @override
  State<GarlandTabsScreen> createState() => _GarlandTabsScreenState();
}

class _GarlandTabsScreenState extends State<GarlandTabsScreen> {
  int _currentIndex = 1; // Приватное состояние, пусть будет с _

  @override
  Widget build(BuildContext context) {
    // Список вкладок
    final List<Widget> pages = [
      // Переименовано: _pages -> pages
      GarlandEffectsScreen(), // Индекс 0
      GarlandSettingsScreen(
        device: widget.device,
        onSettingsChanged: widget.onSettingsChanged,
      ), // Индекс 1
      GarlandCalibrationScreen(), // Индекс 2
    ];

    // Заголовки вкладок
    final List<String> titles = [
      // Переименовано: _titles -> titles
      'Эффекты',
      'Настройки',
      'Калибровка',
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Гирлянда ${widget.device.ip}')),
      body: pages[_currentIndex], // Отображаем текущую вкладку
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Меняем индекс при нажатии на вкладку
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.palette), // Иконка для "Эффектов"
            label: titles[0], // Используем переменную titles
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // Иконка для "Настроек"
            label: titles[1], // Используем переменную titles
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.linear_scale), // Иконка для "Калибровки"
            label: titles[2], // Используем переменную titles
          ),
        ],
      ),
    );
  }
}
