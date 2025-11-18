// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'wifi_status_provider.dart';
import 'esp_communication.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => WifiStatusProvider())],
      child: MaterialApp(
        title: 'Christmas LED Setup',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const MyHomePage(title: 'Управление гирляндой'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isSearching = false;
  List<String>? _foundEspAddresses;

  void _findEsp() async {
    setState(() {
      _isSearching = true;
      _foundEspAddresses = null;
    });

    List<String>? addresses = await EspCommunication.discoverEsp();

    setState(() {
      _foundEspAddresses = addresses;
      _isSearching = false;
    });

    if (addresses != null && addresses.isNotEmpty) {
      debugPrint('Найдены ESP: $addresses');
    } else {
      debugPrint('ESP не найдены');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [
          Consumer<WifiStatusProvider>(
            builder: (context, wifiProvider, child) {
              bool isConnected = wifiProvider.isWifiConnected;
              return IconButton(
                icon: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                tooltip: isConnected ? 'Wi-Fi подключён' : 'Wi-Fi отключён',
                onPressed: () async {
                  await launchUrl(
                    Uri.parse('android.settings.WIFI_SETTINGS'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<WifiStatusProvider>(
        builder: (context, wifiProvider, child) {
          bool isWifiOn = wifiProvider.isWifiConnected;
          return Column(
            children: [
              // Кнопка "Найти ESP" на верху, появляется если Wi-Fi включён
              if (isWifiOn)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _findEsp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isSearching
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Найти ESP'),
                  ),
                ),
              // Expanded для центрирования остального контента (результатов)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Показываем результаты поиска ESP, если они есть
                      if (_foundEspAddresses != null)
                        Text(
                          _foundEspAddresses!.isNotEmpty
                              ? 'Найдено ESP: ${_foundEspAddresses!.join(', ')}'
                              : 'ESP не найдены',
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
