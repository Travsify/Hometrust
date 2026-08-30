import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/socket_service.dart';
import 'active_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const IncomingCallScreen({super.key, required this.callData});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timeoutTimer;
  StreamSubscription? _callEndedSubscription;

  @override
  void initState() {
    super.initState();

    // Pulse animation for incoming call ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Acknowledge ringing to the caller
    final callId = widget.callData['callId'] ?? '';
    final callerId = widget.callData['callerId'] ?? '';
    if (callId.isNotEmpty && callerId.isNotEmpty) {
      SocketService.instance.acknowledgeRinging(callId, callerId);
    }

    // Auto-decline after 35 seconds of ringing
    _timeoutTimer = Timer(const Duration(seconds: 35), () {
      _declineCall();
    });

    // Listen if caller cancelled
    _callEndedSubscription = SocketService.instance.onCallEnded.listen((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timeoutTimer?.cancel();
    _callEndedSubscription?.cancel();
    super.dispose();
  }

  void _answerCall() {
    _timeoutTimer?.cancel();
    final callId = widget.callData['callId'] ?? '';
    final callerId = widget.callData['callerId'] ?? '';
    final channelId = widget.callData['channelId'] ?? 'room_$callId';

    SocketService.instance.acceptCall(callId, callerId, channelId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(
            callId: callId,
            peerId: callerId,
            peerName: widget.callData['callerName'] ?? 'Caller',
            peerRole: widget.callData['callerRole'] ?? 'Verified User',
            propertyTitle: widget.callData['propertyTitle'],
            isIncoming: true,
            initiallyConnected: true,
          ),
        ),
      );
    }
  }

  void _declineCall() {
    _timeoutTimer?.cancel();
    final callId = widget.callData['callId'] ?? '';
    final callerId = widget.callData['callerId'] ?? '';

    SocketService.instance.rejectCall(callId, callerId, reason: 'Declined by recipient');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.callData['callerName'] ?? 'Hometrust Caller';
    final callerRole = widget.callData['callerRole'] ?? 'Verified Customer';
    final propertyTitle = widget.callData['propertyTitle'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Badge
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
                      'INCOMING ENCRYPTED CALL • HOMETRUST RELAY',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),

              // Caller Profile & Pulsing Avatar
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF065F46), Color(0xFF047857)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: const Color(0xFF34D399), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              callerName.isNotEmpty ? callerName[0].toUpperCase() : 'H',
                              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    callerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    callerRole,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  if (propertyTitle != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Regarding: $propertyTitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ring_volume_rounded, color: Color(0xFF34D399), size: 16),
                      SizedBox(width: 6),
                      Text('Ringing...', style: TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),

              // Bottom Actions: Decline (Red) & Answer (Green)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _declineCall,
                          child: Container(
                            width: 72,
                            height: 72,
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
                        const Text('Decline', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w800)),
                      ],
                    ),

                    // Answer
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _answerCall,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.call_rounded, color: Colors.white, size: 34),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Answer', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w800)),
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
  }
}
