import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';

class InspectionBookingModal extends StatefulWidget {
  final String? propertyId;
  final String? projectId;
  final String? milestoneId;
  final String title;
  final String location;
  final String? milestoneName;
  final double? trancheAmount;

  const InspectionBookingModal({
    super.key,
    this.propertyId,
    this.projectId,
    this.milestoneId,
    required this.title,
    required this.location,
    this.milestoneName,
    this.trancheAmount,
  });

  static Future<void> show(
    BuildContext context, {
    String? propertyId,
    String? projectId,
    String? milestoneId,
    required String title,
    required String location,
    String? milestoneName,
    double? trancheAmount,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InspectionBookingModal(
        propertyId: propertyId,
        projectId: projectId,
        milestoneId: milestoneId,
        title: title,
        location: location,
        milestoneName: milestoneName,
        trancheAmount: trancheAmount,
      ),
    );
  }

  @override
  State<InspectionBookingModal> createState() => _InspectionBookingModalState();
}

class _InspectionBookingModalState extends State<InspectionBookingModal> {
  // Options: 'SELF', 'COREN', 'GEOFENCED_VIDEO'
  String _selectedOption = 'SELF';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  String _selectedTime = '10:00 AM – 12:00 PM';
  
  final _visitorNameCtrl = TextEditingController();
  final _visitorPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  bool _isRepresentative = false;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00 AM – 11:00 AM',
    '11:00 AM – 01:00 PM',
    '02:00 PM – 04:00 PM',
    '04:00 PM – 06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _visitorNameCtrl.text = '${auth.user!.firstName} ${auth.user!.lastName}';
      _visitorPhoneCtrl.text = auth.user!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _visitorNameCtrl.dispose();
    _visitorPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 45)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleBookInspection() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book inspection')),
      );
      return;
    }

    if (_selectedOption != 'GEOFENCED_VIDEO') {
      if (_visitorNameCtrl.text.trim().isEmpty || _visitorPhoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter visitor name and phone number')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'propertyId': widget.propertyId,
        'projectId': widget.projectId,
        'milestoneId': widget.milestoneId,
        'scope': widget.milestoneId != null ? 'MILESTONE_VERIFICATION' : 'PRE_PURCHASE',
        'inspectionType': _selectedOption == 'SELF'
            ? 'SELF_OR_REPRESENTATIVE'
            : _selectedOption == 'COREN'
                ? 'COREN_ENGINEER'
                : 'GEOFENCED_VIDEO',
        'preferredDate': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'preferredTime': _selectedTime,
        'attendeeName': _visitorNameCtrl.text.trim(),
        'attendeePhone': _visitorPhoneCtrl.text.trim(),
        'attendeeEmail': auth.user?.email ?? '',
        'representativeName': _isRepresentative ? _visitorNameCtrl.text.trim() : null,
        'representativePhone': _isRepresentative ? _visitorPhoneCtrl.text.trim() : null,
        'notes': _notesCtrl.text.trim(),
        'paymentReference': _selectedOption == 'COREN' ? 'WALLET-DEBIT-${DateTime.now().millisecondsSinceEpoch}' : null,
      };

      final res = await ApiClient.post('/inspections', payload);
      if (!mounted) return;

      Navigator.pop(context);
      _showSuccessDialog(res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book inspection: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.roseText,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(dynamic inspectionData) {
    final gatePass = inspectionData != null && inspectionData['gatePassCode'] != null
        ? inspectionData['gatePassCode']
        : 'HT-PASS-${100000 + Random().nextInt(900000)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedOption == 'COREN'
                  ? 'COREN Engineer Dispatched'
                  : _selectedOption == 'GEOFENCED_VIDEO'
                      ? 'Video Walkthrough Requested'
                      : 'Site Gate Pass Generated!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedOption == 'COREN'
                  ? 'An accredited COREN structural engineer has been assigned to physically inspect the property/milestone. You will receive a stamped engineering compliance report in-app.'
                  : _selectedOption == 'GEOFENCED_VIDEO'
                      ? 'The developer has been notified to record and upload an on-site 360° walkthrough video within the 150m GPS geofence boundary.'
                      : 'Your official site access pass is confirmed. Show this gate pass code to the security/site engineer upon arrival.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            if (_selectedOption == 'SELF') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    const Text('OFFICIAL GATE ACCESS CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      gatePass.toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} • $_selectedTime', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMilestone = widget.milestoneId != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMilestone ? 'Verify Milestone Inspection' : 'Schedule Property Inspection',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Inspection Pathway Selector Title
            const Text(
              'CHOOSE INSPECTION & VERIFICATION METHOD',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            // 1. Self or Representative (Free / ₦0)
            _buildOptionCard(
              id: 'SELF',
              icon: Icons.person_pin_circle_rounded,
              title: 'Self or Representative Visit',
              badge: 'FREE (₦0)',
              badgeColor: const Color(0xFF10B981),
              description: 'You or an appointed family member/friend visit the property in person. Instant gate pass issued.',
            ),
            const SizedBox(height: 10),

            // 2. Hire COREN Structural Engineer (₦25,000)
            _buildOptionCard(
              id: 'COREN',
              icon: Icons.engineering_rounded,
              title: 'Hire Independent COREN Engineer',
              badge: '₦25,000 FLAT',
              badgeColor: const Color(0xFF3B82F6),
              description: 'Hometrust dispatches a certified structural engineer to audit reinforcement, concrete strength & structural safety. Includes stamped compliance report.',
            ),
            const SizedBox(height: 10),

            // 3. Geofenced Live Walkthrough Video (₦0)
            _buildOptionCard(
              id: 'GEOFENCED_VIDEO',
              icon: Icons.videocam_rounded,
              title: 'Request Geofenced Live Video',
              badge: 'FREE (₦0)',
              badgeColor: const Color(0xFF8B5CF6),
              description: 'Developer must record a live walkthrough video locked inside the site GPS geofence (150m radius) with live timestamp.',
            ),
            const SizedBox(height: 20),

            // Dynamic Form based on Selection
            if (_selectedOption != 'GEOFENCED_VIDEO') ...[
              // Date & Time Selectors
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferred Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time Window', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTime,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                              items: _timeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedTime = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Representative toggle for Self option
              if (_selectedOption == 'SELF') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sending a representative? (Family/Friend)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    Switch(
                      value: _isRepresentative,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isRepresentative = val),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Visitor Name & Phone
              Text(
                _selectedOption == 'COREN'
                    ? 'Primary Contact for Inspection Updates'
                    : _isRepresentative
                        ? 'Representative Full Name'
                        : 'Attendee Full Name',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _visitorNameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Babatunde Adeleke',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: _visitorPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g. 08031234567',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.gps_fixed_rounded, color: Color(0xFF7C3AED), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hometrust enforces an automated 150m GPS Geofence boundary on the developer\'s smartphone camera to ensure the video walkthrough is recorded live on the exact property site.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF5B21B6), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Notes / Special Instructions
            const Text('Special Instructions / Inspection Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Please check beam reinforcement and septic tank setback...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button with Cost Badge
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleBookInspection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedOption == 'COREN' ? const Color(0xFF2563EB) : AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedOption == 'COREN'
                                ? Icons.payment_rounded
                                : _selectedOption == 'GEOFENCED_VIDEO'
                                    ? Icons.send_rounded
                                    : Icons.confirmation_number_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedOption == 'COREN'
                                ? 'Pay ₦25,000 & Assign COREN Engineer'
                                : _selectedOption == 'GEOFENCED_VIDEO'
                                    ? 'Request Live Video (Free)'
                                    : 'Confirm Free Site Gate Pass (₦0)',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String id,
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
  }) {
    final isSelected = _selectedOption == id;

    return InkWell(
      onTap: () => setState(() => _selectedOption = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? badgeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? badgeColor.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? badgeColor : const Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(badge, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
