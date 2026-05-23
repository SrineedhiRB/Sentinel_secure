// lib/ui/screens/command_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/auth_provider.dart';
import 'grid_dashboard_screen.dart';
import 'encrypted_vault_screen.dart';
import 'audit_timeline_screen.dart';

/// The main operational command‑center hub.
/// Provides navigation to the core modules and displays live AI telemetry.
class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    GridDashboardScreen(),
    EncryptedVaultScreen(),
    AuditTimelineScreen(),
  ];

  static const List<String> _titles = [
    'National Security Grid',
    'Encrypted Vault',
    'Audit Timeline',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for spoof alerts via AuthService statusMessage.
    ref.listen<String?>(authStatusMessageProvider, (previous, next) {
      if (next != null && next.contains('Spoof')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final telemetryAsync = ref.watch(telemetryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Live telemetry banner
          telemetryAsync.when(
            data: (data) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricTile('CPU', '${data.cpuUsage.toStringAsFixed(1)}%'),
                  _metricTile('GPU', '${data.gpuUsage.toStringAsFixed(1)}%'),
                  _metricTile('Latency', '${data.inferenceLatency.toStringAsFixed(0)}ms'),
                  _metricTile('Edges', '${data.activeEdges}'),
                ],
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          // Selected module page
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Grid'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Vault'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Audit'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyanAccent,
        backgroundColor: const Color(0xFF0A0F1D),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
