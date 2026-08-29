import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _ninCtrl = TextEditingController();
  final _bvnCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cacCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;
  Map<String, dynamic>? _generatedAccount;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDeveloper = auth.user?.role == 'DEVELOPER';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isDeveloper ? 'Corporate KYB Verification' : 'Identity Verification (KYC)'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isSuccess) ...[
              const Icon(Icons.verified_user_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                isDeveloper ? 'Corporate KYB Registration' : 'Complete Your KYC Verification',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                isDeveloper
                  ? 'Verify your corporate registration (CAC) to receive a dedicated business account for escrow payouts.'
                  : 'Verify your NIN & BVN to generate your dedicated Nigerian virtual bank account for seamless property payments.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.roseBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.roseText, fontSize: 12)),
                ),

              if (!isDeveloper) ...[
                TextField(
                  controller: _ninCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'National Identity Number (NIN)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bvnCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bank Verification Number (BVN)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Residential Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Registered Company Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cacCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CAC Registration Number (RC/BN)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ninCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Managing Director NIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSubmit(isDeveloper),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _isLoading ? 'Verifying & Generating Account...' : 'Verify & Generate Dedicated Account',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ] else ...[
              // Success View with Dedicated Account Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.emeraldBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.emeraldBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.emeraldText),
                    const SizedBox(height: 12),
                    const Text('Verification Completed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.emeraldText)),
                    const SizedBox(height: 6),
                    const Text(
                      'Your dedicated bank account is active. You can now transfer funds from any Nigerian mobile banking app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dedicated Account Details
              if (_generatedAccount != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ESTATEVERIFY DEDICATED ACCOUNT', style: TextStyle(color: AppColors.emeraldText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _generatedAccount!['accountNumber'] ?? '0281928391',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedAccount!['bankName'] ?? 'Wema Bank',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 24, color: Color(0xFF334155)),
                      Text(
                        _generatedAccount!['accountName'] ?? 'EstateVerify / Valued Customer',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSubmit(bool isDeveloper) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (isDeveloper) {
        final res = await ApiClient.post('/banking/kyb/submit', {
          'companyName': _companyCtrl.text.trim(),
          'cacNumber': _cacCtrl.text.trim(),
          'directorNin': _ninCtrl.text.trim(),
        });
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _generatedAccount = res['virtualAccount'];
        });
      } else {
        final res = await ApiClient.post('/banking/kyc/submit', {
          'nin': _ninCtrl.text.trim(),
          'bvn': _bvnCtrl.text.trim(),
          'residentialAddress': _addressCtrl.text.trim(),
        });
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _generatedAccount = res['virtualAccount'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}
