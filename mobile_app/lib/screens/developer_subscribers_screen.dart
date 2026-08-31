import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'chat_screen.dart';
import '../widgets/in_app_call_modal.dart';

class DeveloperSubscribersScreen extends StatefulWidget {
  const DeveloperSubscribersScreen({super.key});

  @override
  State<DeveloperSubscribersScreen> createState() => _DeveloperSubscribersScreenState();
}

class _DeveloperSubscribersScreenState extends State<DeveloperSubscribersScreen> {
  bool _isLoading = true;
  List<dynamic> _subscribers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubscribers();
  }

  Future<void> _fetchSubscribers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiClient.get('/developers/my-subscribers');
      if (mounted) {
        setState(() {
          _subscribers = data is List ? data : [];
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

  Future<void> _sendAutomatedReminder(String purchaseId, String buyerName) async {
    try {
      await ApiClient.post('/developers/subscribers/$purchaseId/remind', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automated payment reminder SMS & Push sent to $buyerName via Hometrust Shield.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Subscribers & Sales Ledger', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            onPressed: _fetchSubscribers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _subscribers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 16),
                        const Text('No Buyer Subscriptions Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        const Text(
                          'When buyers subscribe to your off-plan units on instalment plans, their real-time payment schedule, escrow deposits, and signed contracts will be tracked here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSubscribers,
                  color: const Color(0xFF059669),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subscribers.length,
                    itemBuilder: (context, index) {
                      final sub = _subscribers[index];
                      final totalPrice = (sub['totalPrice'] as num?)?.toDouble() ?? 0;
                      final amountPaid = (sub['amountPaid'] as num?)?.toDouble() ?? 0;
                      final balance = (sub['outstandingBalance'] as num?)?.toDouble() ?? (totalPrice - amountPaid);
                      final progress = totalPrice > 0 ? (amountPaid / totalPrice).clamp(0.0, 1.0) : 0.0;
                      final buyerRef = sub['buyerRef'] ?? 'Verified Subscriber';
                      final unitLabel = sub['unitName'] ?? 'Unit';

                      return InkWell(
                        onTap: () => _showSubscriberDetailsModal(sub),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Anonymized Buyer Reference & Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            buyerRef,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                          Text(
                                            sub['purchaseCode'] ?? 'HT-PUR-001',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      sub['status'] ?? 'ACTIVE',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Unit Locked / Purchased
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF059669)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Reserved Unit: $unitLabel',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                            // Financial Progress Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Paid: ${CurrencyFormatter.format(amountPaid)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                Text('Total: ${CurrencyFormatter.format(totalPrice)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance: ${CurrencyFormatter.format(balance)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}% Paid',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Contract Signature Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 14),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Privacy Shield: Communications mediated in-app only',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // IN-APP MEDIATED ACTION BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            recipientId: sub['userId'],
                                            recipientName: buyerRef,
                                            recipientRole: 'Subscriber (${sub['purchaseCode'] ?? 'HT-PUR'})',
                                            propertyTitle: sub['unitName'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                                    label: const Text('In-App Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      foregroundColor: const Color(0xFF0F172A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      InAppCallModal.show(
                                        context,
                                        entityName: buyerRef,
                                        entityRole: 'Subscriber (${sub['purchaseCode'] ?? 'HT-PUR'})',
                                      );
                                    },
                                    icon: const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFF059669)),
                                    label: const Text('In-App Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: const BorderSide(color: Color(0xFF059669)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD97706), size: 20),
                                  tooltip: 'Send Payment Reminder SMS & Push',
                                  onPressed: () => _sendAutomatedReminder(sub['id'], buyerRef),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFFBEB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  ),
                ),
    );
  }

  void _showSubscriberDetailsModal(dynamic sub) {
    final buyerRef = sub['buyerRef'] ?? 'Subscriber';
    final unitLabel = sub['unitName'] ?? 'Unit';
    final totalPrice = (sub['totalPrice'] as num?)?.toDouble() ?? 0;
    final amountPaid = (sub['amountPaid'] as num?)?.toDouble() ?? 0;
    final balance = (sub['outstandingBalance'] as num?)?.toDouble() ?? (totalPrice - amountPaid);
    final progress = totalPrice > 0 ? (amountPaid / totalPrice).clamp(0.0, 1.0) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      buyerRef,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Purchase Code: ${sub['purchaseCode'] ?? 'N/A'} · Status: ${sub['status'] ?? 'ACTIVE'}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
            ),
            const Divider(height: 24),
            _detailRow('Locked Unit', unitLabel),
            _detailRow('Payment Plan', sub['paymentPlanName'] ?? 'Instalment Plan'),
            _detailRow('Total Agreed Price', CurrencyFormatter.format(totalPrice)),
            _detailRow('Total Paid into Escrow', CurrencyFormatter.format(amountPaid), valueColor: const Color(0xFF059669)),
            _detailRow('Outstanding Balance', CurrencyFormatter.format(balance), valueColor: const Color(0xFFDC2626)),
            _detailRow('Progress', '${(progress * 100).toInt()}% Paid'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unit Locked: This unit is permanently locked and cannot be resold or advertised to other buyers.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w700, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close Ledger', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

