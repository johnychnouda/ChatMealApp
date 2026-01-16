import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/order.dart';
import '../../../core/models/cart_item.dart';

class Message {
  final String text;
  final bool isAI;
  final DateTime timestamp;
  final bool showQuickActions;

  Message({
    required this.text,
    required this.isAI,
    required this.timestamp,
    this.showQuickActions = false,
  });
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final Color shadowColor;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    // Voice-only mode: No tap actions, users must speak to AI
    // widget.onTap(); // Removed for voice-only interface
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.title}. ${widget.description}',
      child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: _isPressed ? 0.3 : 0.4),
                  blurRadius: _isPressed ? 15 : 20,
                  spreadRadius: 0,
                  offset: Offset(0, _isPressed ? 6 : 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.iconColor.withValues(alpha: 0.35),
                        widget.iconColor.withValues(alpha: 0.2),
                        widget.iconColor.withValues(alpha: 0.1),
                        widget.iconColor.withValues(alpha: 0.05),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.iconColor.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.1),
                        blurRadius: 4,
                        spreadRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              widget.iconColor.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Inner highlight
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Icon with subtle shadow
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.iconColor,
                            widget.iconColor.withValues(alpha: 0.9),
                          ],
                        ).createShader(bounds),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.textColor.withValues(alpha: 0.95),
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Order status enum
enum OrderStatus {
  preparing,
  onTheWay,
  delivered,
}

// Order model
class ActiveOrder {
  final String id;
  final String restaurantName;
  final OrderStatus status;
  final String estimatedTime;
  final double total;

  ActiveOrder({
    required this.id,
    required this.restaurantName,
    required this.status,
    required this.estimatedTime,
    required this.total,
  });
}

// Promotion model
class Promotion {
  final String id;
  final String title;
  final String description;
  final String? code;
  final Color color;
  final DateTime? expiryDate;
  final int? maxUses;
  final int currentUses;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    this.code,
    required this.color,
    this.expiryDate,
    this.maxUses,
    this.currentUses = 0,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get hasUsesLeft {
    if (maxUses == null) return true;
    return currentUses < maxUses!;
  }

  int? get remainingUses {
    if (maxUses == null) return null;
    return (maxUses! - currentUses).clamp(0, maxUses!);
  }

