import 'dart:convert';

class AppUser {
  final String id;
  final String name;
  final String role;
  final List<double> embedding;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.embedding,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'embedding': jsonEncode(embedding),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      embedding: List<double>.from(jsonDecode(map['embedding'])),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class AuditLog {
  final int? id;
  final String? userId;
  final String status; // SUCCESS, SPOOF_DETECTED, MATCH_FAILED, BLOCKED_DEVICE
  final double confidence;
  final double livenessScore;
  final String? spoofDetails;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  final String deviceId;

  AuditLog({
    this.id,
    this.userId,
    required this.status,
    required this.confidence,
    required this.livenessScore,
    this.spoofDetails,
    required this.timestamp,
    this.lat,
    this.lng,
    required this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'status': status,
      'confidence': confidence,
      'liveness_score': livenessScore,
      'spoof_details': spoofDetails,
      'timestamp': timestamp.toIso8601String(),
      'gps_lat': lat,
      'gps_lng': lng,
      'device_id': deviceId,
    };
  }
}
