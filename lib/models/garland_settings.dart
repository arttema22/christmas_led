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
