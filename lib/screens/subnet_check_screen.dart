// lib/screens/subnet_check_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/garland_device.dart';
import '../models/garland_settings.dart';
import '../services/udp_service.dart';
import 'garland_settings_screen.dart';

class SubnetCheckScreen extends StatefulWidget {
  const SubnetCheckScreen({super.key});

  @override
  State<SubnetCheckScreen> createState() => _SubnetCheckScreenState();
}

class _SubnetCheckScreenState extends State<SubnetCheckScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  final UdpService _udpService = UdpService();

  bool _isCorrectSubnet = false;
  String _subnetMask = 'N/A';
  String _ipAddress = 'N/A';
  bool _isLoading = true;
  bool _isSearching = false;
  List<GarlandDevice> _foundGarlands = [];
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _checkSubnetMask();
    _loadSavedGarlands();
  }

  Future<void> _loadSavedGarlands() async {
    final savedGarlands = await _udpService.loadGarlands();
    setState(() {
      _foundGarlands = savedGarlands;
    });
  }

  Future<void> _checkSubnetMask() async {
    setState(() {
      _isLoading = true;
    });

    String wifiIP = 'N/A';
    String wifiSubmask = 'N/A';
    bool hasCorrectSubnet = false;

    try {
      wifiSubmask = (await _networkInfo.getWifiSubmask()) ?? 'N/A';
      wifiIP = (await _networkInfo.getWifiIP()) ?? 'N/A';

      hasCorrectSubnet = wifiSubmask == "255.255.255.0";
    } catch (e) {
      debugPrint('Ошибка при проверке маски подсети: $e');
      hasCorrectSubnet = false;
      wifiSubmask = 'Error';
      wifiIP = 'N/A';
    }

    setState(() {
      _isCorrectSubnet = hasCorrectSubnet;
      _subnetMask = wifiSubmask;
      _ipAddress = wifiIP;
      _isLoading = false;
    });
  }

  Future<void> _startGarlandSearch() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final foundDevices = await _udpService.searchGarlands();

      for (final newDevice in foundDevices) {
        bool alreadyExists = _foundGarlands.any(
          (existingDevice) => existingDevice.ip == newDevice.ip,
        );

        if (!alreadyExists) {
          final settings = await _udpService.fetchSettings(newDevice.ip);
          newDevice.settings = settings;
          _foundGarlands.add(newDevice);
        } else {
          final existingIndex = _foundGarlands.indexWhere(
            (d) => d.ip == newDevice.ip,
          );
          if (existingIndex != -1) {
            final settings = await _udpService.fetchSettings(newDevice.ip);
            _foundGarlands[existingIndex].settings = settings;
          }
        }
      }

      await _udpService.saveGarlands(_foundGarlands);

      setState(() {
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Ошибка при поиске гирлянд: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  // === Универсальная функция для обновления настроек гирлянды в списке ===
  Future<void> _updateGarlandSettings(
    String ip,
    GarlandSettings newSettings,
  ) async {
    final updatedList = List<GarlandDevice>.from(_foundGarlands);
    final index = updatedList.indexWhere((d) => d.ip == ip);
    if (index != -1) {
      updatedList[index].settings = newSettings;

      setState(() {
        _foundGarlands = updatedList;
      });

      // Сохраняем обновлённый список
      await _udpService.saveGarlands(_foundGarlands);
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garland Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isSearching ? null : _checkSubnetMask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isCorrectSubnet ? Icons.wifi : Icons.wifi_off,
              size: 100,
              color: _isCorrectSubnet ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              _isCorrectSubnet
                  ? 'Подготовлено к поиску гирлянд'
                  : 'Некорректная маска подсети',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isCorrectSubnet ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('IP-адрес:', _ipAddress),
                    const SizedBox(height: 8),
                    _buildInfoRow('Маска подсети:', _subnetMask),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_isCorrectSubnet)
              ElevatedButton(
                onPressed: _isSearching ? null : _startGarlandSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSearching
                        ? const Text('Ищем...')
                        : const Text('Search for garland'),
              ),

            if (!_isCorrectSubnet)
              const Text(
                'Для поиска гирлянд подключитесь к сети с маской 255.255.255.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),

            const SizedBox(height: 24),

            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_foundGarlands.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _foundGarlands.length,
                  itemBuilder: (context, index) {
                    final garland = _foundGarlands[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('Гирлянда ${garland.ip}'),
                        subtitle: Text(
                          garland.settings != null
                              ? 'Питание: ${garland.settings!.power ? "Вкл" : "Выкл"}'
                              : 'Загрузка настроек...',
                        ),
                        trailing: Switch(
                          value: garland.settings?.power ?? false,
                          onChanged:
                              garland.settings != null
                                  ? (bool value) async {
                                    await _udpService.sendPowerCommand(
                                      garland.ip,
                                      value,
                                    );
                                    // Обновляем только питание, остальные поля остаются прежними
                                    final updatedSettings = GarlandSettings(
                                      totalLeds: garland.settings!.totalLeds,
                                      power: value,
                                      brightness: garland.settings!.brightness,
                                      autoChange: garland.settings!.autoChange,
                                      randomChange:
                                          garland.settings!.randomChange,
                                      period: garland.settings!.period,
                                      timerActive:
                                          garland.settings!.timerActive,
                                      timerMinutes:
                                          garland.settings!.timerMinutes,
                                    );
                                    await _updateGarlandSettings(
                                      garland.ip,
                                      updatedSettings,
                                    );
                                  }
                                  : null,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => GarlandSettingsScreen(
                                    device: garland,
                                    onSettingsChanged: (newSettings) async {
                                      // Передаём новую функцию
                                      await _updateGarlandSettings(
                                        garland.ip,
                                        newSettings,
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else if (!_isSearching &&
                _foundGarlands.isEmpty &&
                _isCorrectSubnet)
              const Center(
                child: Text(
                  'Garland not found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            else if (!_isSearching &&
                _foundGarlands.isEmpty &&
                !_isCorrectSubnet)
              const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
