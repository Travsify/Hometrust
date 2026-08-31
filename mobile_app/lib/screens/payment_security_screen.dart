import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

class PaymentSecurityScreen extends StatefulWidget {
  const PaymentSecurityScreen({super.key});

  @override
  State<PaymentSecurityScreen> createState() => _PaymentSecurityScreenState();
}

class _PaymentSecurityScreenState extends State<PaymentSecurityScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsStatus();
  }

  Future<void> _checkBiometricsStatus() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('biometrics_transaction_enabled') ?? true;

      if (mounted) {
        setState(() {
          _biometricsAvailable = canCheck || isDeviceSupported;
          _biometricsEnabled = enabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Scan fingerprint or face to enable biometric transaction confirmation',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (!authenticated) return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Biometric verification failed: $e'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_transaction_enabled', value);
    if (mounted) {
      setState(() => _biometricsEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '✅ Biometric confirmation enabled' : 'ℹ️ Biometric confirmation disabled (PIN will be required)'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _showChangePinModal(BuildContext context, {bool isForgot = false}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasPin = auth.hasTransactionPin;

    final oldPinCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    bool usePassword = isForgot || !hasPin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pin_outlined, color: Color(0xFF059669), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              !hasPin ? 'Create Payment PIN' : (usePassword ? 'Reset PIN with Password' : 'Change 6-Digit PIN'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (hasPin && !usePassword) ...[
                      const Text('Current 6-Digit PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: oldPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Enter current 6-digit PIN',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setModalState(() => usePassword = true),
                          child: const Text('Forgot PIN? Use Password', style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ] else if (hasPin && usePassword) ...[
                      const Text('Account Login Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter account password to verify identity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.key_outlined),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setModalState(() => usePassword = false),
                          child: const Text('Remember PIN? Use Old PIN', style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Text('New 6-Digit PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: newPinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Enter 6 numbers',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.shield_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Confirm New 6-Digit PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Re-enter 6 numbers',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final newPin = newPinCtrl.text.trim();
                                final confirmPin = confirmPinCtrl.text.trim();

                                if (newPin.length != 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PIN must be exactly 6 digits')),
                                  );
                                  return;
                                }
                                if (newPin != confirmPin) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('New PINs do not match')),
                                  );
                                  return;
                                }

                                setModalState(() => _isLoading = true);
                                try {
                                  if (!hasPin) {
                                    await auth.setupTransactionPin(newPin);
                                  } else {
                                    await auth.changeTransactionPin(
                                      currentPin: usePassword ? null : oldPinCtrl.text.trim(),
                                      currentPassword: usePassword ? passwordCtrl.text.trim() : null,
                                      newPin: newPin,
                                    );
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎉 6-Digit Payment PIN updated successfully! 🔒'),
                                        backgroundColor: Color(0xFF059669),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceAll('Exception: ', '')),
                                        backgroundColor: const Color(0xFFDC2626),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setModalState(() => _isLoading = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(!hasPin ? 'Save 6-Digit PIN' : 'Update Payment PIN', style: const TextStyle(fontWeight: FontWeight.w800)),
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
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final hasPin = auth.hasTransactionPin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Security & PIN',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. STATUS CARD
          Container(
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
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF059669), width: 1),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 26),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasPin ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFD97706).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: hasPin ? const Color(0xFF10B981) : const Color(0xFFD97706), width: 0.8),
                      ),
                      child: Text(
                        hasPin ? 'PIN ACTIVE ✅' : 'SETUP REQUIRED ⚠️',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: hasPin ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transaction Safeguard',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  hasPin
                      ? 'Your 6-digit payment PIN protects all disbursements, escrow payments, and withdrawals.'
                      : 'Create your 6-digit payment PIN to secure your wallet funds and enable instant disbursements.',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. BIOMETRIC CONFIRMATION CARD
          const Text('Biometric Authentication', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF059669), size: 24),
              ),
              title: const Text('Fingerprint / Face ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
              subtitle: const Text('Authorize transactions instantly with device biometrics instead of typing your PIN', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              value: _biometricsEnabled,
              activeColor: const Color(0xFF059669),
              onChanged: _biometricsAvailable ? (val) => _toggleBiometrics(val) : null,
            ),
          ),
          const SizedBox(height: 20),

          // 3. PIN ACTIONS
          const Text('PIN Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  title: Text(
                    hasPin ? 'Change 6-Digit Payment PIN' : 'Create 6-Digit Payment PIN',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                  subtitle: Text(
                    hasPin ? 'Update your current transaction PIN' : 'Set up your PIN for the first time',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () => _showChangePinModal(context),
                ),
                if (hasPin) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    title: const Text('Forgot Payment PIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                    subtitle: const Text('Reset your PIN using your account login password', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _showChangePinModal(context, isForgot: true),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. SECURITY INFO
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF059669), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hometrust enforces 256-bit encryption for all PIN data. Hometrust staff will never ask for your 6-digit payment PIN or bank passwords.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
