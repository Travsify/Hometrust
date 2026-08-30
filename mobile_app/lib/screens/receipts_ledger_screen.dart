import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/persistent_bottom_nav.dart';

class ReceiptsLedgerScreen extends StatefulWidget {
  final String purchaseId;
  final String purchaseCode;

  const ReceiptsLedgerScreen({
    super.key,
    required this.purchaseId,
    required this.purchaseCode,
  });

  @override
  State<ReceiptsLedgerScreen> createState() => _ReceiptsLedgerScreenState();
}

class _ReceiptsLedgerScreenState extends State<ReceiptsLedgerScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _ledgerData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  Future<void> _fetchLedger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiClient.get('/purchases/${widget.purchaseId}/receipts-ledger');
      if (mounted) {
        setState(() {
          _ledgerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledgerData;
    final total = (ledger?['totalPrice'] as num?)?.toDouble() ?? 0;
    final paid = (ledger?['amountPaid'] as num?)?.toDouble() ?? 0;
    final balance = (ledger?['outstandingBalance'] as num?)?.toDouble() ?? 0;
    final pct = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final schedule = (ledger?['amortizationSchedule'] as List?) ?? [];
    final payments = (ledger?['paymentsList'] as List?) ?? [];

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Instalment & Receipts Ledger',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary Card
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
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
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
                                Text(
                                  widget.purchaseCode,
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(pct * 100).toInt()}% COMPLETED',
                                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Paid in Escrow', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(paid),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Outstanding Balance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(balance),
                                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: const Color(0xFF334155),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Amortisation Tranches Section
                      const Text(
                        'Milestone Amortisation Schedule',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      ...schedule.map((tranche) {
                        final isPaid = tranche['status'] == 'PAID';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPaid ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? const Color(0xFF059669).withValues(alpha: 0.1)
                                      : const Color(0xFF64748B).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: isPaid ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tranche['tranche'] ?? 'Tranche',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Milestone: ${tranche['milestoneCovered'] ?? "Site"}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format((tranche['targetAmount'] as num?)?.toDouble() ?? 0),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: isPaid ? const Color(0xFF059669) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPaid ? 'PAID IN ESCROW' : 'SCHEDULED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isPaid ? const Color(0xFF059669) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // Verified Receipts List
                      const Text(
                        'Verified Transaction Receipts',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      if (payments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'No receipts generated yet. Initial deposit payment will reflect here immediately upon settlement.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        ...payments.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['ref'] ?? 'EV-PAY-001',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p['date'] != null ? p['date'].toString().split('T')[0] : 'Date',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format((p['amount'] as num?)?.toDouble() ?? 0),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('ESCROW CLEARED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}
