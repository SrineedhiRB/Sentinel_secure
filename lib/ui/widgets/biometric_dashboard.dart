// lib/ui/widgets/biometric_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/biometric_service.dart';

class BiometricDashboard extends ConsumerWidget {
  const BiometricDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(biometricAnalyticsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Confidence gauge
        StreamBuilder<double>(
          stream: analytics.confidenceStream,
          builder: (context, snapshot) {
            final confidence = snapshot.data ?? 0.0;
            return Column(
              children: [
                Text('Live Confidence', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: confidence,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFF00E5FF),
                ),
                Text('${(confidence * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Liveness status and spoof alert
        FutureBuilder<bool>(
          future: analytics.checkLiveness(),
          builder: (context, snapshot) {
            final isLive = snapshot.data ?? true;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isLive ? Icons.check_circle : Icons.error,
                    color: isLive ? Colors.greenAccent : Colors.redAccent,
                    size: 28),
                const SizedBox(width: 8),
                Text(isLive ? 'Live' : 'Spoof Detected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isLive ? Colors.greenAccent : Colors.redAccent)),
                if (!isLive)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
