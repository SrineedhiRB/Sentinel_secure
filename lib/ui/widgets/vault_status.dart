// lib/ui/widgets/vault_status.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/encrypted_vault_service.dart';

class VaultStatusWidget extends ConsumerWidget {
  const VaultStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure vault is initialized (fire‑and‑forget)
    ref.read(encryptedVaultProvider).init();
    return FutureBuilder<List<String>>(
      future: ref.read(encryptedVaultProvider).listSecretIds(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Card(
          elevation: 0,
          color: Theme.of(context).cardTheme.color,
          child: ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFF00E5FF)),
            title: const Text('Encrypted Vault'),
            subtitle: Text('Stored secrets: $count'),
          ),
        );
      },
    );
  }
}
