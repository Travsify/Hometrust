import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'legal_request_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account & Security',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.isAuthenticated ? user?.firstName[0] ?? 'U' : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isAuthenticated ? user?.fullName ?? 'Valued Customer' : 'Guest User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.isAuthenticated ? user?.email ?? '' : 'Sign in to access your vault',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (auth.isAuthenticated) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ROLE: ${user?.role}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.emeraldText),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Menu Items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.gavel_rounded,
                    title: 'Request Legal Document Preparation',
                    subtitle: 'Deeds, Contracts of Sale, Tenancy & Leases',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LegalRequestScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'KYC & Identity Verification',
                    subtitle: 'NIN & BVN verification badge',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.folder_shared_outlined,
                    title: 'Document Vault',
                    subtitle: 'All title deeds, C of O, and payment receipts',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Contact EstateVerify Support',
                    subtitle: 'support@estateverify.ng',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (auth.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout, color: AppColors.roseText, size: 18),
                  label: const Text('Log Out', style: TextStyle(color: AppColors.roseText, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.roseText),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign In / Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
    );
  }
}
