import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Developer specific controllers
  final _companyNameCtrl = TextEditingController();
  final _cacCtrl = TextEditingController();
  final _officeAddressCtrl = TextEditingController();

  bool _isRegistering = false;
  bool _obscurePassword = true;
  String _selectedRole = 'BUYER'; // 'BUYER' or 'DEVELOPER'

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyNameCtrl.dispose();
    _cacCtrl.dispose();
    _officeAddressCtrl.dispose();
    super.dispose();
  }

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  _isRegistering ? 'Create your Account' : 'Welcome to HomeVerify',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegistering
                      ? 'Select whether you are buying/verifying properties or a corporate developer.'
                      : 'Verify documents, track off-plan milestones & pay in instalments.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // ROLE SELECTOR (ONLY WHEN REGISTERING)
                if (_isRegistering) ...[
                  const Text(
                    'I am registering as:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'BUYER'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'BUYER' ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == 'BUYER' ? AppColors.primary : AppColors.cardBorder,
                                width: _selectedRole == 'BUYER' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: _selectedRole == 'BUYER' ? AppColors.primary : AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Buyer / Investor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _selectedRole == 'BUYER' ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Buy & verify land',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'DEVELOPER'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'DEVELOPER' ? const Color(0xFFD97706).withValues(alpha: 0.08) : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == 'DEVELOPER' ? const Color(0xFFD97706) : AppColors.cardBorder,
                                width: _selectedRole == 'DEVELOPER' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  color: _selectedRole == 'DEVELOPER' ? const Color(0xFFD97706) : AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Developer / Co.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _selectedRole == 'DEVELOPER' ? const Color(0xFFD97706) : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'List off-plan builds',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                if (auth.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.roseBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.roseText.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.roseText, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.roseText, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                if (_isRegistering) ...[
                  // CORPORATE DEVELOPER FIELDS
                  if (_selectedRole == 'DEVELOPER') ...[
                    TextFormField(
                      controller: _companyNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Company Name is required' : null,
                      decoration: const InputDecoration(
                        labelText: 'Company / Business Name',
                        hintText: 'e.g. Haven Homes Nigeria Ltd',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cacCtrl,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'CAC RC Number is required' : null,
                      decoration: const InputDecoration(
                        labelText: 'CAC Registration / RC Number',
                        hintText: 'e.g. RC-1849204',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _officeAddressCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Office Address (Optional)',
                        hintText: 'e.g. 14 Admiralty Way, Lekki Phase 1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          decoration: InputDecoration(
                            labelText: _selectedRole == 'DEVELOPER' ? 'Rep. First Name' : 'First Name',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          decoration: InputDecoration(
                            labelText: _selectedRole == 'DEVELOPER' ? 'Rep. Last Name' : 'Last Name',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 10) return 'Enter a valid phone number';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Phone (+234...)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: _selectedRole == 'DEVELOPER' ? 'Official Business Email' : 'Email Address',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (_isRegistering && v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                if (!_isRegistering)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  )
                else
                  const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (_isRegistering) {
                              final devInfo = _selectedRole == 'DEVELOPER'
                                  ? {
                                      'companyName': _companyNameCtrl.text.trim(),
                                      'cacNumber': _cacCtrl.text.trim(),
                                      'officeAddress': _officeAddressCtrl.text.trim(),
                                    }
                                  : null;

                              final success = await auth.register(
                                email: _emailCtrl.text.trim(),
                                password: _passwordCtrl.text,
                                firstName: _firstNameCtrl.text.trim(),
                                lastName: _lastNameCtrl.text.trim(),
                                phone: _phoneCtrl.text.trim(),
                                role: _selectedRole,
                                developerInfo: devInfo,
                              );
                              if (success && mounted) Navigator.pop(context);
                            } else {
                              final success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
                              if (success && mounted) Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isRegistering ? 'Create Account' : 'Sign In',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _formKey.currentState?.reset();
                      });
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
      ),
    );
  }
}
