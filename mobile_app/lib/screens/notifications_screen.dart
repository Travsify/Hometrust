import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/notification_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'wallet_screen.dart';
import 'purchases_screen.dart';
import 'verify_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final notifications = notifProvider.notifications;

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () async {
                await notifProvider.markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ All notifications marked as read!'),
                      backgroundColor: Color(0xFF059669),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Mark All Read',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF64748B), size: 22),
              tooltip: 'Clear All Notifications',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Clear All Notifications', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    content: const Text('Are you sure you want to clear and dismiss all notifications?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await notifProvider.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications cleared'), backgroundColor: Color(0xFF334155)),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : notifications.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => notifProvider.fetchNotifications(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return Dismissible(
                        key: ValueKey(notif.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              SizedBox(width: 8),
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          final dismissedId = notif.id;
                          notifProvider.dismissNotification(dismissedId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${notif.title}"'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF334155),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            notifProvider.markAsRead(notif.id);
                            final t = notif.type.toUpperCase();
                            if (t.contains('PAYMENT') || t.contains('ESCROW') || t.contains('WALLET') || t.contains('TRANSFER')) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                            } else if (t.contains('PURCHASE') || t.contains('MILESTONE') || t.contains('TRANCHE') || t.contains('INSTALMENT')) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
                            } else if (t.contains('VERIFICATION') || t.contains('DOCUMENT') || t.contains('LEGAL')) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF10B981).withValues(alpha: 0.4),
                                width: notif.isRead ? 1 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getIconBg(notif.type),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getIconData(notif.type), color: _getIconColor(notif.type), size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                                                fontSize: 14,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (!notif.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTime(notif.createdAt),
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                          ),
                                          const Row(
                                            children: [
                                              Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF94A3B8)),
                                              SizedBox(width: 3),
                                              Text('Tap to open · Slide to dismiss', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.notifications_none_rounded, color: Color(0xFF059669), size: 40),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are completely up to date! Milestone inspection updates, escrow payments, and title verification reports will appear right here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconBg(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
      case 'ESCROW':
        return const Color(0xFF10B981).withValues(alpha: 0.12);
      case 'VERIFICATION':
        return const Color(0xFF0284C7).withValues(alpha: 0.12);
      case 'MILESTONE':
        return const Color(0xFFEA580C).withValues(alpha: 0.12);
      default:
        return const Color(0xFF64748B).withValues(alpha: 0.12);
    }
  }

  Color _getIconColor(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
      case 'ESCROW':
        return const Color(0xFF059669);
      case 'VERIFICATION':
        return const Color(0xFF0284C7);
      case 'MILESTONE':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF475569);
    }
  }

  IconData _getIconData(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
      case 'ESCROW':
        return Icons.account_balance_wallet_rounded;
      case 'VERIFICATION':
        return Icons.verified_user_rounded;
      case 'MILESTONE':
        return Icons.foundation_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
