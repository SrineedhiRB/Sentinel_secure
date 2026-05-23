import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../core/database/database_service.dart';
import '../core/security/security_service.dart';
import '../core/ai/face_processor.dart';
import '../models/app_models.dart';

enum AuthState {
  idle,
  checkingIntegrity,
  livenessChallenge,
  processingFace,
  authenticated,
  accessDenied,
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _dbService = DatabaseService();
  final _securityService = SecurityService();
  final _faceProcessor = FaceProcessor();

  AuthState _state = AuthState.idle;
  AppUser? _activeUser;
  String? _statusMessage;
  
  // Dynamic challenge state
  LivenessChallenge? _currentChallenge;
  int _challengeProgress = 0;
  final List<LivenessChallenge> _challengesToComplete = [];
  Timer? _challengeTimer;
  int _secondsLeft = 10;
  
  // Audits queue
  int _unsyncedLogsCount = 8; // Simulated unsynced logs upon first launch

  // RBAC states
  String _currentUserRole = 'Highway Officer'; // Simulated logged-in officer role
  String _currentOfficerName = 'Inspector Vikram Singh';
  bool _isAppSecure = true;

  // Getters
  AuthState get state => _state;
  AppUser? get activeUser => _activeUser;
  String? get statusMessage => _statusMessage;
  LivenessChallenge? get currentChallenge => _currentChallenge;
  int get challengeProgress => _challengeProgress;
  int get secondsLeft => _secondsLeft;
  int get unsyncedLogsCount => _unsyncedLogsCount;
  String get currentUserRole => _currentUserRole;
  String get currentOfficerName => _currentOfficerName;
  bool get isAppSecure => _isAppSecure;

  void changeRole(String newRole, String name) {
    _currentUserRole = newRole;
    _currentOfficerName = name;
    notifyListeners();
  }

  void resetState() {
    _state = AuthState.idle;
    _activeUser = null;
    _statusMessage = null;
    _currentChallenge = null;
    _challengeProgress = 0;
    _challengesToComplete.clear();
    _challengeTimer?.cancel();
    notifyListeners();
  }

  /// Runs environmental security scans: Root, Emulator, Integrity
  Future<Map<String, bool>> runSecurityScan() async {
    _state = AuthState.checkingIntegrity;
    notifyListeners();

    final rooted = await _securityService.isRooted();
    final emulator = await _securityService.isEmulator();
    final integrity = await _securityService.checkRuntimeIntegrity();

    _isAppSecure = !rooted && integrity; // Lock flags if rooted

    _state = AuthState.idle;
    notifyListeners();

    return {
      'rooted': rooted,
      'emulator': emulator,
      'integrity': integrity,
    };
  }

