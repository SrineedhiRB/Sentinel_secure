// lib/services/audit_service.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger();

class AuditEvent {
  final DateTime timestamp;
  final String description;
  AuditEvent(this.timestamp, this.description);
}

class AuditService {
  final _controller = StreamController<AuditEvent>.broadcast();

  AuditService() {
    // Simulate periodic audit events
    Timer.periodic(const Duration(seconds: 5), (_) {
      final event = AuditEvent(DateTime.now(), "Biometric check ${DateTime.now().second % 2 == 0 ? 'passed' : 'failed'}");
      _log.i('Audit event: ${event.description}');
      _controller.add(event);
    });
  }

  Stream<AuditEvent> get events => _controller.stream;
}

// Riverpod provider
final auditServiceProvider = Provider<AuditService>((ref) => AuditService());
