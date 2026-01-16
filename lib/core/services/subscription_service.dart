import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Service to handle subscription management
class SubscriptionService {
  final FirebaseService _firebaseService = FirebaseService();

  /// Check if current user has active subscription
  Future<bool> hasActiveSubscription() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return false;
    return await _firebaseService.hasActiveSubscription(userId);
  }

  /// Get subscription info for current user
  Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return null;
    return await _firebaseService.getSubscriptionInfo(userId);
  }

  /// Check subscription status and return user-friendly message
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      return SubscriptionStatus(
        hasSubscription: false,
        message: 'Please log in to access your subscription',
        daysRemaining: 0,
      );
    }

    final subscriptionInfo = await _firebaseService.getSubscriptionInfo(userId);
    if (subscriptionInfo == null) {
      return SubscriptionStatus(
        hasSubscription: false,
        message: 'No subscription found. Please subscribe to continue.',
        daysRemaining: 0,
      );
    }

    final status = subscriptionInfo['status'] as String? ?? 'none';
    final expiry = subscriptionInfo['expiry'] as Timestamp?;
    final type = subscriptionInfo['type'] as String?;

    if (status != 'active' || expiry == null) {
      return SubscriptionStatus(
        hasSubscription: false,
        message: status == 'expired' 
            ? 'Your subscription has expired. Please renew to continue.'
            : 'No active subscription. Please subscribe to continue.',
        daysRemaining: 0,
      );
    }

    final expiryDate = expiry.toDate();
    final now = DateTime.now();
    final daysRemaining = expiryDate.difference(now).inDays;

    if (daysRemaining < 0) {
      // Subscription expired
      return SubscriptionStatus(
        hasSubscription: false,
        message: 'Your subscription has expired. Please renew to continue.',
        daysRemaining: 0,
      );
    }

    return SubscriptionStatus(
      hasSubscription: true,
      message: daysRemaining > 7
          ? 'Your subscription is active'
          : 'Your subscription expires in $daysRemaining day${daysRemaining != 1 ? 's' : ''}',
      daysRemaining: daysRemaining,
      subscriptionType: type,
      expiryDate: expiryDate,
    );
  }
}

/// Subscription status model
class SubscriptionStatus {
  final bool hasSubscription;
  final String message;
  final int daysRemaining;
  final String? subscriptionType;
  final DateTime? expiryDate;

  SubscriptionStatus({
    required this.hasSubscription,
    required this.message,
    required this.daysRemaining,
    this.subscriptionType,
    this.expiryDate,
  });
}
