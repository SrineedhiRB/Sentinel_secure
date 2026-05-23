// lib/ui/widgets/audit_timeline.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audit_service.dart';

class AuditTimelineWidget extends ConsumerWidget {
  const AuditTimelineWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(auditServiceProvider).events;
    return Card(
      elevation: 0,
      color: Theme.of(context).cardTheme.color,
      child: SizedBox(
        height: 200,
        child: StreamBuilder<AuditEvent>(
          stream: stream,
          builder: (context, snapshot) {
            final events = snapshot.data != null ? [snapshot.data!] : [];
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFF00E5FF)),
                  title: Text(e.description),
                  subtitle: Text('${e.timestamp.hour}:${e.timestamp.minute.toString().padLeft(2, '0')}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
