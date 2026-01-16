/// Cart Item Model
class CartItem {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String itemName;
  final String itemDescription;
  final double price;
  int quantity;
  final Map<String, dynamic>? customizations;

  CartItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
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
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'price': price,
      'quantity': quantity,
      'customizations': customizations,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      restaurantId: map['restaurantId'] as String,
      restaurantName: map['restaurantName'] as String,
      itemName: map['itemName'] as String,
      itemDescription: map['itemDescription'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      customizations: map['customizations'] as Map<String, dynamic>?,
    );
  }
}
