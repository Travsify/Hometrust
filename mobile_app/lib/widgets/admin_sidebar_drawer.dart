import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_transactions_screen.dart';
import '../screens/admin_notifications_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/purchases_screen.dart';
import '../screens/developers_screen.dart';
import '../screens/build_for_me_screen.dart';
import '../screens/legal_request_screen.dart';
import '../screens/land_radar_screen.dart';
import '../screens/material_index_screen.dart';
import '../screens/real_estate_dictionary_screen.dart';
import '../screens/support_tickets_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/developer_profile_screen.dart';

class AdminSidebarDrawer extends StatelessWidget {
  const AdminSidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final String fullName = user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Administrator';
    final String role = user?.role ?? 'ADMIN';
    final String email = user?.email ?? 'admin@hometrustng.com';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                          SizedBox(width: 5),
                          Text('LIVE GATEWAY', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  fullName.isNotEmpty ? fullName : 'Hometrust Administrator',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ROLE: $role',
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionHeader('PLATFORM MONITORING'),
                _buildDrawerItem(
                  context,
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Live Transactions',
                  subtitle: 'Ongoing deposits, payouts & debits',
                  badge: 'LIVE',
                  badgeColor: const Color(0xFF059669),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTransactionsScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Dispatched Notifications',
                  subtitle: 'Email, push & in-app logs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: 'Escrow Wallet Ledger',
                  subtitle: 'Virtual account & transaction ledger',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Purchases & Contracts',
                  subtitle: 'Contracts of sale & payment ledgers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
                  },
                ),

                const Divider(height: 24, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                _buildSectionHeader('OPERATIONS & GOVERNANCE'),
                _buildDrawerItem(
                  context,
                  icon: Icons.domain_rounded,
                  iconColor: const Color(0xFF475569),
                  title: 'Developers Directory',
                  subtitle: 'Verified corporate developers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DevelopersScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.construction_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Charter-A-Builder',
                  subtitle: 'Custom structural project requests',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildForMeScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.gavel_rounded,
                  iconColor: const Color(0xFF9333EA),
                  title: 'Legal Search & Title Verification',
                  subtitle: 'Ministry of lands title searches',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalRequestScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.radar_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Land Radar AI',
                  subtitle: 'Topography & gazette zoning radar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LandRadarScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF0D9488),
                  title: 'Building Materials Index',
                  subtitle: 'Real-time Nigerian market prices',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialIndexScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Real Estate Dictionary',
                  subtitle: 'Nigerian land title terms & glossary',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RealEstateDictionaryScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Support Tickets & Helpdesk',
                  subtitle: 'User inquiries and resolution',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen()));
                  },
                ),

                const Divider(height: 24, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                _buildSectionHeader('ACCOUNT & SETTINGS'),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_rounded,
                  iconColor: AppColors.primary,
                  title: 'My Profile & Security',
                  subtitle: '2FA, Biometrics & Virtual NUBAN',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => user?.role == 'DEVELOPER' ? const DeveloperProfileScreen() : const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer info
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hometrust v2.4.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    Text('Bank-Grade Security', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    auth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: const Text('Log Out', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: badgeColor ?? AppColors.primary),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }
}
