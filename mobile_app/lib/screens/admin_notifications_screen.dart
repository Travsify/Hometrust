import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../widgets/persistent_bottom_nav.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _notifications = [];
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/banking/all-notifications?limit=200');
      if (res != null && res is List) {
        setState(() {
          _notifications = res;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredNotifications {
    return _notifications.where((n) {
      final type = n['type']?.toString().toUpperCase() ?? '';
      final title = n['title']?.toString().toLowerCase() ?? '';
      final message = n['message']?.toString().toLowerCase() ?? '';
      final user = n['user'];
      final userEmail = user?['email']?.toString().toLowerCase() ?? '';
      final userName = '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.toLowerCase();

      if (_selectedFilter != 'ALL' && type != _selectedFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return title.contains(q) || message.contains(q) || userEmail.contains(q) || userName.contains(q);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dispatched Notifications Log', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchNotifications,
            tooltip: 'Refresh Notifications',
          ),
        ],
      ),
      bottomNavigationBar: const PersistentBottomNav(),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search title, content, user, or email...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Filter Chips
          Container(
            color: Colors.white,
            height: 44,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('ALL', 'All (${_notifications.length})'),
                _buildFilterChip('PAYMENT', 'Payments & Escrow'),
                _buildFilterChip('VERIFICATION', 'KYC & Verifications'),
                _buildFilterChip('LEGAL', 'Legal Requests'),
                _buildFilterChip('SECURITY', 'Security & Logins'),
                _buildFilterChip('SYSTEM', 'System Alerts'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchNotifications, child: const Text('Try Again')),
                          ],
                        ),
                      )
                    : list.isEmpty
                        ? const Center(
                            child: Text('No dispatched notifications found', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchNotifications,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final n = list[i];
                                final title = n['title'] ?? 'Notification';
                                final message = n['message'] ?? '';
                                final type = n['type'] ?? 'GENERAL';
                                final user = n['user'];
                                final userName = user != null
                                    ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
                                    : 'User';
                                final userEmail = user?['email'] ?? '';
                                DateTime? dt;
                                if (n['createdAt'] != null) {
                                  dt = DateTime.tryParse(n['createdAt']);
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                _buildTypeIcon(type),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              type,
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        message,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$userName ${userEmail.isNotEmpty ? '($userEmail)' : ''}',
                                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                          if (dt != null)
                                            Text(
                                              DateFormat('dd MMM, hh:mm a').format(dt),
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _buildChannelTag(Icons.email_outlined, 'Email (Resend)'),
                                          const SizedBox(width: 6),
                                          _buildChannelTag(Icons.notifications_active_outlined, 'In-App Toast'),
                                          const SizedBox(width: 6),
                                          _buildChannelTag(Icons.phone_android_rounded, 'Push Notification'),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF059669)),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon = Icons.notifications_rounded;
    Color color = AppColors.primary;

    if (type.contains('PAYMENT') || type.contains('ESCROW')) {
      icon = Icons.account_balance_wallet_rounded;
      color = const Color(0xFF059669);
    } else if (type.contains('SECURITY')) {
      icon = Icons.security_rounded;
      color = const Color(0xFFDC2626);
    } else if (type.contains('VERIFICATION')) {
      icon = Icons.verified_user_rounded;
      color = const Color(0xFF2563EB);
    } else if (type.contains('LEGAL')) {
      icon = Icons.gavel_rounded;
      color = const Color(0xFF7C3AED);
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF334155))),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = value);
        },
      ),
    );
  }
}
