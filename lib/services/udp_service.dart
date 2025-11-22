// lib/services/udp_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/garland_device.dart';
import '../models/garland_settings.dart';

class UdpService {
  final NetworkInfo _networkInfo = NetworkInfo();

  // === ЗАПРОС НАСТРОЕК (ОСТАЁТСЯ БЕЗ ИЗМЕНЕНИЙ, Т.К. ОЖИДАЕТ ОТВЕТ) ===
  Future<GarlandSettings?> fetchSettings(String ip) async {
    debugPrint('[UDP Service] Запрос настроек для $ip: {G, T, 1}');
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Запрос: {'G', 'T', 1}
      final requestPacket = <int>[71, 84, 1]; // 'G' = 71, 'T' = 84, 1
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);
      debugPrint(
        '[UDP Service] Отправлен пакет: [71, 84, 1] на $deviceAddress:8888',
      );

      Timer(Duration(seconds: 1), () {
        udpSocket.close();
        debugPrint('[UDP Service] Сокет закрыт по таймауту в fetchSettings');
      });

      await for (RawSocketEvent event in udpSocket) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket.receive();
          if (datagram != null) {
            final data = datagram.data;
            final senderAddress = datagram.address.address;

            // Ответ: {'G', 'T', 1, ...} (всего 11 байт)
            if (data.length >= 11 &&
                data[0] == 71 && // 'G'
                data[1] == 84 && // 'T'
                data[2] == 1) {
              // Команда 1
              debugPrint(
                '[UDP Service] Получен ответ от $senderAddress: ${data.toList()}',
              );

              final totalLeds =
                  data[3] * 100 + data[4]; // <- Исправлено согласно протоколу
              final power = data[5] == 1;
              final brightness = data[6];
              final autoChange = data[7] == 1;
              final randomChange = data[8] == 1;
              final period = data[9];
              final timerActive = data[10] == 1; // <- Теперь 10-й байт
              final timerMinutes = data[11]; // <- Теперь 11-й байт

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

              udpSocket.close();
              debugPrint(
                '[UDP Service] Настройки получены для $ip: totalLeds=$totalLeds, power=$power, brightness=$brightness, autoChange=$autoChange, randomChange=$randomChange, period=$period, timerActive=$timerActive, timerMinutes=$timerMinutes',
              );
              return settings;
            } else {
              debugPrint(
                '[UDP Service] Получен НЕПРАВИЛЬНЫЙ ответ от $senderAddress: ${data.toList()}',
              );
            }
            break; // Получили ответ или не тот формат - выходим
          }
        }
      }
      // Если цикл завершился без возврата
      debugPrint(
        '[UDP Service] Ответ не получен вовремя или формат неверный для $ip',
      );
    } catch (e) {
      debugPrint('[UDP Service] Ошибка при получении настроек для $ip: $e');
    }
    return null;
  }

  // === ВЫБОР ЭФФЕКТА (ОСТАЁТСЯ БЕЗ ИЗМЕНЕНИЙ, Т.К. ОЖИДАЕТ ОТВЕТ) ===
  Future<EffectParams?> sendSelectEffectCommand(
    String ip,
    int effectIndex,
  ) async {
    debugPrint(
      '[UDP Service] Отправка команды выбора эффекта для $ip: {G, T, 4, 0, $effectIndex}',
    );
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 4, 0, n}
      final requestPacket = <int>[71, 84, 4, 0, effectIndex];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);
      debugPrint(
        '[UDP Service] Отправлен пакет: [71, 84, 4, 0, $effectIndex] на $deviceAddress:8888',
      );

      Timer(Duration(seconds: 2), () {
        // Увеличенный таймаут
        udpSocket.close();
        debugPrint(
          '[UDP Service] Сокет закрыт по таймауту в sendSelectEffectCommand',
        );
      });

      await for (RawSocketEvent event in udpSocket) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket.receive();
          if (datagram != null) {
            final data = datagram.data;
            final senderAddress = datagram.address.address;

            // Ответ: {'G', 'T', 4, favorite, масштаб, скорость}
            if (data.length >= 6 &&
                data[0] == 71 && // 'G'
                data[1] == 84 && // 'T'
                data[2] == 4) {
              // Команда 4
              debugPrint(
                '[UDP Service] Получен ответ от $senderAddress: ${data.toList()}',
              );

              final favorite = data[3] == 1;
              final scale = data[4];
              final speed = data[5];

              final params = EffectParams(
                favorite: favorite,
                scale: scale,
                speed: speed,
              );

              udpSocket.close();
              debugPrint(
                '[UDP Service] Параметры эффекта получены для $ip: favorite=$favorite, scale=$scale, speed=$speed',
              );
              return params;
            } else {
              debugPrint(
                '[UDP Service] Получен НЕПРАВИЛЬНЫЙ ответ от $senderAddress: ${data.toList()}',
              );
            }
            break; // Получили ответ или не тот формат - выходим
          }
        }
      }
      // Если цикл завершился без возврата
      debugPrint(
        '[UDP Service] Ответ не получен вовремя или формат неверный для $ip после команды выбора эффекта',
      );
      udpSocket.close();
    } catch (e) {
      debugPrint(
        '[UDP Service] Ошибка при отправке команды выбора эффекта для $ip: $e',
      );
    }
    return null; // Возвращаем null в случае ошибки или таймаута
  }

  // === ПОИСК ГИРЛЯНД (ИСПРАВЛЕНО НА ВОЗВРАТ ЗНАЧЕНИЯ ВО ВСЕХ СЛУЧАЯХ) ===
  Future<List<GarlandDevice>> searchGarlands() async {
    // Создаём пустой список заранее, чтобы его можно было вернуть в любом случае
    final List<GarlandDevice> foundDevices = [];

    try {
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();

      if (wifiIP == null || wifiIP.isEmpty || wifiIP == "0.0.0.0") {
        debugPrint('[UDP Service] Wi-Fi не подключен');
        return foundDevices; // Возвращаем пустой список
      }

      if (wifiBroadcast == null || wifiBroadcast.isEmpty) {
        debugPrint('[UDP Service] Не удалось получить широковещательный адрес');
        return foundDevices; // Возвращаем пустой список
      }

      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      udpSocket.broadcastEnabled = true;

      // Запрос IP: {'G', 'T', 0}
      final requestPacket = <int>[71, 84, 0];
      final broadcastAddress = InternetAddress(wifiBroadcast);
      udpSocket.send(requestPacket, broadcastAddress, 8888);
      debugPrint(
        '[UDP Service] Отправлен широковещательный пакет: [71, 84, 0] на $broadcastAddress:8888',
      );

      Timer(Duration(seconds: 2), () {
        udpSocket.close();
        debugPrint('[UDP Service] Сокет поиска закрыт по таймауту');
      });

      await for (RawSocketEvent event in udpSocket) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket.receive();
          if (datagram != null) {
            final data = datagram.data;
            final senderAddress = datagram.address.address;

            // Ответ: {'G', 'T', 0, ip} (согласно протоколу)
            if (data.length >= 4 &&
                data[0] == 71 && // 'G'
                data[1] == 84 && // 'T'
                data[2] == 0) {
              // Команда 0
              debugPrint(
                '[UDP Service] Найдено устройство от $senderAddress: ${data.toList()}',
              );

              final lastOctet = data[3];
              final device = GarlandDevice(
                ip: senderAddress,
                lastOctet: lastOctet,
              );
              foundDevices.add(device);
              debugPrint('[UDP Service] Добавлено устройство: ${device.ip}');
            }
          }
        }
      }
      // Если всё прошло успешно, возвращаем найденные устройства
      return foundDevices;
    } catch (e) {
      // В случае ЛЮБОЙ ошибки, логируем её и возвращаем пустой список
      debugPrint('[UDP Service] Ошибка при поиске гирлянд: $e');
      return foundDevices; // <-- КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: всегда возвращаем список
    }
  }

  // === ЧАСТНАЯ ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ ОТПРАВКИ КОМАНД БЕЗ ОЖИДАНИЯ ОТВЕТА ===
  /// Отправляет UDP-пакет на указанный IP-адрес и порт.
  /// Добавляет префикс "GT" к команде.
  /// Делает небольшую задержку и закрывает сокет.
  Future<void> _sendUdpCommand(String ip, List<int> command) async {
    // Формируем полный пакет с префиксом "GT"
    final requestPacket = <int>[71, 84, ...command]; // 71='G', 84='T'
    final deviceAddress = InternetAddress(ip);

    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Отправка пакета
      udpSocket.send(requestPacket, deviceAddress, 8888);
      debugPrint(
        '[UDP Service] Отправлен пакет: $requestPacket на $deviceAddress:8888',
      );

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(const Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('[UDP Service] Ошибка при отправке команды на $ip: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ ПИТАНИЯ ===
  Future<void> sendPowerCommand(String ip, bool power) async {
    debugPrint(
      '[UDP Service] Отправка команды питания для $ip: {G, T, 2, 1, ${power ? 1 : 0}}',
    );
    final val = power ? 1 : 0;
    await _sendUdpCommand(ip, [2, 1, val]);
    debugPrint('[UDP Service] Команда питания отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ КОЛИЧЕСТВА ЛЕДОВ ===
  Future<void> sendLedCountCommand(String ip, int ledCount) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения количества ледов для $ip: {G, T, 2, 0, ${ledCount ~/ 100}, ${ledCount % 100}}',
    );
    final am1 = ledCount ~/ 100;
    final am2 = ledCount % 100;
    await _sendUdpCommand(ip, [2, 0, am1, am2]);
    debugPrint('[UDP Service] Команда изменения количества ледов отправлена');
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ЯРКОСТИ ===
  Future<void> sendBrightnessCommand(String ip, int brightness) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения яркости для $ip: {G, T, 2, 2, $brightness}',
    );
    final val = brightness.clamp(1, 251);
    await _sendUdpCommand(ip, [2, 2, val]);
    debugPrint('[UDP Service] Команда изменения яркости отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ СОСТОЯНИЯ ТАЙМЕРА ===
  Future<void> sendTimerActiveCommand(String ip, bool timerActive) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения состояния таймера для $ip: {G, T, 2, 7}',
    );
    await _sendUdpCommand(ip, [2, 7]);
    debugPrint(
      '[UDP Service] Команда изменения состояния таймера отправлена успешно',
    );
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ВРЕМЕНИ ТАЙМЕРА ===
  Future<void> sendTimerMinutesCommand(String ip, int timerMinutes) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения времени таймера для $ip: {G, T, 2, 8, $timerMinutes}',
    );
    final val = timerMinutes.clamp(1, 240);
    await _sendUdpCommand(ip, [2, 8, val]);
    debugPrint(
      '[UDP Service] Команда изменения времени таймера отправлена успешно',
    );
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ФЛАГА АВТОСМЕНЫ ===
  Future<void> sendAutoChangeCommand(String ip, bool autoChange) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения флага автосмены для $ip: {G, T, 2, 3, ${autoChange ? 1 : 0}}',
    );
    final val = autoChange ? 1 : 0;
    await _sendUdpCommand(ip, [2, 3, val]);
    debugPrint(
      '[UDP Service] Команда изменения флага автосмены отправлена успешно',
    );
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ФЛАГА СЛУЧАЙНОЙ СМЕНЫ ===
  Future<void> sendRandomChangeCommand(String ip, bool randomChange) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения флага случайной смены для $ip: {G, T, 2, 4, ${randomChange ? 1 : 0}}',
    );
    final val = randomChange ? 1 : 0;
    await _sendUdpCommand(ip, [2, 4, val]);
    debugPrint(
      '[UDP Service] Команда изменения флага случайной смены отправлена успешно',
    );
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ПЕРИОДА СМЕНЫ ===
  Future<void> sendPeriodCommand(String ip, int period) async {
    debugPrint(
      '[UDP Service] Отправка команды изменения периода смены для $ip: {G, T, 2, 5, $period}',
    );
    final val = period.clamp(1, 10);
    await _sendUdpCommand(ip, [2, 5, val]);
    debugPrint(
      '[UDP Service] Команда изменения периода смены отправлена успешно',
    );
  }

  // === ОТПРАВКА КОМАНДЫ "СЛЕДУЮЩИЙ ЭФФЕКТ" ===
  Future<void> sendNextEffectCommand(String ip) async {
    debugPrint(
      '[UDP Service] Отправка команды "следующий эффект" для $ip: {G, T, 2, 6}',
    );
    await _sendUdpCommand(ip, [2, 6]);
    debugPrint('[UDP Service] Команда "следующий эффект" отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ ИЗБРАННОЕ ===
  Future<void> sendFavoriteCommand(String ip, bool favorite) async {
    debugPrint(
      '[UDP Service] Отправка команды избранное для $ip: {G, T, 4, 1, ${favorite ? 1 : 0}}',
    );
    final val = favorite ? 1 : 0;
    await _sendUdpCommand(ip, [4, 1, val]);
    debugPrint('[UDP Service] Команда избранное отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ МАСШТАБ ===
  Future<void> sendScaleCommand(String ip, int scale) async {
    debugPrint(
      '[UDP Service] Отправка команды масштаб для $ip: {G, T, 4, 2, $scale}',
    );
    final clampedScale = scale.clamp(0, 255);
    await _sendUdpCommand(ip, [4, 2, clampedScale]);
    debugPrint('[UDP Service] Команда масштаб отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ СКОРОСТЬ ===
  Future<void> sendSpeedCommand(String ip, int speed) async {
    debugPrint(
      '[UDP Service] Отправка команды скорость для $ip: {G, T, 4, 3, $speed}',
    );
    final clampedSpeed = speed.clamp(0, 255);
    await _sendUdpCommand(ip, [4, 3, clampedSpeed]);
    debugPrint('[UDP Service] Команда скорость отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ ЗАПУСКА КАЛИБРОВКИ ===
  Future<void> sendCalibrationStartCommand(String ip) async {
    debugPrint(
      '[UDP Service] Отправка команды запуска калибровки для $ip: {G, T, 3, 0}',
    );
    await _sendUdpCommand(ip, [3, 0]);
    debugPrint('[UDP Service] Команда запуска калибровки отправлена успешно');
  }

  // === ОТПРАВКА КОМАНДЫ СЛЕДУЮЩЕГО СВЕТОДИОДА КАЛИБРОВКИ ===
  Future<void> sendCalibrationNextLedCommand(
    String ip,
    int ledNumber,
    int x,
    int y,
  ) async {
    debugPrint(
      '[UDP Service] Отправка команды следующего светодиода калибровки для $ip: {G, T, 3, 1, ${ledNumber ~/ 100}, ${ledNumber % 100}, $x, $y}',
    );
    final n1 = ledNumber ~/ 100;
    final n2 = ledNumber % 100;
    await _sendUdpCommand(ip, [3, 1, n1, n2, x, y]);
    debugPrint(
      '[UDP Service] Команда следующего светодиода калибровки отправлена успешно',
    );
  }

  // === ОТПРАВКА КОМАНДЫ ОСТАНОВКИ КАЛИБРОВКИ ===
  Future<void> sendCalibrationStopCommand(String ip) async {
    debugPrint(
      '[UDP Service] Отправка команды остановки калибровки для $ip: {G, T, 3, 2}',
    );
    await _sendUdpCommand(ip, [3, 2]);
    debugPrint('[UDP Service] Команда остановки калибровки отправлена успешно');
  }

  // === СОХРАНЕНИЕ ГИРЛЯНД В ЛОКАЛЬНОЕ ХРАНИЛИЩЕ ===
  Future<void> saveGarlands(List<GarlandDevice> garlands) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedGarlands =
        garlands.map((device) {
          final power = device.settings?.power ?? false;
          return "${device.ip}|${device.lastOctet}|$power";
        }).toList();

    await prefs.setStringList('saved_garlands', encodedGarlands);
    debugPrint(
      '[UDP Service] Сохранено устройств в локальное хранилище: ${encodedGarlands.length}',
    );
  }

  // === ЗАГРУЗКА ГИРЛЯНД ИЗ ЛОКАЛЬНОГО ХРАНИЛИЩА ===
  Future<List<GarlandDevice>> loadGarlands() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedGarlands = prefs.getStringList('saved_garlands');

    if (encodedGarlands == null || encodedGarlands.isEmpty) {
      debugPrint(
        '[UDP Service] Нет сохранённых устройств в локальном хранилище',
      );
      return [];
    }

    final List<GarlandDevice> loadedGarlands = [];
    for (String encoded in encodedGarlands) {
      final parts = encoded.split('|');
      if (parts.length == 3) {
        try {
          final ip = parts[0];
          final lastOctet = int.parse(parts[1]);
          final power = parts[2] == 'true';

          final settings = GarlandSettings(
            totalLeds: 0, // Значение по умолчанию
            power: power,
            brightness: 128, // Значение по умолчанию
            autoChange: false, // Значение по умолчанию
            randomChange: false, // Значение по умолчанию
            period: 1, // Значение по умолчанию
            timerActive: false, // Значение по умолчанию
            timerMinutes: 1, // Значение по умолчанию
          );

          final device = GarlandDevice(
            ip: ip,
            lastOctet: lastOctet,
            settings: settings,
          );
          loadedGarlands.add(device);
        } catch (e) {
          debugPrint(
            '[UDP Service] Ошибка при разборе сохранённой гирлянды: $encoded, $e',
          );
        }
      }
    }
    debugPrint(
      '[UDP Service] Загружено устройств из локального хранилища: ${loadedGarlands.length}',
    );
    return loadedGarlands;
  }
}

// === КЛАСС ДЛЯ ПАРАМЕТРОВ ЭФФЕКТА ===
class EffectParams {
  final bool favorite;
  final int scale;
  final int speed;

  EffectParams({
    required this.favorite,
    required this.scale,
    required this.speed,
  });
}
