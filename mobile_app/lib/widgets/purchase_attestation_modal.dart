import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class PurchaseAttestationModal extends StatefulWidget {
  final String title;
  final String? purchaseId;
  final VoidCallback onConfirmed;

  const PurchaseAttestationModal({
    super.key,
    required this.title,
    this.purchaseId,
    required this.onConfirmed,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? purchaseId,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PurchaseAttestationModal(
        title: title,
        purchaseId: purchaseId,
        onConfirmed: () => Navigator.pop(context, true),
      ),
    );
    return result ?? false;
  }

  @override
  State<PurchaseAttestationModal> createState() => _PurchaseAttestationModalState();
}

class _PurchaseAttestationModalState extends State<PurchaseAttestationModal> {
  bool _q1 = false;
  bool _q2 = false;
  bool _q3 = false;
  bool _q4 = false;
  bool _q5 = false;
  bool _q6 = false;
  bool _isSubmitting = false;

  bool get _allConfirmed => _q1 && _q2 && _q3 && _q4 && _q5 && _q6;

  Future<void> _handleConfirm() async {
    if (!_allConfirmed) return;

    if (widget.purchaseId != null) {
      setState(() => _isSubmitting = true);
      try {
        await ApiClient.post('/purchases/${widget.purchaseId}/attest', {
          'q1': _q1,
          'q2': _q2,
          'q3': _q3,
          'q4': _q4,
          'q5': _q5,
          'q6': _q6,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attestation error: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }
    }

    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Buyer Pre-Purchase Attestation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Attestation for ${widget.title}. You must review and agree to each condition in your sound mind before a 30-minute reservation lock can be issued.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 14),

          // Questions List
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAttestationItem(
                    index: 1,
                    question: 'I have inspected or received full information about this property/unit.',
                    value: _q1,
                    onChanged: (val) => setState(() => _q1 = val ?? false),
                  ),
                  _buildAttestationItem(
                    index: 2,
                    question: 'I am fully satisfied with the specifications, condition, and location.',
                    value: _q2,
                    onChanged: (val) => setState(() => _q2 = val ?? false),
                  ),
                  _buildAttestationItem(
                    index: 3,
                    question: 'I understand the total agreed price, payment schedule, and platform fees.',
                    value: _q3,
                    onChanged: (val) => setState(() => _q3 = val ?? false),
                  ),
                  _buildAttestationItem(
                    index: 4,
                    question: 'I am initiating this purchase and reservation of my own free will.',
                    value: _q4,
                    onChanged: (val) => setState(() => _q4 = val ?? false),
                  ),
                  _buildAttestationItem(
                    index: 5,
                    question: 'I accept Hometrust\'s Terms of Service and Escrow Agreement covenants.',
                    value: _q5,
                    onChanged: (val) => setState(() => _q5 = val ?? false),
                  ),
                  _buildAttestationItem(
                    index: 6,
                    question: 'I understand my funds are held securely in escrow until milestones are independently verified.',
                    value: _q6,
                    onChanged: (val) => setState(() => _q6 = val ?? false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lock notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Once submitted, a 30-minute atomic lock will be placed on this unit. If payment is not initiated within 30 minutes, the lock will automatically expire and release the unit back to the public.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _allConfirmed && !_isSubmitting ? _handleConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _allConfirmed ? 'I Attest & Accept — Proceed to Lock Unit' : 'Answer "Yes" to All 6 Questions',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttestationItem({
    required int index,
    required String question,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF059669).withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          width: value ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item $index',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: value ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    question,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
