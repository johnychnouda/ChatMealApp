/// Order Model
class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final String status; // pending, confirmed, preparing, ready, onTheWay, delivered, cancelled
  final String? deliveryAddress;
  final String? specialInstructions;
  final String paymentMethod; // cash_on_delivery, card, etc.
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDeliveryTime;

  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.deliveryFee = 0.0,
    required this.total,
    this.status = 'pending',
    this.deliveryAddress,
    this.specialInstructions,
    this.paymentMethod = 'cash_on_delivery',
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDeliveryTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'specialInstructions': specialInstructions,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      userId: map['userId'] as String,
      restaurantId: map['restaurantId'] as String,
      restaurantName: map['restaurantName'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      deliveryAddress: map['deliveryAddress'] as String?,
      specialInstructions: map['specialInstructions'] as String?,
      paymentMethod: map['paymentMethod'] as String? ?? 'cash_on_delivery',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      estimatedDeliveryTime: map['estimatedDeliveryTime'] != null
          ? DateTime.parse(map['estimatedDeliveryTime'] as String)
          : null,
    );
  }

  factory Order.fromFirestore(Map<String, dynamic> map, String docId) {
    // Handle Firestore Timestamps
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.parse(timestamp);
      // Firestore Timestamp
      return (timestamp as dynamic).toDate();
    }

    return Order(
      id: docId,
      userId: map['userId'] as String,
      restaurantId: map['restaurantId'] as String,
      restaurantName: map['restaurantName'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      deliveryAddress: map['deliveryAddress'] as String?,
      specialInstructions: map['specialInstructions'] as String?,
      paymentMethod: map['paymentMethod'] as String? ?? 'cash_on_delivery',
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
      estimatedDeliveryTime: map['estimatedDeliveryTime'] != null
          ? parseTimestamp(map['estimatedDeliveryTime'])
          : null,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'specialInstructions': specialInstructions,
      'paymentMethod': paymentMethod,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'onTheWay':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isActive {
    return !['delivered', 'cancelled'].contains(status);
  }
}

/// Order Item Model
class OrderItem {
  final String id;
  final String itemName;
  final String itemDescription;
  final double price;
  final int quantity;
  final Map<String, dynamic>? customizations;

  OrderItem({
    required this.id,
    required this.itemName,
    required this.itemDescription,
    required this.price,
    this.quantity = 1,
    this.customizations,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'price': price,
      'quantity': quantity,
      'customizations': customizations,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      itemDescription: map['itemDescription'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      customizations: map['customizations'] as Map<String, dynamic>?,
    );
  }
}
