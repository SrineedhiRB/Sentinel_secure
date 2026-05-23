import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/auth_service.dart';
import '../../core/ai/face_processor.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  List<Face> _detectedFaces = [];
  final List<Face> _historicalFrames = [];
  bool _lowLightBoost = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startLivenessChallenges();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Use front-facing camera for biometric scanning
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  void _startLivenessChallenges() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.startLivenessVerification(
      () {
        // Authenticated or matched successfully
      },
      () {
        // Liveness challenge failed
      },
    );
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting || _cameraController == null) return;
    _isDetecting = true;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.state != AuthState.livenessChallenge) {
        _isDetecting = false;
        return;
      }

      // Convert CameraImage format to InputImage format for ML Kit
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotation.rotation270;
      final InputImageFormat inputImageFormat = InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      final faces = await FaceProcessor().detectFaces(inputImage);
      
      if (mounted) {
        setState(() {
          _detectedFaces = faces;
        });
      }

      if (faces.isNotEmpty) {
        final face = faces.first;
        _historicalFrames.add(face);
        if (_historicalFrames.length > 15) {
          _historicalFrames.removeAt(0);
        }

        // Simulate local face embedding matching trigger based on current face positions
        authService.feedFrame(
          face, 
          _historicalFrames, 
          () => FaceProcessor().extractEmbedding(dynamicMockCrop(), face),
          () {
            // Success handler -> navigate back or show success panel
          }
        );
      }
    } catch (e) {
      print("Face detection loop error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  // Helper crop generator (used when native tflite doesn't compile on host system)
  dynamic dynamicMockCrop() {
    // Return dummy dynamic pixels object
    return null;
  }

  void _toggleLowLightBoost() {
    setState(() {
      _lowLightBoost = !_lowLightBoost;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Feed / Preview Container
          Positioned.fill(
            child: (_cameraController != null && _cameraController!.value.isInitialized)
                ? CameraPreview(_cameraController!)
                : Container(
                    color: const Color(0xFF070B16),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            "LAUNCHING CAMERA HARDWARE...",
                            style: TextStyle(fontSize: 12, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
          ),

          // Low-light enhancement shader overlay
          if (_lowLightBoost)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),

          // 2. Futuristic Cyber HUD Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: CyberHudPainter(
                detectedFaces: _detectedFaces,
                previewSize: _cameraController != null ? _cameraController!.value.previewSize : null,
                screenSize: size,
              ),
            ),
          ),

          // 3. Dynamic Liveness Challenge Card
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: _buildLivenessChallengeCard(authService),
          ),

          // 4. Quick Simulator Helper Buttons (If testing on emulator where camera feeds can be hard to trigger)
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuickActionBtn(
                    icon: Icons.lightbulb,
                    label: "LIGHT BOOST",
                    active: _lowLightBoost,
                    onTap: _toggleLowLightBoost,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionBtn(
                    icon: Icons.skip_next,
                    label: "PASS CHALLENGE",
                    onTap: () {
                      // Simulates bypassing checks when testing UI transitions on emulator
                      if (authService.state == AuthState.livenessChallenge) {
                        // Generate a dummy face for simulation
                        final dummyEmbedding = List<double>.generate(128, (i) => i == 10 ? 0.85 : 0.02); // matches officer
                        authService.resetState();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF00E676),
                            content: Text("MATCH SUCCESS: Inspector Vikram Singh (Highway Officer)"),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionBtn(
                    icon: Icons.error_outline,
                    label: "FAIL SPOOF",
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFFFF3D00),
                          content: Text("SPOOF DETECTED: Static photo or replay attack blocked!"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Auth State Display Footer Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStatusFooter(authService),
          ),
        ],
      ),
    );
  }

  Widget _buildLivenessChallengeCard(AuthService authService) {
    if (authService.state != AuthState.livenessChallenge || authService.currentChallenge == null) {
      return const SizedBox.shrink();
    }

    String challengeText = "";
    IconData challengeIcon = Icons.face;
    Color alertColor = Theme.of(context).colorScheme.primary;

    switch (authService.currentChallenge!) {
      case LivenessChallenge.blink:
        challengeText = "BLINK YOUR EYES 2 TIMES";
        challengeIcon = Icons.remove_red_eye;
        break;
      case LivenessChallenge.smile:
        challengeText = "SMILE NATURALLY";
        challengeIcon = Icons.sentiment_very_satisfied;
        break;
      case LivenessChallenge.turnLeft:
        challengeText = "SLOWLY TURN YOUR HEAD LEFT";
        challengeIcon = Icons.arrow_back;
        break;
      case LivenessChallenge.turnRight:
        challengeText = "SLOWLY TURN YOUR HEAD RIGHT";
        challengeIcon = Icons.arrow_forward;
        break;
      case LivenessChallenge.lookUp:
        challengeText = "LOOK UP SLOWLY";
        challengeIcon = Icons.arrow_upward;
        break;
      case LivenessChallenge.lookDown:
        challengeText = "LOOK DOWN SLOWLY";
        challengeIcon = Icons.arrow_downward;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1526).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertColor, width: 2),
        boxShadow: [
          BoxShadow(color: alertColor.withOpacity(0.2), blurRadius: 15, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(challengeIcon, color: alertColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "ANTI-SPOOF CHALLENGE ${authService.challengeProgress + 1}/3",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: alertColor, letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  challengeText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          // Timer circular indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: authService.secondsLeft / 12.0,
                  strokeWidth: 3,
                  color: alertColor,
                  backgroundColor: Colors.grey[800],
                ),
              ),
              Text(
                "${authService.secondsLeft}s",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({required IconData icon, required String label, bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF).withOpacity(0.2) : const Color(0xFF0F1526).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF00E5FF) : const Color(0xFF1E294B), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? const Color(0xFF00E5FF) : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: active ? const Color(0xFF00E5FF) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFooter(AuthService authService) {
    Color panelColor = const Color(0xFF0F172A);
    String title = "PREPARING AI SCANNER...";
    String detail = "Align face in the box to initiate verification";
    IconData icon = Icons.photo_camera;

    switch (authService.state) {
      case AuthState.checkingIntegrity:
        title = "CHECKING ENVIRONMENT...";
        detail = "Scanning runtime memory bounds for tampering";
        icon = Icons.security;
        break;
      case AuthState.livenessChallenge:
        title = "VERIFYING LIVENESS...";
        detail = "Follow HUD indicators to pass anti-spoof checks";
        icon = Icons.contactless;
        break;
      case AuthState.processingFace:
        title = "EXTRACTING EMBEDDING...";
        detail = "Running local MobileFaceNet 128-D float vector...";
        icon = Icons.sync_problem;
        break;
      case AuthState.authenticated:
        panelColor = const Color(0xFF065F46); // Forest Green
        title = "ACCESS AUTHORIZED";
        detail = authService.statusMessage ?? "Operator profile matched";
        icon = Icons.verified;
        break;
      case AuthState.accessDenied:
        panelColor = const Color(0xFF991B1B); // Crimson Red
        title = "ACCESS DENIED";
        detail = authService.statusMessage ?? "Identification mismatch";
        icon = Icons.error;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: panelColor.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFF1E294B), width: 1.5)),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bounding Box HUD Painter
class CyberHudPainter extends CustomPainter {
  final List<Face> detectedFaces;
  final Size? previewSize;
  final Size screenSize;

  CyberHudPainter({
    required this.detectedFaces,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00E5FF);

    // Draw scanner helper target brackets
    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2 - 50;
    final double radiusX = screenSize.width * 0.35;
    final double radiusY = screenSize.width * 0.45;

    // Outer cyber oval box guide
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00E5FF).withOpacity(0.3);
    
    canvas.drawOval(
      Rect.fromLTRB(centerX - radiusX, centerY - radiusY, centerX + radiusX, centerY + radiusY),
      guidePaint,
    );

    if (detectedFaces.isEmpty) {
      // Paint pulsing target dots
      return;
    }

    if (previewSize == null) return;

    // Convert ML Kit coordinates to screen size
    final double scaleX = screenSize.width / previewSize!.height;
    final double scaleY = screenSize.height / previewSize!.width;

    for (final face in detectedFaces) {
      final rect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(rect, paint);
      
      // Draw cyber corner highlights
      final double len = 20.0;
      final cornerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = const Color(0xFF00E676);

      // Top Left Corner
      canvas.drawPath(
        Path()
          ..moveTo(rect.left, rect.top + len)
          ..lineTo(rect.left, rect.top)
          ..lineTo(rect.left + len, rect.top),
        cornerPaint,
      );

      // Top Right Corner
      canvas.drawPath(
        Path()
          ..moveTo(rect.right - len, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.top + len),
        cornerPaint,
      );

      // Bottom Left Corner
      canvas.drawPath(
        Path()
          ..moveTo(rect.left, rect.bottom - len)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(rect.left + len, rect.bottom),
        cornerPaint,
      );

      // Bottom Right Corner
      canvas.drawPath(
        Path()
          ..moveTo(rect.right - len, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.right, rect.bottom - len),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CyberHudPainter oldDelegate) => true;
}
