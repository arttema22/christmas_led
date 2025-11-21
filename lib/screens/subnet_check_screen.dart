// lib/screens/subnet_check_screen.dart
import 'dart:async';
// import 'package:flutter/foundation.dart'; // Удалите эту строку
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
    _loadSavedGarlands(); // Загружаем сохранённые гирлянды при запуске
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
      // _foundGarlands.clear(); // Не очищаем при проверке подсети, чтобы сохранить загруженные
    });

    String wifiIP = 'N/A';
    String wifiSubmask = 'N/A';
    bool hasCorrectSubnet = false;

    try {
      wifiSubmask = (await _networkInfo.getWifiSubmask()) ?? 'N/A';
      wifiIP = (await _networkInfo.getWifiIP()) ?? 'N/A';

      hasCorrectSubnet = wifiSubmask == "255.255.255.0";
    } catch (e) {
      debugPrint(
        'Ошибка при проверке маски подсети: $e',
      ); // debugPrint всё ещё доступен
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
      // _foundGarlands.clear(); // Не очищаем, а добавляем новые к существующим
    });

    try {
      final foundDevices = await _udpService.searchGarlands();

      // Для каждой найденной гирлянды проверяем, есть ли она уже в списке
      for (final newDevice in foundDevices) {
        bool alreadyExists = _foundGarlands.any(
          (existingDevice) => existingDevice.ip == newDevice.ip,
        );

        if (!alreadyExists) {
          // Если новая, запрашиваем настройки и добавляем в список
          final settings = await _udpService.fetchSettings(newDevice.ip);
          newDevice.settings = settings;
          _foundGarlands.add(newDevice);
        } else {
          // Если уже есть, можно обновить настройки, если они пришли
          final existingIndex = _foundGarlands.indexWhere(
            (d) => d.ip == newDevice.ip,
          );
          if (existingIndex != -1) {
            final settings = await _udpService.fetchSettings(newDevice.ip);
            _foundGarlands[existingIndex].settings = settings;
          }
        }
      }

      // Сохраняем обновлённый список
      await _udpService.saveGarlands(_foundGarlands);

      setState(() {
        _isSearching = false;
      });
    } catch (e) {
      debugPrint(
        'Ошибка при поиске гирлянд: $e',
      ); // debugPrint всё ещё доступен
      setState(() {
        _isSearching = false;
      });
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
                              garland.settings !=
                                      null // Проверка на null для безопасности
                                  ? (bool value) async {
                                    // 1. Оптимистично обновляем состояние в UI
                                    final updatedList =
                                        List<GarlandDevice>.from(
                                          _foundGarlands,
                                        );
                                    final updatedIndex = updatedList.indexWhere(
                                      (d) => d.ip == garland.ip,
                                    );
                                    if (updatedIndex != -1 &&
                                        updatedList[updatedIndex].settings !=
                                            null) {
                                      updatedList[updatedIndex]
                                          .settings = GarlandSettings(
                                        totalLeds:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .totalLeds,
                                        power: value,
                                        brightness:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .brightness,
                                        autoChange:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .autoChange,
                                        randomChange:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .randomChange,
                                        period:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .period,
                                        timerActive:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .timerActive,
                                        timerMinutes:
                                            updatedList[updatedIndex]
                                                .settings!
                                                .timerMinutes,
                                      );
                                      setState(() {
                                        _foundGarlands = updatedList;
                                      });
                                    }

                                    // 2. Отправляем команду на устройство
                                    await _udpService.sendPowerCommand(
                                      garland.ip,
                                      value,
                                    );

                                    // 3. Сохраняем обновлённый список после переключения
                                    await _udpService.saveGarlands(
                                      _foundGarlands,
                                    );
                                  }
                                  : null,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      GarlandSettingsScreen(device: garland),
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
              const SizedBox(), // Пустое пространство, если маска неправильная и гирлянд нет
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
