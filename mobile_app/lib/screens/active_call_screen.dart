import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/socket_service.dart';

class ActiveCallScreen extends StatefulWidget {
  final String callId;
  final String peerId;
  final String peerName;
  final String peerRole;
  final String? propertyTitle;
  final bool isIncoming;
  final bool initiallyConnected;

  const ActiveCallScreen({
    super.key,
    required this.callId,
    required this.peerId,
    required this.peerName,
    this.peerRole = 'Verified Developer',
    this.propertyTitle,
    this.isIncoming = false,
    this.initiallyConnected = false,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isConnected = false;
  String _callStatusText = 'Calling...';
  int _seconds = 0;
  Timer? _timer;

  StreamSubscription? _acceptedSub;
  StreamSubscription? _ringingSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;

  @override
  void initState() {
    super.initState();

    if (widget.initiallyConnected) {
      _isConnected = true;
      _startTimer();
    } else {
      _callStatusText = 'Ringing via Hometrust Relay...';
      _listenToCallSignals();
    }
  }

  void _listenToCallSignals() {
    _ringingSub = SocketService.instance.onCallRinging.listen((data) {
      if (mounted && !_isConnected) {
        setState(() => _callStatusText = 'Ringing on developer device...');
      }
    });

    _acceptedSub = SocketService.instance.onCallAccepted.listen((data) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _callStatusText = 'Connected';
        });
        _startTimer();
      }
    });

    _rejectedSub = SocketService.instance.onCallRejected.listen((data) {
      if (mounted) {
        setState(() => _callStatusText = 'Call Declined (${data['reason'] ?? 'Busy'})');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });

    _endedSub = SocketService.instance.onCallEnded.listen((data) {
      if (mounted) {
        setState(() => _callStatusText = 'Call Ended');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _endCall() {
    _timer?.cancel();
    SocketService.instance.endCall(widget.callId, widget.peerId, durationSeconds: _seconds);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _acceptedSub?.cancel();
    _ringingSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Privacy Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'IN-APP ENCRYPTED CALL • NUMBERS MASKED',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Peer Avatar & Details
              Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isConnected
                            ? [const Color(0xFF065F46), const Color(0xFF047857)]
                            : [const Color(0xFF1E293B), const Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: _isConnected ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? const Color(0xFF10B981) : const Color(0xFF38BDF8)).withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : 'D',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.peerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.peerRole,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.propertyTitle != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Re: ${widget.propertyTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _isConnected ? _formattedTime : _callStatusText,
                    style: TextStyle(
                      color: _isConnected ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                      fontSize: _isConnected ? 18 : 13,
                      fontWeight: _isConnected ? FontWeight.w900 : FontWeight.w600,
                      letterSpacing: _isConnected ? 1.0 : 0.0,
                    ),
                  ),
                ],
              ),

              // Action Controls & End Call
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
                      // Chat / Keypad
                      _buildCallAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        isActive: false,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),

                  // End Call Red Button
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'End Call',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            width: 54,
            height: 54,
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
