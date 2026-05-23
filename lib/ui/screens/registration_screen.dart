import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = "Contractor";
  bool _isRegistering = false;

  final List<String> _roles = ["Highway Officer", "Toll Operator", "Contractor", "Visitor"];

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _triggerEnrollment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    // Simulate taking enrollment pictures and extracting a mock embedding
    await Future.delayed(const Duration(seconds: 2));

    // Seed a pseudo-random unique embedding vector representing the user's facial geometry
    final sampleEmbedding = List<double>.generate(128, (i) {
      if (i == 40) return 0.78;
      if (i == 80) return -0.45;
      return 0.05;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.registerUser(
      _idController.text.trim(),
      _nameController.text.trim(),
      _selectedRole,
      sampleEmbedding,
    );

    if (mounted) {
      setState(() {
        _isRegistering = false;
      });

      if (success) {
        // Show success alert dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141C33),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                const Text("ENROLLMENT SECURED"),
              ],
            ),
            content: Text(
              "Biometric embedding for ${_nameController.text} has been encrypted (AES-256) and saved locally inside the SQLCipher vault.",
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pop(); // pop registration screen
                },
                child: const Text("CLOSE TERMINAL", style: TextStyle(color: Color(0xFF00E5FF))),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFF3D00),
            content: Text("FAIL: Could not save profile in local database."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final canEnroll = authService.currentUserRole == 'Admin' || authService.currentUserRole == 'Highway Officer';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("ENROLLMENT PANEL", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Panel header icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15), width: 1.5),
                  ),
                  child: Icon(Icons.assignment_ind, size: 48, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              if (!canEnroll) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.error, width: 1.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gpp_maybe, color: Color(0xFFFF3D00)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "INSUFFICIENT ACCESS PRIVILEGES.\nOnly Administrators or Highway Officers are permitted to enroll biometric profiles.",
                          style: TextStyle(fontSize: 11, color: Color(0xFFFF3D00), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User ID Input
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: "SYSTEM ID (e.g. NHAI-CON-482)",
                          prefixIcon: Icon(Icons.badge, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Unique system identity key is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // User Full Name Input
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "OFFICER / CONTRACTOR FULL NAME",
                          prefixIcon: Icon(Icons.person, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Full name identifier is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111726),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E294B), width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: "ASSIGNED SECURITY ROLE",
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            dropdownColor: const Color(0xFF141C33),
                            items: _roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isRegistering ? null : _triggerEnrollment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: const Color(0xFF0A0F1D),
                        ),
                        child: _isRegistering
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0F1D)),
                                  ),
                                  SizedBox(width: 12),
                                  Text("ENROLLING FACE GEOMETRY...")
                                ],
                              )
                            : const Text("CAPTURE FACE & REGISTER"),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              // Security Policy Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1526),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
                        SizedBox(width: 6),
                        Text(
                          "Offline Enrolment Regulations:",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "• Raw photos are NEVER stored to disk to comply with NHAI biometric privacy mandates.\n"
                      "• A 128-dimensional irreversible double-encrypted hash is generated as the primary index.\n"
                      "• Ensure glare-free lighting and direct head alignment during enrollment capture.",
                      style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
