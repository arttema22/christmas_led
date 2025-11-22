// lib/screens/garland_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/garland_device.dart';
import '../models/garland_settings.dart';
import '../services/udp_service.dart';

class GarlandSettingsScreen extends StatefulWidget {
  final GarlandDevice device;
  final Future<void> Function(GarlandSettings)? onSettingsChanged;

  const GarlandSettingsScreen({
    super.key,
    required this.device,
    this.onSettingsChanged,
  });

  @override
  State<GarlandSettingsScreen> createState() => _GarlandSettingsScreenState();
}

class _GarlandSettingsScreenState extends State<GarlandSettingsScreen> {
  bool _isLoading = true;
  GarlandSettings? _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.device.settings;
    if (_settings == null) {
      _fetchSettings();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchSettings() async {
    final service = UdpService();
    final settings = await service.fetchSettings(widget.device.ip);

    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePower(bool value) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendPowerCommand(widget.device.ip, value);

    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: value,
      brightness: _settings!.brightness,
      autoChange: _settings!.autoChange,
      randomChange: _settings!.randomChange,
      period: _settings!.period,
      timerActive: _settings!.timerActive,
      timerMinutes: _settings!.timerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для отправки команды изменения количества ледов ===
  Future<void> _updateTotalLeds(int newTotalLeds) async {
    if (_settings == null) return;

    final service = UdpService();

    // 1. Отправляем команду изменения количества ледов
    await service.sendLedCountCommand(widget.device.ip, newTotalLeds);

    // 2. ЗАПРАШИВАЕМ обновлённые настройки ОТДЕЛЬНО
    final updatedSettings = await service.fetchSettings(widget.device.ip);

    if (updatedSettings != null && mounted) {
      setState(() {
        _settings = updatedSettings;
      });

      if (widget.onSettingsChanged != null) {
        await widget.onSettingsChanged!(updatedSettings);
      }
    }
  }

  // === Метод для отправки команды изменения яркости ===
  Future<void> _updateBrightness(int newBrightness) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendBrightnessCommand(widget.device.ip, newBrightness);

    // Обновляем только яркость локально
    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: _settings!.power,
      brightness: newBrightness,
      autoChange: _settings!.autoChange,
      randomChange: _settings!.randomChange,
      period: _settings!.period,
      timerActive: _settings!.timerActive,
      timerMinutes: _settings!.timerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для переключения состояния таймера ===
  Future<void> _toggleTimerActive(bool value) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendTimerActiveCommand(widget.device.ip, value);

    // Обновляем только состояние таймера локально
    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: _settings!.power,
      brightness: _settings!.brightness,
      autoChange: _settings!.autoChange,
      randomChange: _settings!.randomChange,
      period: _settings!.period,
      timerActive: value,
      timerMinutes: _settings!.timerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для отправки команды изменения времени таймера ===
  Future<void> _updateTimerMinutes(int newTimerMinutes) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendTimerMinutesCommand(widget.device.ip, newTimerMinutes);

    // Обновляем только время таймера локально
    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: _settings!.power,
      brightness: _settings!.brightness,
      autoChange: _settings!.autoChange,
      randomChange: _settings!.randomChange,
      period: _settings!.period, // ВАЖНО: это было period, а не timerMinutes
      timerActive: _settings!.timerActive,
      timerMinutes: newTimerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для переключения автосмены ===
  Future<void> _toggleAutoChange(bool value) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendAutoChangeCommand(widget.device.ip, value);

    // Обновляем только автосмену локально
    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: _settings!.power,
      brightness: _settings!.brightness,
      autoChange: value,
      randomChange: _settings!.randomChange,
      period: _settings!.period,
      timerActive: _settings!.timerActive,
      timerMinutes: _settings!.timerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для переключения случайной смены ===
  Future<void> _toggleRandomChange(bool value) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendRandomChangeCommand(widget.device.ip, value);

    // Обновляем только случайную смену локально
    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: _settings!.power,
      brightness: _settings!.brightness,
      autoChange: _settings!.autoChange,
      randomChange: value,
      period: _settings!.period,
      timerActive: _settings!.timerActive,
      timerMinutes: _settings!.timerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для отправки команды изменения периода смены ===
  Future<void> _updatePeriod(int newPeriod) async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendPeriodCommand(widget.device.ip, newPeriod);

    // Обновляем только период локально
    final updatedSettings = GarlandSettings(
      totalLeds: _settings!.totalLeds,
      power: _settings!.power,
      brightness: _settings!.brightness,
      autoChange: _settings!.autoChange,
      randomChange: _settings!.randomChange,
      period: newPeriod,
      timerActive: _settings!.timerActive,
      timerMinutes: _settings!.timerMinutes,
    );

    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // === Метод для отправки команды "следующий эффект" ===
  Future<void> _sendNextEffect() async {
    if (_settings == null) return;

    final service = UdpService();
    await service.sendNextEffectCommand(widget.device.ip);

    // Запрашиваем обновлённые настройки, так как эффект мог измениться
    final updatedSettings = await service.fetchSettings(widget.device.ip);
    if (updatedSettings != null && mounted) {
      setState(() {
        _settings = updatedSettings;
      });

      if (widget.onSettingsChanged != null) {
        await widget.onSettingsChanged!(updatedSettings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Оборачиваем ВЕСЬ Column в SingleChildScrollView для прокрутки
      child: SingleChildScrollView(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _settings != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Switch питания - первый
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Питание',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Switch(
                          value: _settings!.power,
                          onChanged: _togglePower,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Слайдер для количества светодиодов - второй
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Количество светодиодов',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_settings!.totalLeds}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Slider(
                      value: _settings!.totalLeds.toDouble(),
                      min: 0.0,
                      max: 500.0,
                      divisions: 500,
                      label: '${_settings!.totalLeds}',
                      onChanged: (double newValue) {
                        final newIntValue = newValue.round();
                        if (newIntValue != _settings!.totalLeds) {
                          _updateTotalLeds(newIntValue);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Слайдер для яркости - третий
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Яркость',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_settings!.brightness}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Slider(
                      value: _settings!.brightness.toDouble(),
                      min: 1.0,
                      max: 251.0,
                      divisions: 250,
                      label: '${_settings!.brightness}',
                      onChanged: (double newValue) {
                        final newIntValue = newValue.round();
                        final clampedValue = newIntValue.clamp(
                          1,
                          251,
                        ); // УБРАНО 'as int'
                        if (clampedValue != _settings!.brightness) {
                          _updateBrightness(clampedValue);
                        }
                      },
                    ),
                    const SizedBox(height: 8), // Отступ перед блоком таймера
                    // === Блок управления таймером (Switch + Slider) - четвёртый ===
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Таймер выключения',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Switch(
                                  value: _settings!.timerActive,
                                  onChanged: _toggleTimerActive,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Слайдер для времени таймера
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Время (мин)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${_settings!.timerMinutes}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value:
                                  _settings!.timerActive
                                      ? _settings!.timerMinutes.toDouble()
                                      : 1.0,
                              min: 1.0,
                              max: 240.0,
                              divisions: 239,
                              label: '${_settings!.timerMinutes}',
                              onChanged:
                                  _settings!.timerActive
                                      ? (double newValue) {
                                        final newIntValue = newValue.round();
                                        final clampedValue = newIntValue.clamp(
                                          1,
                                          240,
                                        ); // УБРАНО 'as int'
                                        if (clampedValue !=
                                            _settings!.timerMinutes) {
                                          _updateTimerMinutes(clampedValue);
                                        }
                                      }
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // Отступ перед блоком эффектов
                    // === Блок управления эффектами (Switch + Slider + Button) - пятый ===
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Эффекты',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Switch автосмена
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Автосмена'),
                                Switch(
                                  value: _settings!.autoChange,
                                  onChanged: _toggleAutoChange,
                                ),
                              ],
                            ),
                            // Switch случайная смена
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Случайная смена'),
                                Switch(
                                  value: _settings!.randomChange,
                                  onChanged: _toggleRandomChange,
                                ),
                              ],
                            ),
                            // Слайдер периода смены
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Период (мин)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${_settings!.period}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _settings!.period.toDouble(),
                              min: 1.0,
                              max: 10.0,
                              divisions: 9, // 10 значений (1-10)
                              label: '${_settings!.period}',
                              onChanged: (double newValue) {
                                final newIntValue = newValue.round();
                                // Ограничиваем значение в диапазоне 1-10
                                final clampedValue = newIntValue.clamp(
                                  1,
                                  10,
                                ); // УБРАНО 'as int'
                                if (clampedValue != _settings!.period) {
                                  _updatePeriod(clampedValue);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            // Кнопка "Следующий эффект"
                            ElevatedButton(
                              onPressed: _sendNextEffect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Следующий эффект'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                : const Center(
                  child: Text(
                    'Не удалось получить настройки',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
      ),
    );
  }
}
