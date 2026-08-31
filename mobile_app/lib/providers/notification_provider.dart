import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'] ?? 'GENERAL',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.get('/notifications');
      if (res != null && res is List) {
        _notifications = res.map((n) => NotificationItem.fromJson(n)).toList();
      }
    } catch (_) {
      // If offline / empty
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.patch('/notifications/read-all', {});
      _notifications = _notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;
    // Optimistically mark as read locally
    final old = _notifications[idx];
    _notifications[idx] = NotificationItem(
      id: old.id, title: old.title, message: old.message,
      type: old.type, isRead: true, createdAt: old.createdAt,
    );
    notifyListeners();
    try {
      await ApiClient.patch('/notifications/$id/read', {});
    } catch (_) {}
  }

  Future<void> dismissNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await ApiClient.delete('/notifications/$id');
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    try {
      await ApiClient.delete('/notifications/clear-all');
    } catch (_) {}
  }
}
