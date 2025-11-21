// lib/services/udp_service.dart
import 'dart:async'; // Добавлено для Timer
import 'dart:io';
import 'package:flutter/foundation.dart'; // Добавлено для debugPrint
import 'package:network_info_plus/network_info_plus.dart';
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
        // Timer теперь доступен
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

              return settings;
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Ошибка при получении настроек для $ip: $e',
      ); // debugPrint теперь доступен
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
      debugPrint(
        'Ошибка при отправке команды питания: $e',
      ); // debugPrint теперь доступен
    }
  }

  // === ПОИСК ГИРЛЯНД ===
  Future<List<GarlandDevice>> searchGarlands() async {
    final List<GarlandDevice> foundDevices = [];

    try {
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();

      if (wifiIP == null || wifiIP.isEmpty || wifiIP == "0.0.0.0") {
        debugPrint('Wi-Fi не подключен'); // debugPrint теперь доступен
        return foundDevices;
      }

      if (wifiBroadcast == null || wifiBroadcast.isEmpty) {
        debugPrint(
          'Не удалось получить широковещательный адрес',
        ); // debugPrint теперь доступен
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
        // Timer теперь доступен
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
      debugPrint('Ошибка при поиске гирлянд: $e'); // debugPrint теперь доступен
    }

    return foundDevices;
  }
}
