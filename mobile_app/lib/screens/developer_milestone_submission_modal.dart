import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class DeveloperMilestoneSubmissionModal extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Map<String, dynamic> milestone;
  final VoidCallback onSubmitted;

  const DeveloperMilestoneSubmissionModal({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.milestone,
    required this.onSubmitted,
  });

  @override
  State<DeveloperMilestoneSubmissionModal> createState() => _DeveloperMilestoneSubmissionModalState();
}

class _DeveloperMilestoneSubmissionModalState extends State<DeveloperMilestoneSubmissionModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late TextEditingController _engineerNameCtrl;
  late TextEditingController _corenNumberCtrl;
  late TextEditingController _certUrlCtrl;
  late TextEditingController _testReportUrlCtrl;
  late TextEditingController _videoUrlCtrl;
  late TextEditingController _trancheAmountCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final m = widget.milestone;
    _engineerNameCtrl = TextEditingController(text: m['corenEngineerName'] ?? '');
    _corenNumberCtrl = TextEditingController(text: m['corenLicenseNumber'] ?? '');
    _certUrlCtrl = TextEditingController(text: m['corenCertificateUrl'] ?? '');
    _testReportUrlCtrl = TextEditingController(text: m['testReportUrl'] ?? '');
    _videoUrlCtrl = TextEditingController(text: m['walkthroughVideoUrl'] ?? '');
    _trancheAmountCtrl = TextEditingController(
      text: (m['trancheAmount'] != null && m['trancheAmount'] > 0)
          ? m['trancheAmount'].toString()
          : '15000000',
    );
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _engineerNameCtrl.dispose();
    _corenNumberCtrl.dispose();
    _certUrlCtrl.dispose();
    _testReportUrlCtrl.dispose();
    _videoUrlCtrl.dispose();
    _trancheAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _simulateLiveCameraCapture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Acquiring live GPS lock & starting 360° camera...'),
          ],
        ),
        backgroundColor: Color(0xFF0F172A),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _videoUrlCtrl.text = 'https://stream.hometrust.ng/proof/${widget.projectId}/milestone-${widget.milestone['id'].toString().substring(0, 8)}.mp4';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ 360° Live Geotagged Video recorded & watermarked successfully!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    });
  }

  Future<void> _submitProofPack() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'projectId': widget.projectId,
        'milestoneId': widget.milestone['id'],
        'corenEngineerName': _engineerNameCtrl.text.trim(),
        'corenLicenseNumber': _corenNumberCtrl.text.trim(),
        'corenCertificateUrl': _certUrlCtrl.text.trim(),
        'testReportUrl': _testReportUrlCtrl.text.trim(),
        'walkthroughVideoUrl': _videoUrlCtrl.text.trim(),
        'trancheAmount': double.tryParse(_trancheAmountCtrl.text.trim()) ?? 0,
        'notes': _notesCtrl.text.trim(),
      };

      await ApiClient.post('/developers/submit-milestone-proof', payload);

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Milestone Proof Pack submitted! 5-Day Buyer Review Window is now active.'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.milestone['title'] ?? 'Milestone';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit Milestone Proof Pack',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.projectName} • $title',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Submitting this proof pack initiates the 5-day subscriber review window. Funds release automatically upon consensus.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. COREN Lead Structural Engineer
              const Text('1. COREN Registered Structural Engineer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _engineerNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Lead Project Engineer Name',
                  hintText: 'e.g. Engr. Babatunde Ogunlesi (FNSE, COREN)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Engineer name is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _corenNumberCtrl,
                decoration: InputDecoration(
                  labelText: 'COREN License Registration Number',
                  hintText: 'e.g. R. 48291 / NSE-39201',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.verified_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'COREN license number is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _certUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'Stamped Valuation / Interim Certificate Document URL',
                  hintText: 'https://storage.hometrust.ng/certs/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Material Quality & Crushing Test Reports
              const Text('2. Concrete Crushing & Material Test Reports', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _testReportUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'Batching Plant Test Report / Steel Mill Waybill',
                  hintText: 'https://storage.hometrust.ng/test-reports/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.science_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Live 360 Walkthrough Video
              const Text('3. Live Geotagged 360° Walkthrough Video', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _videoUrlCtrl,
                      decoration: InputDecoration(
                        labelText: 'Walkthrough Video Stream URL',
                        hintText: 'https://stream.hometrust.ng/...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.videocam_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Live video walkthrough is required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _simulateLiveCameraCapture,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Record Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Tranche Amount & Notes
              const Text('4. Escrow Tranche Disbursement Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _trancheAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Requested Tranche Amount (₦)',
                  prefixText: '₦ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Tranche amount is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Contractor Site Completion Notes',
                  hintText: 'e.g. German floor slab cast with C25 mix; rebar inspection signed off.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProofPack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Proof Pack & Activate 5-Day Review',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
