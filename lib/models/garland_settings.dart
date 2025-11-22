// lib/models/garland_settings.dart
class GarlandSettings {
  final int totalLeds;
  final bool power;
  final int brightness;
  final bool autoChange;
  final bool randomChange;
  final int period;
  final bool timerActive;
  final int timerMinutes;

  const GarlandSettings({
    required this.totalLeds,
    required this.power,
    required this.brightness,
    required this.autoChange,
    required this.randomChange,
    required this.period,
    required this.timerActive,
    required this.timerMinutes,
  });

  GarlandSettings copyWith({
    int? totalLeds,
    bool? power,
    int? brightness,
    bool? autoChange,
    bool? randomChange,
    int? period,
    bool? timerActive,
    int? timerMinutes,
  }) {
    return GarlandSettings(
      totalLeds: totalLeds ?? this.totalLeds,
      power: power ?? this.power,
      brightness: brightness ?? this.brightness,
      autoChange: autoChange ?? this.autoChange,
      randomChange: randomChange ?? this.randomChange,
      period: period ?? this.period,
      timerActive: timerActive ?? this.timerActive,
      timerMinutes: timerMinutes ?? this.timerMinutes,
    );
  }
}
