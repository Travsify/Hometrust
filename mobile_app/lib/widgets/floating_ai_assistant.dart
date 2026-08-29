import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class FloatingAiAssistant extends StatefulWidget {
  const FloatingAiAssistant({super.key});

  @override
  State<FloatingAiAssistant> createState() => _FloatingAiAssistantState();
}

class _FloatingAiAssistantState extends State<FloatingAiAssistant> {
  Offset? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position == null) {
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 68, size.height - 180);
    }
  }

  void _openAiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pos = _position ?? Offset(screenSize.width - 68, screenSize.height - 180);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newX = (pos.dx + details.delta.dx).clamp(10.0, screenSize.width - 62.0);
            final newY = (pos.dy + details.delta.dy).clamp(60.0, screenSize.height - 130.0);
            _position = Offset(newX, newY);
          });
        },
        onTap: () => _openAiSheet(context),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.accentGoldLight, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.accentGold.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.accentGoldLight,
                size: 26,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
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
      'text': 'Hello! 👋 I am your Hometrust AI Legal & Property Advisor for Nigerian real estate. Ask me anything about verifying land titles (C-of-O, Gazette, Governor\'s Consent), scanning GPS beacon coordinates across 36 states, milestone escrow protection, or live construction costs.',
    },
  ];

  final List<String> _quickPrompts = [
    'What documents are needed to verify land in Lagos?',
    'How does Milestone Escrow protect my money?',
    'What is the difference between C-of-O & Gazette?',
    'What are current cement and rebar prices?',
  ];

  String _generateConversationalResponse(String userMsg) {
    final lower = userMsg.toLowerCase().trim();

    // 1. GREETINGS & CASUAL INTRODUCTIONS
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'good morning' ||
        lower == 'good afternoon' ||
        lower == 'good evening' ||
        lower == 'howdy' ||
        lower == 'sup' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ')) {
      return 'Hello there! 👋 Welcome to Hometrust.\n\n'
          'I am your AI Property & Legal Advisor. How can I assist you with your Nigerian property transaction today?\n\n'
          'Here are a few things I can help you with:\n'
          '• 🛡️ Verify C-of-O, Gazette, Governor\'s Consent, or Survey Plans\n'
          '• 📡 Scan beacon coordinates for government acquisition risk\n'
          '• 🔒 Explain how our Milestone Escrow protects your payments\n'
          '• 📊 Check live cement, rebar, and building material prices\n'
          '• 📝 Request legal document preparation (Deed of Assignment / POA)';
    }

    // 2. WHO ARE YOU / WHAT CAN YOU DO
    if (lower.contains('who are you') || lower.contains('what can you do') || lower.contains('help me')) {
      return 'I am the Hometrust AI Legal & Real Estate Advisor for Nigeria.\n\n'
          'My purpose is to protect property buyers, investors, and developers from real estate fraud, double-allocation, and contractor abandonment.\n\n'
          'Feel free to ask any question about property titles, Nigerian land laws, escrow milestones, or building material costs!';
    }

    // 3. TITLE DOCUMENTS & VERIFICATION
    if (lower.contains('lagos') ||
        lower.contains('document') ||
        lower.contains('verify') ||
        lower.contains('c of o') ||
        lower.contains('c-of-o') ||
        lower.contains('title') ||
        lower.contains('survey')) {
      return 'Key Title Documents Required for Land Verification in Nigeria:\n\n'
          '1. Certificate of Occupancy (C-of-O) or Governor\'s Consent: Official state-recognized ownership title.\n'
          '2. Registered Survey Plan: Beacon coordinates must be lodged and verified at the State Surveyor General\'s Office (e.g. Alausa or AGIS) to confirm land is NOT under committed government acquisition or road alignment.\n'
          '3. Deed of Assignment: Legal instrument transferring ownership from the root vendor to the buyer with complete root of title.\n'
          '4. Contract of Sale: Outlines purchase terms, escrow milestones, and possession covenants.\n\n'
          'Tip: You can submit your survey plan or C-of-O directly on the Verify tab for our certified legal and surveying team to audit.';
    }

    // 4. ESCROW & PAYMENT PROTECTION
    if (lower.contains('escrow') ||
        lower.contains('milestone') ||
        lower.contains('protect') ||
        lower.contains('payment') ||
        lower.contains('fraud') ||
        lower.contains('safe') ||
        lower.contains('money')) {
      return 'How Hometrust Milestone Escrow Protects Buyers:\n\n'
          '• Zero Upfront Developer Risk: Funds are held in a secure CBN-regulated escrow trust account.\n'
          '• Stage-by-Stage Verification: The developer does NOT receive money until a certified structural engineer audits and approves the on-site milestone.\n'
          '• 100% Dedicated NUBAN Accounts: Every buyer is issued a unique virtual bank account for automated, trackable instalment payments.\n'
          '• Critical Security Policy: NEVER transfer funds directly to developers or agents outside Hometrust, as off-app payments void all escrow warranties and cannot be recovered.';
    }

    // 5. GAZETTE VS C-OF-O VS EXCISION
    if (lower.contains('gazette') || lower.contains('difference') || lower.contains('excision') || lower.contains('free')) {
      return 'Understanding C-of-O vs. Government Gazette vs. Excision:\n\n'
          '• Excision / Gazette: An official state government publication releasing a specific tract of ancestral land from compulsory government acquisition.\n'
          '• Certificate of Occupancy (C-of-O): A direct 99-year state grant giving the title holder unencumbered legal leasehold.\n'
          '• Governor\'s Consent: Mandatory approval from the State Governor whenever land with existing C-of-O is resold to a new buyer.\n\n'
          'Caution: Always confirm that excised land is officially gazetted before making any initial deposit.';
    }

    // 6. MATERIAL PRICES & CONSTRUCTION COSTS
    if (lower.contains('cost') ||
        lower.contains('cement') ||
        lower.contains('price') ||
        lower.contains('rebar') ||
        lower.contains('build') ||
        lower.contains('material') ||
        lower.contains('steel') ||
        lower.contains('granite')) {
      return 'Current Construction Price Benchmarks (August 2026):\n\n'
          '• 50kg Portland Cement (Dangote/BUA): ₦8,300 – ₦8,900 (depending on state logistics)\n'
          '• 12mm High-Tensile TMT Rebar: ~₦1,180,000 / Ton (approx. 94 lengths)\n'
          '• 16mm High-Tensile TMT Rebar: ~₦1,220,000 / Ton (approx. 53 lengths)\n'
          '• 30-Ton Clean Black Granite (3/4"): ₦280,000 – ₦310,000\n'
          '• 20-Ton Washed Sharp Sand: ₦140,000 – ₦160,000\n'
          '• 9-inch Machine-Vibrated Solid Blocks: ₦760 – ₦880/piece\n\n'
          'Tip: Use the "Material Index" on the Home Screen for state-by-state prices across all 36 Nigerian states.';
    }

    // 7. DEVELOPER & KYB CORPORATE ACCOUNT
    if (lower.contains('developer') || lower.contains('company') || lower.contains('sign up') || lower.contains('register') || lower.contains('cac')) {
      return 'Developer & Corporate Account Guidelines:\n\n'
          '• Corporate Onboarding: Real estate developers must register with their CAC RC Number, registered corporate name, and official business address.\n'
          '• Off-Plan Project Audits: Before an off-plan project is listed, structural drawings, EIA reports, and building approvals must be vetted by our technical committee.\n'
          '• Milestone Disbursement: Payments are disbursed strictly upon verified engineering milestone sign-off.';
    }

    // 8. GENERAL INTELLIGENT LEGAL ADVISORY
    return 'Hometrust Legal & Real Estate Advisory:\n\n'
        'Regarding: "$userMsg"\n\n'
        'In Nigerian real estate, complete legal due diligence and milestone escrow are crucial before committing funds. Key recommended actions:\n\n'
        '1. Run the beacon coordinates through our Free Land Radar (covering all 36 States + FCT).\n'
        '2. Conduct a certified title search at the State Ministry of Lands.\n'
        '3. Ensure all agreements are drafted by a certified property solicitor (available via Document Prep).\n'
        '4. Always channel payments through your dedicated Hometrust virtual account.';
  }

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
      }).timeout(const Duration(seconds: 4));

      if (res != null) {
        if (res is Map && res['reply'] != null && (res['reply'] as String).trim().isNotEmpty) {
          reply = (res['reply'] as String).trim();
        } else if (res is Map && res['data'] != null && res['data']['reply'] != null) {
          reply = (res['data']['reply'] as String).trim();
        } else if (res is String && res.trim().isNotEmpty) {
          reply = res.trim();
        }
      }
    } catch (_) {
      // Direct offline / NLP response handler
    }

    if (reply.isEmpty) {
      reply = _generateConversationalResponse(userMsg);
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
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hometrust Legal AI Advisor',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Instant Nigerian Property Law & Escrow Intel',
                        style: TextStyle(fontSize: 11, color: AppColors.emeraldText, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Quick Prompts Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final q = _quickPrompts[idx];
                return GestureDetector(
                  onTap: () => _sendMessage(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      q,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Chat Message History
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                      border: isUser ? null : Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI Advisor is analyzing Nigerian land regulations...',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Input Box
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask about C-of-O, escrow, land radar...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
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