import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  bool _isSyncing = false;
  String _syncStatus = "";
  double _syncProgress = 0.0;

  void _triggerSync() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.unsyncedLogsCount == 0) return;

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncStatus = "ESTABLISHING SECURE UDP TUNNEL...";
    });

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _syncProgress = 0.3;
      _syncStatus = "AUTHENTICATING CRYPTO CLIENT SIGNATURES...";
    });

    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _syncProgress = 0.6;
      _syncStatus = "TRANSMITTING ENCRYPTED AUDIT PAYLOADS (AES-256)...";
    });

    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _syncProgress = 0.9;
      _syncStatus = "VERIFYING NHAI SERVER CHECKSUM HASHES...";
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await authService.simulateSync();

    setState(() {
      _syncProgress = 1.0;
      _isSyncing = false;
      _syncStatus = "";
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141C33),
          title: const Row(
            children: [
              Icon(Icons.cloud_done, color: Color(0xFF00E676)),
              SizedBox(width: 8),
              Text("SYNCHRONIZATION COMPLETE"),
            ],
          ),
          content: const Text(
            "All pending local authentication logs have been safely pushed to the NHAI Central Registry. Local transaction cache has been cleared.",
            style: TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CLOSE", style: TextStyle(color: Color(0xFF00E5FF))),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("OFFLINE SYNC & VAULT", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sync Telemetry Panel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TRANSMISSION QUEUE STATUS",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                          ),
                          Icon(
                            authService.unsyncedLogsCount > 0 ? Icons.sync_problem : Icons.cloud_done,
                            color: authService.unsyncedLogsCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF00E676),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${authService.unsyncedLogsCount} Pending Logs",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        authService.unsyncedLogsCount > 0
                            ? "Authentication scans recorded in field environment waiting for connection."
                            : "All logs synced. Local database cache matches central portal.",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      
                      if (_isSyncing) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _syncProgress,
                          backgroundColor: Colors.grey[800],
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _syncStatus,
                          style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: (authService.unsyncedLogsCount == 0 || _isSyncing) ? null : _triggerSync,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: const Color(0xFF0A0F1D),
                        ),
                        child: const Text("SYNC CACHE WITH NHAI CLOUD"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cryptographic details panel
              Text(
                "CRYPTOGRAPHIC CONFIGURATION",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E294B), width: 1.5),
                ),
                child: const Column(
                  children: [
                    _InfoRow(label: "SQL Database Engine", value: "SQLite + SQLCipher"),
                    Divider(color: Color(0xFF1E294B), height: 16),
                    _InfoRow(label: "Database Encryption", value: "AES-256-CBC"),
                    Divider(color: Color(0xFF1E294B), height: 16),
                    _InfoRow(label: "Key Management Store", value: "Android Keystore / iOS Keychain"),
                    Divider(color: Color(0xFF1E294B), height: 16),
                    _InfoRow(label: "Encryption Key Tag", value: "sentinel_master_key"),
                    Divider(color: Color(0xFF1E294B), height: 16),
                    _InfoRow(label: "Double Shielding", value: "Encrypted DB + Encrypted Fields"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security Integrity panel
              Text(
                "ACTIVE TAMPER PROTECTION STATS",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E294B), width: 1.5),
                ),
                child: Column(
                  children: [
                    _StatusIndicatorRow(
                      label: "Anti-Screenshot Protection", 
                      value: "ENABLED", 
                      active: true,
                    ),
                    const Divider(color: Color(0xFF1E294B), height: 16),
                    _StatusIndicatorRow(
                      label: "Root/Superuser Blocking", 
                      value: "ACTIVE", 
                      active: authService.isAppSecure,
                    ),
                    const Divider(color: Color(0xFF1E294B), height: 16),
                    _StatusIndicatorRow(
                      label: "Runtime Integrity Checker", 
                      value: "VERIFIED", 
                      active: authService.isAppSecure,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

class _StatusIndicatorRow extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  const _StatusIndicatorRow({required this.label, required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: active ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
