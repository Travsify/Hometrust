import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';

class DeveloperJvBoardScreen extends StatefulWidget {
  const DeveloperJvBoardScreen({super.key});

  @override
  State<DeveloperJvBoardScreen> createState() => _DeveloperJvBoardScreenState();
}

class _DeveloperJvBoardScreenState extends State<DeveloperJvBoardScreen> {
  bool _isLoading = true;
  List<dynamic> _jvListings = [];

  @override
  void initState() {
    super.initState();
    _fetchJvLands();
  }

  Future<void> _fetchJvLands() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/developers/jv-lands');
      if (mounted) {
        setState(() {
          _jvListings = data is List ? data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSubmitProposalModal(dynamic jv) {
    final offerCtrl = TextEditingController(text: 'Proposed: 60% Developer / 40% Landowner with 24-Month Project Turnaround');
    final devTypeCtrl = TextEditingController(text: '12 Units of 4-Bedroom Luxury Terraces with Gym & Swimming Pool');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Submit Joint Venture Proposal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Land: ${jv['title']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: devTypeCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Proposed Development Typology',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: offerCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Sharing Ratio & Development Terms',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('JV proposal submitted! Hometrust Legal & Escrow team will review and coordinate the agreement.'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send Formal Proposal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('JV Land Matching Board', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.handshake_rounded, color: Color(0xFF0284C7), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Joint Venture Opportunities',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All land titles are verified with Governor’s Consent / C-of-O at state registries before listing.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ..._jvListings.map((jv) {
                  final features = (jv['features'] as List?) ?? [];
                  return Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                                  SizedBox(width: 4),
                                  Text('TITLE VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                ],
                              ),
                            ),
                            Text(
                              '${jv['sizeSqm']} SQM',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          jv['title'] ?? 'JV Land',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(jv['location'] ?? 'Nigeria', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Title Document:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  Text(jv['titleDocument'] ?? 'C-of-O', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Proposed Sharing:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  Text(jv['sharingRatio'] ?? '60/40', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Est. GDV:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  Text(CurrencyFormatter.format((jv['estimatedGrossDevValue'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(f, style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSubmitProposalModal(jv),
                            icon: const Icon(Icons.send_rounded, size: 14),
                            label: const Text('Submit JV Proposal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
