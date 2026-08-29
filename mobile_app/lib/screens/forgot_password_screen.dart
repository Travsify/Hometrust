import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  bool _isDispatched = false;
  bool _isLoading = false;
  String? _message;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_reset_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              _isDispatched ? 'Enter Reset Code' : 'Forgot Password',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _isDispatched
                  ? 'Enter the security token and your new password.'
                  : 'Enter your registered email address to receive password reset instructions.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.emeraldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_message!, style: const TextStyle(color: AppColors.emeraldText, fontSize: 12)),
              ),

            if (!_isDispatched) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Registered Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _isLoading ? 'Sending...' : 'Send Reset Instructions',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reset Token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _isLoading ? 'Updating Password...' : 'Save New Password',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSendResetLink() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final res = await ApiClient.post('/auth/forgot-password', {
        'email': _emailCtrl.text.trim(),
      });
      setState(() {
        _isLoading = false;
        _isDispatched = true;
        _message = 'Reset instructions dispatched.';
        if (res['resetToken'] != null) {
          _tokenCtrl.text = res['resetToken'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _handleResetPassword() async {
    if (_tokenCtrl.text.trim().isEmpty || _newPasswordCtrl.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.post('/auth/reset-password', {
        'token': _tokenCtrl.text.trim(),
        'newPassword': _newPasswordCtrl.text,
      });
      setState(() {
        _isLoading = false;
        _message = res['message'] ?? 'Password reset successfully.';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}
