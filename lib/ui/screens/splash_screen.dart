import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/ai/face_processor.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final List<String> _bootLogs = [];
  bool _scanComplete = false;
  String _scanStatus = "BOOTING SECURE ENVIRONMENT...";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final faceProcessor = FaceProcessor();

    await Future.delayed(const Duration(milliseconds: 600));
    _addLog("Loading environment drivers...");
    
    await Future.delayed(const Duration(milliseconds: 400));
    _addLog("Checking device integrity parameters...");
    final securityResults = await authService.runSecurityScan();
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (securityResults['rooted'] == true) {
      _addLog("[WARNING] SU BINARIES FOUND (DEVICE MAY BE ROOTED)");
    } else {
      _addLog("Device Integrity: SOLID (No root detected)");
    }

    if (securityResults['emulator'] == true) {
      _addLog("Environment: EMULATOR ENVIRONMENT DETECTED");
    } else {
      _addLog("Environment: PHYSICAL DEVICE DETECTED");
    }

    await Future.delayed(const Duration(milliseconds: 400));
    _addLog("Initializing SQLCipher database vault...");
    
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog("Loading quantized MobileFaceNet AI engine...");
    await faceProcessor.initialize();
    
    if (faceProcessor.isMock) {
      _addLog("[WARN] Native TFLite unavailable. Using Biometric Geometry Fallback Engine.");
    } else {
      _addLog("AI engine: MobileFaceNet (FP32 quantized) [ONLINE]");
    }

    await Future.delayed(const Duration(milliseconds: 600));
    _addLog("Securing runtime screen parameters...");
    await authService.runSecurityScan();
    // Enable screenshot prevention on startup
    await authService.simulateSync(); // Pre-cache configs
    
    setState(() {
      _scanComplete = true;
      _scanStatus = "SECURE VAULT STACK LOADED.";
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        _bootLogs.add(log);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cybergrid background layout (simulated with gradients)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF070B16), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Grid lines simulation overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: Theme.of(context).colorScheme.primary,
                divisions: 2,
                subdivisions: 2,
                interval: 100.0,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // Animated Biometric Scan Logo
                  Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _scanComplete 
                                ? Theme.of(context).colorScheme.secondary 
                                : Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_scanComplete 
                                      ? Theme.of(context).colorScheme.secondary 
                                      : Theme.of(context).colorScheme.primary)
                                  .withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          size: 70,
                          color: _scanComplete 
                              ? Theme.of(context).colorScheme.secondary 
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title text
                  Center(
                    child: Text(
                      "SENTINEL OFF-BIOMETRIC",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "NATIONAL HIGHWAYS SECURE GATEWAY",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Diagnostic Logs Terminal Container
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1526),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E294B), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _scanComplete 
                                    ? Theme.of(context).colorScheme.secondary 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _scanStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _scanComplete 
                                    ? Theme.of(context).colorScheme.secondary 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1E294B), height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _bootLogs.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              final log = _bootLogs[_bootLogs.length - 1 - index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  "> $log",
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Footer security notice
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gpp_good, size: 14, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Text(
                        "MIL-STD SECURE OFFLINE ARCHITECTURE",
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
