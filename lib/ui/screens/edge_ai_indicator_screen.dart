// lib/ui/screens/edge_ai_indicator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/telemetry_provider.dart';
import '../../widgets/glass_container.dart';

/// Screen displaying live Edge‑AI metrics with smooth animated gauges.
class EdgeAIIndicatorScreen extends ConsumerWidget {
  const EdgeAIIndicatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(telemetryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Edge AI Indicators'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: telemetryAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGauge('CPU Usage', data.cpuUsage, Icons.memory, Colors.cyanAccent),
              const SizedBox(height: 16),
              _buildGauge('GPU Usage', data.gpuUsage, Icons.graphic_eq, Colors.deepPurpleAccent),
              const SizedBox(height: 16),
              _buildGauge('Inference Latency', data.inferenceLatency, Icons.speed, Colors.orangeAccent),
              const SizedBox(height: 16),
              _buildGauge('Active Edge Modules', data.activeEdges.toDouble(), Icons.device_hub, Colors.limeAccent),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load telemetry')),
      ),
    );
  }

  Widget _buildGauge(String label, double value, IconData icon, Color accent) {
    final max = label.contains('Latency') ? 300.0 : 100.0;
    final percent = (value / max).clamp(0.0, 1.0);
    return GlassContainer(
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, anim, _) {
                    return LinearProgressIndicator(
                      value: anim,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${value.toStringAsFixed(1)}${label.contains('Latency') ? ' ms' : '%'}',
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
