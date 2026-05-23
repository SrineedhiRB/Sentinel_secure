// lib/ui/widgets/liveness_simulation.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/biometric_service.dart';

class LivenessSimulationWidget extends ConsumerWidget {
  const LivenessSimulationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the latest liveness check result (live/spoof)
    // For demo we just show a pulsing neon circle that changes color on each check.
    return StreamBuilder<bool>(
      stream: ref.read(biometricAnalyticsProvider).confidenceStream.map((_) => true),
      // The above mapping is just to trigger UI rebuild; actual liveness is stored in parent state.
      builder: (context, snapshot) {
        // Use a simple animated container to mimic a liveness heartbeat.
        return Center(
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF00E676)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.favorite, color: Colors.white, size: 40),
            ),
          ),
        );
      },
    );
  }
}
