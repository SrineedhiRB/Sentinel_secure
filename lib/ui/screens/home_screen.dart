import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/database/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  int _userCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final users = await _dbService.getAllUsers();
      if (mounted) {
        setState(() {
          _userCount = users.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isTollOperator = authService.currentUserRole == 'Toll Operator';
    final isAdmin = authService.currentUserRole == 'Admin';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00E676), // Green indicating offline ready
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "SECURE TERMINAL",
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF3D00)),
            onPressed: () {
              authService.resetState();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operator status card (Glassmorphic look)
              _buildOperatorHeader(authService),
              const SizedBox(height: 24),

              // Environment health grid
              Text(
                "SYSTEM TELEMETRY",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildTelemetryGrid(authService),
              const SizedBox(height: 24),

              // Menu Options
              Text(
                "TACTICAL OPERATION UTILITIES",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              
              // Verify scan button (Primary Action)
              _buildActionButton(
                context: context,
                title: "START BIOMETRIC SCAN",
                subtitle: "Real-time face matching & liveness scan",
                icon: Icons.face,
                color: Theme.of(context).colorScheme.primary,
                route: '/camera_scan',
              ),
              const SizedBox(height: 12),

              // Enroll user (restricted for Toll Operators)
              _buildActionButton(
                context: context,
                title: "ENROLL NEW BIOMETRIC",
                subtitle: "Register officer/contractor securely",
                icon: Icons.person_add,
                color: isTollOperator ? Colors.grey[700]! : Theme.of(context).colorScheme.secondary,
                route: isTollOperator ? null : '/registration',
                enabled: !isTollOperator,
              ),
              const SizedBox(height: 12),

              // Searchable local audit history logs
              _buildActionButton(
                context: context,
                title: "AUDIT LOGS DASHBOARD",
                subtitle: "Search, analyze, and export local files",
                icon: Icons.receipt_long,
                color: const Color(0xFF818CF8),
                route: '/audit_dashboard',
              ),
              const SizedBox(height: 12),

              // Settings and Cloud sync (Admin only)
              _buildActionButton(
                context: context,
                title: "OFFLINE SYNC & SYSTEM VAULT",
                subtitle: "Force queues sync, manage DB assets",
                icon: Icons.sync,
                color: isAdmin ? const Color(0xFFF59E0B) : Colors.grey[700]!,
                route: isAdmin ? '/offline_sync' : null,
                enabled: isAdmin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorHeader(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E294B), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            radius: 28,
            child: Icon(
              authService.currentUserRole == 'Admin' 
                  ? Icons.admin_panel_settings 
                  : authService.currentUserRole == 'Highway Officer' 
                      ? Icons.local_police 
                      : Icons.badge,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.currentOfficerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        authService.currentUserRole.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "ID: NHAI-OFC-072",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(AuthService authService) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildTelemetryCard(
          title: "ENROLLED USERS",
          value: _isLoading ? "..." : "$_userCount profiles",
          icon: Icons.people,
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
        _buildTelemetryCard(
          title: "UNSYNCED AUDITS",
          value: "${authService.unsyncedLogsCount} queue",
          icon: Icons.cloud_off,
          iconColor: const Color(0xFFF59E0B),
        ),
        _buildTelemetryCard(
          title: "VAULT INTEGRITY",
          value: authService.isAppSecure ? "SECURED (AES)" : "TAMPER WARNING",
          icon: Icons.gpp_good,
          iconColor: authService.isAppSecure ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
        ),
        _buildTelemetryCard(
          title: "AI INFERENCE ENGINE",
          value: "Edge CPU (TFLite)",
          icon: Icons.memory,
          iconColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1526),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E294B), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String? route,
    bool enabled = true,
  }) {
    return Card(
      color: enabled ? const Color(0xFF141C33) : const Color(0xFF0F1321),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled ? const Color(0xFF1E294B) : const Color(0xFF0F1321),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: (enabled && route != null) 
            ? () => Navigator.of(context).pushNamed(route).then((_) => _loadStats())
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(enabled ? 0.1 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: enabled ? color : Colors.grey[700], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled ? const Color(0xFF94A3B8) : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
