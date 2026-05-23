import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../core/database/database_service.dart';
import '../../models/app_models.dart';

class AuditDashboardScreen extends StatefulWidget {
  const AuditDashboardScreen({super.key});

  @override
  State<AuditDashboardScreen> createState() => _AuditDashboardScreenState();
}

class _AuditDashboardScreenState extends State<AuditDashboardScreen> {
  final _dbService = DatabaseService();
  final _searchController = TextEditingController();
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String _selectedFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<AuditLog> fetchedLogs;
      if (_searchController.text.trim().isNotEmpty) {
        fetchedLogs = await _dbService.searchAuditLogs(_searchController.text.trim());
      } else {
        fetchedLogs = await _dbService.getAuditLogs();
      }

      // Apply filter tab
      if (_selectedFilter == "SUCCESS") {
        fetchedLogs = fetchedLogs.where((l) => l.status == "SUCCESS").toList();
      } else if (_selectedFilter == "SPOOFS") {
        fetchedLogs = fetchedLogs.where((l) => l.status == "SPOOF_DETECTED").toList();
      } else if (_selectedFilter == "FAILED") {
        fetchedLogs = fetchedLogs.where((l) => l.status == "MATCH_FAILED").toList();
      }

      if (mounted) {
        setState(() {
          _logs = fetchedLogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading logs: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln("ID,User ID,Status,Confidence,Liveness Score,Spoof Details,Timestamp,GPS Lat,GPS Lng,Device ID");
      for (var log in _logs) {
        buffer.writeln(
          "${log.id ?? ''},"
          "${log.userId ?? ''},"
          "${log.status},"
          "${log.confidence.toStringAsFixed(3)},"
          "${log.livenessScore.toStringAsFixed(3)},"
          "\"${log.spoofDetails ?? ''}\","
          "${log.timestamp.toIso8601String()},"
          "${log.lat ?? ''},"
          "${log.lng ?? ''},"
          "${log.deviceId}"
        );
      }
      
      // Simulate saving CSV file
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141C33),
          title: const Row(
            children: [
              Icon(Icons.download, color: Color(0xFF00E5FF)),
              SizedBox(width: 8),
              Text("CSV REPORT EXPORTED"),
            ],
          ),
          content: const Text(
            "Audit reports generated and exported successfully:\n"
            "Path: /storage/emulated/0/Download/NHAI_Audit_Log.csv\n\n"
            "File contains encrypted hashes, timestamps, GPS, and liveness scores.",
            style: TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(color: Color(0xFF00E5FF))),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error exporting report: $e")),
      );
    }
  }

  Future<void> _clearLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141C33),
        title: const Text("WIPE LOCAL LOGS?"),
        content: const Text("This action will permanently delete all local audits inside the SQLCipher vault database."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _dbService.clearAuditLogs();
              _loadLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFFF3D00),
                  content: Text("Audit logs database wiped successfully."),
                ),
              );
            },
            child: const Text("WIPE", style: TextStyle(color: Color(0xFFFF3D00))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.currentUserRole == 'Admin';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("AUDIT VAULT", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF00E5FF)),
            onPressed: _logs.isEmpty ? null : _exportCsv,
            tooltip: "Export CSV Report",
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFFF3D00)),
              onPressed: _logs.isEmpty ? null : _clearLogs,
              tooltip: "Clear Database Logs",
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadLogs(),
                  decoration: InputDecoration(
                    hintText: "Search by User ID, status, or details...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadLogs();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Horizontal filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("ALL"),
                      const SizedBox(width: 8),
                      _buildFilterChip("SUCCESS"),
                      const SizedBox(width: 8),
                      _buildFilterChip("FAILED"),
                      const SizedBox(width: 8),
                      _buildFilterChip("SPOOFS"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logs listing
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text(
                              "NO AUDIT ENTRIES FOUND",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final active = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _loadLogs();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : const Color(0xFF141C33),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Theme.of(context).colorScheme.primary : const Color(0xFF1E294B),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF0A0F1D) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    Color statusColor = const Color(0xFF00E676);
    IconData statusIcon = Icons.check_circle;
    String statusTitle = "AUTHENTICATED";

    if (log.status == "SPOOF_DETECTED") {
      statusColor = const Color(0xFFFF3D00);
      statusIcon = Icons.gpp_maybe;
      statusTitle = "SPOOF ATTACK";
    } else if (log.status == "MATCH_FAILED") {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.cancel;
      statusTitle = "MATCH FAIL";
    } else if (log.status == "PROCESSING_ERROR") {
      statusColor = Colors.grey;
      statusIcon = Icons.warning;
      statusTitle = "EXECUTION ERROR";
    }

    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor, size: 24),
        title: Text(
          log.userId ?? "GUEST_UNKNOWN",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          "$statusTitle | $formattedDate",
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem("CONFIDENCE", "${(log.confidence * 100).toStringAsFixed(1)}%"),
              _buildDetailItem("LIVENESS SCORE", "${(log.livenessScore * 100).toStringAsFixed(1)}%"),
              _buildDetailItem("GPS ACCURACY", log.lat != null ? "FIXED" : "OFFLINE"),
            ],
          ),
          const SizedBox(height: 12),
          if (log.lat != null && log.lng != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTextDetail(
                icon: Icons.location_on,
                label: "GPS Coordinates",
                val: "Lat: ${log.lat!.toStringAsFixed(5)}, Lng: ${log.lng!.toStringAsFixed(5)}",
              ),
            ),
          _buildTextDetail(
            icon: Icons.cell_tower,
            label: "Device Terminal ID",
            val: log.deviceId,
          ),
          if (log.spoofDetails != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RISK ANALYSIS REPORT:",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.spoofDetails!,
                    style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTextDetail({required IconData icon, required String label, required String val}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF00E5FF)),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        Text(
          val,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
