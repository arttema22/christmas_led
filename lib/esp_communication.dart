import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class EspCommunication {
  static const int espPort = 8888;
  static const int broadcastPort = 8888;
  static const String broadcastAddress = '255.255.255.255';

  static Future<List<String>?> discoverEsp() async {
    late RawDatagramSocket socket;
    String subnetPrefix = '192.168.1.';

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      List<int> packet = [71, 84, 0]; // 'G' = 71, 'T' = 84, 0 = 0

      socket.send(
        Uint8List.fromList(packet),
        InternetAddress(broadcastAddress),
        broadcastPort,
      );

      List<String> espAddresses = [];
      Completer<void> timeoutCompleter = Completer<void>();

      Timer(const Duration(seconds: 3), () {
        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete();
        }
      });

      StreamSubscription<RawSocketEvent> subscription = socket
          .asBroadcastStream()
          .listen((event) {
            if (event == RawSocketEvent.read) {
              Datagram? dg = socket.receive();
              if (dg != null) {
                Uint8List data = dg.data;
                if (data.length == 4 &&
                    data[0] == 71 &&
                    data[1] == 84 &&
                    data[2] == 0) {
                  int lastOctet = data[3];
                  if (lastOctet > 0 && lastOctet < 255) {
                    String espAddress = '$subnetPrefix$lastOctet';
                    if (!espAddresses.contains(espAddress)) {
                      espAddresses.add(espAddress);
                      // Заменили print на debugPrint
                      debugPrint('Найдено ESP по адресу: $espAddress');
                    }
                  } else {
                    // Заменили print на debugPrint
                    debugPrint(
                      'Получен некорректный октет IP: $lastOctet, игнорируем',
                    );
                  }
                }
              }
            }
          });

      await timeoutCompleter.future;
      await subscription.cancel();

      return espAddresses.isEmpty ? null : espAddresses;
    } catch (e) {
      // Заменили print на debugPrint
      debugPrint('Ошибка при поиске ESP: $e');
      return null;
    } finally {
      socket.close();
    }
  }

  static Future<Uint8List?> sendCommand(String ip, List<int> command) async {
    late RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(Uint8List.fromList(command), InternetAddress(ip), espPort);

      Completer<Uint8List?> completer = Completer();
      Timer timeout = Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = socket.receive();
          if (dg != null && dg.address.address == ip) {
            if (!completer.isCompleted) {
              completer.complete(dg.data);
              timeout.cancel();
            }
          }
        }
      });

      Uint8List? response = await completer.future;
      return response;
    } catch (e) {
      // Заменили print на debugPrint
      debugPrint('Ошибка при отправке команды на $ip: $e');
      return null;
    } finally {
      socket.close();
    }
  }

  // Примеры команд
  static List<int> getIpPacket() => [71, 84, 0];
  static List<int> getSettingsPacket() => [71, 84, 1];
  static List<int> setPowerPacket(bool on) => [71, 84, 2, 1, on ? 1 : 0];
  static List<int> setBrightnessPacket(int brightness) => [
    71,
    84,
    2,
    2,
    brightness,
  ];
}
