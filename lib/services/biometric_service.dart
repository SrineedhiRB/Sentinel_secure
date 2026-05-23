// lib/services/biometric_service.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// A service that simulates live biometric analytics, liveness detection,
/// spoof alerts and AI telemetry.
class BiometricAnalyticsService {
  // Simulated stream of confidence scores (0.0 - 1.0)
  Stream<double> get confidenceStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      final score = (0.7 + (0.3 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000));
      logger.i('Biometric confidence: $score');
      yield score;
    }
  }

  // Simulated liveness detection result
  Future<bool> checkLiveness() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Randomly return true (live) or false (spoof) for demo
    final live = DateTime.now().second % 2 == 0;
    logger.i('Liveness check: ${live ? "live" : "spoof"}');
    // Emit spoof alert via stream if spoof detected
    if (!live) _spoofController.add('Spoof alert detected!');
    return live;
  }

  // Spoof alert stream controller
  final _spoofController = StreamController<String>.broadcast();

  /// Stream of spoof alert messages.
  Stream<String> get spoofAlertStream => _spoofController.stream;


  // Simulated AI telemetry data
  Stream<Map<String, dynamic>> get telemetryStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final data = {
        'cpuUsage': (10 + (DateTime.now().second % 20)).toDouble(),
        'memoryUsage': (300 + (DateTime.now().second % 100)).toDouble(),
        'inferenceLatencyMs': (50 + (DateTime.now().millisecond % 50)),
      };
      logger.i('AI telemetry: $data');
      yield data;
    }
  }
}

// Riverpod provider for the service
final biometricAnalyticsProvider = Provider<BiometricAnalyticsService>((ref) => BiometricAnalyticsService());
