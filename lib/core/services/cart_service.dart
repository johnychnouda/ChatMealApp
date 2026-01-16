import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

/// Service to manage shopping cart
class CartService extends ChangeNotifier {
  static const String _cartKey = 'shopping_cart';
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get total => _items.fold(0.0, (sum, item) => sum + item.total);
  
  bool get isEmpty => _items.isEmpty;
  
  bool get isNotEmpty => _items.isNotEmpty;

  CartService() {
    _loadCart();
  }

  /// Load cart from storage
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> cartData = jsonDecode(cartJson);
        _items.clear();
        _items.addAll(cartData.map((item) => CartItem.fromMap(item)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CartService: Error loading cart: $e');
    }
  }

  /// Save cart to storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((item) => item.toMap()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      debugPrint('CartService: Error saving cart: $e');
    }
  }

  /// Add item to cart
  Future<void> addItem(CartItem item) async {
    // Check if item already exists (same restaurant, same item)
    final existingIndex = _items.indexWhere(
      (existing) => existing.restaurantId == item.restaurantId && 
                    existing.itemName == item.itemName,
    );
    
    if (existingIndex != -1) {
      // Update quantity
      _items[existingIndex].quantity += item.quantity;
    } else {
      // Add new item
      _items.add(item);
    }
    
    await _saveCart();
    notifyListeners();
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    await _saveCart();
    notifyListeners();
  }

  /// Update item quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }
    
    final item = _items.firstWhere((item) => item.id == itemId);
    item.quantity = quantity;
    await _saveCart();
    notifyListeners();
  }

  /// Clear cart
  Future<void> clear() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  /// Get items for a specific restaurant
  List<CartItem> getItemsForRestaurant(String restaurantId) {
    return _items.where((item) => item.restaurantId == restaurantId).toList();
  }
}
