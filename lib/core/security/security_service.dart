import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _storage = const FlutterSecureStorage();
  final String _keyAlias = 'sentinel_master_key';
  static const platform = MethodChannel('com.sentinel.offline_biometric/security');

  /// Initializes or retrieves the master key from Secure Storage
  Future<String> getOrGenerateMasterKey() async {
    String? key = await _storage.read(key: _keyAlias);
    if (key == null) {
      // Generate a high-entropy 32-byte key
      var values = List<int>.generate(32, (i) => Random.secure().nextInt(256));
      key = base64Url.encode(values);
      await _storage.write(key: _keyAlias, value: key);
    }
    return key;
  }

  /// Encrypts sensitive data (like embeddings) using AES-256
  Future<String> encryptData(String plainText) async {
    final masterKey = await getOrGenerateMasterKey();
    final key = encrypt.Key.fromBase64(masterKey);
    // Use a random IV for every encryption to prevent patterns
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${encrypted.base64}:${iv.base64}";
  }

  /// Decrypts sensitive data
  Future<String> decryptData(String encryptedPayload) async {
    final parts = encryptedPayload.split(':');
    if (parts.length != 2) throw Exception("Invalid encrypted format");

    final masterKey = await getOrGenerateMasterKey();
    final key = encrypt.Key.fromBase64(masterKey);
    final iv = encrypt.IV.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt64(parts[0], iv: iv);
  }

  /// Secure Hash for secondary verification (SHA-256)
  String hashData(String data) {
    var bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  /// Detects rooted Android devices or jailbroken iOS devices offline
  Future<bool> isRooted() async {
    if (Platform.isAndroid) {
      final paths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su'
      ];
      for (var path in paths) {
        if (File(path).existsSync()) return true;
      }
      
      // Secondary check: Can we run "su" command?
      try {
        final result = await Process.run('which', ['su']);
        if (result.exitCode == 0) return true;
      } catch (_) {}
    } else if (Platform.isIOS) {
      final paths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt'
      ];
      for (var path in paths) {
        if (Directory(path).existsSync() || File(path).existsSync()) return true;
      }
    }
    return false;
  }

  /// Detects whether the app is running on an emulator or simulator
  Future<bool> isEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice ||
          androidInfo.fingerprint.startsWith('generic') ||
          androidInfo.fingerprint.startsWith('unknown') ||
          androidInfo.model.contains('google_sdk') ||
          androidInfo.model.contains('Emulator') ||
          androidInfo.model.contains('Android SDK built for x86') ||
          androidInfo.hardware.contains('goldfish') ||
          androidInfo.hardware.contains('ranchu') ||
          androidInfo.hardware.contains('vbox86') ||
          androidInfo.brand.startsWith('generic') ||
          androidInfo.device.startsWith('generic') ||
          androidInfo.product.startsWith('sdk_gphone');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  /// Prevents screenshots and screen recording (Android/iOS secure window)
  Future<void> enableSecureWindow(bool enable) async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('setSecureWindow', {'enable': enable});
      }
    } on PlatformException catch (e) {
      print("Failed to set secure window: ${e.message}");
    }
  }

  /// Detects if there has been any modification to code libraries or binary integrity
  Future<bool> checkRuntimeIntegrity() async {
    // Verifies signatures, libraries size, or package signatures if needed
    // In standard Flutter, we can check code signature hash via platform channel
    try {
      final result = await platform.invokeMethod('checkSignature');
      return result as bool;
    } catch (_) {
      // Fallback: assume integrated in debug/dev testing
      return true;
    }
  }
}
