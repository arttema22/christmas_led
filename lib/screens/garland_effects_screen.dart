// lib/screens/garland_effects_screen.dart
import 'package:flutter/material.dart';
import '../models/garland_device.dart';
import '../services/udp_service.dart';

class GarlandEffectsScreen extends StatefulWidget {
  final GarlandDevice device; // Добавляем поле device

  const GarlandEffectsScreen({
    super.key,
    required this.device, // Требуем device в конструкторе
  });

  @override
  State<GarlandEffectsScreen> createState() => _GarlandEffectsScreenState();
}

class _GarlandEffectsScreenState extends State<GarlandEffectsScreen> {
  // === Список эффектов из Processing-прототипа ===
  final List<String> _effectNames = [
    "1. Вечеринка градиент",
    "2. Радуга градиент",
    "3. Полосы градиент",
    "4. Закат градиент",
    "5. Пепси градиент",
    "6. Тёплый градиент",
    "7. Холодный градиент",
    "8. Горячий градиент",
    "9. Розовый градиент",
    "10. Кибер-градиент",
    "11. Красно-белый градиент",
    "12. Вечеринка шум",
    "13. Радуга шум",
    "14. Полосы шум",
    "15. Закат шум",
    "16. Пепси шум",
    "17. Тёплый шум",
    "18. Холодный шум",
    "19. Горячий шум",
    "20. Розовый шум",
    "21. Кибер-шум",
    "22. Красно-белый шум",
  ];

  // === Индекс выбранного эффекта ===
  int? _selectedEffectIndex;

  // === Параметры текущего эффекта (полученные от ESP) ===
  bool _favorite = false;
  int _scale = 0;
  int _speed = 0;

  // === Для доступа к UDP сервису ===
  final UdpService _udpService = UdpService();

  // === Метод для выбора эффекта ===
  Future<void> _selectEffect(int index, String ip) async {
    if (index < 0 || index >= _effectNames.length) return;

    try {
      // Отправляем команду выбора эффекта {4, 0, n}
      final updatedSettings = await _udpService.sendSelectEffectCommand(
        ip,
        index,
      );

      if (updatedSettings != null) {
        // Обновляем локальное состояние с параметрами нового эффекта
        setState(() {
          _selectedEffectIndex = index;
          _favorite = updatedSettings.favorite;
          _scale = updatedSettings.scale;
          _speed = updatedSettings.speed;
        });
      } else {
        debugPrint('Ошибка получения параметров для эффекта $index');
      }
    } catch (e) {
      debugPrint('Ошибка при выборе эффекта $index: $e');
    }
  }

  // === Метод для переключения флага "избранное" ===
  Future<void> _toggleFavorite(String ip) async {
    if (_selectedEffectIndex == null) return;

    final newFavorite = !_favorite;
    try {
      await _udpService.sendFavoriteCommand(ip, newFavorite);

      setState(() {
        _favorite = newFavorite;
      });
    } catch (e) {
      debugPrint('Ошибка при переключении избранного: $e');
    }
  }

  // === Метод для изменения масштаба ===
  Future<void> _updateScale(int newScale, String ip) async {
    if (_selectedEffectIndex == null) return;

    try {
      await _udpService.sendScaleCommand(ip, newScale);

      setState(() {
        _scale = newScale;
      });
    } catch (e) {
      debugPrint('Ошибка при обновлении масштаба: $e');
    }
  }

  // === Метод для изменения скорости ===
  Future<void> _updateSpeed(int newSpeed, String ip) async {
    if (_selectedEffectIndex == null) return;

    try {
      await _udpService.sendSpeedCommand(ip, newSpeed);

      setState(() {
        _speed = newSpeed;
      });
    } catch (e) {
      debugPrint('Ошибка при обновлении скорости: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Теперь используем widget.device напрямую
    final device = widget.device;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите эффект:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // === Список эффектов ===
            Expanded(
              child: ListView.builder(
                itemCount: _effectNames.length,
                itemBuilder: (context, index) {
                  final effectName = _effectNames[index];
                  final isSelected = _selectedEffectIndex == index;

                  return Card(
                    color:
                        isSelected
                            ? Colors.blue.shade100
                            : null, // Подсветка выбранного
                    child: ListTile(
                      title: Text(effectName),
                      onTap:
                          () => _selectEffect(
                            index,
                            device.ip,
                          ), // Используем device.ip
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // === Параметры выбранного эффекта ===
            if (_selectedEffectIndex != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Параметры эффекта: ${_effectNames[_selectedEffectIndex!]}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Переключатель "Избранное"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Избранное'),
                          Switch(
                            value: _favorite,
                            onChanged:
                                (value) => _toggleFavorite(
                                  device.ip,
                                ), // Используем device.ip
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Слайдер "Масштаб"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Масштаб'), Text('$_scale')],
                      ),
                      Slider(
                        value: _scale.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 255,
                        label: '$_scale',
                        onChanged: (double value) {
                          final intValue = value.round();
                          if (intValue != _scale) {
                            _updateScale(
                              intValue,
                              device.ip,
                            ); // Используем device.ip
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Слайдер "Скорость"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Скорость'), Text('$_speed')],
                      ),
                      Slider(
                        value: _speed.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 255,
                        label: '$_speed',
                        onChanged: (double value) {
                          final intValue = value.round();
                          if (intValue != _speed) {
                            _updateSpeed(
                              intValue,
                              device.ip,
                            ); // Используем device.ip
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
