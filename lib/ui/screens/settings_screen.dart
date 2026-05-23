import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/security/security_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final securityService = Provider.of<SecurityService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Root/Emulator detection'),
            value: securityService.isDeviceSecure,
            onChanged: (_) {}, // read‑only display
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Dark cyber‑grid (default)'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // placeholder for future theme selector
            },
          ),
          ListTile(
            title: const Text('Encryption Key'),
            subtitle: Text(securityService.masterKey != null ? '${securityService.masterKey!.substring(0, 4)}••••${securityService.masterKey!.substring(securityService.masterKey!.length - 4)}' : 'Unavailable'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: securityService.masterKey ?? ''));
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear Audit Logs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              // Hook to DatabaseService to purge logs – implement as needed
            },
          ),
        ],
      ),
    );
  }
}
