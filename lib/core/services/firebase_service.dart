import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Firestore operations
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _usersCollection => _firestore.collection('users');
  static CollectionReference get _restaurantsCollection => _firestore.collection('restaurants');
  static CollectionReference get _ordersCollection => _firestore.collection('orders');

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER OPERATIONS ====================

  /// Create or update user document in Firestore
  Future<void> createOrUpdateUser({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _usersCollection.doc(userId).set({
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'subscriptionStatus': 'none', // none, active, expired
        'subscriptionType': null, // monthly, yearly
        'subscriptionExpiry': null,
      }, SetOptions(merge: true));
      
      debugPrint('FirebaseService: User document created/updated: $userId');
    } catch (e) {
      debugPrint('FirebaseService: Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user document
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('FirebaseService: Error getting user data: $e');
      return null;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final userData = await getUserData(userId);
      if (userData == null) return false;

      final status = userData['subscriptionStatus'] as String?;
      final expiry = userData['subscriptionExpiry'] as Timestamp?;

      if (status != 'active') return false;
      if (expiry == null) return false;

      // Check if subscription has expired
      final now = DateTime.now();
      final expiryDate = expiry.toDate();
      
      if (expiryDate.isBefore(now)) {
        // Subscription expired, update status
        await _usersCollection.doc(userId).update({
          'subscriptionStatus': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('FirebaseService: Error checking subscription: $e');
      return false;
    }
  }

  /// Get subscription info
  Future<Map<String, dynamic>?> getSubscriptionInfo(String userId) async {
    try {
      final userData = await getUserData(userId);
      if (userData == null) return null;

      return {
        'status': userData['subscriptionStatus'] ?? 'none',
        'type': userData['subscriptionType'],
        'expiry': userData['subscriptionExpiry'],
      };
    } catch (e) {
      debugPrint('FirebaseService: Error getting subscription info: $e');
      return null;
    }
  }

  // ==================== RESTAURANT OPERATIONS ====================

  /// Get all active restaurants
  Stream<List<Map<String, dynamic>>> getActiveRestaurants() {
    return _restaurantsCollection
        .where('isActive', isEqualTo: true)
        .where('subscriptionStatus', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get restaurants once (non-streaming)
  Future<List<Map<String, dynamic>>> getActiveRestaurantsOnce() async {
    try {
      final snapshot = await _restaurantsCollection
          .where('isActive', isEqualTo: true)
          .where('subscriptionStatus', isEqualTo: 'active')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('FirebaseService: Error getting restaurants: $e');
      return [];
    }
  }

  /// Get restaurant by ID
  Future<Map<String, dynamic>?> getRestaurant(String restaurantId) async {
    try {
      final doc = await _restaurantsCollection.doc(restaurantId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('FirebaseService: Error getting restaurant: $e');
      return null;
    }
  }

  /// Get restaurant menu items
  Future<List<Map<String, dynamic>>> getRestaurantMenuItems(String restaurantId) async {
    try {
      final restaurant = await getRestaurant(restaurantId);
      if (restaurant == null) return [];

      final menuItems = restaurant['menuItems'] as List<dynamic>?;
      if (menuItems == null) return [];

      return menuItems.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('FirebaseService: Error getting menu items: $e');
      return [];
    }
  }

  // ==================== ORDER OPERATIONS ====================

  /// Create a new order
  Future<String?> createOrder({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required double total,
    String? deliveryAddress,
    String? specialInstructions,
  }) async {
    try {
      final orderData = {
        'userId': userId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'items': items,
        'total': total,
        'status': 'pending', // pending, confirmed, preparing, ready, delivered, cancelled
        'deliveryAddress': deliveryAddress,
        'specialInstructions': specialInstructions,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _ordersCollection.add(orderData);
      debugPrint('FirebaseService: Order created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('FirebaseService: Error creating order: $e');
      return null;
    }
  }

  /// Get user orders
  Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get order by ID
  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('FirebaseService: Error getting order: $e');
      return null;
    }
  }

  /// Get order stream (for real-time updates)
  Stream<Map<String, dynamic>?> getOrderStream(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    });
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FirebaseService: Order status updated: $orderId -> $status');
      return true;
    } catch (e) {
      debugPrint('FirebaseService: Error updating order status: $e');
      return false;
    }
  }
}
