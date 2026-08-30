import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../widgets/in_app_call_modal.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class DevelopersScreen extends StatefulWidget {
  const DevelopersScreen({super.key});

  @override
  State<DevelopersScreen> createState() => _DevelopersScreenState();
}

class _DevelopersScreenState extends State<DevelopersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _developers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchDevelopers();
  }

  Future<void> _fetchDevelopers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/developers');
      final rawList = res is List ? res : (res is Map && res['developers'] is List ? res['developers'] : []);
      
      final List<Map<String, dynamic>> mapped = [];
      for (var item in rawList) {
        if (item is Map<String, dynamic>) {
          mapped.add({
            'id': item['id'] ?? '',
            'companyName': item['companyName'] ?? 'Developer',
            'cacNumber': item['cacNumber'] ?? '',
            'officeAddress': item['officeAddress'] ?? 'Corporate Office',
            'contactPerson': item['contactPerson'] ?? 'Official Representative',
            'phone': item['phone'] ?? '',
            'email': item['email'] ?? '',
            'isVerified': item['isVerified'] ?? false,
            'activeProjectsCount': item['_count'] != null && item['_count']['projects'] != null
                ? item['_count']['projects']
                : (item['projects'] != null && item['projects'] is List ? (item['projects'] as List).length : 0),
            'escrowProtected': true,
            'rating': 4.9,
          });
        }
      }
      if (mounted) {
        setState(() => _developers = mapped);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _developers = []);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDevelopers {
    if (_searchQuery.trim().isEmpty) return _developers;
    final q = _searchQuery.toLowerCase();
    return _developers.where((d) {
      final name = (d['companyName'] ?? '').toString().toLowerCase();
      final cac = (d['cacNumber'] ?? '').toString().toLowerCase();
      final addr = (d['officeAddress'] ?? '').toString().toLowerCase();
      return name.contains(q) || cac.contains(q) || addr.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Verified Developers',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            Text(
              'CAC Audited & Escrow Bound Developers',
              style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by developer name, CAC RC or address...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Trust Guarantee Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: const [
                Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All listed developers are CAC verified with mandatory milestone escrow audits. No direct external payments.',
                    style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // Developers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredDevelopers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.business_rounded, size: 48, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No matching verified developers found',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDevelopers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDevelopers.length,
                          itemBuilder: (context, index) {
                            final dev = _filteredDevelopers[index];
                            return _buildDeveloperCard(context, dev);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context, Map<String, dynamic> dev) {
    final companyName = dev['companyName'] ?? 'Developer';
    final cacNumber = dev['cacNumber'] ?? 'RC-Verified';
    final address = dev['officeAddress'] ?? 'Registered Commercial Office, Nigeria';
    final activeProjects = dev['activeProjectsCount'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      companyName.isNotEmpty ? companyName[0].toUpperCase() : 'D',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                                const SizedBox(width: 4),
                                Text(
                                  cacNumber,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$activeProjects Active Projects',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Registered Office Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // IN-APP ACTION BUTTONS (CALL IN-APP & CHAT IN-APP)
            Row(
              children: [
                // 1. Chat In-App
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (!auth.isAuthenticated) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            recipientName: companyName,
                            recipientRole: 'Verified Developer Representative',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Chat In-App',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Call In-App (Encrypted Relay - No Phone Numbers Displayed)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (!auth.isAuthenticated) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        return;
                      }
                      InAppCallModal.show(
                        context,
                        entityName: companyName,
                        entityRole: 'Verified Developer Representative',
                      );
                    },
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Call In-App',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
