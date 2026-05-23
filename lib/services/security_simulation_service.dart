// lib/services/security_simulation_service.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger();

class SecuritySimulationService {
  // Simulated threat level (0-100) stream
  Stream<int> get threatLevelStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      // Random threat level for demo purposes
      final level = (DateTime.now().second * 7) % 101; // 0‑100 range
      _log.i('Threat level: $level');
      yield level;
    }
  }
}

// Riverpod provider
final securitySimulationProvider = Provider<SecuritySimulationService>((ref) => SecuritySimulationService());
