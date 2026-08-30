import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import 'inspection_booking_modal.dart';

class SubscriberMilestoneReviewModal extends StatefulWidget {
  final Map<String, dynamic> milestone;
  final String projectName;
  final VoidCallback onVoted;

  const SubscriberMilestoneReviewModal({
    super.key,
    required this.milestone,
    required this.projectName,
    required this.onVoted,
  });

  @override
  State<SubscriberMilestoneReviewModal> createState() => _SubscriberMilestoneReviewModalState();
}

class _SubscriberMilestoneReviewModalState extends State<SubscriberMilestoneReviewModal> {
  bool _isVoting = false;
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.milestone['remainingSeconds'] ?? 0;
    if (_remainingSeconds > 0) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemainingTime(int totalSeconds) {
    if (totalSeconds <= 0) return 'Review Window Closed (Auto-Disbursement Active)';
    final days = totalSeconds ~/ (24 * 3600);
    final hours = (totalSeconds % (24 * 3600)) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (days > 0) {
      return '$days days $hours hrs $minutes mins remaining';
    }
    return '$hours hrs $minutes mins $seconds secs remaining';
  }

  Future<void> _castVote(String decision, {String? comment}) async {
    setState(() => _isVoting = true);

    try {
      final payload = {
        'milestoneId': widget.milestone['id'],
        'decision': decision,
        'comment': comment,
      };

      await ApiClient.post('/purchases/milestones/vote', payload);

      if (mounted) {
        Navigator.pop(context);
        widget.onVoted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'APPROVE'
                  ? '🎉 Your approval vote for this tranche release has been recorded!'
                  : '⚠️ Your dispute observation has been lodged with the platform legal desk.',
            ),
            backgroundColor: decision == 'APPROVE' ? const Color(0xFF059669) : const Color(0xFFE11D48),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVoting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showDisputeDialog() {
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text('Raise Milestone Dispute', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please describe the physical or structural defect observed on site or in the live walkthrough video. Escrow disbursement will be paused pending remediation.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Defect Description / Site Observation',
                  hintText: 'e.g. Ground slab cracks observed near perimeter wall...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _castVote('DISPUTE', comment: commentCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit Dispute', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final title = m['title'] ?? 'Construction Milestone';
    final engineerName = m['corenEngineerName'] ?? 'Certified Project Engineer';
    final corenNumber = m['corenLicenseNumber'] ?? 'COREN Registered';
    final videoUrl = m['walkthroughVideoUrl'] ?? '';
    final certUrl = m['corenCertificateUrl'] ?? '';
    final testReportUrl = m['testReportUrl'] ?? '';
    final trancheAmount = (m['trancheAmount'] as num?)?.toDouble() ?? 0;
    final userVoted = m['userVoted'] == true;
    final userDecision = m['userDecision'];
    final approvalsCount = m['approvalsCount'] ?? 0;
    final disputesCount = m['disputesCount'] ?? 0;

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
                        'Milestone Review & Release Vote',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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

            // 5-Day Countdown Timer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _remainingSeconds > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _remainingSeconds > 0 ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _remainingSeconds > 0 ? Icons.timer_outlined : Icons.check_circle_outline_rounded,
                    color: _remainingSeconds > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _remainingSeconds > 0 ? '5-Day Review & Self-Inspection Window' : 'Review Window Concluded',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _remainingSeconds > 0 ? const Color(0xFFB45309) : const Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRemainingTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _remainingSeconds > 0 ? const Color(0xFF78350F) : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. COREN Engineer Sign-off Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(engineerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('COREN Registration: $corenNumber', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('COREN CERTIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Video Walkthrough Viewer / Player Strip
            if (videoUrl.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('360° Live Geotagged Site Walkthrough', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text('Tap to stream live site inspection footage with GPS timestamp', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. Test Reports & Document Proofs
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science_outlined, size: 18, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Batching Plant Test', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              Text(testReportUrl.isNotEmpty ? 'Verified 28-Day C25' : 'Attached with Sign-off', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Interim Valuation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              Text(certUrl.isNotEmpty ? 'Stamped Cert' : 'Signed Valuation', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Tranche Details & Subscriber Consensus
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requested Escrow Tranche', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(CurrencyFormatter.format(trancheAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subscriber Consensus', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Row(
                        children: [
                          Text('👍 $approvalsCount Approvals', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                          if (disputesCount > 0) ...[
                            const SizedBox(width: 8),
                            Text('⚠️ $disputesCount Disputes', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFE11D48))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Optional Site Inspection / COREN Audit Trigger
            InkWell(
              onTap: () {
                InspectionBookingModal.show(
                  context,
                  projectId: widget.milestone['projectId'],
                  milestoneId: widget.milestone['id'],
                  title: widget.projectName,
                  location: 'Construction Site Location',
                  milestoneName: title,
                  trancheAmount: trancheAmount,
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.engineering_rounded, color: Color(0xFF059669), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Need on-site verification first?',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                          ),
                          Text(
                            'Book free Self-Visit (₦0) or Hire Independent COREN Engineer (₦25k)',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF047857), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF059669)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Voting Actions
            if (userVoted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: userDecision == 'APPROVE' ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: userDecision == 'APPROVE' ? const Color(0xFFA7F3D0) : const Color(0xFFFDA4AF),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      userDecision == 'APPROVE' ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: userDecision == 'APPROVE' ? const Color(0xFF059669) : const Color(0xFFE11D48),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userDecision == 'APPROVE' ? 'You have Approved this Tranche Release' : 'You have Flagged a Dispute on this Milestone',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: userDecision == 'APPROVE' ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isVoting ? null : _showDisputeDialog,
                      icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFE11D48)),
                      label: const Text('Raise Dispute', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w800, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFDA4AF)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isVoting ? null : () => _castVote('APPROVE'),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: _isVoting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Approve & Release', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
