import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Service to manage favorite restaurants
class FavoritesService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _favoriteRestaurantIds = [];
  List<String> get favoriteRestaurantIds => List.unmodifiable(_favoriteRestaurantIds);

  FavoritesService() {
    _loadFavorites();
  }

  /// Get favorites collection reference for current user
  CollectionReference get _favoritesCollection {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  /// Load favorites from Firestore
  Future<void> _loadFavorites() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;

    try {
      _favoritesCollection.snapshots().listen((snapshot) {
        _favoriteRestaurantIds = snapshot.docs.map((doc) => doc.id).toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('FavoritesService: Error loading favorites: $e');
    }
  }

  /// Check if restaurant is favorite
  bool isFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }

  /// Add restaurant to favorites
  Future<bool> addFavorite(String restaurantId, String restaurantName) async {
    try {
      await _favoritesCollection.doc(restaurantId).set({
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'addedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FavoritesService: Added favorite: $restaurantId');
      return true;
    } catch (e) {
      debugPrint('FavoritesService: Error adding favorite: $e');
      return false;
    }
  }

  /// Remove restaurant from favorites
  Future<bool> removeFavorite(String restaurantId) async {
    try {
      await _favoritesCollection.doc(restaurantId).delete();
      debugPrint('FavoritesService: Removed favorite: $restaurantId');
      return true;
    } catch (e) {
      debugPrint('FavoritesService: Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String restaurantId, String restaurantName) async {
    if (isFavorite(restaurantId)) {
      return await removeFavorite(restaurantId);
    } else {
      return await addFavorite(restaurantId, restaurantName);
    }
  }

  /// Get favorite restaurants data
  Future<List<Map<String, dynamic>>> getFavoriteRestaurants() async {
    try {
      final snapshot = await _favoritesCollection.get();
      if (snapshot.docs.isEmpty) return [];

      final restaurantIds = snapshot.docs.map((doc) => doc.id).toList();
      final restaurants = <Map<String, dynamic>>[];

      for (final restaurantId in restaurantIds) {
        final restaurant = await _firebaseService.getRestaurant(restaurantId);
        if (restaurant != null) {
          restaurants.add(restaurant);
        }
      }

      return restaurants;
    } catch (e) {
      debugPrint('FavoritesService: Error getting favorite restaurants: $e');
      return [];
    }
  }
}
