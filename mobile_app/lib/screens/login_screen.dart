import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'john.doe@example.com');
  final _passwordCtrl = TextEditingController(text: 'Password123!');
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                _isRegistering ? 'Create your Account' : 'Welcome to EstateVerify',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify documents, track off-plan milestones & pay in instalments.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              if (auth.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.roseBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.roseText.withOpacity(0.3)),
                  ),
                  child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.roseText, fontSize: 12)),
                ),

              if (_isRegistering) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone (+234...)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (_isRegistering) {
                            final success = await auth.register(
                              email: _emailCtrl.text,
                              password: _passwordCtrl.text,
                              firstName: _firstNameCtrl.text,
                              lastName: _lastNameCtrl.text,
                              phone: _phoneCtrl.text,
                            );
                            if (success && mounted) Navigator.pop(context);
                          } else {
                            final success = await auth.login(_emailCtrl.text, _passwordCtrl.text);
                            if (success && mounted) Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    auth.isLoading
                        ? 'Please wait...'
                        : _isRegistering
                            ? 'Create Account'
                            : 'Sign In',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _isRegistering = !_isRegistering);
                  },
                  child: Text(
                    _isRegistering ? 'Already have an account? Sign In' : "Don't have an account? Register",
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
