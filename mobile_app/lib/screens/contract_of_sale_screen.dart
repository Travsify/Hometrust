import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../widgets/persistent_bottom_nav.dart';

class ContractOfSaleScreen extends StatefulWidget {
  final String purchaseId;
  final String purchaseCode;

  const ContractOfSaleScreen({
    super.key,
    required this.purchaseId,
    required this.purchaseCode,
  });

  @override
  State<ContractOfSaleScreen> createState() => _ContractOfSaleScreenState();
}

class _ContractOfSaleScreenState extends State<ContractOfSaleScreen> {
  bool _isLoading = true;
  bool _isSigning = false;
  Map<String, dynamic>? _contractData;
  String? _errorMessage;
  final TextEditingController _signatureCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContract();
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient.get('/purchases/${widget.purchaseId}/contract');
      if (mounted) {
        setState(() {
          _contractData = res;
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

  Future<void> _signContract() async {
    if (_signatureCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type your legal full name to sign.')),
      );
      return;
    }

    setState(() => _isSigning = true);

    try {
      final res = await ApiClient.post('/purchases/${widget.purchaseId}/sign-contract', {
        'legalFullName': _signatureCtrl.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isSigning = false;
          _contractData = res['contract'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Contract successfully signed and verified with cryptographic timestamp!'),
            backgroundColor: AppColors.emeraldText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.roseText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contractData;
    final isSigned = contract?['status'] == 'FULLY_EXECUTED';
    final parties = contract?['parties'] as Map<String, dynamic>?;
    final recitals = (contract?['recitals'] as List?) ?? [];
    final clauses = (contract?['clauses'] as List?) ?? [];

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Tri-Partite Contract of Sale',
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
                      // Status Badge Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSigned
                              ? const Color(0xFF059669).withValues(alpha: 0.1)
                              : const Color(0xFFD97706).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSigned ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSigned ? Icons.verified_rounded : Icons.pending_actions_rounded,
                              color: isSigned ? const Color(0xFF059669) : const Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSigned ? 'CONTRACT FULLY EXECUTED' : 'PENDING PURCHASER E-SIGNATURE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isSigned ? const Color(0xFF059669) : const Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSigned
                                        ? 'Executed on ${contract?['signatureDate']?.toString().split('T')[0] ?? "Today"}. Legally binding under the Arbitration & Mediation Act 2023.'
                                        : 'Please review all covenants and type your legal name to execute.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Document Body Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'THIS TRI-PARTITE CONTRACT OF SALE',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // PARTIES
                            _header('THE PARTIES'),
                            _partyBox('PARTY A (VENDOR)', parties?['partyA_developer']?['name'] ?? 'Developer Ltd', 'Registered RC: ${parties?['partyA_developer']?['cac'] ?? "RC-Certified"}'),
                            const SizedBox(height: 8),
                            _partyBox('PARTY B (PURCHASER)', parties?['partyB_buyer']?['name'] ?? 'Valued Buyer', 'Contact: ${parties?['partyB_buyer']?['email'] ?? "On file"}'),
                            const SizedBox(height: 8),
                            _partyBox('PARTY C (ESCROW ARBITER)', 'Hometrust Title Assurance & Escrow Services Ltd', 'Regulatory Escrow Custodian & Title Arbiter'),
                            const Divider(height: 28, color: AppColors.cardBorder),

                            // RECITALS
                            _header('RECITALS & ROOT OF TITLE'),
                            ...recitals.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $r', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.4)),
                                )),
                            const Divider(height: 28, color: AppColors.cardBorder),

                            // CLAUSES
                            _header('OPERATIVE COVENANTS & TERMS'),
                            ...clauses.map((c) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${c['clauseNumber']} ${c['title']}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['content'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Execution Signature Box
                      if (!isSigned) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Electronic Signature & Attestation',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'By typing your full legal name below, you execute this Tri-Partite Contract of Sale with full legal effect under the Nigerian Evidence Act 2011 and Arbitration Act 2023.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _signatureCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Type Full Legal Name (E-Signature)',
                                  hintText: parties?['partyB_buyer']?['name'] ?? 'Your Full Name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.draw_rounded, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSigning ? null : _signContract,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isSigning
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Execute & Digitally Sign Contract',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
      ),
    );
  }

  Widget _partyBox(String role, String name, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: Color(0xFF64748B), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
