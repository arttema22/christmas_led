// lib/screens/garland_tabs_screen.dart
import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../models/garland_device.dart';
import '../models/garland_settings.dart';
import '../services/udp_service.dart';
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
  int _currentIndex = 0;
  GarlandSettings? _settings;
  bool _isLoadingSettings = true;
  late final UdpService _udpService;

  @override
  void initState() {
    super.initState();
    _udpService = UdpService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _udpService.fetchSettings(widget.device.ip);
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _togglePower(bool value) async {
    await _udpService.sendPowerCommand(widget.device.ip, value);
    if (_settings != null) {
      final updated = _settings!.copyWith(power: value);
      setState(() {
        _settings = updated;
      });
      widget.onSettingsChanged?.call(updated);
    }
  }

  Future<void> _toggleTimerActiveGlobal(bool value) async {
    await _udpService.sendTimerActiveCommand(widget.device.ip, value);
  }

  Future<void> _updateTimerMinutesGlobal(int minutes) async {
    await _udpService.sendTimerMinutesCommand(widget.device.ip, minutes);
  }

  void _showTimerBottomSheet(BuildContext context) {
    if (_settings == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _TimerBottomSheet(
          initialSettings: _settings!,
          onTimerActiveChanged: _toggleTimerActiveGlobal,
          onTimerMinutesChanged: _updateTimerMinutesGlobal,
          onSettingsUpdated: (newSettings) {
            if (mounted) {
              setState(() {
                _settings = newSettings;
              });
            }
            widget.onSettingsChanged?.call(newSettings);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      GarlandEffectsScreen(device: widget.device),
      GarlandSettingsScreen(
        device: widget.device,
        onSettingsChanged: (settings) async {
          if (mounted) {
            setState(() {
              _settings = settings;
            });
          }
          if (widget.onSettingsChanged != null) {
            await widget.onSettingsChanged!(settings);
          }
        },
      ),
      GarlandCalibrationScreen(device: widget.device),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.ip}'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.timer,
              color: _settings?.timerActive == true ? Colors.green : null,
            ),
            onPressed: () => _showTimerBottomSheet(context),
            tooltip: 'Таймер выключения',
          ),
          if (!_isLoadingSettings && _settings != null)
            Switch(
              value: _settings!.power,
              onChanged: _togglePower,
              activeColor: Colors.green,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          if (_isLoadingSettings)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Эффекты'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Калибровка',
          ),
        ],
      ),
    );
  }
}

// ========== ВИДЖЕТ НИЖНЕГО ЛИСТА ДЛЯ ТАЙМЕРА ==========
class _TimerBottomSheet extends StatefulWidget {
  final GarlandSettings initialSettings;
  final Future<void> Function(bool) onTimerActiveChanged;
  final Future<void> Function(int) onTimerMinutesChanged;
  final void Function(GarlandSettings) onSettingsUpdated;

  const _TimerBottomSheet({
    required this.initialSettings,
    required this.onTimerActiveChanged,
    required this.onTimerMinutesChanged,
    required this.onSettingsUpdated,
  });

  @override
  State<_TimerBottomSheet> createState() => _TimerBottomSheetState();
}

class _TimerBottomSheetState extends State<_TimerBottomSheet> {
  late GarlandSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _updateLocalSettings(GarlandSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsUpdated(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Таймер выключения',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Активен'),
              Switch(
                value: _settings.timerActive,
                onChanged: (value) async {
                  await widget.onTimerActiveChanged(value);
                  _updateLocalSettings(_settings.copyWith(timerActive: value));
                },
              ),
            ],
          ),
          if (_settings.timerActive) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              height: 240,
              child: SleekCircularSlider(
                min: 1,
                max: 240,
                initialValue: _settings.timerMinutes.toDouble(),
                innerWidget: (value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'мин',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
                onChange: (value) {
                  final minutes = value.toInt();
                  if (minutes != _settings.timerMinutes) {
                    widget.onTimerMinutesChanged(minutes);
                    _updateLocalSettings(
                      _settings.copyWith(timerMinutes: minutes),
                    );
                  }
                },
                appearance: CircularSliderAppearance(
                  animationEnabled: true,
                  startAngle: -90,
                  angleRange: 360,
                  // === InfoProperties: только top и bottom ===
                  infoProperties: InfoProperties(
                    topLabelText: '120',
                    bottomLabelText: '240',
                    topLabelStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    bottomLabelStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  // === CustomSliderColors ===
                  customColors: CustomSliderColors(
                    trackColor: Colors.grey[300]!,
                    progressBarColor: Colors.green,
                    dotColor: Colors.white,
                  ),
                  // === CustomSliderWidths ===
                  customWidths: CustomSliderWidths(
                    trackWidth: 16,
                    progressBarWidth: 22,
                    handlerSize: 24, // размер "ручки" (knob)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Кнопки быстрого выбора
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children:
                  [10, 30, 60, 90, 120, 180, 240].map((min) {
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              _settings.timerMinutes == min
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        foregroundColor:
                            _settings.timerMinutes == min
                                ? Colors.green
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () {
                        widget.onTimerMinutesChanged(min);
                        _updateLocalSettings(
                          _settings.copyWith(timerMinutes: min),
                        );
                      },
                      child: Text('$min'),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
