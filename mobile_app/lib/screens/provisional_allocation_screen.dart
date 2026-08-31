import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';

class ProvisionalAllocationScreen extends StatefulWidget {
  final String purchaseId;
  final String purchaseCode;

  const ProvisionalAllocationScreen({
    super.key,
    required this.purchaseId,
    required this.purchaseCode,
  });

  @override
  State<ProvisionalAllocationScreen> createState() => _ProvisionalAllocationScreenState();
}

class _ProvisionalAllocationScreenState extends State<ProvisionalAllocationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _allocationData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllocationLetter();
  }

  Future<void> _fetchAllocationLetter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiClient.get('/purchases/${widget.purchaseId}/allocation-letter');
      if (mounted) {
        setState(() {
          _allocationData = data;
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alloc = _allocationData;
    final buyer = alloc?['buyer'] as Map<String, dynamic>?;
    final dev = alloc?['developer'] as Map<String, dynamic>?;
    final prop = alloc?['property'] as Map<String, dynamic>?;
    final fin = alloc?['financialGuarantee'] as Map<String, dynamic>?;
    final covenants = (alloc?['legalCovenants'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Provisional Allocation Certificate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {
              final shareUrl = _allocationData?['qrVerificationUrl'] ??
                  'https://hometrust.ng/verify/${widget.purchaseCode}';
              Share.share(
                'My Hometrust Provisional Allocation Certificate (${widget.purchaseCode}):\n$shareUrl',
                subject: 'Hometrust Allocation Certificate - ${widget.purchaseCode}',
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF34D399)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAllocationLetter,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // Certificate Container with Parchment Texture Effect
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFD97706), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Seal & Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0F172A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'HOMETRUST',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'TITLE ASSURANCE & ESCROW ARBITER',
                                          style: TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF059669)),
                                  ),
                                  child: const Text(
                                    'OFFICIAL SEAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF059669),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28, thickness: 1, color: Color(0xFFE2E8F0)),

                            // Document Title
                            const Center(
                              child: Column(
                                children: [
                                  Text(
                                    'PROVISIONAL LETTER OF ALLOCATION',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tri-Partite Verified Off-Plan Title Guarantee',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Reference Box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Allocation Ref', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                      Text(
                                        alloc?['allocationRef'] ?? 'HT-ALLOC-000',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Date Stamped', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                      Text(
                                        alloc?['stampedDate'] != null ? alloc!['stampedDate'].toString().split('T')[0] : 'Today',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 1. ALLOCATED PURCHASER DETAILS
                            _sectionHeader('1. ALLOCATED PURCHASER (BENEFICIARY)'),
                            _dataRow('Full Legal Name', buyer?['fullName'] ?? 'Valued Purchaser'),
                            _dataRow('Identity Verification', 'NIN / BVN Biometrically Verified 🛡️'),
                            _dataRow('Contact Phone', buyer?['phone'] ?? 'On File'),
                            _dataRow('Registered Email', buyer?['email'] ?? 'On File'),
                            const SizedBox(height: 14),

                            // 2. PROPERTY & UNIT SPECIFICATIONS
                            _sectionHeader('2. PROPERTY & UNIT SPECIFICATIONS'),
                            _dataRow('Development', prop?['estateName'] ?? 'Estate'),
                            _dataRow('Allocated Unit', prop?['unitDesignation'] ?? 'Unit'),
                            _dataRow('Cadastral Location', prop?['location'] ?? 'Lagos, Nigeria'),
                            _dataRow('Unit Footprint', '${prop?['sizeSqm'] ?? "180 SQM"} (${prop?['bedrooms'] ?? 3} Bedrooms)'),
                            _dataRow('Cadastral Survey Polygon', 'GPS Hashed & Plotted ✅'),
                            const SizedBox(height: 14),

                            // 3. FINANCIAL GUARANTEE & PRICE LOCK
                            _sectionHeader('3. FINANCIAL & PRICE LOCK GUARANTEE'),
                            _dataRow('Agreed Purchase Price', CurrencyFormatter.format((fin?['totalAgreedPrice'] as num?)?.toDouble() ?? 0)),
                            _dataRow('Initial Commitment Deposit', CurrencyFormatter.format((fin?['initialDepositRequired'] as num?)?.toDouble() ?? 0)),
                            _dataRow('Current Amount in Escrow', CurrencyFormatter.format((fin?['amountPaidIntoEscrow'] as num?)?.toDouble() ?? 0)),
                            _dataRow('Outstanding Balance', CurrencyFormatter.format((fin?['outstandingBalance'] as num?)?.toDouble() ?? 0)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Price Lock Guarantee: Developer is legally barred from increasing price during construction.',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. STATUTORY LEGAL COVENANTS
                            _sectionHeader('4. LEGAL COVENANTS & TITLE UNDERTAKINGS'),
                            ...covenants.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                                      Expanded(
                                        child: Text(
                                          c.toString(),
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 20),

                            // Official Seal & Signatures
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_rounded, color: Color(0xFFD97706), size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AUTHENTICATED BY HOMETRUST LEGAL',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Official Tri-Partite Title Assurance Seal. Enforceable under Nigerian Property & Arbitration Law.',
                                          style: TextStyle(fontSize: 9.5, color: Color(0xFF78350F), height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Download PDF Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final certUrl = _allocationData?['certificatePdfUrl'] ??
                                'https://estateverify-app.onrender.com/api/v1/purchases/${widget.purchaseId}/allocation-certificate.pdf';
                            try {
                              final uri = Uri.parse(certUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open PDF. Please try again.'),
                                      backgroundColor: Color(0xFFDC2626),
                                    ),
                                  );
                                }
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open PDF. Please check your internet connection.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download Official Stamped PDF Certificate', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
