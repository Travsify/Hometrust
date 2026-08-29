import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;
  Map<String, dynamic>? _generatedAccount;
  String _currentStep = '';

  void _startAutomatedKyc(bool isDeveloper) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentStep = 'Connecting to National Identity Gateway...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _currentStep = isDeveloper
              ? 'Validating Corporate CAC & RC Registration...'
              : 'Validating National Identity Register (NIN & BVN)...';
        });
      }

      final res = await ApiClient.post('/banking/kyc/auto-verify', {
        'verificationType': isDeveloper ? 'CORPORATE_KYB' : 'INDIVIDUAL_KYC',
      });

      if (mounted) {
        setState(() {
          _currentStep = 'Issuing Dedicated CBN-Regulated Virtual NUBAN Account...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.refreshUser();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _generatedAccount = res != null && res is Map ? (res['virtualAccount'] ?? res) : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isDeveloper = user?.role == 'DEVELOPER';

    // 1. MUST SIGN IN FIRST GATE
    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Identity Verification',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_person_rounded, color: Color(0xFF059669), size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in or register an account before proceeding with identity verification (KYC/KYB).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Sign In / Register',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isDeveloper ? 'Corporate Verification (KYB)' : 'Identity Verification (KYC)',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSuccess) ...[
              // SUCCESS STATE
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 42),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verification Successful! 🛡️',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your identity is officially verified. Your dedicated CBN-regulated Virtual Bank Account is now live.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    // Virtual Account Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'DEDICATED ESCROW NUBAN',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE & VERIFIED',
                                  style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _generatedAccount?['accountNumber'] ?? '9938472910',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _generatedAccount?['bankName'] ?? 'Providus Bank',
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _generatedAccount?['accountName'] ?? '${user.firstName} ${user.lastName}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Proceed to Home Screen',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // PRE-VERIFICATION FLOW
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.security_rounded, color: Color(0xFF059669), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDeveloper ? 'Corporate KYB Gateway' : 'Identity Verification (KYC)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Bank-Grade National Identity & CAC Check',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    Text(
                      isDeveloper
                          ? 'Corporate Verification:\nYour CAC registration and corporate identity will be validated in real time against the business registry. Once verified, a dedicated corporate escrow account is provisioned for receiving milestone disbursements.'
                          : 'Identity Verification:\nYour NIN and BVN identity records will be validated in real time against the national identity register. This instantly activates your dedicated Nigerian Virtual Bank Account for funding property purchases.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // USER PROFILE SNAPSHOT
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Registered Name:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Account Type:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          isDeveloper ? 'Corporate Developer (KYB)' : 'Individual Buyer (KYC)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Status:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'UNVERIFIED ⚠️',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                ),
              ],

              const SizedBox(height: 28),

              // AUTOMATED VERIFICATION BUTTON / PROGRESS
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF059669)),
                      const SizedBox(height: 16),
                      Text(
                        _currentStep,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _startAutomatedKyc(isDeveloper),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: const Color(0xFF059669).withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          isDeveloper ? 'Launch KYB' : 'Launch KYC',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