  /// Start the multi-challenge liveness detection pipeline
  void startLivenessVerification(VoidCallback onLivenessCompleted, VoidCallback onLivenessFailed) {
    resetState();
    _state = AuthState.livenessChallenge;
    
    // Select 3 random challenges to prevent playbacks
    final available = [
      LivenessChallenge.blink,
      LivenessChallenge.smile,
      LivenessChallenge.turnLeft,
      LivenessChallenge.turnRight,
      LivenessChallenge.lookUp,
      LivenessChallenge.lookDown
    ];
    available.shuffle();
    
    _challengesToComplete.addAll(available.take(3));
    _challengeProgress = 0;
    _currentChallenge = _challengesToComplete[_challengeProgress];
    _secondsLeft = 12; // 12 seconds total budget for challenges
    
    notifyListeners();

    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        // Challenge timed out
        _challengeTimer?.cancel();
        _state = AuthState.accessDenied;
        _statusMessage = "Liveness verification timed out.";
        _logAttempt(null, "SPOOF_DETECTED", 0.0, 0.0, "Liveness challenge timeout");
        onLivenessFailed();
        notifyListeners();
      }
    });
  }

  /// Check if the detected face fulfills the current challenge
  void feedFrame(var face, List<var> history, List<double> Function() getEmbedding, VoidCallback onSuccess) {
    if (_state != AuthState.livenessChallenge || _currentChallenge == null) return;

    bool passed = false;
    switch (_currentChallenge!) {
      case LivenessChallenge.blink:
        passed = _faceProcessor.checkBlink(face);
        break;
      case LivenessChallenge.smile:
        passed = _faceProcessor.checkSmile(face);
        break;
      default:
        passed = _faceProcessor.checkHeadTurn(face, _currentChallenge!);
        break;
    }

    if (passed) {
      _challengeProgress++;
      if (_challengeProgress >= _challengesToComplete.length) {
        // Passed all liveness tests
        _challengeTimer?.cancel();
        _state = AuthState.processingFace;
        _statusMessage = "Liveness verified. Extracting features...";
        notifyListeners();

        // Process face embedding matching
        Future.delayed(const Duration(milliseconds: 300), () async {
          await _authenticateFace(face, history, getEmbedding);
          onSuccess();
        });
      } else {
        // Go to next challenge
        _currentChallenge = _challengesToComplete[_challengeProgress];
        _secondsLeft = 8; // Reset countdown for the next individual challenge
        notifyListeners();
      }
    }
  }

  /// Complete verification against local SQLite users database
  Future<void> _authenticateFace(var face, List<var> history, List<double> Function() getEmbedding) async {
    _state = AuthState.processingFace;
    notifyListeners();

    try {
      final embedding = getEmbedding();
      final users = await _dbService.getAllUsers();

      AppUser? bestMatch;
      double highestSimilarity = 0.0;
      const double threshold = 0.76; // Match threshold for high security

      for (var user in users) {
        final sim = _faceProcessor.compare(embedding, user.embedding);
        if (sim > highestSimilarity) {
          highestSimilarity = sim;
          bestMatch = user;
        }
      }

      // Estimate dynamic spoof risk from head landmark variances
      final riskScore = _faceProcessor.evaluateAntiSpoofRisk(face, history.cast());
      final livenessScore = 1.0 - riskScore;

      if (riskScore > 0.6) {
        _state = AuthState.accessDenied;
        _statusMessage = "Spoof alert! Static photo or replay detected.";
        await _logAttempt(null, "SPOOF_DETECTED", highestSimilarity, livenessScore, "High texture/motion spoof risk: ${(riskScore * 100).toStringAsFixed(0)}%");
      } else if (highestSimilarity >= threshold && bestMatch != null) {
        _state = AuthState.authenticated;
        _activeUser = bestMatch;
        _statusMessage = "Authentication Success: ${bestMatch.name} (${bestMatch.role})";
        await _logAttempt(bestMatch.id, "SUCCESS", highestSimilarity, livenessScore, null);
      } else {
        _state = AuthState.accessDenied;
        _statusMessage = "Verification Failed: Face does not match registered profiles.";
        await _logAttempt(bestMatch?.id, "MATCH_FAILED", highestSimilarity, livenessScore, "Similarity: ${(highestSimilarity * 100).toStringAsFixed(1)}% below threshold");
      }
    } catch (e) {
      _state = AuthState.accessDenied;
      _statusMessage = "Processing Error: $e";
      await _logAttempt(null, "PROCESSING_ERROR", 0.0, 0.0, e.toString());
    }
    notifyListeners();
  }

  /// Secure Register user method
  Future<bool> registerUser(String id, String name, String role, List<double> embedding) async {
    try {
      final user = AppUser(
        id: id,
        name: name,
        role: role,
        embedding: embedding,
        createdAt: DateTime.now(),
      );
      await _dbService.saveUser(user);
      return true;
    } catch (e) {
      print("Registration error: $e");
      return false;
    }
  }

  /// Write logged attempts locally with GPS & Device Metadata
  Future<void> _logAttempt(String? userId, String status, double confidence, double liveness, String? spoofDetails) async {
    double? lat;
    double? lng;
    String deviceId = "ANDROID_GENERIC_EDGE";

    // 1. Fetch GPS coordinates if location services allowed
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 2));
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (_) {
      // Offline fallback: log null coordinates
    }

    // 2. Fetch unique Device ID
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = "Android_${androidInfo.brand}_${androidInfo.model}_${androidInfo.id.hashCode}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = "iOS_${iosInfo.name}_${iosInfo.identifierForVendor.hashCode}";
      }
    } catch (_) {}

    final audit = AuditLog(
      userId: userId ?? 'GUEST_UNKNOWN',
      status: status,
      confidence: confidence,
      livenessScore: liveness,
      spoofDetails: spoofDetails,
      timestamp: DateTime.now(),
      lat: lat,
      lng: lng,
      deviceId: deviceId,
    );

    await _dbService.logAuthAttempt(audit);
    _unsyncedLogsCount++;
    notifyListeners();
  }

  /// Sync offline events queue
  Future<void> simulateSync() async {
    if (_unsyncedLogsCount == 0) return;
    _unsyncedLogsCount = 0;
    notifyListeners();
  }
}
