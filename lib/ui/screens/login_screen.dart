import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/security/security_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _securityService = SecurityService();
  String _pin = "";
  final String _correctPin = "8899"; // Admin default pin
  String? _errorMessage;

  final List<Map<String, String>> _roles = [
    {'role': 'Admin', 'name': 'Dr. Rajesh Sharma'},
    {'role': 'Highway Officer', 'name': 'Inspector Vikram Singh'},
    {'role': 'Toll Operator', 'name': 'Operator Sanjay Patil'},
  ];

  late Map<String, String> _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles[1]; // default to Highway Officer
    // Prevent screenshots on the authentication page
    _securityService.enableSecureWindow(true);
  }

  @override
  void dispose() {
    // Re-enable screens on exit
    _securityService.enableSecureWindow(false);
    super.dispose();
  }

  void _onKeyPress(String val) {
    setState(() {
      _errorMessage = null;
      if (_pin.length < 4) {
        _pin += val;
      }
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_pin == _correctPin) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.changeRole(_selectedRole['role']!, _selectedRole['name']!);
      
      // Clear PIN and route to home
      setState(() {
        _pin = "";
      });
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _pin = "";
        _errorMessage = "INVALID SECURITY ACCESS KEY";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cybergrid layout background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0A0F1D),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: GridPaper(
                color: Theme.of(context).colorScheme.primary,
                divisions: 2,
                subdivisions: 2,
                interval: 80.0,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Header branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "SENTINEL BIOMETRIC",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 1.5,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      "OFFLINE HIGHWAY SECURITY AUTHENTICATOR",
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Role Selector Dropdown Card
                  Card(
                    color: const Color(0xFF141C33),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Terminal Operator Profile:",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, String>>(
                              value: _selectedRole,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF141C33),
                              items: _roles.map((item) {
                                return DropdownMenuItem<Map<String, String>>(
                                  value: item,
                                  child: Row(
                                    children: [
                                      Icon(
                                        item['role'] == 'Admin' 
                                            ? Icons.admin_panel_settings 
                                            : item['role'] == 'Highway Officer' 
                                                ? Icons.local_police 
                                                : Icons.badge,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item['name']!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Role: ${item['role']!}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRole = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PIN entry circles
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "ENTER SECURITY KEYPASS PIN",
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final filled = index < _pin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10.0),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.transparent,
                                border: Border.all(
                                  color: filled 
                                      ? Theme.of(context).colorScheme.primary 
                                      : const Color(0xFF1E294B),
                                  width: 2.0,
                                ),
                                boxShadow: filled ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ] : null,
                              ),
                            );
                          }),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Numerical PIN Keyboard (Gov HUD style)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ["1", "2", "3"].map((n) => _buildKeyboardKey(n)).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ["4", "5", "6"].map((n) => _buildKeyboardKey(n)).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ["7", "8", "9"].map((n) => _buildKeyboardKey(n)).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBiometricMockKey(),
                          _buildKeyboardKey("0"),
                          _buildBackspaceKey(),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Demo PIN Code: 8899",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardKey(String num) {
    return InkWell(
      onTap: () => _onKeyPress(num),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF141C33),
          border: Border.all(color: const Color(0xFF1E294B), width: 1.0),
        ),
        child: Center(
          child: Text(
            num,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.backspace,
          color: Color(0xFF94A3B8),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBiometricMockKey() {
    return InkWell(
      onTap: () {
        // Quick bypass with mock biometrics for officer logging
        setState(() {
          _pin = "8899";
        });
        _verifyPin();
      },
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.fingerprint,
          color: Theme.of(context).colorScheme.primary,
          size: 26,
        ),
      ),
    );
  }
}
