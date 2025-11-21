import 'package:flutter/material.dart';
import '../models/garland_device.dart';
import '../services/udp_service.dart';

class GarlandSettingsScreen extends StatefulWidget {
  final GarlandDevice device;

  const GarlandSettingsScreen({super.key, required this.device});

  @override
  State<GarlandSettingsScreen> createState() => _GarlandSettingsScreenState();
}

class _GarlandSettingsScreenState extends State<GarlandSettingsScreen> {
  bool _isLoading = true;
  var _settings;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки гирлянды ${widget.device.ip}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _settings != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingRow(
                      'Количество светодиодов:',
                      '${_settings.totalLeds}',
                    ),
                    _buildSettingRow(
                      'Питание:',
                      _settings.power ? 'Включено' : 'Выключено',
                    ),
                    _buildSettingRow('Яркость:', '${_settings.brightness}'),
                    _buildSettingRow(
                      'Автосмена:',
                      _settings.autoChange ? 'Да' : 'Нет',
                    ),
                    _buildSettingRow(
                      'Случайная смена:',
                      _settings.randomChange ? 'Да' : 'Нет',
                    ),
                    _buildSettingRow('Период (с):', '${_settings.period}'),
                    _buildSettingRow(
                      'Таймер активен:',
                      _settings.timerActive ? 'Да' : 'Нет',
                    ),
                    _buildSettingRow(
                      'Время таймера (мин):',
                      '${_settings.timerMinutes}',
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

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 1, child: Text(value)),
        ],
      ),
    );
  }
}
