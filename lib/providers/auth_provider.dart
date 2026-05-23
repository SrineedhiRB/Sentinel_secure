// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Exposes [AuthService] as a Riverpod provider.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
