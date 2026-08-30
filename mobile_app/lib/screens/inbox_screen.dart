import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _listenToIncomingMessages();
  }

  void _listenToIncomingMessages() {
    _msgSub = SocketService.instance.onMessageReceived.listen((_) {
      _fetchConversations(silent: true);
    });
  }

  Future<void> _fetchConversations({bool silent = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    if (!silent) setState(() => _loading = true);

    try {
      final res = await ApiClient.get('/chat/my-conversations');
      if (mounted && res != null && res is List) {
        setState(() {
          _conversations = res;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Messages & Chats',
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
            onPressed: () => _fetchConversations(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchConversations(),
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
            : _conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Messages Yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'When you chat with verified developers or project team experts regarding properties or building requests, all your conversations appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatScreen(
                                    isSupport: true,
                                    recipientName: 'Hometrust Support & Developer Desk',
                                    recipientRole: 'Concierge Support',
                                  ),
                                ),
                              );
                              _fetchConversations();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_comment_rounded, size: 16),
                            label: const Text('Start New Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = _conversations[index];
                      final peerName = c['peerName'] ?? 'Hometrust Support';
                      final peerRole = c['peerRole'] ?? 'Support';
                      final isOnline = c['isPeerOnline'] == true;
                      final unreadCount = c['unreadCount'] ?? 0;
                      final lastMsg = c['lastMessage']?['content'] ?? 'Tap to chat';
                      final timeStr = c['lastMessageAt'] != null
                          ? DateTime.tryParse(c['lastMessageAt'])?.toLocal().toString().substring(11, 16) ?? ''
                          : '';

                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: c['id'],
                                recipientId: c['peerId'],
                                recipientName: peerName,
                                recipientRole: peerRole,
                                propertyId: c['propertyId'],
                                projectId: c['projectId'],
                              ),
                            ),
                          );
                          _fetchConversations(silent: true);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                              width: unreadCount > 0 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F172A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        peerName.isNotEmpty ? peerName[0].toUpperCase() : 'H',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            peerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            peerRole,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMsg,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w500,
                                        color: unreadCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
