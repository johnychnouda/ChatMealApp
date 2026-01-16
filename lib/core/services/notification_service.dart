import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Service to handle push notifications
class NotificationService {
  final FirebaseService _firebaseService = FirebaseService();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _saveTokenToFirestore(token);
      });

      // Configure foreground message handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('NotificationService: Error initializing: $e');
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('NotificationService: FCM Token: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('NotificationService: Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NotificationService: Error saving token to Firestore: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('NotificationService: Foreground message received: ${message.messageId}');
    debugPrint('NotificationService: Title: ${message.notification?.title}');
    debugPrint('NotificationService: Body: ${message.notification?.body}');
    debugPrint('NotificationService: Data: ${message.data}');

    // You can show a local notification or update UI here
    // For now, we'll just log it
  }

  /// Handle background messages (when app is opened from notification)
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('NotificationService: App opened from notification: ${message.messageId}');
    debugPrint('NotificationService: Data: ${message.data}');

    // Navigate to relevant screen based on notification data
    // This will be handled in the home screen
  }

  /// Subscribe to order notifications
  Future<void> subscribeToOrderNotifications(String orderId) async {
    try {
      await _messaging.subscribeToTopic('order_$orderId');
      debugPrint('NotificationService: Subscribed to order topic: order_$orderId');
    } catch (e) {
      debugPrint('NotificationService: Error subscribing to order notifications: $e');
    }
  }

  /// Unsubscribe from order notifications
  Future<void> unsubscribeFromOrderNotifications(String orderId) async {
    try {
      await _messaging.unsubscribeFromTopic('order_$orderId');
      debugPrint('NotificationService: Unsubscribed from order topic: order_$orderId');
    } catch (e) {
      debugPrint('NotificationService: Error unsubscribing from order notifications: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('NotificationService: Background message received: ${message.messageId}');
}
