import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class FloatingAiAssistant extends StatefulWidget {
  const FloatingAiAssistant({super.key});

  @override
  State<FloatingAiAssistant> createState() => _FloatingAiAssistantState();
}

class _FloatingAiAssistantState extends State<FloatingAiAssistant> with SingleTickerProviderStateMixin {
  Offset? _position;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _openAiChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Default position: bottom-right above navbar
    _position ??= Offset(screenWidth - 70, screenHeight - 160);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newX = (_position!.dx + details.delta.dx).clamp(10.0, screenWidth - 62.0);
            final newY = (_position!.dy + details.delta.dy).clamp(60.0, screenHeight - 130.0);
            _position = Offset(newX, newY);
          });
        },
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.5),
            child: InkWell(
              onTap: () => _openAiChat(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D5C3A), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.accentGoldLight, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'Hello! I am your HomeVerify AI Legal & Property Advisor powered by OpenRouter. Ask me anything about Nigerian land titles (C-of-O, Gazette, Governor Consent), beacon coordinates, milestone escrow, or live building costs.',
    },
  ];

  final List<String> _quickPrompts = [
    'What documents are needed to verify land in Lagos?',
    'How does Milestone Escrow protect my money?',
    'What is the difference between C-of-O & Gazette?',
    'What are the current cement & rebar prices?',
  ];

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMsg = text.trim();
    _msgCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': userMsg});
      _isTyping = true;
    });

    _scrollToBottom();

    String reply = '';

    try {
      final res = await ApiClient.post('/ai/chat', {
        'message': userMsg,
        'history': _messages.map((m) => {'role': m['role'], 'content': m['text']}).toList(),
      });

      if (res['success'] == true && res['reply'] != null) {
        reply = res['reply'] as String;
      }
    } catch (_) {
      // Offline / immediate heuristic fallback
      final lower = userMsg.toLowerCase();
      if (lower.contains('lagos') || lower.contains('document') || lower.contains('verify') || lower.contains('c of o') || lower.contains('c-of-o')) {
        reply = 'Key Title Documents Required for Lagos Land:\n\n1. Certificate of Occupancy (C-of-O) or Governor\'s Consent: Confirms state-recognized ownership title.\n2. Registered Survey Plan: Coordinates must be checked at the Surveyor General\'s Office (Alausa) to confirm land is NOT under government acquisition.\n3. Deed of Assignment: Establishes complete legal history.\n\nTip: You can submit your survey plan or C-of-O on the Verify tab for our legal team and surveyor AI to verify.';
      } else if (lower.contains('escrow') || lower.contains('milestone') || lower.contains('protect')) {
        reply = 'How HomeVerify Milestone Escrow Works:\n\n- Your funds are held securely in an escrow trust vault.\n- The developer does NOT receive money upfront.\n- Independent certified structural engineers audit each stage on-site.\n- Developer payouts are released only after milestone approval.';
      } else if (lower.contains('gazette') || lower.contains('difference') || lower.contains('excision')) {
        reply = 'C-of-O vs. Government Gazette:\n\n- Gazette / Excision: Official government publication confirming ancestral land has been released to the community.\n- C-of-O: Individual 99-year state grant.\n\nNotice: Land with only Gazette requires processing a Governor\'s Consent or C-of-O for absolute title perfection.';
      } else if (lower.contains('cost') || lower.contains('cement') || lower.contains('price') || lower.contains('rebar') || lower.contains('build')) {
        reply = 'Current Construction Benchmark:\n\n- 50kg Cement (Dangote/BUA): ₦8,400 - ₦8,700\n- 12mm TMT High-Yield Rebar: ~₦1,180,000 / ton\n- 30-Ton Clean Black Granite: ~₦285,000\n- 9-inch Solid Sandcrete Blocks: ₦780 - ₦850/unit\n\nCheck the Material Index feature on the home screen for live depot rates.';
      } else {
        reply = 'HomeVerify AI Advisory:\n\nRegarding: "$userMsg"\n\nIn Nigerian real estate transactions, strict title perfection and milestone controls are essential before committing funds. Always verify beacon coordinates at the state land bureau, confirm approved layout plans, and ensure all payments are locked in milestone escrow.\n\nWould you like our legal team to draft or review your contract of sale or survey plan?';
      }
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'assistant', 'text': reply});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'HomeVerify AI Legal Advisor',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Powered by OpenRouter • Nigerian Land Law & Escrow Expert',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text('AI is researching land registry guidelines...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                return ActionChip(
                  label: Text(_quickPrompts[idx], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.cardBorder),
                  onPressed: () => _sendMessage(_quickPrompts[idx]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask about C-of-O, escrow, land laws...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 22,
                  child: IconButton(
                    onPressed: () => _sendMessage(_msgCtrl.text),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}