// lib/screens/garland_calibration_screen.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/garland_device.dart';
import '../services/udp_service.dart';

class GarlandCalibrationScreen extends StatefulWidget {
  final GarlandDevice device;

  const GarlandCalibrationScreen({super.key, required this.device});

  @override
  State<GarlandCalibrationScreen> createState() =>
      _GarlandCalibrationScreenState();
}

class _GarlandCalibrationScreenState extends State<GarlandCalibrationScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCalibrating = false;
  int _currentLed = 0;
  int _totalLeds = 0;
  Timer? _calibrationTimer;
  final UdpService _udpService = UdpService();

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('Камера не найдена');
      return;
    }

    // Выбираем первую доступную камеру (обычно задняя)
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium, // Или другой подходящий режим
    );

    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  Future<void> _startCalibration() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Камера не инициализирована');
      return;
    }

    if (widget.device.settings == null) {
      debugPrint('Настройки гирлянды не загружены');
      return;
    }

    setState(() {
      _isCalibrating = true;
      _currentLed = 0;
      _totalLeds = widget.device.settings!.totalLeds;
    });

    // Отправляем команду запуска калибровки на ESP
    await _udpService.sendCalibrationStartCommand(widget.device.ip);

    _calibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!_isCalibrating || _currentLed >= _totalLeds) {
        timer.cancel();
        return;
      }

      // Отправляем команду на включение следующего светодиода
      await _udpService.sendCalibrationNextLedCommand(
        widget.device.ip,
        _currentLed,
        0,
        0,
      );

      setState(() {
        _currentLed++;
      });

      // Завершаем калибровку, если все светодиоды пройдены
      if (_currentLed >= _totalLeds) {
        _stopCalibration();
      }
    });
  }

  Future<void> _stopCalibration() async {
    setState(() {
      _isCalibrating = false;
    });

    _calibrationTimer?.cancel();

    // Отправляем команду остановки калибровки на ESP
    await _udpService.sendCalibrationStopCommand(widget.device.ip);
  }

  @override
  void dispose() {
    _calibrationTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Убран AppBar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Expanded для максимального использования вертикального пространства камерой
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child:
                    _controller == null
                        ? const Center(child: Text('Загрузка камеры...'))
                        : FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return CameraPreview(
                                _controller!,
                              ); // CameraPreview теперь внутри Expanded
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
              ),
            ),
            const SizedBox(height: 16), // Отступ между камерой и остальным
            // Индикатор прогресса
            LinearProgressIndicator(
              value: _totalLeds > 0 ? _currentLed / _totalLeds : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Светодиод: $_currentLed / $_totalLeds',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Кнопки управления калибровкой
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Кнопка "Старт"
                ElevatedButton(
                  onPressed: _isCalibrating ? null : _startCalibration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Старт'),
                ),
                // Кнопка "Стоп"
                ElevatedButton(
                  onPressed: _isCalibrating ? _stopCalibration : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Стоп'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
