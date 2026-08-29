import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BecomeDeveloperScreen extends StatefulWidget {
  const BecomeDeveloperScreen({super.key});

  @override
  State<BecomeDeveloperScreen> createState() => _BecomeDeveloperScreenState();
}

class _BecomeDeveloperScreenState extends State<BecomeDeveloperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _cacCtrl = TextEditingController();
  final _officeAddressCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  String _businessType = 'LTD';
  int _yearsOperating = 1;
  bool _isLoading = false;
  int _step = 0; // 0 = info, 1 = review, 2 = success

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _cacCtrl.dispose();
    _officeAddressCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiClient.post('/auth/upgrade-to-developer', {
        'companyName': _companyNameCtrl.text.trim(),
        'cacNumber': _cacCtrl.text.trim(),
        'officeAddress': _officeAddressCtrl.text.trim(),
        'contactPerson': _contactPersonCtrl.text.trim().isEmpty
            ? null
            : _contactPersonCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'businessType': _businessType,
        'yearsOperating': _yearsOperating,
        'website': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        'about': _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
      });

      // Persist the new token and update AuthProvider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final newToken = result['token'] as String?;
      if (newToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', newToken);
        // Reload user from /auth/me so the provider holds the DEVELOPER role
        await auth.refreshUser();
        // Set developer mode active
        final modePrefs = await SharedPreferences.getInstance();
        await modePrefs.setBool('developer_mode_active', true);
      }

      if (mounted) setState(() => _step = 2);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Become a Developer',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: _step == 2 ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_center_rounded, color: Color(0xFF059669), size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Application Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your developer account is now active. Your application is under review — you will be fully verified within 24–48 hours.\n\nYou can start using your Developer Dashboard right away.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop back to profile; the provider now reflects DEVELOPER role
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Go to Developer Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business_center_rounded, color: Color(0xFF34D399), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Developer Onboarding', style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            Text('Hometrust Certified Developer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '✅  Your existing KYC verification carries over — no re-verification needed.\n'
                    '✅  Your current NIN/BVN identity is already linked to this account.\n'
                    '✅  Once approved, you can switch between Developer and Buyer mode anytime.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Company Info
            _sectionLabel('Company Information'),
            _field(
              controller: _companyNameCtrl,
              label: 'Registered Company Name',
              hint: 'e.g. Greenfield Homes Ltd',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _cacCtrl,
              label: 'CAC Registration Number',
              hint: 'e.g. RC-1234567',
              validator: (v) => (v == null || v.trim().length < 5) ? 'Enter a valid CAC number' : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _officeAddressCtrl,
              label: 'Head Office Address',
              hint: 'e.g. 14 Ozumba Mbadiwe, Victoria Island, Lagos',
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Office address is required' : null,
            ),
            const SizedBox(height: 14),

            // Business type picker
            const Text('Business Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _businessType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'LTD', child: Text('Private Limited (Ltd)')),
                    DropdownMenuItem(value: 'PLC', child: Text('Public Limited (Plc)')),
                    DropdownMenuItem(value: 'SOLE', child: Text('Sole Proprietorship')),
                    DropdownMenuItem(value: 'PARTNERSHIP', child: Text('Partnership')),
                    DropdownMenuItem(value: 'NGO', child: Text('NGO / Foundation')),
                  ],
                  onChanged: (v) => setState(() => _businessType = v ?? 'LTD'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Years in operation
            const Text('Years Operating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _yearsOperating,
                  isExpanded: true,
                  items: List.generate(30, (i) => i + 1)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y year${y > 1 ? 's' : ''}')))
                      .toList(),
                  onChanged: (v) => setState(() => _yearsOperating = v ?? 1),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Contact
            _sectionLabel('Contact Details'),
            _field(
              controller: _contactPersonCtrl,
              label: 'Contact Person / Director Name',
              hint: user?.fullName ?? 'Leave blank to use your name',
            ),
            const SizedBox(height: 14),
            _field(
              controller: _phoneCtrl,
              label: 'Business Phone Number',
              hint: '+234 800 000 0000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _websiteCtrl,
              label: 'Website (optional)',
              hint: 'https://yourcompany.com',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Section: About
            _sectionLabel('About Your Company'),
            _field(
              controller: _aboutCtrl,
              label: 'Brief description of your projects',
              hint: 'Tell us about your developments, areas of focus, and track record…',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your developer profile will be reviewed by the Hometrust compliance team within 24–48 hours. You will receive full developer privileges after approval.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: const Color(0xFF059669).withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Developer Application',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
        ),
      ],
    );
  }
}
