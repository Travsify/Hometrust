import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'chat_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/support/tickets');
      if (res != null && res['data'] is List) {
        setState(() {
          _tickets = res['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateTicketModal() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedPriority = 'URGENT';
    String selectedCategory = 'PAYMENT_ESCROW';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text('Open Support Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Text(
                  'Select ticket priority and describe your issue. Our support team responds directly in-app.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // 1. PRIORITY SELECTOR (URGENT / HIGH / MEDIUM / LOW)
                const Text('PRIORITY LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityOption(
                      'URGENT',
                      'Urgent',
                      Icons.warning_amber_rounded,
                      const Color(0xFFEF4444),
                      selectedPriority,
                      (p) => setModalState(() => selectedPriority = p),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityOption(
                      'HIGH',
                      'High',
                      Icons.priority_high_rounded,
                      const Color(0xFFF59E0B),
                      selectedPriority,
                      (p) => setModalState(() => selectedPriority = p),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityOption(
                      'MEDIUM',
                      'Medium',
                      Icons.info_outline_rounded,
                      const Color(0xFF3B82F6),
                      selectedPriority,
                      (p) => setModalState(() => selectedPriority = p),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityOption(
                      'LOW',
                      'Low',
                      Icons.low_priority_rounded,
                      const Color(0xFF64748B),
                      selectedPriority,
                      (p) => setModalState(() => selectedPriority = p),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. CATEGORY SELECTOR
                const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 'PAYMENT_ESCROW', child: Text('💰 Payment & Escrow Wallet')),
                        DropdownMenuItem(value: 'BUILD_FOR_ME', child: Text('🏗️ Charter-A-Builder / Build-For-Me')),
                        DropdownMenuItem(value: 'VERIFICATION', child: Text('🛡️ Title Deed & KYC Verification')),
                        DropdownMenuItem(value: 'ACCOUNT_KYC', child: Text('👤 Profile & Virtual NUBAN Account')),
                        DropdownMenuItem(value: 'TECHNICAL', child: Text('⚙️ App & Technical Issue')),
                        DropdownMenuItem(value: 'GENERAL', child: Text('❓ General Inquiry')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. SUBJECT
                const Text('SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Deposit not credited or Project inquiry',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. MESSAGE DESCRIPTION
                const Text('DETAILED DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: messageCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide details, transaction references, or project codes to help us resolve your request quickly.',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 20),

                // SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(isSubmitting ? 'Submitting Ticket...' : 'Submit Support Ticket', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter both a subject and message description.')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await ApiClient.post('/support/tickets', {
                                'subject': subjectCtrl.text.trim(),
                                'category': selectedCategory,
                                'message': messageCtrl.text.trim(),
                                'priority': selectedPriority,
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                _fetchTickets();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('Support ticket opened! Admin has been notified.')),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF059669),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(
    String value,
    String label,
    IconData icon,
    Color color,
    String selectedValue,
    Function(String) onSelect,
  ) {
    final bool isSelected = value == selectedValue;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 16),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    final String subject = ticket['subject'] ?? 'Support Ticket';
    final String message = ticket['message'] ?? '';
    final String category = ticket['category'] ?? 'GENERAL';
    final String priority = (ticket['priority'] ?? 'NORMAL').toString().toUpperCase();
    final String status = (ticket['status'] ?? 'OPEN').toString().toUpperCase();
    final String adminReply = ticket['adminReply'] ?? '';
    final String dateStr = ticket['createdAt'] != null
        ? DateTime.parse(ticket['createdAt']).toLocal().toString().substring(0, 16)
        : '';
    final String replyDateStr = ticket['repliedAt'] != null
        ? DateTime.parse(ticket['repliedAt']).toLocal().toString().substring(0, 16)
        : '';

    Color priorityColor = const Color(0xFF64748B);
    if (priority == 'URGENT') priorityColor = const Color(0xFFEF4444);
    if (priority == 'HIGH') priorityColor = const Color(0xFFF59E0B);
    if (priority == 'MEDIUM') priorityColor = const Color(0xFF3B82F6);

    Color statusColor = const Color(0xFF3B82F6);
    if (status == 'RESOLVED' || status == 'CLOSED') statusColor = const Color(0xFF059669);
    if (status == 'IN_PROGRESS') statusColor = const Color(0xFFF59E0B);

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),

              // Badges: Priority + Status + Category
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: priorityColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 16),

              // User's Message
              const Text('YOUR MESSAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Reply Section
              const Text('ADMIN RESPONSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              if (adminReply.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.support_agent_rounded, color: Color(0xFF059669), size: 16),
                              SizedBox(width: 6),
                              Text('Hometrust Support Officer', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                            ],
                          ),
                          if (replyDateStr.isNotEmpty)
                            Text(replyDateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF059669))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adminReply,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF064E3B), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A support agent has received your ticket and is investigating. You will receive an instant notification when replied.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── CHAT WITH ADMIN BUTTON ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final String ticketCode = ticket['ticketNumber'] ?? (ticket['id'] != null ? ticket['id'].toString().substring(0, 8).toUpperCase() : 'TICKET');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          recipientName: 'Hometrust Support & Escrow Admin',
                          propertyTitle: 'Support Ticket #$ticketCode: $subject',
                          isSupport: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat Live with Admin on this Ticket', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = _tickets.where((t) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'URGENT') return (t['priority'] ?? '').toString().toUpperCase() == 'URGENT';
      if (_selectedFilter == 'OPEN') return (t['status'] ?? '').toString().toUpperCase() == 'OPEN' || (t['status'] ?? '').toString().toUpperCase() == 'IN_PROGRESS';
      if (_selectedFilter == 'RESOLVED') return (t['status'] ?? '').toString().toUpperCase() == 'RESOLVED' || (t['status'] ?? '').toString().toUpperCase() == 'CLOSED';
      return true;
    }).toList();

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Support Tickets',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchTickets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Open Ticket', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _showCreateTicketModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchTickets,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D5C3A), Color(0xFF083C25)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hometrust Helpdesk', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                                SizedBox(height: 2),
                                Text(
                                  'State Urgent, High, or Medium priority to get immediate attention from dedicated officers.',
                                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All Tickets (${_tickets.length})'),
                          _buildFilterChip('URGENT', '🔴 Urgent Priority'),
                          _buildFilterChip('OPEN', '⏳ Pending/Active'),
                          _buildFilterChip('RESOLVED', '✅ Resolved'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tickets List
                    if (filteredTickets.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No support tickets found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              const Text('Tap "Open Ticket" below to submit an inquiry or report an issue.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...filteredTickets.map((t) {
                        final priority = (t['priority'] ?? 'NORMAL').toString().toUpperCase();
                        final status = (t['status'] ?? 'OPEN').toString().toUpperCase();
                        final subject = t['subject'] ?? 'Support Ticket';
                        final message = t['message'] ?? '';
                        final hasReply = (t['adminReply'] ?? '').toString().isNotEmpty;

                        Color pColor = const Color(0xFF64748B);
                        if (priority == 'URGENT') pColor = const Color(0xFFEF4444);
                        if (priority == 'HIGH') pColor = const Color(0xFFF59E0B);
                        if (priority == 'MEDIUM') pColor = const Color(0xFF3B82F6);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _showTicketDetails(t),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
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
                                          color: pColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: pColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          priority,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: pColor),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: status == 'RESOLVED' || status == 'CLOSED'
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: status == 'RESOLVED' || status == 'CLOSED'
                                                ? const Color(0xFF059669)
                                                : const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    subject,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                                  ),
                                  if (hasReply) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.reply_rounded, color: Color(0xFF059669), size: 14),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text('Admin has replied to this ticket. Tap to read.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                                          ),
                                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF059669)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 60),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF475569))),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0))),
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = value);
        },
      ),
    );
  }
}
