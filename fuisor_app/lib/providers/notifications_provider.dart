import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class NotificationsProvider with ChangeNotifier {
  final ApiService _apiService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMoreNotifications = true;
  String? _error;
  int _currentPage = 1;
  int _unreadCount = 0;

  NotificationsProvider(this._apiService);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  bool get hasMoreNotifications => _hasMoreNotifications;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  // Load notifications
  Future<void> loadNotifications({bool refresh = false, AuthProvider? authProvider}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMoreNotifications = true;
      _notifications = [];
      _isInitialLoading = true;
    } else {
      _isLoading = true;
    }

    _error = null;
    notifyListeners();

    try {
      print('NotificationsProvider: Loading notifications (page $_currentPage)...');
      
      // Get access token from AuthProvider
      String? accessToken;
      if (authProvider != null) {
        accessToken = await authProvider.getAccessToken();
        if (accessToken != null) {
          _apiService.setAccessToken(accessToken);
        }
      }
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      final response = await _apiService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      final List<dynamic> notificationsData = response['notifications'] ?? [];
      final List<NotificationModel> newNotifications = notificationsData
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      _unreadCount = response['unreadCount'] ?? 0;

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _hasMoreNotifications = newNotifications.length >= 20;
      _currentPage++;

      print('NotificationsProvider: Loaded ${newNotifications.length} notifications');
      print('NotificationsProvider: Unread count: $_unreadCount');
      print('NotificationsProvider: Has more: $_hasMoreNotifications');
    } catch (e) {
      print('NotificationsProvider: Error loading notifications: $e');
      _error = e.toString();
      if (!refresh) {
        _hasMoreNotifications = false;
      }
    } finally {
      _isLoading = false;
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  // Load more notifications (for infinite scroll)
  Future<void> loadMoreNotifications({AuthProvider? authProvider}) async {
    if (!_hasMoreNotifications || _isLoading) return;
    await loadNotifications(refresh: false, authProvider: authProvider);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId, {AuthProvider? authProvider}) async {
    try {
      // Get access token from AuthProvider
      String? accessToken;
      if (authProvider != null) {
        accessToken = await authProvider.getAccessToken();
        if (accessToken != null) {
          _apiService.setAccessToken(accessToken);
        }
      }
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      await _apiService.markNotificationAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        final updatedNotification = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          actorId: _notifications[index].actorId,
          type: _notifications[index].type,
          postId: _notifications[index].postId,
          commentId: _notifications[index].commentId,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          actor: _notifications[index].actor,
          post: _notifications[index].post,
          comment: _notifications[index].comment,
        );
        _notifications[index] = updatedNotification;
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      print('NotificationsProvider: Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead({AuthProvider? authProvider}) async {
    try {
      // Get access token from AuthProvider
      String? accessToken;
      if (authProvider != null) {
        accessToken = await authProvider.getAccessToken();
        if (accessToken != null) {
          _apiService.setAccessToken(accessToken);
        }
      }
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      await _apiService.markAllNotificationsAsRead();
      
      // Update local state
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        userId: n.userId,
        actorId: n.actorId,
        type: n.type,
        postId: n.postId,
        commentId: n.commentId,
        isRead: true,
        createdAt: n.createdAt,
        actor: n.actor,
        post: n.post,
        comment: n.comment,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('NotificationsProvider: Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId, {AuthProvider? authProvider}) async {
    try {
      // Get access token from AuthProvider
      String? accessToken;
      if (authProvider != null) {
        accessToken = await authProvider.getAccessToken();
        if (accessToken != null) {
          _apiService.setAccessToken(accessToken);
        }
      }
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      await _apiService.deleteNotification(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        if (!_notifications[index].isRead) {
          _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        }
        _notifications.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      print('NotificationsProvider: Error deleting notification: $e');
      throw Exception('Failed to delete notification');
    }
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _hasMoreNotifications = true;
    _error = null;
    _isInitialLoading = true;
    notifyListeners();
  }
}

