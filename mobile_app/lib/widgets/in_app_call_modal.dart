import 'dart:async';
import 'package:flutter/material.dart';

class InAppCallModal extends StatefulWidget {
  final String entityName;
  final String entityRole;

  const InAppCallModal({
    super.key,
    required this.entityName,
    this.entityRole = 'Verified Developer',
  });

  static void show(BuildContext context, {required String entityName, String entityRole = 'Verified Developer'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InAppCallModal(entityName: entityName, entityRole: entityRole),
    );
  }

  @override
  State<InAppCallModal> createState() => _InAppCallModalState();
}

class _InAppCallModalState extends State<InAppCallModal> {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isConnected = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate connection after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _isConnected = true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Caller info
          Column(
            children: [
              // Privacy Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'IN-APP ENCRYPTED CALL • NUMBERS MASKED',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Glowing Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.entityName.isNotEmpty ? widget.entityName[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                widget.entityName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.entityRole,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Call Status
              Text(
                _isConnected ? _formattedTime : 'Calling via HomeVerify Secure Relay...',
                style: TextStyle(
                  color: _isConnected ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                  fontSize: _isConnected ? 16 : 12,
                  fontWeight: _isConnected ? FontWeight.w900 : FontWeight.w500,
                  letterSpacing: _isConnected ? 1.0 : 0.0,
                ),
              ),
            ],
          ),

          // Action Controls
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  _buildCallAction(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    isActive: _isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // Speaker
                  _buildCallAction(
                    icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    label: 'Speaker',
                    isActive: _isSpeaker,
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                  // Keypad
                  _buildCallAction(
                    icon: Icons.dialpad_rounded,
                    label: 'Keypad',
                    isActive: false,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // End Call Red Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'End Call',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0F172A) : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
