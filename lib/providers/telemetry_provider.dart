// lib/providers/telemetry_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Simulated AI telemetry stream emitting metrics every second.
class TelemetryData {
  final double cpuUsage; // percentage
  final double gpuUsage; // percentage
  final double inferenceLatency; // ms
  final int activeEdges; // number of edge AI modules active
  TelemetryData({
    required this.cpuUsage,
    required this.gpuUsage,
    required this.inferenceLatency,
    required this.activeEdges,
  });
}

final telemetryProvider = StreamProvider<TelemetryData>((ref) {
  // In a real system this would pull from native platforms or a backend.
  const duration = Duration(seconds: 1);
  return Stream.periodic(duration, (_) {
    // Generate random but plausible values.
    final now = DateTime.now().millisecondsSinceEpoch;
    final double cpu = (now % 100).toDouble();
    final double gpu = ((now ~/ 2) % 100).toDouble();
    final double latency = (now % 250) + 50.0; // 50‑300 ms
    final int edges = (now % 8) + 1; // 1‑8 edge modules
    return TelemetryData(
      cpuUsage: cpu,
      gpuUsage: gpu,
      inferenceLatency: latency,
      activeEdges: edges,
    );
  });
});
