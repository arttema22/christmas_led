import 'garland_settings.dart';

class GarlandDevice {
  final String ip;
  final int lastOctet;
  GarlandSettings? settings;

  GarlandDevice({required this.ip, required this.lastOctet, this.settings});
}
