import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as models;
import '../models/cart_item.dart';
import 'firebase_service.dart';

/// Service to manage orders
class OrderService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ordersCollection = _firestore.collection('orders');

  // Default tax rate (10%)
  static const double defaultTaxRate = 0.10;
  // Default delivery fee
  static const double defaultDeliveryFee = 2.99;

  // Active order (if any)
  models.Order? _activeOrder;
  models.Order? get activeOrder => _activeOrder;

  // Order history
  List<models.Order> _orderHistory = [];
  List<models.Order> get orderHistory => List.unmodifiable(_orderHistory);

  OrderService() {
    _initialize();
  }

  Future<void> _initialize() async {
    final userId = _firebaseService.currentUserId;
    if (userId != null) {
      // Listen for active order
      _listenForActiveOrder(userId);
      // Load order history
      _loadOrderHistory(userId);
    }
  }

  /// Listen for active order changes
  void _listenForActiveOrder(String userId) {
    _ordersCollection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'confirmed', 'preparing', 'ready', 'onTheWay'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _activeOrder = models.Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        _activeOrder = null;
      }
      notifyListeners();
    });
  }

  /// Load order history
  void _loadOrderHistory(String userId) {
    _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _orderHistory = snapshot.docs.map((doc) {
        return models.Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      notifyListeners();
    });
  }

  /// Create order from cart items
  Future<String?> createOrder({
    required String userId,
    required List<CartItem> cartItems,
    required String deliveryAddress,
    String? specialInstructions,
    String paymentMethod = 'cash_on_delivery',
  }) async {
    if (cartItems.isEmpty) {
      debugPrint('OrderService: Cannot create order with empty cart');
      return null;
    }

    try {
      // Group items by restaurant (for now, assume all items from same restaurant)
      final firstItem = cartItems.first;
      final restaurantId = firstItem.restaurantId;
      final restaurantName = firstItem.restaurantName;

      // Calculate totals
      final subtotal = cartItems.fold(0.0, (total, item) => total + item.total);
      final tax = subtotal * defaultTaxRate;
      final deliveryFee = defaultDeliveryFee;
      final total = subtotal + tax + deliveryFee;

      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) {
        return {
          'id': cartItem.id,
          'itemName': cartItem.itemName,
          'itemDescription': cartItem.itemDescription,
          'price': cartItem.price,
          'quantity': cartItem.quantity,
          'customizations': cartItem.customizations,
        };
      }).toList();

      // Create order data
      final orderData = {
        'userId': userId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'items': orderItems,
        'subtotal': subtotal,
        'tax': tax,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': 'pending',
        'deliveryAddress': deliveryAddress,
        'specialInstructions': specialInstructions,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'estimatedDeliveryTime': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 30)),
        ),
      };

      final docRef = await _ordersCollection.add(orderData);
      debugPrint('OrderService: Order created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('OrderService: Error creating order: $e');
      return null;
    }
  }

  /// Get order by ID
  Future<models.Order?> getOrder(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        return models.Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('OrderService: Error getting order: $e');
      return null;
    }
  }

  /// Get order stream for real-time updates
  Stream<models.Order?> getOrderStream(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return models.Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Get user orders stream
  Stream<List<models.Order>> getUserOrdersStream(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return models.Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('OrderService: Order status updated: $orderId -> $status');
      return true;
    } catch (e) {
      debugPrint('OrderService: Error updating order status: $e');
      return false;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');
      return true;
    } catch (e) {
      debugPrint('OrderService: Error cancelling order: $e');
      return false;
    }
  }

  /// Reorder (create new order from previous order)
  Future<String?> reorder(models.Order previousOrder, String deliveryAddress) async {
    try {
      // Convert order items back to cart items format
      final cartItems = previousOrder.items.map((item) {
        return CartItem(
          id: item.id,
          restaurantId: previousOrder.restaurantId,
          restaurantName: previousOrder.restaurantName,
          itemName: item.itemName,
          itemDescription: item.itemDescription,
          price: item.price,
          quantity: item.quantity,
          customizations: item.customizations,
        );
      }).toList();

      // Create new order
      return await createOrder(
        userId: previousOrder.userId,
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        specialInstructions: previousOrder.specialInstructions,
        paymentMethod: previousOrder.paymentMethod,
      );
    } catch (e) {
      debugPrint('OrderService: Error reordering: $e');
      return null;
    }
  }

  /// Calculate estimated delivery time
  DateTime calculateEstimatedDeliveryTime() {
    return DateTime.now().add(const Duration(minutes: 30));
  }
}
