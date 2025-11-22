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
  late final UdpService _udpService; // Единый экземпляр сервиса

  @override
  void initState() {
    super.initState();
    _udpService = UdpService();
    _settings = widget.device.settings;
    if (_settings == null) {
      _fetchSettings();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchSettings() async {
    final settings = await _udpService.fetchSettings(widget.device.ip);
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  // Обновление с локальным созданием нового состояния
  Future<void> _updateSettingLocally({
    required Future<void> Function(UdpService service) sendCommand,
    required GarlandSettings Function() buildUpdatedSettings,
  }) async {
    if (_settings == null) return;

    await sendCommand(_udpService);

    final updatedSettings = buildUpdatedSettings();
    if (mounted) {
      setState(() {
        _settings = updatedSettings;
      });
    }

    if (widget.onSettingsChanged != null) {
      await widget.onSettingsChanged!(updatedSettings);
    }
  }

  // Обновление с повторным запросом настроек с устройства
  Future<void> _updateSettingAndFetch({
    required Future<void> Function(UdpService service) sendCommand,
  }) async {
    if (_settings == null) return;

    await sendCommand(_udpService);

    final updatedSettings = await _udpService.fetchSettings(widget.device.ip);
    if (updatedSettings != null && mounted) {
      setState(() {
        _settings = updatedSettings;
      });
      if (widget.onSettingsChanged != null) {
        await widget.onSettingsChanged!(updatedSettings);
      }
    }
  }

  // Методы управления

  Future<void> _togglePower(bool value) async {
    await _updateSettingLocally(
      sendCommand:
          (service) => service.sendPowerCommand(widget.device.ip, value),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: value,
            brightness: _settings!.brightness,
            autoChange: _settings!.autoChange,
            randomChange: _settings!.randomChange,
            period: _settings!.period,
            timerActive: _settings!.timerActive,
            timerMinutes: _settings!.timerMinutes,
          ),
    );
  }

  Future<void> _updateTotalLeds(int newTotalLeds) async {
    await _updateSettingAndFetch(
      sendCommand:
          (service) =>
              service.sendLedCountCommand(widget.device.ip, newTotalLeds),
    );
  }

  Future<void> _updateBrightness(int newBrightness) async {
    await _updateSettingLocally(
      sendCommand:
          (service) =>
              service.sendBrightnessCommand(widget.device.ip, newBrightness),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: _settings!.power,
            brightness: newBrightness,
            autoChange: _settings!.autoChange,
            randomChange: _settings!.randomChange,
            period: _settings!.period,
            timerActive: _settings!.timerActive,
            timerMinutes: _settings!.timerMinutes,
          ),
    );
  }

  Future<void> _toggleTimerActive(bool value) async {
    await _updateSettingLocally(
      sendCommand:
          (service) => service.sendTimerActiveCommand(widget.device.ip, value),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: _settings!.power,
            brightness: _settings!.brightness,
            autoChange: _settings!.autoChange,
            randomChange: _settings!.randomChange,
            period: _settings!.period,
            timerActive: value,
            timerMinutes: _settings!.timerMinutes,
          ),
    );
  }

  Future<void> _updateTimerMinutes(int newTimerMinutes) async {
    await _updateSettingLocally(
      sendCommand:
          (service) => service.sendTimerMinutesCommand(
            widget.device.ip,
            newTimerMinutes,
          ),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: _settings!.power,
            brightness: _settings!.brightness,
            autoChange: _settings!.autoChange,
            randomChange: _settings!.randomChange,
            period: _settings!.period,
            timerActive: _settings!.timerActive,
            timerMinutes: newTimerMinutes,
          ),
    );
  }

  Future<void> _toggleAutoChange(bool value) async {
    await _updateSettingLocally(
      sendCommand:
          (service) => service.sendAutoChangeCommand(widget.device.ip, value),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: _settings!.power,
            brightness: _settings!.brightness,
            autoChange: value,
            randomChange: _settings!.randomChange,
            period: _settings!.period,
            timerActive: _settings!.timerActive,
            timerMinutes: _settings!.timerMinutes,
          ),
    );
  }

  Future<void> _toggleRandomChange(bool value) async {
    await _updateSettingLocally(
      sendCommand:
          (service) => service.sendRandomChangeCommand(widget.device.ip, value),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: _settings!.power,
            brightness: _settings!.brightness,
            autoChange: _settings!.autoChange,
            randomChange: value,
            period: _settings!.period,
            timerActive: _settings!.timerActive,
            timerMinutes: _settings!.timerMinutes,
          ),
    );
  }

  Future<void> _updatePeriod(int newPeriod) async {
    await _updateSettingLocally(
      sendCommand:
          (service) => service.sendPeriodCommand(widget.device.ip, newPeriod),
      buildUpdatedSettings:
          () => GarlandSettings(
            totalLeds: _settings!.totalLeds,
            power: _settings!.power,
            brightness: _settings!.brightness,
            autoChange: _settings!.autoChange,
            randomChange: _settings!.randomChange,
            period: newPeriod,
            timerActive: _settings!.timerActive,
            timerMinutes: _settings!.timerMinutes,
          ),
    );
  }

  Future<void> _sendNextEffect() async {
    await _updateSettingAndFetch(
      sendCommand: (service) => service.sendNextEffectCommand(widget.device.ip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _settings != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Количество светодиодов
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

                    // Яркость
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
                        final clampedValue = newIntValue.clamp(1, 251);
                        if (clampedValue != _settings!.brightness) {
                          _updateBrightness(clampedValue);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Блок эффектов
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
                              divisions: 9,
                              label: '${_settings!.period}',
                              onChanged: (double newValue) {
                                final newIntValue = newValue.round();
                                final clampedValue = newIntValue.clamp(1, 10);
                                if (clampedValue != _settings!.period) {
                                  _updatePeriod(clampedValue);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
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
