// lib/ui/screens/encrypted_vault_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/vault_service.dart';

final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

class EncryptedVaultScreen extends ConsumerWidget {
  const EncryptedVaultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Vault'),
        backgroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: vault.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Vault is empty'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['id'] as String),
                subtitle: Text(item['value'] as String),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await vault.deleteItem(item['id'] as String);
                    // Force rebuild by calling setState via ref.refresh
                    ref.refresh(vaultServiceProvider);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add),
        onPressed: () async {
          final keyController = TextEditingController();
          final valueController = TextEditingController();
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Secret'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(labelText: 'Key'),
                  ),
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (result == true && keyController.text.isNotEmpty) {
            await vault.putItem(keyController.text, valueController.text);
            ref.refresh(vaultServiceProvider);
          }
        },
      ),
    );
  }
}
