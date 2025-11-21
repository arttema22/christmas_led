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

  // === ЗАПРОС НАСТРОЕК ===
  Future<GarlandSettings?> fetchSettings(String ip) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Запрос: {'G', 'T', 1}
      final requestPacket = <int>[71, 84, 1];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      Timer(Duration(seconds: 1), () {
        udpSocket.close();
      });

      await for (RawSocketEvent event in udpSocket) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket.receive();
          if (datagram != null) {
            final data = datagram.data;

            // Ответ: {'G', 'T', 1, ...} (всего 11 байт)
            if (data.length >= 11 &&
                data[0] == 71 && // 'G'
                data[1] == 84 && // 'T'
                data[2] == 1) {
              // Команда 1

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

              return settings;
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при получении настроек для $ip: $e');
    }
    return null;
  }

  // === ОТПРАВКА КОМАНДЫ ПИТАНИЯ ===
  Future<void> sendPowerCommand(String ip, bool power) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 1, val}
      final val = power ? 1 : 0;
      final requestPacket = <int>[71, 84, 2, 1, val];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды питания: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ КОЛИЧЕСТВА ЛЕДОВ И ПОВТОРНЫЙ ЗАПРОС НАСТРОЕК ===
  Future<GarlandSettings?> sendLedCountCommand(String ip, int ledCount) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 0, am1, am2}
      final am1 = ledCount ~/ 100;
      final am2 = ledCount % 100;
      final requestPacket = <int>[71, 84, 2, 0, am1, am2];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));

      // === ПОВТОРНЫЙ ЗАПРОС НАСТРОЕК ===
      final updatedSettings = await fetchSettings(ip);

      udpSocket.close();
      return updatedSettings;
    } catch (e) {
      debugPrint('Ошибка при отправке команды изменения количества ледов: $e');
      return null;
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ЯРКОСТИ ===
  Future<void> sendBrightnessCommand(String ip, int brightness) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 2, val}
      final val = brightness.clamp(1, 251);
      final requestPacket = <int>[71, 84, 2, 2, val];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды изменения яркости: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ СОСТОЯНИЯ ТАЙМЕРА ===
  Future<void> sendTimerActiveCommand(String ip, bool timerActive) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 7} - отправить состояние таймера выключения
      final requestPacket = <int>[71, 84, 2, 7];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды изменения состояния таймера: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ВРЕМЕНИ ТАЙМЕРА ===
  Future<void> sendTimerMinutesCommand(String ip, int timerMinutes) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 8, val}
      final val = timerMinutes.clamp(1, 240);
      final requestPacket = <int>[71, 84, 2, 8, val];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды изменения времени таймера: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ФЛАГА АВТОСМЕНЫ ===
  Future<void> sendAutoChangeCommand(String ip, bool autoChange) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 3, val}
      final val = autoChange ? 1 : 0;
      final requestPacket = <int>[71, 84, 2, 3, val];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды изменения флага автосмены: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ФЛАГА СЛУЧАЙНОЙ СМЕНЫ ===
  Future<void> sendRandomChangeCommand(String ip, bool randomChange) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 4, val}
      final val = randomChange ? 1 : 0;
      final requestPacket = <int>[71, 84, 2, 4, val];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint(
        'Ошибка при отправке команды изменения флага случайной смены: $e',
      );
    }
  }

  // === ОТПРАВКА КОМАНДЫ ИЗМЕНЕНИЯ ПЕРИОДА СМЕНЫ ===
  Future<void> sendPeriodCommand(String ip, int period) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 5, val}
      final val = period.clamp(1, 10); // Ограничиваем в диапазоне 1-10
      final requestPacket = <int>[71, 84, 2, 5, val];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды изменения периода смены: $e');
    }
  }

  // === ОТПРАВКА КОМАНДЫ "СЛЕДУЮЩИЙ ЭФФЕКТ" ===
  Future<void> sendNextEffectCommand(String ip) async {
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Команда: {'G', 'T', 2, 6}
      final requestPacket = <int>[71, 84, 2, 6];
      final deviceAddress = InternetAddress(ip);
      udpSocket.send(requestPacket, deviceAddress, 8888);

      // Небольшая задержка, чтобы пакет успел отправиться
      await Future.delayed(Duration(milliseconds: 100));
      udpSocket.close();
    } catch (e) {
      debugPrint('Ошибка при отправке команды "следующий эффект": $e');
    }
  }

  // === ПОИСК ГИРЛЯНД ===
  Future<List<GarlandDevice>> searchGarlands() async {
    final List<GarlandDevice> foundDevices = [];

    try {
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();

      if (wifiIP == null || wifiIP.isEmpty || wifiIP == "0.0.0.0") {
        debugPrint('Wi-Fi не подключен');
        return foundDevices;
      }

      if (wifiBroadcast == null || wifiBroadcast.isEmpty) {
        debugPrint('Не удалось получить широковещательный адрес');
        return foundDevices;
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

      Timer(Duration(seconds: 2), () {
        udpSocket.close();
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
              final lastOctet = data[3];
              final device = GarlandDevice(
                ip: senderAddress,
                lastOctet: lastOctet,
              );
              foundDevices.add(device);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при поиске гирлянд: $e');
    }

    return foundDevices;
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
  }

  // === ЗАГРУЗКА ГИРЛЯНД ИЗ ЛОКАЛЬНОГО ХРАНИЛИЩА ===
  Future<List<GarlandDevice>> loadGarlands() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedGarlands = prefs.getStringList('saved_garlands');

    if (encodedGarlands == null || encodedGarlands.isEmpty) {
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
            totalLeds: 0,
            power: power,
            brightness: 128,
            autoChange: false,
            randomChange: false,
            period: 1, // Значение по умолчанию в диапазоне 1-10
            timerActive: false,
            timerMinutes: 1,
          );

          final device = GarlandDevice(
            ip: ip,
            lastOctet: lastOctet,
            settings: settings,
          );
          loadedGarlands.add(device);
        } catch (e) {
          debugPrint('Ошибка при разборе сохранённой гирлянды: $encoded, $e');
        }
      }
    }
    return loadedGarlands;
  }
}
