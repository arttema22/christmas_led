// wifi_status_provider.dart
import 'package:flutter/foundation.dart'; // Для debugPrint
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Для StreamSubscription

class WifiStatusProvider with ChangeNotifier {
  bool _isWifiConnected = false;

  bool get isWifiConnected => _isWifiConnected;

  // Подписка на поток изменений подключения
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  WifiStatusProvider() {
    // Начинаем слушать изменения подключения при создании провайдера
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  // Этот метод вызывается каждый раз, когда тип подключения меняется
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // Проверяем, содержит ли список результатов тип подключения Wi-Fi
    // Это означает, что устройство подключено к Wi-Fi, независимо от доступа к интернету
    bool wasConnected = _isWifiConnected;
    _isWifiConnected = result.contains(ConnectivityResult.wifi);

    // Уведомляем слушателей (например, UI) только если статус изменился
    if (wasConnected != _isWifiConnected) {
      debugPrint(
        'Статус Wi-Fi изменён: $_isWifiConnected (Полный результат: $result)',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Важно отменить подписку, чтобы избежать утечек памяти
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
