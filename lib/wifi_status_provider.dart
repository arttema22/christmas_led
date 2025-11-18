// wifi_status_provider.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Для debugPrint

class WifiStatusProvider with ChangeNotifier {
  bool _isWifiConnected = false;

  bool get isWifiConnected => _isWifiConnected;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  WifiStatusProvider() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // Проверяем, есть ли подключение по Wi-Fi, независимо от доступа к интернету
    _isWifiConnected = result.contains(ConnectivityResult.wifi);
    debugPrint('Статус Wi-Fi изменён: $_isWifiConnected');
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
