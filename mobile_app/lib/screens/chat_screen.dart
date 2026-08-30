import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../providers/auth_provider.dart';
import 'active_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? recipientId;
  final String? developerId;
  final String recipientName;
  final String recipientRole;
  final String? propertyTitle;
  final String? propertyId;
  final String? projectId;
  final bool isSupport;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.recipientId,
    this.developerId,
    required this.recipientName,
    this.recipientRole = 'Verified Developer',
    this.propertyTitle,
    this.propertyId,
    this.projectId,
    this.isSupport = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String? _activeConvId;
  String? _activePeerId;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _isPeerTyping = false;
  Timer? _typingTimer;

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversationId;
    _activePeerId = widget.recipientId;
    _initChat();
  }

  Future<void> _initChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    // 1. Ensure Socket.io is connected
    await SocketService.instance.connect(
      userId: auth.user?.id,
      userName: auth.user?.fullName,
    );

    // 2. Resolve Conversation ID if not passed
    if (_activeConvId == null) {
      setState(() => _loading = true);
      try {
        if (widget.isSupport) {
          final res = await ApiClient.post('/chat/start/support', {});
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
          }
        } else if (widget.developerId != null) {
          final res = await ApiClient.post('/chat/start/developer', {
            'developerId': widget.developerId,
            'propertyId': widget.propertyId,
            'projectId': widget.projectId,
          });
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
          }
        } else if (widget.recipientId != null) {
          final res = await ApiClient.post('/chat/conversation', {
            'recipientId': widget.recipientId,
            'propertyId': widget.propertyId,
            'projectId': widget.projectId,
          });
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
          }
        } else {
          final res = await ApiClient.post('/chat/start/support', {});
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
          }
        }
      } catch (e) {
        debugPrint('Error starting conversation: $e');
      }
    }

    // 3. Join Socket Room & Fetch Message History
    if (_activeConvId != null) {
      SocketService.instance.joinConversation(_activeConvId!);
      await _fetchMessages();
    } else {
      if (mounted) setState(() => _loading = false);
    }

    // 4. Listen to Real-Time Incoming Messages from Real Humans
    _msgSub = SocketService.instance.onMessageReceived.listen((msg) {
      if (msg['conversationId'] == _activeConvId) {
        final currentUserId = auth.user?.id;
        final bool isMe = msg['senderId'] == currentUserId;

        if (mounted) {
          setState(() {
            // Check if already in list to avoid duplicates
            final exists = _messages.any((m) => m['id'] == msg['id']);
            if (!exists) {
              _messages.add({
                'id': msg['id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                'isMe': isMe,
                'senderName': msg['senderName'] ?? widget.recipientName,
                'content': msg['content'] ?? '',
                'createdAt': msg['createdAt'] ?? DateTime.now().toIso8601String(),
                'attachmentUrl': msg['attachmentUrl'],
                'attachmentType': msg['attachmentType'],
              });
            }
          });
          _scrollToBottom();

          // Acknowledge read receipt
          if (!isMe) {
            SocketService.instance.markAsRead(_activeConvId!, messageId: msg['id']);
          }
        }
      }
    });

    // 5. Listen to Typing Indicator
    _typingSub = SocketService.instance.onUserTyping.listen((data) {
      if (data['conversationId'] == _activeConvId) {
        if (mounted) {
          setState(() => _isPeerTyping = data['isTyping'] == true);
          if (_isPeerTyping) {
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _isPeerTyping = false);
            });
          }
        }
      }
    });
  }

  Future<void> _fetchMessages() async {
    if (_activeConvId == null) return;
    try {
      final res = await ApiClient.get('/chat/conversations/$_activeConvId/messages');
      if (mounted && res != null && res is List) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = text.trim();
    _msgCtrl.clear();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id ?? '';
    final currentUserName = auth.user?.fullName ?? 'Me';

    // Optimistic local update
    final tempMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'isMe': true,
      'senderName': currentUserName,
      'content': msg,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    // Ensure conversation exists before sending
    if (_activeConvId == null) {
      try {
        if (widget.isSupport) {
          final res = await ApiClient.post('/chat/start/support', {'message': msg});
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
            SocketService.instance.joinConversation(_activeConvId!);
            _fetchMessages();
            return;
          }
        } else if (widget.developerId != null) {
          final res = await ApiClient.post('/chat/start/developer', {
            'developerId': widget.developerId,
            'propertyId': widget.propertyId,
            'projectId': widget.projectId,
            'message': msg,
          });
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
            SocketService.instance.joinConversation(_activeConvId!);
            _fetchMessages();
            return;
          }
        } else if (widget.recipientId != null) {
          final res = await ApiClient.post('/chat/conversation', {
            'recipientId': widget.recipientId,
            'propertyId': widget.propertyId,
            'projectId': widget.projectId,
          });
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
            SocketService.instance.joinConversation(_activeConvId!);
          }
        } else {
          final res = await ApiClient.post('/chat/start/support', {'message': msg});
          if (res != null && res['id'] != null) {
            _activeConvId = res['id'];
            SocketService.instance.joinConversation(_activeConvId!);
            _fetchMessages();
            return;
          }
        }
      } catch (e) {
        debugPrint('Error creating conversation on send: $e');
      }
    }

    // 1. Emit via Socket.io
    if (_activeConvId != null) {
      SocketService.instance.sendMessage(
        conversationId: _activeConvId!,
        recipientId: _activePeerId,
        content: msg,
      );

      // 2. Persist via REST API
      try {
        await ApiClient.post('/chat/conversations/$_activeConvId/messages', {
          'content': msg,
        });
      } catch (err) {
        debugPrint('Failed to persist message via REST: $err');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startInAppCall() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final callerName = auth.user?.fullName ?? 'Hometrust User';
    final callerRole = auth.user?.role == 'DEVELOPER' ? 'Verified Developer' : 'Verified Buyer';
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final targetPeerId = _activePeerId ?? widget.recipientId ?? widget.developerId ?? 'peer';

    // Emit live call initiation to signaling server
    SocketService.instance.initiateCall(
      callId: callId,
      recipientId: targetPeerId,
      callerName: callerName,
      callerRole: callerRole,
      propertyTitle: widget.propertyTitle,
    );

    // Push Active Call Screen in Outgoing Call State
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveCallScreen(
          callId: callId,
          peerId: targetPeerId,
          peerName: widget.recipientName,
          peerRole: widget.recipientRole,
          propertyTitle: widget.propertyTitle,
          isIncoming: false,
          initiallyConnected: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_activeConvId != null) {
      SocketService.instance.leaveConversation(_activeConvId!);
    }
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : 'H',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.recipientName,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 14),
                    ],
                  ),
                  Text(
                    _isPeerTyping ? 'typing...' : 'Online • Human Representative',
                    style: TextStyle(
                      fontSize: 10,
                      color: _isPeerTyping ? AppColors.primary : const Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // IN-APP ENCRYPTED CALL BUTTON
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF059669), size: 18),
            ),
            tooltip: 'Live In-App Call',
            onPressed: _startInAppCall,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Anti-Fraud Security Notice Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anti-Fraud Warning: NEVER transfer funds directly outside Hometrust. All milestone payments must be made to your dedicated escrow account.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          if (widget.propertyTitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  const Icon(Icons.home_work_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Inquiry Property: ${widget.propertyTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_rounded, color: Color(0xFF059669), size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Direct Chat with ${widget.recipientName}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Send a message below to connect with their corporate representative in real-time.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['isMe'] == true;
                          final content = msg['content']?.toString() ?? '';
                          final timeStr = msg['createdAt'] != null
                              ? DateTime.tryParse(msg['createdAt'])?.toLocal().toString().substring(11, 16) ?? ''
                              : '';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    content,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isMe ? Colors.white : const Color(0xFF0F172A),
                                      height: 1.4,
                                      fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Message Input Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                      onChanged: (val) {
                        if (_activeConvId != null) {
                          SocketService.instance.sendTyping(_activeConvId!, val.isNotEmpty);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Type your message to ${widget.recipientName}...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_msgCtrl.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
