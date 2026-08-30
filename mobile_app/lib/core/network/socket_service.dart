import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'api_client.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream Controllers for Reactive UI
  final _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _incomingCallStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRingingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAcceptedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get onIncomingCall => _incomingCallStreamController.stream;
  Stream<Map<String, dynamic>> get onCallRinging => _callRingingStreamController.stream;
  Stream<Map<String, dynamic>> get onCallAccepted => _callAcceptedStreamController.stream;
  Stream<Map<String, dynamic>> get onCallRejected => _callRejectedStreamController.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedStreamController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingStreamController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadStreamController.stream;

  SocketService._();

  /// Initialize and connect to the real-time Socket.io server
  Future<void> connect({String? userId, String? userName}) async {
    if (_socket != null && _socket!.connected) return;

    final token = await ApiClient.getToken();

    // Determine host server from ApiConstants
    String serverUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    if (serverUrl.isEmpty) {
      serverUrl = 'https://estateverify-app.onrender.com';
    }

    try {
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setAuth({
              'token': token ?? '',
              'userId': userId ?? '',
              'userName': userName ?? 'User',
            })
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) {
          print('✅ [SOCKET.IO] Connected to Hometrust Gateway: ${_socket!.id}');
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) {
          print('⚠️ [SOCKET.IO] Disconnected from Hometrust Gateway');
        }
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        if (kDebugMode) {
          print('❌ [SOCKET.IO] Connection error: $err');
        }
      });

      // ─── LISTEN TO CHAT EVENTS ───────────────────────────────────────────
      _socket!.on('new_message', (data) {
        if (data is Map) {
          _messageStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('message_notification', (data) {
        if (data is Map) {
          _messageStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('user_typing', (data) {
        if (data is Map) {
          _typingStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('messages_read', (data) {
        if (data is Map) {
          _messagesReadStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      // ─── LISTEN TO CALLING EVENTS ────────────────────────────────────────
      _socket!.on('incoming_call', (data) {
        if (data is Map) {
          if (kDebugMode) print('📞 [CALL] Incoming call received: $data');
          _incomingCallStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('call_ringing', (data) {
        if (data is Map) {
          _callRingingStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('call_accepted', (data) {
        if (data is Map) {
          if (kDebugMode) print('📞 [CALL] Call accepted by peer: $data');
          _callAcceptedStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('call_rejected', (data) {
        if (data is Map) {
          if (kDebugMode) print('📞 [CALL] Call rejected: $data');
          _callRejectedStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('call_ended', (data) {
        if (data is Map) {
          if (kDebugMode) print('📞 [CALL] Call ended: $data');
          _callEndedStreamController.add(Map<String, dynamic>.from(data));
        }
      });
    } catch (e) {
      if (kDebugMode) print('❌ [SOCKET.IO] Setup exception: $e');
    }
  }

  // ─── CHAT EMITTERS ────────────────────────────────────────────────────────

  void joinConversation(String conversationId) {
    if (_socket?.connected == true) {
      _socket!.emit('join_conversation', {'conversationId': conversationId});
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket?.connected == true) {
      _socket!.emit('leave_conversation', {'conversationId': conversationId});
    }
  }

  void sendMessage({
    required String conversationId,
    required String content,
    String? recipientId,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    if (_socket?.connected == true) {
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'recipientId': recipientId,
        'content': content,
        'attachmentUrl': attachmentUrl,
        'attachmentType': attachmentType,
      });
    }
  }

  void sendTyping(String conversationId, bool isTyping) {
    if (_socket?.connected == true) {
      _socket!.emit('typing', {
        'conversationId': conversationId,
        'isTyping': isTyping,
      });
    }
  }

  void markAsRead(String conversationId, {String? messageId}) {
    if (_socket?.connected == true) {
      _socket!.emit('mark_as_read', {
        'conversationId': conversationId,
        'messageId': messageId,
      });
    }
  }

  // ─── CALLING EMITTERS ─────────────────────────────────────────────────────

  void initiateCall({
    required String callId,
    required String recipientId,
    required String callerName,
    String? callerRole,
    String? callerAvatar,
    String? propertyTitle,
    bool isVideo = false,
    String? channelId,
  }) {
    if (_socket?.connected == true) {
      _socket!.emit('call_initiate', {
        'callId': callId,
        'recipientId': recipientId,
        'callerName': callerName,
        'callerRole': callerRole,
        'callerAvatar': callerAvatar,
        'propertyTitle': propertyTitle,
        'isVideo': isVideo,
        'channelId': channelId ?? 'room_$callId',
      });
    }
  }

  void acknowledgeRinging(String callId, String callerId) {
    if (_socket?.connected == true) {
      _socket!.emit('call_ringing', {
        'callId': callId,
        'callerId': callerId,
      });
    }
  }

  void acceptCall(String callId, String callerId, String channelId) {
    if (_socket?.connected == true) {
      _socket!.emit('call_accept', {
        'callId': callId,
        'callerId': callerId,
        'channelId': channelId,
      });
    }
  }

  void rejectCall(String callId, String callerId, {String? reason}) {
    if (_socket?.connected == true) {
      _socket!.emit('call_reject', {
        'callId': callId,
        'callerId': callerId,
        'reason': reason ?? 'Declined',
      });
    }
  }

  void endCall(String callId, String peerId, {int durationSeconds = 0}) {
    if (_socket?.connected == true) {
      _socket!.emit('call_end', {
        'callId': callId,
        'peerId': peerId,
        'durationSeconds': durationSeconds,
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