  Duration? get timeRemaining {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiryDate!)) return Duration.zero;
    return expiryDate!.difference(now);
  }
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _showRestaurants = false; // Default to chat view
  bool _showMenu = false; // Show menu view
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  late VoiceService _voiceService;
  late OpenAIService _openAIService;
  final FirebaseService _firebaseService = FirebaseService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  late CartService _cartService;
  late OrderService _orderService;
  late FavoritesService _favoritesService;
  final NotificationService _notificationService = NotificationService();
  String? _selectedRestaurant;
  Map<String, dynamic>? _selectedRestaurantData; // Store full restaurant data
  bool _autoListenAfterSpeaking = false;
  bool _isProcessingAI = false;
  // Conversation history for context
  final List<Map<String, String>> _conversationHistory = [];
  
  // Firebase data
  List<Map<String, dynamic>> _firestoreRestaurants = [];
  bool _isLoadingRestaurants = true;
  bool _hasActiveSubscription = false;

  String _selectedCategory = 'All';
  late AnimationController _cardAnimationController;
  late Animation<double> _card1Animation;
  late Animation<double> _card2Animation;

  // Active order state (set to null to hide, or provide an order to show)
  ActiveOrder? _activeOrder;

  // Promotions data
  final List<Promotion> _promotions = [
    Promotion(
      id: '1',
      title: '🎉 New User Special',
      description: 'Get 20% off your first order! Use code: FIRST20',
      code: 'FIRST20',
      color: AppTheme.goldenYellow,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      maxUses: 1,
      currentUses: 0,
    ),
    Promotion(
      id: '2',
      title: '🍕 Weekend Deal',
      description: 'Free delivery on orders over \$25 this weekend',
      color: AppTheme.darkTealGreen,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      maxUses: 100,
      currentUses: 45,
    ),
    Promotion(
      id: '3',
      title: '⚡ Flash Sale',
      description: '50% off on selected restaurants - Limited time!',
      color: AppTheme.goldenOrange,
      expiryDate: DateTime.now().add(const Duration(hours: 12)),
      maxUses: 50,
      currentUses: 32,
    ),
  ];
  int _currentPromotionIndex = 0;


  // Restaurants from Firestore (will be populated)
  Map<String, List<Map<String, dynamic>>> _restaurantsByCategory = {};
  
  // Sample restaurants grouped by category (fallback if Firestore is empty)
  final Map<String, List<Map<String, dynamic>>> _fallbackRestaurants = {
    'Pizza': [
      {
        'name': 'Pizza Palace',
        'cuisine': 'Italian',
        'rating': 4.8,
        'deliveryTime': '25-35 min',
        'icon': Icons.local_pizza,
        'items': ['Pizza', 'Pasta', 'Salads'],
      },
      {
        'name': 'Mario\'s Pizzeria',
        'cuisine': 'Italian',
        'rating': 4.7,
        'deliveryTime': '20-30 min',
        'icon': Icons.local_pizza,
        'items': ['Pizza', 'Calzones', 'Garlic Bread'],
      },
      {
        'name': 'New York Pizza',
        'cuisine': 'American',
        'rating': 4.6,
        'deliveryTime': '30-40 min',
        'icon': Icons.local_pizza,
        'items': ['Pizza', 'Wings', 'Salads'],
      },
    ],
    'Burger': [
      {
        'name': 'Burger House',
        'cuisine': 'American',
        'rating': 4.6,
        'deliveryTime': '20-30 min',
        'icon': Icons.lunch_dining,
        'items': ['Burgers', 'Fries', 'Shakes'],
      },
      {
        'name': 'Grill Master',
        'cuisine': 'American',
        'rating': 4.8,
        'deliveryTime': '25-35 min',
        'icon': Icons.lunch_dining,
        'items': ['Burgers', 'Ribs', 'Onion Rings'],
      },
      {
        'name': 'Classic Burger',
        'cuisine': 'American',
        'rating': 4.5,
        'deliveryTime': '15-25 min',
        'icon': Icons.lunch_dining,
        'items': ['Burgers', 'Fries', 'Milkshakes'],
      },
    ],
    'Lebanese': [
      {
        'name': 'Shawarma King',
        'cuisine': 'Lebanese',
        'rating': 4.9,
        'deliveryTime': '20-30 min',
        'icon': Icons.restaurant,
        'items': ['Shawarma', 'Falafel', 'Hummus'],
      },
      {
        'name': 'Beirut Express',
        'cuisine': 'Lebanese',
        'rating': 4.8,
        'deliveryTime': '25-35 min',
        'icon': Icons.restaurant,
        'items': ['Shawarma', 'Kebab', 'Tabbouleh'],
      },
      {
        'name': 'Al Fanoos',
        'cuisine': 'Lebanese',
        'rating': 4.7,
        'deliveryTime': '20-30 min',
        'icon': Icons.restaurant,
        'items': ['Shawarma', 'Manakish', 'Fattoush'],
      },
    ],
    'Italian': [
      {
        'name': 'Bella Italia',
        'cuisine': 'Italian',
        'rating': 4.9,
        'deliveryTime': '30-40 min',
        'icon': Icons.restaurant_menu,
        'items': ['Pasta', 'Risotto', 'Tiramisu'],
      },
      {
        'name': 'Trattoria Roma',
        'cuisine': 'Italian',
        'rating': 4.7,
        'deliveryTime': '25-35 min',
        'icon': Icons.restaurant_menu,
        'items': ['Pasta', 'Pizza', 'Gelato'],
      },
    ],
    'Japanese': [
      {
        'name': 'Sushi Express',
        'cuisine': 'Japanese',
        'rating': 4.9,
        'deliveryTime': '30-40 min',
        'icon': Icons.set_meal,
        'items': ['Sushi', 'Ramen', 'Teriyaki'],
      },
      {
        'name': 'Tokyo Sushi',
        'cuisine': 'Japanese',
        'rating': 4.8,
        'deliveryTime': '35-45 min',
        'icon': Icons.set_meal,
        'items': ['Sushi', 'Sashimi', 'Miso Soup'],
      },
    ],
    'Mediterranean': [
      {
        'name': 'Mediterranean Delight',
        'cuisine': 'Mediterranean',
        'rating': 4.7,
        'deliveryTime': '15-25 min',
        'icon': Icons.restaurant_menu,
        'items': ['Shawarma', 'Kebab', 'Tabbouleh'],
      },
    ],
  };

  List<String> get _categories {
    final cats = _restaurantsByCategory.keys.toList();
    return ['All', ...cats];
  }
  
  List<Map<String, dynamic>> get _filteredRestaurants {
    if (_restaurantsByCategory.isEmpty) {
      // Use fallback if Firestore data not loaded yet
      if (_selectedCategory == 'All') {
        return _fallbackRestaurants.values.expand((list) => list).toList();
      }
      return _fallbackRestaurants[_selectedCategory] ?? [];
    }
    
    if (_selectedCategory == 'All') {
      return _restaurantsByCategory.values.expand((list) => list).toList();
    }
    return _restaurantsByCategory[_selectedCategory] ?? [];
  }

  // Get recommended restaurants (top rated)
  List<Map<String, dynamic>> get _recommendedRestaurants {
    final allRestaurants = _restaurantsByCategory.isEmpty
        ? _fallbackRestaurants.values.expand((list) => list).toList()
        : _restaurantsByCategory.values.expand((list) => list).toList();
    
    if (allRestaurants.isEmpty) return [];
    
    // Sort by rating and return top 3
    allRestaurants.sort((a, b) {
      final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
      final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
    
    return allRestaurants.take(3).toList();
  }
  
  // Get restaurant data by name
  Map<String, dynamic>? _getRestaurantByName(String name) {
    final allRestaurants = _restaurantsByCategory.isEmpty
        ? _fallbackRestaurants.values.expand((list) => list).toList()
        : _restaurantsByCategory.values.expand((list) => list).toList();
    try {
      return allRestaurants.firstWhere(
        (restaurant) => (restaurant['name'] as String?)?.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get menu items for a restaurant (from Firestore or fallback)
  Future<List<Map<String, dynamic>>> _getMenuItems(String restaurantId, String restaurantName) async {
    // Try to get menu items from Firestore first
    final menuItems = await _firebaseService.getRestaurantMenuItems(restaurantId);
    if (menuItems.isNotEmpty) {
      return menuItems;
    }
    
    // Fallback: Generate menu items based on restaurant name/category
    final restaurant = _getRestaurantByName(restaurantName);
    if (restaurant == null) return [];
    
    final itemCategories = restaurant['items'] as List<dynamic>?;
    if (itemCategories == null) return [];
    
    final generatedItems = <Map<String, dynamic>>[];
    for (var category in itemCategories) {
      final categoryStr = category.toString().toLowerCase();
      switch (categoryStr) {
        case 'pizza':
          generatedItems.addAll([
            {'name': 'Margherita Pizza', 'description': 'Classic tomato, mozzarella, and basil', 'price': 12.99, 'category': 'Pizza'},
            {'name': 'Pepperoni Pizza', 'description': 'Pepperoni, mozzarella, and tomato sauce', 'price': 14.99, 'category': 'Pizza'},
            {'name': 'BBQ Chicken Pizza', 'description': 'BBQ chicken, red onions, and cilantro', 'price': 16.99, 'category': 'Pizza'},
          ]);
          break;
        case 'shawarma':
          generatedItems.addAll([
            {'name': 'Chicken Shawarma Wrap', 'description': 'Tender chicken with tahini and pickles', 'price': 8.99, 'category': 'Shawarma'},
            {'name': 'Beef Shawarma Plate', 'description': 'Spiced beef with rice and salad', 'price': 14.99, 'category': 'Shawarma'},
            {'name': 'Shawarma Sandwich', 'description': 'Chicken or beef shawarma in pita bread', 'price': 7.99, 'category': 'Shawarma'},
          ]);
          break;
        case 'burgers':
          generatedItems.addAll([
            {'name': 'Classic Burger', 'description': 'Beef patty, lettuce, tomato, and special sauce', 'price': 9.99, 'category': 'Burgers'},
            {'name': 'Cheeseburger', 'description': 'Beef patty with cheese, pickles, and onions', 'price': 10.99, 'category': 'Burgers'},
            {'name': 'BBQ Burger', 'description': 'Beef patty with BBQ sauce and crispy onions', 'price': 11.99, 'category': 'Burgers'},
          ]);
          break;
        case 'pasta':
          generatedItems.addAll([
            {'name': 'Spaghetti Carbonara', 'description': 'Creamy pasta with bacon and parmesan', 'price': 13.99, 'category': 'Pasta'},
            {'name': 'Fettuccine Alfredo', 'description': 'Creamy alfredo sauce with parmesan', 'price': 12.99, 'category': 'Pasta'},
            {'name': 'Penne Arrabbiata', 'description': 'Spicy tomato sauce with garlic', 'price': 11.99, 'category': 'Pasta'},
          ]);
          break;
        case 'sushi':
          generatedItems.addAll([
            {'name': 'Salmon Roll', 'description': 'Fresh salmon with rice and nori', 'price': 8.99, 'category': 'Sushi'},
            {'name': 'California Roll', 'description': 'Crab, avocado, and cucumber', 'price': 7.99, 'category': 'Sushi'},
            {'name': 'Dragon Roll', 'description': 'Eel and avocado topped with eel sauce', 'price': 12.99, 'category': 'Sushi'},
          ]);
          break;
        default:
          generatedItems.add({
            'name': category.toString(),
            'description': 'Delicious ${category.toString()}',
            'price': 9.99,
            'category': category.toString(),
          });
      }
    }
    
    return generatedItems;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _cartService = CartService();
    _orderService = OrderService();
    _favoritesService = FavoritesService();
    
    // Initialize notification service
    _notificationService.initialize();
    
    // Check subscription status first
    _checkSubscriptionStatus();
    
    // Load restaurants from Firestore
    _loadRestaurantsFromFirestore();
    
    // Initialize voice service
    _voiceService = VoiceService();
    _voiceService.initialize().then((initialized) {
      if (initialized && mounted) {
        _setupVoiceCallbacks();
      }
    });
    
    // Initialize OpenAI service
    _openAIService = OpenAIService();
    _openAIService.initialize().then((hasApiKey) {
      if (!hasApiKey && mounted) {
        // Show API key setup dialog on first use
        _showApiKeyDialog();
      }
    });
    
    // Listen to cart changes
    _cartService.addListener(_onCartChanged);
    
    // Listen to order changes
    _orderService.addListener(_onOrderChanged);
    
    // Add initial AI greeting with action buttons
    _messages.add(Message(
      text: "",
      isAI: true,
      timestamp: DateTime.now(),
      showQuickActions: true,
    ));
    _setupCardAnimations();
    
    // Rotate promotions every 5 seconds
    _startPromotionRotation();
    
    // Give initial voice greeting
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _voiceService.speak("Welcome to ChatMeal! I'm your AI food ordering assistant. Just tell me what you'd like to eat, and I'll help you find restaurants, browse menus, and place your order. For example, say 'I want pizza' or 'Show me Italian restaurants'. Everything is voice-controlled - just speak naturally!");
      }
    });
  }
  
  /// Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    try {
      final status = await _subscriptionService.checkSubscriptionStatus();
      if (mounted) {
        setState(() {
          _hasActiveSubscription = status.hasSubscription;
        });
        
        if (!status.hasSubscription) {
          // Show subscription required dialog
          _showSubscriptionRequiredDialog(status.message);
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
    }
  }
  
  /// Load restaurants from Firestore
  void _loadRestaurantsFromFirestore() {
    setState(() {
      _isLoadingRestaurants = true;
    });
    
    _firebaseService.getActiveRestaurants().listen((restaurants) {
      if (mounted) {
        setState(() {
          _firestoreRestaurants = restaurants;
          _isLoadingRestaurants = false;
          
          // Group restaurants by category
          _restaurantsByCategory = {};
          for (var restaurant in restaurants) {
            final category = restaurant['category'] as String? ?? 
                            restaurant['cuisine'] as String? ?? 
                            'Other';
            if (!_restaurantsByCategory.containsKey(category)) {
              _restaurantsByCategory[category] = [];
            }
            _restaurantsByCategory[category]!.add(restaurant);
          }
        });
      }
    }, onError: (error) {
      debugPrint('Error loading restaurants: $error');
      if (mounted) {
        setState(() {
          _isLoadingRestaurants = false;
          // Use fallback restaurants if Firestore fails
          _restaurantsByCategory = _fallbackRestaurants;
        });
      }
    });
  }
  
  /// Show subscription required dialog
  void _showSubscriptionRequiredDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Subscription Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to subscription screen
            },
            child: const Text(
              'Subscribe',
              style: TextStyle(color: AppTheme.goldenYellow),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _startPromotionRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _promotions.length > 1) {
        setState(() {
          _currentPromotionIndex = (_currentPromotionIndex + 1) % _promotions.length;
        });
        _startPromotionRotation();
      }
    });
  }

  void _setupCardAnimations() {
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimation,
    );

    _card1Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _card2Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _cardAnimationController.forward();
  }

  void _setupVoiceCallbacks() {
    _voiceService.onResult = (text) {
      if (mounted) {
        _handleVoiceInput(text);
      }
    };
    
    _voiceService.onError = (error) {
      if (mounted) {
        debugPrint('Voice error: $error');
        setState(() {
          _isListening = false;
        });
      }
    };
    
    _voiceService.onListeningStarted = () {
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    };
    
    _voiceService.onListeningStopped = () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    };
    
    _voiceService.onSpeakingStarted = () {
      if (mounted) {
        setState(() {
          // UI will update based on _voiceService.isSpeaking
        });
      }
    };
    
    _voiceService.onSpeakingCompleted = () {
      // After AI finishes speaking, automatically start listening if enabled
      if (_autoListenAfterSpeaking && mounted && !_voiceService.isListening) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _voiceService.startListening();
          }
        });
      }
      _autoListenAfterSpeaking = false; // Reset after use
      if (mounted) {
        setState(() {
          // UI will update based on _voiceService.isSpeaking
        });
      }
    };
  }
  
  void _handleVoiceInput(String text) async {
    if (_isProcessingAI) return;
    
    // Add user message to chat
    setState(() {
      _messages.add(Message(
        text: text,
        isAI: false,
        timestamp: DateTime.now(),
      ));
      // Remove quick actions if present
      if (_messages.length > 1 && _messages[0].showQuickActions) {
        _messages.removeAt(0);
      }
    });
    _scrollToBottom();
    
    // Check if OpenAI is available
    if (!_openAIService.hasApiKey) {
      setState(() {
        _messages.add(Message(
          text: "Please set your OpenAI API key in settings to use AI features.",
          isAI: true,
          timestamp: DateTime.now(),
        ));
      });
      _voiceService.speak("Please set your OpenAI API key in settings to use AI features.");
      _scrollToBottom();
      return;
    }
    
    setState(() {
      _isProcessingAI = true;
    });
    
    // Build comprehensive context with full restaurant data for AI
    final context = await _buildFullContext();
    
    // Get AI response
    final aiResponse = await _openAIService.getChatResponse(
      userMessage: text,
      context: context,
      conversationHistory: _conversationHistory,
    );
    
    setState(() {
      _isProcessingAI = false;
    });
    
    if (aiResponse != null) {
      // Add AI response to chat
      setState(() {
        _messages.add(Message(
          text: aiResponse,
          isAI: true,
          timestamp: DateTime.now(),
        ));
      });
      
      // Update conversation history (keep last 5 messages for context)
      _conversationHistory.add({'role': 'user', 'content': text});
      _conversationHistory.add({'role': 'assistant', 'content': aiResponse});
      if (_conversationHistory.length > 10) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 10);
      }
      
      // Try to extract actions from response
      _processAIResponse(aiResponse, text);
      
      // Enable auto-listening after AI speaks for continuous conversation
      _autoListenAfterSpeaking = true;
      
      // Speak the response (always speak, even if it's an error message)
      _voiceService.speak(aiResponse);
      _scrollToBottom();
    } else {
      // Fallback to simple processing
      _processGeneralVoiceInput(text);
    }
  }
  
  /// Build comprehensive context with full restaurant data for AI
  Future<String> _buildFullContext() async {
    final restaurants = _restaurantsByCategory.isEmpty
        ? _fallbackRestaurants.values.expand((list) => list).toList()
        : _restaurantsByCategory.values.expand((list) => list).toList();
    
    String context = 'IMPORTANT: This is a VOICE-ONLY food ordering app. Users interact entirely through voice conversation with you (ChatGPT). There are NO manual tap interactions - you control everything through voice commands. When users want to browse restaurants, select items, or place orders, they speak to you and you handle it.\n\n';
    
    // Add cart context
    if (_cartService.isNotEmpty) {
      context += 'SHOPPING CART:\n';
      context += 'Items in cart: ${_cartService.itemCount}\n';
      context += 'Total: \$${_cartService.total.toStringAsFixed(2)}\n';
      for (var item in _cartService.items) {
        context += '- ${item.itemName} x${item.quantity} - \$${item.total.toStringAsFixed(2)}\n';
      }
      context += '\n';
    } else {
      context += 'SHOPPING CART: Empty\n\n';
    }
    
    // Add order context
    if (_orderService.activeOrder != null) {
      final order = _orderService.activeOrder!;
      context += 'ACTIVE ORDER:\n';
      context += 'Order ID: ${order.id}\n';
      context += 'Restaurant: ${order.restaurantName}\n';
      context += 'Status: ${order.statusDisplay}\n';
      context += 'Total: \$${order.total.toStringAsFixed(2)}\n\n';
    }
    
    context += 'FULL RESTAURANT DATABASE:\n';
    context += 'Total restaurants: ${restaurants.length}\n\n';
    
    // Add top-rated restaurants summary for quick recommendations
    if (restaurants.isNotEmpty) {
      final sortedByRating = List<Map<String, dynamic>>.from(restaurants);
      sortedByRating.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
      
      context += 'TOP-RATED RESTAURANTS (for recommendations):\n';
      for (var i = 0; i < (sortedByRating.length > 5 ? 5 : sortedByRating.length); i++) {
        final r = sortedByRating[i];
        final name = r['name'] as String? ?? 'Unknown';
        final rating = r['rating'] ?? 0.0;
        final cuisine = r['cuisine'] as String? ?? r['category'] as String? ?? 'Unknown';
        final deliveryTime = r['deliveryTime'] as String? ?? 'N/A';
        context += '${i + 1}. $name - $cuisine (Rating: $rating, Delivery: $deliveryTime)\n';
      }
      context += '\n';
    }
    
    // Group by category for better organization
    final categories = _restaurantsByCategory.isEmpty 
        ? _fallbackRestaurants.keys 
        : _restaurantsByCategory.keys;
    
    for (var category in categories) {
      final categoryRestaurants = _restaurantsByCategory.isEmpty
          ? _fallbackRestaurants[category]!
          : _restaurantsByCategory[category]!;
      
      context += '$category (${categoryRestaurants.length} restaurants):\n';
      for (var r in categoryRestaurants) {
        final restaurantId = r['id'] as String? ?? '';
        final restaurantName = r['name'] as String? ?? 'Unknown';
        final cuisine = r['cuisine'] as String? ?? r['category'] as String? ?? 'Unknown';
        final rating = r['rating'] ?? 0.0;
        final deliveryTime = r['deliveryTime'] as String? ?? 'N/A';
        
        // Get menu items (async, but we'll use a simplified version for context)
        final menuItems = r['menuItems'] as List<dynamic>?;
        String menuText = 'Menu items available';
        if (menuItems != null && menuItems.isNotEmpty) {
          menuText = menuItems.take(5).map((item) {
            final itemMap = item as Map<String, dynamic>;
            final name = itemMap['name'] as String? ?? 'Item';
            final price = itemMap['price'] ?? 0.0;
            return '$name (\$${price.toStringAsFixed(2)})';
          }).join(', ');
          if (menuItems.length > 5) {
            menuText += ' and ${menuItems.length - 5} more';
          }
        }
        
        context += '- $restaurantName ($cuisine, Rating: $rating, Delivery: $deliveryTime)\n';
        context += '  Menu: $menuText\n';
      }
      context += '\n';
    }
    
    // Add current state
    if (_selectedRestaurant != null) {
      final restaurant = _getRestaurantByName(_selectedRestaurant!);
      if (restaurant != null) {
        final restaurantId = restaurant['id'] as String? ?? '';
        final menuItems = await _getMenuItems(restaurantId, _selectedRestaurant!);
        context += '\nCURRENT STATE: User is viewing menu for $_selectedRestaurant.\n';
        if (menuItems.isNotEmpty) {
          context += 'Menu items: ${menuItems.take(10).map((item) => '${item['name']} - \$${item['price']}').join(', ')}\n';
        }
      }
    } else if (_showRestaurants) {
      context += '\nCURRENT STATE: User is browsing restaurants list.\n';
    } else {
      context += '\nCURRENT STATE: User is in main chat view.\n';
    }
    
    return context;
  }
  
  /// Get category for a restaurant
  String _getRestaurantCategory(String restaurantName) {
    final restaurants = _restaurantsByCategory.isEmpty 
        ? _fallbackRestaurants 
        : _restaurantsByCategory;
    
    for (var entry in restaurants.entries) {
      if (entry.value.any((r) => (r['name'] as String?)?.toLowerCase() == restaurantName.toLowerCase())) {
        return entry.key;
      }
    }
    return 'Unknown';
  }
  
  /// Process AI response and extract intelligent actions
  void _processAIResponse(String aiResponse, String userInput) {
    final lowerResponse = aiResponse.toLowerCase();
    final lowerInput = userInput.toLowerCase();
    
    // Handle cart commands
    _processCartCommands(lowerInput, lowerResponse);
    
    // Handle order commands
    _processOrderCommands(lowerInput, lowerResponse);
    
    // Handle favorites commands
    _processFavoritesCommands(lowerInput, lowerResponse);
    
    // Action 1: Show restaurants
    if (_shouldShowRestaurants(lowerInput, lowerResponse)) {
      setState(() {
        _showRestaurants = true;
        _selectedCategory = 'All'; // Reset to show all
      });
      return;
    }
    
    // Action 2: Filter by category/cuisine
    final categoryFilter = _extractCategoryFilter(lowerInput, lowerResponse);
    if (categoryFilter != null) {
      setState(() {
        _showRestaurants = true;
        _selectedCategory = categoryFilter;
      });
      return;
    }
    
    // Action 3: Search by rating
    if (_shouldFilterByRating(lowerInput, lowerResponse)) {
      _filterByRating(lowerInput);
      return;
    }
    
    // Action 4: Search by delivery time
    if (_shouldFilterByDeliveryTime(lowerInput, lowerResponse)) {
      _filterByDeliveryTime(lowerInput);
      return;
    }
    
    // Action 5: Select restaurant by name
    final restaurantName = _extractRestaurantName(lowerInput, lowerResponse);
    if (restaurantName != null) {
      _selectRestaurant(restaurantName);
      return;
    }
    
    // Action 6: Search by menu item
    final menuItemSearch = _extractMenuItemSearch(lowerInput);
    if (menuItemSearch != null) {
      _searchByMenuItem(menuItemSearch);
      return;
    }
  }
  
  /// Process cart-related voice commands
  void _processCartCommands(String lowerInput, String lowerResponse) {
    // Add to cart
    if (lowerInput.contains('add') && (lowerInput.contains('cart') || lowerInput.contains('order'))) {
      _handleAddToCart(lowerInput);
    }
    // View cart
    else if (lowerInput.contains('cart') || lowerInput.contains('what\'s in my') || lowerInput.contains('show my')) {
      _handleShowCart();
    }
    // Remove from cart
    else if (lowerInput.contains('remove') || lowerInput.contains('delete')) {
      _handleRemoveFromCart(lowerInput);
    }
    // Update quantity
    else if (lowerInput.contains('change') || lowerInput.contains('update') || lowerInput.contains('quantity')) {
      _handleUpdateQuantity(lowerInput);
    }
  }
  
  /// Process order-related voice commands
  void _processOrderCommands(String lowerInput, String lowerResponse) {
    // Place order
    if (lowerInput.contains('place') || lowerInput.contains('checkout') || lowerInput.contains('ready to order')) {
      _handlePlaceOrder();
    }
    // Order history
    else if (lowerInput.contains('order history') || lowerInput.contains('my orders') || lowerInput.contains('past orders')) {
      _handleShowOrderHistory();
    }
    // Track order
    else if (lowerInput.contains('where') || lowerInput.contains('track') || lowerInput.contains('status')) {
      _handleTrackOrder();
    }
    // Reorder
    else if (lowerInput.contains('reorder') || lowerInput.contains('same as last')) {
      _handleReorder();
    }
  }
  
  /// Process favorites-related voice commands
  void _processFavoritesCommands(String lowerInput, String lowerResponse) {
    // Save favorite
    if (lowerInput.contains('save') || lowerInput.contains('favorite') || lowerInput.contains('like this')) {
      _handleSaveFavorite();
    }
    // View favorites
    else if (lowerInput.contains('my favorites') || lowerInput.contains('favorite restaurants')) {
      _handleShowFavorites();
    }
  }
  
  bool _shouldShowRestaurants(String lowerInput, String lowerResponse) {
    final triggers = ['browse', 'show restaurant', 'list restaurant', 'restaurants', 
                     'show me', 'let me see', 'display'];
    return triggers.any((trigger) => lowerInput.contains(trigger) || lowerResponse.contains(trigger));
  }
  
  String? _extractCategoryFilter(String lowerInput, String lowerResponse) {
    for (var category in _categories) {
      if (category == 'All') continue;
      final lowerCategory = category.toLowerCase();
      if (lowerInput.contains(lowerCategory) || lowerResponse.contains(lowerCategory)) {
        return category;
      }
    }
    
    // Also check for cuisine types
    final cuisineMap = {
      'lebanese': 'Lebanese',
      'italian': 'Italian',
      'japanese': 'Japanese',
      'pizza': 'Pizza',
      'burger': 'Burger',
      'mediterranean': 'Mediterranean',
    };
    
    for (var entry in cuisineMap.entries) {
      if (lowerInput.contains(entry.key) || lowerResponse.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  bool _shouldFilterByRating(String lowerInput, String lowerResponse) {
    return lowerInput.contains('rating') || lowerInput.contains('star') || 
           lowerInput.contains('best') || lowerInput.contains('top rated') ||
           lowerInput.contains('highest') || lowerResponse.contains('rating');
  }
  
  void _filterByRating(String lowerInput) {
    final allRestaurants = _restaurantsByCategory.values.expand((list) => list).toList();
    
    // Sort by rating
    allRestaurants.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    
    // Filter based on input
    List<Map<String, dynamic>> filtered = [];
    if (lowerInput.contains('above') || lowerInput.contains('over')) {
      // Extract number if mentioned
      final numbers = RegExp(r'(\d+\.?\d*)').allMatches(lowerInput);
      if (numbers.isNotEmpty) {
        final minRating = double.tryParse(numbers.first.group(1) ?? '4.0') ?? 4.0;
        filtered = allRestaurants.where((r) => (r['rating'] as double) >= minRating).toList();
      } else {
        filtered = allRestaurants.where((r) => (r['rating'] as double) >= 4.5).toList();
      }
    } else {
      // Just show top rated
      filtered = allRestaurants.take(5).toList();
    }
    
    if (filtered.isNotEmpty) {
      setState(() {
        _showRestaurants = true;
        _selectedCategory = 'All';
        // Store filtered results (you might want to add a filtered restaurants list)
      });
    }
  }
  
  bool _shouldFilterByDeliveryTime(String lowerInput, String lowerResponse) {
    return lowerInput.contains('delivery') || lowerInput.contains('fast') || 
           lowerInput.contains('quick') || lowerInput.contains('time') ||
           lowerResponse.contains('delivery');
  }
  
  void _filterByDeliveryTime(String lowerInput) {
    setState(() {
      _showRestaurants = true;
      _selectedCategory = 'All';
      // You can add delivery time filtering logic here
    });
  }
  
  String? _extractRestaurantName(String lowerInput, String lowerResponse) {
    final allRestaurants = _restaurantsByCategory.values.expand((list) => list).toList();
    
    // Try exact match first
    for (var restaurant in allRestaurants) {
      final name = (restaurant['name'] as String).toLowerCase();
      if (lowerInput.contains(name) || lowerResponse.contains(name)) {
        return restaurant['name'] as String;
      }
    }
    
    // Try partial match
    for (var restaurant in allRestaurants) {
      final name = (restaurant['name'] as String).toLowerCase();
      final words = name.split(' ');
      for (var word in words) {
        if (word.length > 3 && (lowerInput.contains(word) || lowerResponse.contains(word))) {
          return restaurant['name'] as String;
        }
      }
    }
    
    return null;
  }
  
  String? _extractMenuItemSearch(String lowerInput) {
    final menuKeywords = ['shawarma', 'pizza', 'burger', 'pasta', 'sushi', 
                          'falafel', 'kebab', 'ramen', 'sashimi'];
    for (var keyword in menuKeywords) {
      if (lowerInput.contains(keyword)) {
        return keyword;
      }
    }
    return null;
  }
  
  void _searchByMenuItem(String menuItem) {
    final allRestaurants = _restaurantsByCategory.values.expand((list) => list).toList();
    final matchingRestaurants = allRestaurants.where((r) {
      final items = r['items'] as List<String>;
      return items.any((item) => item.toLowerCase().contains(menuItem.toLowerCase()));
    }).toList();
    
    if (matchingRestaurants.isNotEmpty) {
      setState(() {
        _showRestaurants = true;
        _selectedCategory = 'All';
        // You can store matching restaurants for display
      });
    }
  }
  
  void _processGeneralVoiceInput(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('browse') || lowerText.contains('restaurant') || lowerText.contains('show restaurant')) {
      setState(() {
        _showRestaurants = true;
      });
      _voiceService.speak("Here are the restaurants. You can browse through them and tap on one to start ordering.");
    } else if (lowerText.contains('order') || lowerText.contains('food') || lowerText.contains('hungry')) {
      _voiceService.speak("I'd be happy to help you order! Would you like to browse restaurants or tell me what you're craving?");
    } else {
      _voiceService.speak("I'm here to help you order food. You can say 'browse restaurants' to see options, or tell me what you're craving.");
    }
  }
  
  void _processRestaurantSelection(String text) {
    // Find restaurant by name
    final allRestaurants = _restaurantsByCategory.values.expand((list) => list).toList();
    final lowerText = text.toLowerCase();
    
    for (var restaurant in allRestaurants) {
      final name = (restaurant['name'] as String).toLowerCase();
      if (lowerText.contains(name)) {
        _selectRestaurant(restaurant['name'] as String);
        return;
      }
    }
    
    _voiceService.speak("I couldn't find that restaurant. Please tap on a restaurant from the list, or try saying the name again.");
  }
  
  void _processOrderVoiceInput(String text) {
    // Process order - for now just acknowledge
    _voiceService.speak("Got it! You said: $text. I'll help you with that order from $_selectedRestaurant.");
    // TODO: Process the actual order details
  }
  
  // ==================== CART HANDLERS ====================
  
  Future<void> _handleAddToCart(String userInput) async {
    if (_selectedRestaurantData == null) {
      _voiceService.speak("Please select a restaurant first before adding items to cart.");
      return;
    }
    
    // Extract item name and quantity from user input
    // This is simplified - in production, use NLP to extract better
    final words = userInput.split(' ');
    int quantity = 1;
    String? itemName;
    
    // Try to extract quantity
    for (var i = 0; i < words.length; i++) {
      final num = int.tryParse(words[i]);
      if (num != null && num > 0) {
        quantity = num;
      }
      if (words[i] == 'pizza' || words[i] == 'burger' || words[i] == 'shawarma' || words[i].contains('item')) {
        itemName = words.sublist(i).join(' ');
        break;
      }
    }
    
    if (itemName == null) {
      _voiceService.speak("I couldn't identify the item you want to add. Please try again, for example: 'add pizza to cart' or 'I want 2 burgers'.");
      return;
    }
    
    // Get menu items and find matching item
    final menuItems = await _getMenuItems(
      _selectedRestaurantData!['id'] as String? ?? '',
      _selectedRestaurantData!['name'] as String? ?? '',
    );
    
    final matchedItem = menuItems.firstWhere(
      (item) => (item['name'] as String?)?.toLowerCase().contains(itemName!.toLowerCase()) ?? false,
      orElse: () => <String, dynamic>{},
    );
    
    if (matchedItem.isEmpty) {
      _voiceService.speak("I couldn't find that item on the menu. Please try a different item name.");
      return;
    }
    
    // Add to cart
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantId: _selectedRestaurantData!['id'] as String? ?? '',
      restaurantName: _selectedRestaurantData!['name'] as String? ?? '',
      itemName: matchedItem['name'] as String,
      itemDescription: matchedItem['description'] as String? ?? '',
      price: (matchedItem['price'] as num).toDouble(),
      quantity: quantity,
    );
    
    await _cartService.addItem(cartItem);
    _voiceService.speak("Added $quantity ${matchedItem['name']} to your cart. Your cart total is now \$${_cartService.total.toStringAsFixed(2)}.");
  }
  
  void _handleShowCart() {
    if (_cartService.isEmpty) {
      _voiceService.speak("Your cart is empty. Add some items to get started!");
      return;
    }
    
    final cartSummary = StringBuffer("Your cart contains:\n");
    for (var item in _cartService.items) {
      cartSummary.writeln("${item.quantity}x ${item.itemName} - \$${item.total.toStringAsFixed(2)}");
    }
    cartSummary.writeln("Total: \$${_cartService.total.toStringAsFixed(2)}");
    
    _voiceService.speak(cartSummary.toString());
  }
  
  Future<void> _handleRemoveFromCart(String userInput) async {
    // Extract item name from input
    final words = userInput.split(' ');
    String? itemName;
    
    for (var i = 0; i < words.length; i++) {
      if (words[i] == 'remove' || words[i] == 'delete') {
        itemName = words.sublist(i + 1).join(' ');
        break;
      }
    }
    
    if (itemName == null) return;
    
    final itemToRemove = _cartService.items.firstWhere(
      (item) => item.itemName.toLowerCase().contains(itemName!.toLowerCase()),
      orElse: () => _cartService.items.first,
    );
    
    await _cartService.removeItem(itemToRemove.id);
    _voiceService.speak("Removed ${itemToRemove.itemName} from your cart.");
  }
  
  Future<void> _handleUpdateQuantity(String userInput) async {
    // Extract item name and new quantity
    // Simplified - in production use better NLP
    final words = userInput.split(' ');
    int? newQuantity;
    String? itemName;
    
    for (var i = 0; i < words.length; i++) {
      final num = int.tryParse(words[i]);
      if (num != null && num > 0) {
        newQuantity = num;
      }
      if (words[i] == 'to' && i < words.length - 1) {
        newQuantity = int.tryParse(words[i + 1]);
      }
      if (words.contains('pizza') || words.contains('burger')) {
        itemName = words.firstWhere((w) => w == 'pizza' || w == 'burger');
      }
    }
    
    if (itemName == null || newQuantity == null) return;
    
    final item = _cartService.items.firstWhere(
      (item) => item.itemName.toLowerCase().contains(itemName!),
    );
    
    await _cartService.updateQuantity(item.id, newQuantity);
    _voiceService.speak("Updated ${item.itemName} quantity to $newQuantity.");
  }
  
  // ==================== ORDER HANDLERS ====================
  
  Future<void> _handlePlaceOrder() async {
    if (_cartService.isEmpty) {
      _voiceService.speak("Your cart is empty. Add some items before placing an order.");
      return;
    }
    
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      _voiceService.speak("Please log in to place an order.");
      return;
    }
    
    // For now, use a default address - in production, ask user via voice
    final deliveryAddress = "123 Main St, City, State"; // TODO: Get from user profile
    
    final orderId = await _orderService.createOrder(
      userId: userId,
      cartItems: _cartService.items,
      deliveryAddress: deliveryAddress,
      paymentMethod: 'cash_on_delivery',
    );
    
    if (orderId != null) {
      await _cartService.clear();
      _voiceService.speak("Order placed successfully! Your order ID is $orderId. Payment will be cash on delivery. Estimated delivery time is 30 minutes.");
      
      // Subscribe to order notifications
      await _notificationService.subscribeToOrderNotifications(orderId);
      
      // Add confirmation message to chat
      setState(() {
        _messages.add(Message(
          text: "✓ Order placed successfully! Order ID: $orderId. Payment: Cash on Delivery. Estimated delivery: 30 minutes.",
          isAI: true,
          timestamp: DateTime.now(),
        ));
      });
    } else {
      _voiceService.speak("Sorry, there was an error placing your order. Please try again.");
    }
  }
  
  Future<void> _handleShowOrderHistory() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;
    
    final ordersStream = _orderService.getUserOrdersStream(userId);
    ordersStream.first.then((orders) {
      if (orders.isEmpty) {
        _voiceService.speak("You haven't placed any orders yet.");
        return;
      }
      
      final summary = StringBuffer("Your recent orders:\n");
      for (var i = 0; i < (orders.length > 5 ? 5 : orders.length); i++) {
        final order = orders[i];
        summary.writeln("Order ${order.id.substring(0, 8)} - ${order.restaurantName} - \$${order.total.toStringAsFixed(2)} - ${order.statusDisplay}");
      }
      
      _voiceService.speak(summary.toString());
    });
  }
  
  void _handleTrackOrder() {
    if (_orderService.activeOrder == null) {
      _voiceService.speak("You don't have an active order to track.");
      return;
    }
    
    final order = _orderService.activeOrder!;
    _voiceService.speak("Your order from ${order.restaurantName} is currently ${order.statusDisplay}. Total: \$${order.total.toStringAsFixed(2)}.");
  }
  
  Future<void> _handleReorder() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;
    
    final ordersStream = _orderService.getUserOrdersStream(userId);
    ordersStream.first.then((orders) {
      if (orders.isEmpty) {
        _voiceService.speak("You don't have any previous orders to reorder.");
        return;
      }
      
      final lastOrder = orders.first;
      // For now, just add items back to cart
      // In production, implement full reorder with address confirmation
      _voiceService.speak("I'll help you reorder from ${lastOrder.restaurantName}. Add items to your cart and place the order when ready.");
    });
  }
  
  // ==================== FAVORITES HANDLERS ====================
  
  Future<void> _handleSaveFavorite() async {
    if (_selectedRestaurantData == null) {
      _voiceService.speak("Please select a restaurant first to save it as favorite.");
      return;
    }
    
    final restaurantId = _selectedRestaurantData!['id'] as String? ?? '';
    final restaurantName = _selectedRestaurantData!['name'] as String? ?? '';
    
    if (restaurantId.isEmpty) {
      _voiceService.speak("Unable to save favorite. Restaurant ID is missing.");
      return;
    }
    
    final success = await _favoritesService.addFavorite(restaurantId, restaurantName);
    if (success) {
      _voiceService.speak("Saved $restaurantName to your favorites!");
    } else {
      _voiceService.speak("Sorry, there was an error saving the favorite.");
    }
  }
  
  Future<void> _handleShowFavorites() async {
    final favorites = await _favoritesService.getFavoriteRestaurants();
    if (favorites.isEmpty) {
      _voiceService.speak("You don't have any favorite restaurants yet. Save restaurants you like to access them quickly.");
      return;
    }
    
    final summary = StringBuffer("Your favorite restaurants:\n");
    for (var restaurant in favorites) {
      summary.writeln("${restaurant['name']} - ${restaurant['cuisine'] ?? ''}");
    }
    
    _voiceService.speak(summary.toString());
  }
  
  void _showApiKeyDialog() {
    final apiKeyController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'OpenAI API Key Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use AI features, please enter your OpenAI API key.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.goldenYellow),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Open OpenAI API key page
                // You can add url_launcher here if needed
              },
              child: const Text(
                'Get API Key',
                style: TextStyle(color: AppTheme.goldenYellow),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (apiKeyController.text.isNotEmpty) {
                await _openAIService.setApiKey(apiKeyController.text.trim());
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API key saved successfully!'),
                      backgroundColor: AppTheme.darkTealGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldenYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    _orderService.removeListener(_onOrderChanged);
    _voiceService.dispose();
    _scrollController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }
  
  void _onCartChanged() {
    if (mounted) {
      setState(() {
        // Cart changed, update UI if needed
      });
    }
  }
  
  void _onOrderChanged() {
    if (mounted) {
      setState(() {
        // Order changed, update UI if needed
        if (_orderService.activeOrder != null) {
          final order = _orderService.activeOrder!;
          _activeOrder = ActiveOrder(
            id: order.id,
            restaurantName: order.restaurantName,
            status: _mapOrderStatus(order.status),
            estimatedTime: order.estimatedDeliveryTime != null
                ? '${DateTime.now().difference(order.estimatedDeliveryTime!).inMinutes.abs()} min'
                : '30 min',
            total: order.total,
          );
        } else {
          _activeOrder = null;
        }
      });
    }
  }
  
  OrderStatus _mapOrderStatus(String status) {
    switch (status) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'onTheWay':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      default:
        return OrderStatus.preparing;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (context.mounted) {
      context.go('/auth');
    }
  }

  void _toggleThemeMode() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.toggleTheme();
  }

  void _toggleListening() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      if (_voiceService.isSpeaking) {
        await _voiceService.stopSpeaking();
      }
      await _voiceService.startListening();
    }
  }

  void _selectRestaurant(String restaurantName) {
    // User selected a restaurant - show menu
    final restaurantData = _getRestaurantByName(restaurantName);
    if (restaurantData == null) {
      _voiceService.speak("Sorry, I couldn't find that restaurant. Please try again.");
      return;
    }
    
    setState(() {
      _showRestaurants = false;
      _showMenu = true;
      _selectedRestaurant = restaurantName;
      _selectedRestaurantData = restaurantData;
    });
    
    // AI speaks the response
    _voiceService.speak("Perfect! Here's the menu for $restaurantName. Browse through the items and tell me what you'd like to order.");
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _shouldShowBackButton() {
    // Show back button when viewing restaurants
    if (_showRestaurants) return true;
    
    // Show back button when viewing menu
    if (_showMenu) return true;
    
    // Show back button when in chat view and there are messages beyond the initial quick actions
    if (_messages.isEmpty) return false;
    
    final hasOnlyQuickActions = _messages.length == 1 && 
        _messages[0].showQuickActions && 
        _messages[0].isAI && 
        _messages[0].text.isEmpty;
    
    // Show back button if we have messages beyond just the quick actions
    return !hasOnlyQuickActions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        leading: _shouldShowBackButton()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 24),
                onPressed: () {
                  setState(() {
                    if (_showMenu) {
                      // Go back to restaurants list from menu
                      _showMenu = false;
                      _showRestaurants = true;
                      _selectedRestaurant = null;
                      _selectedRestaurantData = null;
                    } else if (_showRestaurants) {
                      // Go back to home from restaurants
                      _showRestaurants = false;
                      // Reset to initial state with only the two option cards
                      _messages.clear();
                      _messages.add(Message(
                        text: "",
                        isAI: true,
                        timestamp: DateTime.now(),
                        showQuickActions: true,
                      ));
                    } else {
                      // Go back from chat view to initial state
                      // Reset to initial state with only the two option cards
                      _messages.clear();
                      _conversationHistory.clear();
                      _messages.add(Message(
                        text: "",
                        isAI: true,
                        timestamp: DateTime.now(),
                        showQuickActions: true,
                      ));
                    }
                  });
                },
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.goldenYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.black,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppTheme.darkTealGreen,
                  AppTheme.lightTeal,
                  AppTheme.goldenYellow,
                  AppTheme.goldenOrange,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'ChatMeal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white70, size: 28),
            color: Colors.grey[900],
            onSelected: (value) {
              if (value == 'profile') {
                // TODO: Navigate to profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile screen coming soon'),
                    backgroundColor: AppTheme.darkTealGreen,
                  ),
                );
              } else if (value == 'settings') {
                _showApiKeyDialog();
              } else if (value == 'api_key') {
                _showApiKeyDialog();
              } else if (value == 'theme') {
                _toggleThemeMode();
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              final themeService = Provider.of<ThemeService>(context, listen: true);
              return [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Text('Profile', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Text('Settings', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'api_key',
                  child: Row(
                    children: [
                      Icon(Icons.key, color: AppTheme.goldenYellow, size: 20),
                      SizedBox(width: 12),
                      Text('OpenAI API Key', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(
                        themeService.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                        color: AppTheme.goldenYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        themeService.themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Active Order Status Banner (Enhanced with Timeline)
              if (_activeOrder != null) _buildActiveOrderBanner(),
              
              // Shopping Cart Summary
              _buildShoppingCartSummary(),
              
              // Content Area - Restaurants, Menu, or Chat
              Expanded(
                child: _showMenu
                    ? _buildMenuView()
                    : (_showRestaurants
                        ? _buildRestaurantsList()
                        : _buildChatView()),
              ),
            ],
          ),
          
          // Floating Action Button (FAB) for Voice Input
          _buildVoiceFAB(),
        ],
      ),
    );
  }

  Widget _buildRestaurantsList() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.darkTealGreen
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.goldenYellow
                          : Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.goldenYellow
                            : Colors.grey[400],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
              );
            },
          ),
        ),
        
        // Restaurants List
        Expanded(
          child: _selectedCategory == 'All'
              ? _buildGroupedRestaurantsList()
              : _buildSimpleRestaurantsList(),
        ),
      ],
    );
  }

  Widget _buildGroupedRestaurantsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _restaurantsByCategory.length,
      itemBuilder: (context, categoryIndex) {
        final category = _categories[categoryIndex + 1]; // Skip 'All'
        final restaurants = _restaurantsByCategory[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: categoryIndex > 0 ? 24 : 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.darkTealGreen.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lightTeal,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${restaurants.length})',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Restaurants in this category
            ...restaurants.map((restaurant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRestaurantCard(restaurant),
            )),
          ],
        );
      },
    );
  }

  Widget _buildSimpleRestaurantsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRestaurantCard(restaurant),
        );
      },
    );
  }

  Widget _buildMenuView() {
    if (_selectedRestaurantData == null || _selectedRestaurant == null) {
      return const Center(child: Text('No menu available'));
    }
    
    final restaurant = _selectedRestaurantData!;
    final restaurantId = restaurant['id'] as String? ?? '';
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMenuItems(restaurantId, _selectedRestaurant!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error loading menu: ${snapshot.error}'));
        }
        
        final menuItems = snapshot.data ?? [];
        
        return Column(
      children: [
        // Restaurant Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkTealGreen.withValues(alpha: 0.3),
                AppTheme.lightTeal.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.darkTealGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.lightTeal,
                    width: 2,
                  ),
                ),
                child: Icon(
                  restaurant['icon'] as IconData,
                  color: AppTheme.goldenYellow,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant['name'] as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant['cuisine'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.goldenYellow,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant['rating']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant['deliveryTime'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Menu Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${(item['price'] as double).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldenYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.goldenYellow,
                      size: 28,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Order Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              top: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Start voice ordering
                setState(() {
                  _showMenu = false;
                  _autoListenAfterSpeaking = true;
                });
                _voiceService.speak("Perfect! I'm ready to take your order from $_selectedRestaurant. What would you like to order? Just tell me what you'd like.");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldenYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Order with Voice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.darkTealGreen.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTeal,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    restaurant['icon'] as IconData,
                    color: AppTheme.goldenYellow,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant['cuisine'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.goldenYellow,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant['rating']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            color: Colors.grey[500],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant['deliveryTime'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildActiveOrderBanner() {
    if (_activeOrder == null) return const SizedBox.shrink();

    final order = _activeOrder!;
    IconData statusIcon;
    String statusText;
    Color statusColor;

    switch (order.status) {
      case OrderStatus.preparing:
        statusIcon = Icons.restaurant_menu;
        statusText = 'Preparing your order';
        statusColor = AppTheme.goldenYellow;
        break;
      case OrderStatus.onTheWay:
        statusIcon = Icons.delivery_dining;
        statusText = 'On the way';
        statusColor = AppTheme.darkTealGreen;
        break;
      case OrderStatus.delivered:
        statusIcon = Icons.check_circle;
        statusText = 'Delivered';
        statusColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.restaurantName} • ETA: ${order.estimatedTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: statusColor,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Order Progress Timeline
          _buildOrderProgressTimeline(order.status),
        ],
      ),
    );
  }

  Widget _buildOrderProgressTimeline(OrderStatus currentStatus) {
    final steps = [
      {'status': OrderStatus.preparing, 'label': 'Ordered', 'icon': Icons.check_circle_outline},
      {'status': OrderStatus.preparing, 'label': 'Preparing', 'icon': Icons.restaurant_menu},
      {'status': OrderStatus.onTheWay, 'label': 'On the way', 'icon': Icons.delivery_dining},
      {'status': OrderStatus.delivered, 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentStep = 0;
    switch (currentStatus) {
      case OrderStatus.preparing:
        currentStep = 1;
        break;
      case OrderStatus.onTheWay:
        currentStep = 2;
        break;
      case OrderStatus.delivered:
        currentStep = 3;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isCurrent = index == currentStep;
        final step = steps[index];
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? (isCurrent ? AppTheme.goldenYellow : AppTheme.darkTealGreen)
                            : Colors.grey[800],
                        border: Border.all(
                          color: isCompleted
                              ? (isCurrent ? AppTheme.goldenYellow : AppTheme.darkTealGreen)
                              : Colors.grey[700]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        size: 16,
                        color: isCompleted ? Colors.white : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted ? Colors.white70 : Colors.grey[600],
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: index < currentStep
                          ? AppTheme.darkTealGreen
                          : Colors.grey[800],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShoppingCartSummary() {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        if (cartService.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldenYellow.withValues(alpha: 0.2),
                AppTheme.goldenOrange.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldenYellow.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldenYellow.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Trigger voice command to show cart
                _voiceService.speak("Here's your cart. Say 'show my cart' to view details.");
                _handleVoiceInput("show my cart");
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.goldenYellow.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.goldenYellow,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          color: AppTheme.goldenYellow,
                          size: 24,
                        ),
                        if (cartService.itemCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.darkTealGreen,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${cartService.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldenYellow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${cartService.itemCount} ${cartService.itemCount == 1 ? 'item' : 'items'} • \$${cartService.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say "show my cart" or "checkout"',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.goldenYellow,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildPromotionsBanner() {
    if (_promotions.isEmpty) return const SizedBox.shrink();

    final promotion = _promotions[_currentPromotionIndex];
    
    // Check if promotion is expired
    if (promotion.isExpired) {
      // Skip to next promotion
      Future.microtask(() {
        if (mounted && _currentPromotionIndex < _promotions.length - 1) {
          setState(() {
            _currentPromotionIndex = (_currentPromotionIndex + 1) % _promotions.length;
          });
        }
      });
      return const SizedBox.shrink();
    }

    String timeRemainingText = '';
    if (promotion.timeRemaining != null) {
      final duration = promotion.timeRemaining!;
      if (duration.inDays > 0) {
        timeRemainingText = '${duration.inDays}d ${duration.inHours % 24}h left';
      } else if (duration.inHours > 0) {
        timeRemainingText = '${duration.inHours}h ${duration.inMinutes % 60}m left';
      } else {
        timeRemainingText = '${duration.inMinutes}m left';
      }
    }

    String usesText = '';
    if (promotion.maxUses != null && promotion.remainingUses != null) {
      usesText = '${promotion.remainingUses} uses left';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                promotion.color.withValues(alpha: 0.25),
                promotion.color.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: promotion.color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: promotion.color.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: promotion.color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_offer,
                      color: promotion.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: promotion.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          promotion.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[300],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_promotions.length > 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _promotions.length,
                        (index) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentPromotionIndex
                                ? promotion.color
                                : promotion.color.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (timeRemainingText.isNotEmpty || usesText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (timeRemainingText.isNotEmpty) ...[
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: promotion.color.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeRemainingText,
                        style: TextStyle(
                          fontSize: 10,
                          color: promotion.color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (timeRemainingText.isNotEmpty && usesText.isNotEmpty)
                      const SizedBox(width: 12),
                    if (usesText.isNotEmpty) ...[
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: promotion.color.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        usesText,
                        style: TextStyle(
                          fontSize: 10,
                          color: promotion.color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantRecommendations() {
    final recommendations = _recommendedRestaurants;
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.goldenYellow,
                size: 18,
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppTheme.goldenYellow,
                    AppTheme.goldenOrange,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Popular Near You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final restaurant = recommendations[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 10),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.goldenYellow.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldenYellow.withValues(alpha: 0.1),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.goldenYellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.goldenYellow.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              restaurant['icon'] as IconData,
                              color: AppTheme.goldenYellow,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  restaurant['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: AppTheme.goldenYellow,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${restaurant['rating']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.grey[500],
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      restaurant['deliveryTime'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildChatView() {
    // Check if we should show only the quick actions (initial state)
    final hasQuickActionsOnly = _messages.length == 1 && 
        _messages[0].showQuickActions && 
        _messages[0].isAI && 
        _messages[0].text.isEmpty;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey[900]!.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: hasQuickActionsOnly
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Main action cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMessageBubble(_messages[0]),
                  ),
                  // Restaurant Recommendations (after action cards)
                  _buildRestaurantRecommendations(),
                  // Promotions Banner (Enhanced with countdown and usage)
                  _buildPromotionsBanner(),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // Skip the initial quick actions message if there are other messages
                if (message.showQuickActions && message.isAI && message.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildMessageBubble(message);
              },
            ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    // Special case: Show buttons only without chat bubble styling
    if (message.showQuickActions && message.isAI && message.text.isEmpty) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [],
          ),
        ),
      );
    }

    // Regular chat bubble for messages with text
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isAI) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkTealGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.darkTealGreen,
                            AppTheme.lightTeal,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: message.isAI
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (message.isAI && message.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      children: [
                        Text(
                          'ChatMeal',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (message.text.contains('✓') || message.text.contains('Order placed'))
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppTheme.goldenYellow,
                            ),
                          ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: message.isAI
                        ? (message.text.contains('✓') || message.text.contains('Order placed'))
                            ? AppTheme.darkTealGreen.withValues(alpha: 0.4)
                            : Colors.grey[850]
                        : AppTheme.goldenYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: message.isAI
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomRight: message.isAI
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                    ),
                    border: message.isAI
                        ? (message.text.contains('✓') || message.text.contains('Order placed'))
                            ? Border.all(
                                color: AppTheme.goldenYellow.withValues(alpha: 0.5),
                                width: 1.5,
                              )
                            : null
                        : Border.all(
                            color: AppTheme.goldenYellow.withValues(alpha: 0.3),
                            width: 1,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: message.isAI ? FontWeight.w400 : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (!message.isAI) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.goldenYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Floating Action Button for Voice Input
  Widget _buildVoiceFAB() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: GestureDetector(
        onLongPressStart: (_) {
          // Start listening on long press
          if (!_voiceService.isListening && !_voiceService.isSpeaking) {
            _toggleListening();
          }
        },
        onLongPressEnd: (_) {
          // Stop listening when released
          if (_voiceService.isListening) {
            _voiceService.stopListening();
          }
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isListening
                  ? [
                      AppTheme.darkTealGreen,
                      AppTheme.lightTeal,
                    ]
                  : [
                      AppTheme.goldenYellow,
                      AppTheme.goldenOrange,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isListening
                        ? AppTheme.darkTealGreen
                        : AppTheme.goldenYellow)
                    .withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: (_isListening
                        ? AppTheme.lightTeal
                        : AppTheme.goldenOrange)
                    .withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isListening
                  ? () {
                      _voiceService.stopListening();
                    }
                  : () {
                      if (_voiceService.isSpeaking) {
                        _voiceService.stopSpeaking();
                      }
                      _toggleListening();
                    },
              borderRadius: BorderRadius.circular(36),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Microphone icon
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
