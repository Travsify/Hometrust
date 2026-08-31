import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

class TransactionAuthResult {
  final bool authorized;
  final String? pin;
  final bool isBiometric;

  TransactionAuthResult({
    required this.authorized,
    this.pin,
    this.isBiometric = false,
  });
}

class TransactionSecurityModal extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double? amount;
  final String? recipient;
  final bool forcePinOnly;

  const TransactionSecurityModal({
    Key? key,
    this.title = 'Authorize Transaction',
    this.subtitle,
    this.amount,
    this.recipient,
    this.forcePinOnly = false,
  }) : super(key: key);

  static Future<TransactionAuthResult?> show(
    BuildContext context, {
    String title = 'Authorize Transaction',
    String? subtitle,
    double? amount,
    String? recipient,
    bool forcePinOnly = false,
  }) {
    return showModalBottomSheet<TransactionAuthResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionSecurityModal(
        title: title,
        subtitle: subtitle,
        amount: amount,
        recipient: recipient,
        forcePinOnly: forcePinOnly,
      ),
    );
  }

  @override
  State<TransactionSecurityModal> createState() => _TransactionSecurityModalState();
}

enum _ModalFlow {
  verify,
  setupNew,
  setupConfirm,
}

class _TransactionSecurityModalState extends State<TransactionSecurityModal> {
  _ModalFlow _flow = _ModalFlow.verify;
  String _enteredPin = '';
  String _firstEnteredPin = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.hasTransactionPin) {
        setState(() {
          _flow = _ModalFlow.setupNew;
        });
      } else if (!widget.forcePinOnly) {
        _triggerBiometricAuth();
      }
    });
  }

  Future<void> _triggerBiometricAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool success = await auth.authenticateTransactionWithBiometrics(
      reason: widget.amount != null
          ? 'Authorize payment of ₦${widget.amount!.toStringAsFixed(0)}'
          : 'Authorize transaction with biometrics',
    );

    if (success && mounted) {
      Navigator.of(context).pop(TransactionAuthResult(
        authorized: true,
        isBiometric: true,
      ));
    }
  }

  void _onKeyPress(String digit) {
    if (_isLoading) return;
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 6) {
        _onPinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_isLoading) return;
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _onPinComplete() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_flow == _ModalFlow.verify) {
      setState(() => _isLoading = true);
      final isValid = await auth.verifyTransactionPin(_enteredPin);
      setState(() => _isLoading = false);

      if (isValid && mounted) {
        Navigator.of(context).pop(TransactionAuthResult(
          authorized: true,
          pin: _enteredPin,
          isBiometric: false,
        ));
      } else if (mounted) {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect 6-digit Payment PIN. Please try again.';
        });
      }
    } else if (_flow == _ModalFlow.setupNew) {
      setState(() {
        _firstEnteredPin = _enteredPin;
        _enteredPin = '';
        _flow = _ModalFlow.setupConfirm;
      });
    } else if (_flow == _ModalFlow.setupConfirm) {
      if (_enteredPin != _firstEnteredPin) {
        setState(() {
          _enteredPin = '';
          _firstEnteredPin = '';
          _flow = _ModalFlow.setupNew;
          _errorMessage = 'PINs did not match. Please enter a 6-digit PIN.';
        });
        return;
      }

      setState(() => _isLoading = true);
      final success = await auth.setupTransactionPin(_enteredPin);
      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.of(context).pop(TransactionAuthResult(
          authorized: true,
          pin: _enteredPin,
          isBiometric: false,
        ));
      } else if (mounted) {
        setState(() {
          _enteredPin = '';
          _firstEnteredPin = '';
          _flow = _ModalFlow.setupNew;
          _errorMessage = auth.errorMessage ?? 'Failed to set up PIN. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle;
    String headerSubtitle;

    if (_flow == _ModalFlow.setupNew) {
      headerTitle = 'Create 6-Digit Payment PIN';
      headerSubtitle = 'Create a secure 6-digit PIN to safeguard your withdrawals and wallet payments.';
    } else if (_flow == _ModalFlow.setupConfirm) {
      headerTitle = 'Confirm Your 6-Digit PIN';
      headerSubtitle = 'Re-enter your 6-digit PIN to confirm setup.';
    } else {
      headerTitle = widget.title;
      headerSubtitle = widget.subtitle ??
          (widget.amount != null
              ? 'Enter your 6-digit PIN or use biometrics to confirm ₦${widget.amount!.toStringAsFixed(0)}'
              : 'Enter your 6-digit Payment PIN to authorize this action.');
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emeraldBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.emeraldBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              headerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              headerSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            if (widget.amount != null && _flow == _ModalFlow.verify) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '₦${widget.amount!.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\\d{1,3})(?=(\\d{3})+(?!\\d))"), (Match m) => "${m[1]},")}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 6-Digit PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : AppColors.cardBorder,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.roseText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.primary),
            ] else ...[
              const SizedBox(height: 28),

              // Custom Keypad (1 - 9, Biometric/Empty, 0, Backspace)
              Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric Action or Empty
                      if (_flow == _ModalFlow.verify && !widget.forcePinOnly)
                        _buildSpecialKey(
                          icon: Icons.fingerprint_rounded,
                          onTap: _triggerBiometricAuth,
                        )
                      else
                        const SizedBox(width: 72, height: 56),

                      _buildKeypadButton('0'),

                      _buildSpecialKey(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 72,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 26,
          ),
        ),
      ),
    );
  }
}
