import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

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

class SubnetCheckScreen extends StatefulWidget {
  const SubnetCheckScreen({super.key});

  @override
  State<SubnetCheckScreen> createState() => _SubnetCheckScreenState();
}

class _SubnetCheckScreenState extends State<SubnetCheckScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
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
  }

  Future<void> _checkSubnetMask() async {
    setState(() {
      _isLoading = true;
      _foundGarlands.clear();
    });

    try {
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiSubmask = await _networkInfo.getWifiSubmask();

      bool hasCorrectSubnet = wifiSubmask == "255.255.255.0";

      setState(() {
        _isCorrectSubnet = hasCorrectSubnet;
        _subnetMask = wifiSubmask ?? 'N/A';
        _ipAddress = wifiIP ?? 'N/A';
      });
    } catch (e) {
      debugPrint('Ошибка при проверке маски подсети: $e');
      setState(() {
        _isCorrectSubnet = false;
        _subnetMask = 'Error';
        _ipAddress = 'N/A';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startGarlandSearch() async {
    setState(() {
      _isSearching = true;
      _foundGarlands.clear();
    });

    try {
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();
      final wifiSubmask = await _networkInfo.getWifiSubmask();

      if (wifiSubmask != "255.255.255.0") {
        debugPrint('Неподдерживаемая маска подсети: $_subnetMask');
        setState(() {
          _isSearching = false;
        });
        return;
      }

      if (wifiIP == null || wifiIP.isEmpty || wifiIP == "0.0.0.0") {
        debugPrint('Wi-Fi не подключен');
        setState(() {
          _isSearching = false;
        });
        return;
      }

      if (wifiBroadcast == null || wifiBroadcast.isEmpty) {
        debugPrint('Не удалось получить широковещательный адрес');
        setState(() {
          _isSearching = false;
        });
        return;
      }

      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      udpSocket.broadcastEnabled = true;

      // === ЗАПРОС IP: {'G', 'T', 0} ===
      final requestPacket = <int>[71, 84, 0]; // 'G' = 71, 'T' = 84, 0
      final broadcastAddress = InternetAddress(wifiBroadcast);
      udpSocket.send(requestPacket, broadcastAddress, 8888);

      _searchTimer = Timer(Duration(seconds: 2), () {
        udpSocket.close();
      });

      final responses = <GarlandDevice>[];

      udpSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket.receive();
          if (datagram != null) {
            final data = datagram.data;
            final senderAddress = datagram.address.address;

            // === ОТВЕТ НА ЗАПРОС IP: {'G', 'T', 0, ip} ===
            if (data.length >= 4 &&
                data[0] == 71 && // 'G'
                data[1] == 84 && // 'T'
                data[2] == 0) {
              // Команда 0
              final lastOctet = data[3];
              final device = GarlandDevice(
                ip: senderAddress,
                lastOctet: lastOctet,
              );

              if (!responses.any((d) => d.ip == device.ip)) {
                responses.add(device);
              }
            }
          }
        }
      });

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _foundGarlands = responses;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Ошибка при поиске гирлянд: $e');
      setState(() {
        _isSearching = false;
      });
    } finally {
      _searchTimer?.cancel();
      _searchTimer = null;
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
                        subtitle: Text('Последний октет: ${garland.lastOctet}'),
                        trailing: const Icon(Icons.lightbulb),
                        // === ПЕРЕХОД НА СТРАНИЦУ НАСТРОЕК ===
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
              ),
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

class GarlandDevice {
  final String ip;
  final int lastOctet;

  GarlandDevice({required this.ip, required this.lastOctet});
}

// === СТРАНИЦА НАСТРОЕК ГИРЛЯНДЫ ===
class GarlandSettingsScreen extends StatefulWidget {
  final GarlandDevice device;

  const GarlandSettingsScreen({super.key, required this.device});

  @override
  State<GarlandSettingsScreen> createState() => _GarlandSettingsScreenState();
}

class _GarlandSettingsScreenState extends State<GarlandSettingsScreen> {
  bool _isLoading = true;
  GarlandSettings? _settings;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // === ЗАПРОС НАСТРОЕК: {'G', 'T', 1} ===
      final requestPacket = <int>[71, 84, 1]; // 'G' = 71, 'T' = 84, 1
      final deviceAddress = InternetAddress(widget.device.ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      Timer(Duration(seconds: 1), () {
        udpSocket.close();
      });

      await for (RawSocketEvent event in udpSocket) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket.receive();
          if (datagram != null) {
            final data = datagram.data;

            // === ОТВЕТ НА ЗАПРОС НАСТРОЕК: {'G', 'T', 1, ...} (всего 11 байт) ===
            if (data.length >= 11 &&
                data[0] == 71 && // 'G'
                data[1] == 84 && // 'T'
                data[2] == 1) {
              // Команда 1

              // === РАЗБОР ОТВЕТА ПО ПРОТОКОЛУ ===
              final totalLeds = data[3] * 100 + data[4];
              final power = data[5] == 1;
              final brightness = data[6];
              final autoChange = data[7] == 1;
              final randomChange = data[8] == 1;
              final period = data[9];
              final timerActive = data[10] == 1;
              final timerMinutes = data[11];

              final settings = GarlandSettings(
                totalLeds: totalLeds,
                power: power,
                brightness: brightness,
                autoChange: autoChange,
                randomChange: randomChange,
                period: period,
                timerActive: timerActive,
                timerMinutes: timerMinutes,
              );

              setState(() {
                _settings = settings;
                _isLoading = false;
              });
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при получении настроек: $e');
      setState(() {
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
                      '${_settings!.totalLeds}',
                    ),
                    _buildSettingRow(
                      'Питание:',
                      _settings!.power ? 'Включено' : 'Выключено',
                    ),
                    _buildSettingRow('Яркость:', '${_settings!.brightness}'),
                    _buildSettingRow(
                      'Автосмена:',
                      _settings!.autoChange ? 'Да' : 'Нет',
                    ),
                    _buildSettingRow(
                      'Случайная смена:',
                      _settings!.randomChange ? 'Да' : 'Нет',
                    ),
                    _buildSettingRow('Период (с):', '${_settings!.period}'),
                    _buildSettingRow(
                      'Таймер активен:',
                      _settings!.timerActive ? 'Да' : 'Нет',
                    ),
                    _buildSettingRow(
                      'Время таймера (мин):',
                      '${_settings!.timerMinutes}',
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

class GarlandSettings {
  final int totalLeds;
  final bool power;
  final int brightness;
  final bool autoChange;
  final bool randomChange;
  final int period;
  final bool timerActive;
  final int timerMinutes;

  GarlandSettings({
    required this.totalLeds,
    required this.power,
    required this.brightness,
    required this.autoChange,
    required this.randomChange,
    required this.period,
    required this.timerActive,
    required this.timerMinutes,
  });
}
