import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import 'forgot_password_screen.dart';
import 'login_otp_screen.dart';
import 'navigation_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Developer specific controllers
  final _companyNameCtrl = TextEditingController();
  final _cacCtrl = TextEditingController();
  final _officeAddressCtrl = TextEditingController();

  bool _isRegistering = false;
  int _currentStep = 1; // Step-wise registration (Buyer: 1-2, Developer: 1-3)
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'BUYER'; // 'BUYER' or 'DEVELOPER'

  // Sign-in method toggle: false = Email, true = Phone
  bool _loginByPhone = false;
  final _loginPhoneCtrl = TextEditingController();

  // Verification states for Sign-Up
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isSendingEmailOtp = false;
  bool _isSendingPhoneOtp = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final available = await auth.isBiometricsAvailable();
    final enabled = await auth.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _canUseBiometrics = available && enabled;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _loginPhoneCtrl.dispose();
    _companyNameCtrl.dispose();
    _cacCtrl.dispose();
    _officeAddressCtrl.dispose();
    super.dispose();
  }

  int get _maxSteps => _selectedRole == 'DEVELOPER' ? 3 : 2;

  void _handleBackStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      setState(() {
        _isRegistering = false;
        _currentStep = 1;
      });
    }
  }

  // --- OTP Verification Dialog for Email or Phone ---
  Future<void> _showOtpModal({
    required String target,
    required String title,
    required String subtitle,
    required Future<bool> Function() onResend,
    required Future<String?> Function(String code) onVerify,
    required VoidCallback onVerifiedSuccess,
  }) async {
    final controllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());
    int countdown = 60;
    Timer? timer;
    bool isVerifying = false;
    String? localError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 0) {
                setModalState(() => countdown--);
              } else {
                timer?.cancel();
              }
            });

            String getOtp() => controllers.map((c) => c.text).join();

            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 6 Pin boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            onChanged: (val) async {
                              if (val.isNotEmpty && index < 5) {
                                focusNodes[index + 1].requestFocus();
                              } else if (val.isEmpty && index > 0) {
                                focusNodes[index - 1].requestFocus();
                              }
                              if (getOtp().length == 6) {
                                setModalState(() {
                                  isVerifying = true;
                                  localError = null;
                                });
                                final res = await onVerify(getOtp());
                                if (res != null) {
                                  timer?.cancel();
                                  Navigator.pop(modalCtx);
                                  onVerifiedSuccess();
                                } else {
                                  setModalState(() {
                                    isVerifying = false;
                                    localError = 'Invalid code. Please check and re-enter.';
                                  });
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final code = getOtp();
                                if (code.length < 6) {
                                  setModalState(() => localError = 'Enter the 6-digit code');
                                  return;
                                }
                                setModalState(() {
                                  isVerifying = true;
                                  localError = null;
                                });
                                final res = await onVerify(code);
                                if (res != null) {
                                  timer?.cancel();
                                  Navigator.pop(modalCtx);
                                  onVerifiedSuccess();
                                } else {
                                  setModalState(() {
                                    isVerifying = false;
                                    localError = 'Invalid code. Please try again.';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Confirm & Verify', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Resend Timer
                    Center(
                      child: TextButton(
                        onPressed: countdown == 0
                            ? () async {
                                final ok = await onResend();
                                if (ok) {
                                  setModalState(() {
                                    countdown = 60;
                                    localError = null;
                                  });
                                }
                              }
                            : null,
                        child: Text(
                          countdown > 0 ? 'Resend code in ${countdown}s' : 'Resend Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: countdown > 0 ? AppColors.textSecondary : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    timer?.cancel();
  }

  // --- Send Email OTP Action ---
  Future<void> _handleVerifyEmail() async {
    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address first.')),
      );
      return;
    }

    setState(() => _isSendingEmailOtp = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sent = await auth.sendEmailOtp(email, purpose: 'REGISTRATION_EMAIL');
    setState(() => _isSendingEmailOtp = false);

    if (!sent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Failed to send OTP to email'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _showOtpModal(
      target: email,
      title: 'Verify Email Address',
      subtitle: 'Code dispatched to $email',
      onResend: () => auth.sendEmailOtp(email, purpose: 'REGISTRATION_EMAIL'),
      onVerify: (code) => auth.verifyEmailOtp(email, code, purpose: 'REGISTRATION_EMAIL'),
      onVerifiedSuccess: () {
        setState(() => _isEmailVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully! ✅'), backgroundColor: AppColors.primary),
        );
      },
    );
  }

  // --- Send Phone OTP Action ---
  Future<void> _handleVerifyPhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number (e.g. 08026990956).')),
      );
      return;
    }

    setState(() => _isSendingPhoneOtp = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sent = await auth.sendPhoneOtp(phone, purpose: 'REGISTRATION_PHONE');
    setState(() => _isSendingPhoneOtp = false);

    if (!sent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Failed to send OTP to phone'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _showOtpModal(
      target: phone,
      title: 'Verify Phone Number',
      subtitle: 'SMS code dispatched to $phone',
      onResend: () => auth.sendPhoneOtp(phone, purpose: 'REGISTRATION_PHONE'),
      onVerify: (code) => auth.verifyPhoneOtp(phone, code, purpose: 'REGISTRATION_PHONE'),
      onVerifiedSuccess: () {
        setState(() => _isPhoneVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified successfully! ✅'), backgroundColor: AppColors.primary),
        );
      },
    );
  }

  // --- Biometric Login Action ---
  Future<void> _handleBiometricLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.biometricLogin();
    if (success && mounted) {
      _handleSuccessfulLogin();
    }
  }

  void _handleSuccessfulLogin() {
    if (!mounted) return;
    Provider.of<PurchaseProvider>(context, listen: false).fetchMyPurchases();
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NavigationWrapper()),
        (route) => false,
      );
    }
  }

  // --- Step 1 Validator & Advance ---
  void _advanceFromStep1() {
    if (_selectedRole == 'BUYER') {
      // Validate First & Last Name
      final fn = _firstNameCtrl.text.trim();
      final ln = _lastNameCtrl.text.trim();
      if (fn.isEmpty || ln.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your First Name and Last Name to continue.')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      // Validate Developer Company details
      final comp = _companyNameCtrl.text.trim();
      final cac = _cacCtrl.text.trim();
      if (comp.isEmpty || cac.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your Company Name and CAC Number to continue.')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  // --- Step 2 Validator & Advance for Developer ---
  void _advanceFromStep2Developer() {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    if (fn.isEmpty || ln.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Representative / Director First and Last Name.')),
      );
      return;
    }
    setState(() => _currentStep = 3);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return PopScope(
      canPop: !_isRegistering || _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackStep();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () {
              if (_isRegistering && _currentStep > 1) {
                _handleBackStep();
              } else if (_isRegistering && _currentStep == 1) {
                setState(() {
                  _isRegistering = false;
                  _formKey.currentState?.reset();
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: _isRegistering
              ? Text(
                  'Step $_currentStep of $_maxSteps',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                )
              : null,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STEP PROGRESS BAR (WHEN REGISTERING)
                  if (_isRegistering) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentStep / _maxSteps,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // HEADER BADGE & TITLES
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isRegistering
                          ? (_selectedRole == 'DEVELOPER' ? Icons.business_rounded : Icons.person_add_alt_1_rounded)
                          : Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    _getHeaderTitle(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getHeaderSubtitle(),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // ERROR BANNER
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

                  // ==========================================
                  // 1. SIGN IN VIEW (NOT REGISTERING)
                  // ==========================================
                  if (!_isRegistering) ...[

                    // ── Email / Phone Tab Toggle ─────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _loginByPhone = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_loginByPhone ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_loginByPhone
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: !_loginByPhone ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: !_loginByPhone ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _loginByPhone = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _loginByPhone ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _loginByPhone
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: _loginByPhone ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Phone',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _loginByPhone ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Input Field (switches based on tab) ──────────────
                    if (!_loginByPhone)
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email address is required';
                          final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
                          if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'e.g. name@domain.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      )
                    else
                      TextFormField(
                        controller: _loginPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone number is required';
                          final cleaned = v.trim().replaceAll(RegExp(r'[\s\-\+]'), '');
                          if (cleaned.length < 10) return 'Enter a valid Nigerian phone number (e.g. 08012345678)';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g. 08012345678',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // ── Password Field ────────────────────────────────────
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Sign In Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final identifier = _loginByPhone
                                    ? _loginPhoneCtrl.text.trim()
                                    : _emailCtrl.text.trim();
                                final loginRes = await auth.login(identifier, _passwordCtrl.text);
                                if (!mounted) return;

                                if (loginRes['requires2FA'] == true) {
                                  final verified = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginOtpScreen(
                                        twoFactorToken: loginRes['twoFactorToken'] ?? '',
                                        email: loginRes['email'] ?? '',
                                        phone: loginRes['phone'],
                                        identifier: identifier,
                                        channel: loginRes['channel'] ?? (_loginByPhone ? 'SMS' : 'EMAIL'),
                                        maskedDestination: loginRes['maskedDestination'] ?? '',
                                      ),
                                    ),
                                  );
                                  if (verified == true && mounted) {
                                    _handleSuccessfulLogin();
                                  }
                                } else if (loginRes['success'] == true) {
                                  _handleSuccessfulLogin();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _loginByPhone ? 'Sign In with Phone' : 'Sign In with Email',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ),

                    if (_canUseBiometrics) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                          label: const Text(
                            'Unlock with Face ID / Fingerprint',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = true;
                            _currentStep = 1;
                            _isEmailVerified = false;
                            _isPhoneVerified = false;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: const Text(
                          "Don't have an account? Create Account",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

                  // ==========================================
                  // 2. STEP-WISE REGISTRATION VIEWS
                  // ==========================================
                  if (_isRegistering) ...[
                    // ----------------------------------------------------
                    // STEP 1: ROLE SELECTOR & INITIAL DETAILS
                    // ----------------------------------------------------
                    if (_currentStep == 1) ...[
                      const Text(
                        'Select Account Type:',
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
                                    const Text('Buy & verify land', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                                    const Text('List off-plan builds', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // BUYER STEP 1 FIELDS: First Name & Last Name
                      if (_selectedRole == 'BUYER') ...[
                        TextFormField(
                          controller: _firstNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            hintText: 'e.g. Chukwudi',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lastNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            hintText: 'e.g. Adeleke',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                      ] else ...[
                        // DEVELOPER STEP 1 FIELDS: Company Name, CAC, Office Address
                        TextFormField(
                          controller: _companyNameCtrl,
                          textCapitalization: TextCapitalization.words,
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
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _advanceFromStep1,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ----------------------------------------------------
                    // STEP 2 FOR DEVELOPER: REP / DIRECTOR NAME
                    // ----------------------------------------------------
                    if (_selectedRole == 'DEVELOPER' && _currentStep == 2) ...[
                      TextFormField(
                        controller: _firstNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Director / Rep. First Name',
                          hintText: 'e.g. Tunde',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _lastNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Director / Rep. Last Name',
                          hintText: 'e.g. Bakare',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleBackStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _advanceFromStep2Developer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ----------------------------------------------------
                    // FINAL STEP: CONTACT, PHONE OTP, EMAIL OTP & PASSWORD
                    // (Step 2 for Buyer, Step 3 for Developer)
                    // ----------------------------------------------------
                    if ((_selectedRole == 'BUYER' && _currentStep == 2) ||
                        (_selectedRole == 'DEVELOPER' && _currentStep == 3)) ...[
                      // PHONE NUMBER + TWILIO VERIFY BUTTON
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_isPhoneVerified) setState(() => _isPhoneVerified = false);
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone number is required';
                          if (v.trim().length < 10) return 'Enter a valid phone number';
                          if (!_isPhoneVerified) return 'Please tap Verify to confirm your phone';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Phone Number (+234...)',
                          hintText: '08026990956',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _isPhoneVerified
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                      SizedBox(width: 4),
                                      Text('Verified', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: _isSendingPhoneOtp ? null : _handleVerifyPhone,
                                    child: _isSendingPhoneOtp
                                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Verify Phone', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary)),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // EMAIL ADDRESS + RESEND VERIFY BUTTON
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        onChanged: (_) {
                          if (_isEmailVerified) setState(() => _isEmailVerified = false);
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
                          if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                          if (!_isEmailVerified) return 'Please tap Verify to confirm your email';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: _selectedRole == 'DEVELOPER' ? 'Official Business Email' : 'Email Address',
                          hintText: _selectedRole == 'DEVELOPER' ? 'info@company.com' : 'you@example.com',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.mail_outline),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _isEmailVerified
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                      SizedBox(width: 4),
                                      Text('Verified', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: _isSendingEmailOtp ? null : _handleVerifyEmail,
                                    child: _isSendingEmailOtp
                                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Verify Email', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary)),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // PASSWORD FIELD
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 8) return 'Password must be at least 8 characters';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'At least 8 characters',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CONFIRM PASSWORD FIELD
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _passwordCtrl.text) return 'Passwords do not match';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ACTIONS: BACK & CREATE ACCOUNT
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleBackStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) return;
                                      if (!_isPhoneVerified) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please tap "Verify Phone" to confirm your phone number.')),
                                        );
                                        return;
                                      }
                                      if (!_isEmailVerified) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please tap "Verify Email" to confirm your email address.')),
                                        );
                                        return;
                                      }

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
                                      if (success && mounted) {
                                        Provider.of<PurchaseProvider>(context, listen: false).fetchMyPurchases();
                                        Navigator.pop(context);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _selectedRole == 'DEVELOPER' ? 'Create Corporate Account' : 'Create Account',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = false;
                            _currentStep = 1;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: const Text(
                          'Already have an account? Sign In',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHeaderTitle() {
    if (!_isRegistering) return 'Welcome to Hometrust';
    if (_selectedRole == 'BUYER') {
      return _currentStep == 1 ? 'Personal Information' : 'Contact & Security';
    } else {
      if (_currentStep == 1) return 'Corporate Profile';
      if (_currentStep == 2) return 'Authorized Director / Rep';
      return 'Official Contact & Security';
    }
  }

  String _getHeaderSubtitle() {
    if (!_isRegistering) {
      return 'Verify title documents, track off-plan milestones & pay in escrow instalments.';
    }
    if (_selectedRole == 'BUYER') {
      return _currentStep == 1
          ? 'Enter your legal first and last name to get started.'
          : 'Verify your phone number and email address with OTP codes to secure your transactions.';
    } else {
      if (_currentStep == 1) return 'Enter your company name and CAC RC number as registered with CAC Nigeria.';
      if (_currentStep == 2) return 'Enter the legal name of the primary director or authorized company representative.';
      return 'Verify official phone number and corporate email address for escrow management.';
    }
  }
}

