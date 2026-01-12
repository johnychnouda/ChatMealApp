import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';

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
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.description}',
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
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
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          letterSpacing: 0.3,
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
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _showRestaurants = false; // Default to chat view
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  String _selectedCategory = 'All';
  late AnimationController _cardAnimationController;
  late Animation<double> _card1Animation;
  late Animation<double> _card2Animation;

  // Sample restaurants grouped by category
  final Map<String, List<Map<String, dynamic>>> _restaurantsByCategory = {
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

  List<String> get _categories => ['All', ..._restaurantsByCategory.keys.toList()];
  
  List<Map<String, dynamic>> get _filteredRestaurants {
    if (_selectedCategory == 'All') {
      return _restaurantsByCategory.values.expand((list) => list).toList();
    }
    return _restaurantsByCategory[_selectedCategory] ?? [];
  }

  @override
  void initState() {
    super.initState();
    // Add initial AI greeting with action buttons
    _messages.add(Message(
      text: "",
      isAI: true,
      timestamp: DateTime.now(),
      showQuickActions: true,
    ));
    _setupCardAnimations();
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

  @override
  void dispose() {
    _scrollController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (context.mounted) {
      context.go('/auth');
    }
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _showRestaurants = false; // Switch to chat view when listening
      }
    });
    
    if (_isListening) {
      // TODO: Start voice recognition
      // Simulate user speaking
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isListening = false;
            // Add user message
            _messages.add(Message(
              text: "I want to order shawarma",
              isAI: false,
              timestamp: DateTime.now(),
              showQuickActions: false,
            ));
            _scrollToBottom();
            
            // AI suggests restaurants
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _messages.add(Message(
                    text: "Great choice! 🥙 Here are restaurants that serve shawarma:\n\n📍 Shawarma King (4.9⭐)\n   ⏱️ 20-30 min • Middle Eastern\n\n📍 Mediterranean Delight (4.7⭐)\n   ⏱️ 15-25 min • Mediterranean\n\nWhich one would you like to order from?",
                    isAI: true,
                    timestamp: DateTime.now(),
                    showQuickActions: false,
                  ));
                  _scrollToBottom();
                });
              }
            });
          });
        }
      });
    } else {
      // TODO: Stop voice recognition
    }
  }

  void _selectRestaurant(String restaurantName) {
    // User selected a restaurant - switch to voice ordering
    setState(() {
      _showRestaurants = false;
      _messages.add(Message(
        text: "I'll order from $restaurantName",
        isAI: false,
        timestamp: DateTime.now(),
        showQuickActions: false,
      ));
      _scrollToBottom();
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _messages.add(Message(
              text: "Perfect! 🎉\n\nNow tell me what you'd like to order from $restaurantName. For example: \"I want 2 shawarma sandwiches\"",
              isAI: true,
              timestamp: DateTime.now(),
              showQuickActions: false,
            ));
            _scrollToBottom();
          });
        }
      });
    });
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
                    _showRestaurants = false;
                    // Reset to initial state with only the two option cards
                    _messages.clear();
                    _messages.add(Message(
                      text: "",
                      isAI: true,
                      timestamp: DateTime.now(),
                      showQuickActions: true,
                    ));
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
                // TODO: Navigate to settings screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings screen coming soon'),
                    backgroundColor: AppTheme.darkTealGreen,
                  ),
                );
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
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
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Content Area - Restaurants or Chat
          Expanded(
            child: _showRestaurants
                ? _buildRestaurantsList()
                : _buildChatView(),
          ),
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
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
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
        child: InkWell(
          onTap: () => _selectRestaurant(restaurant['name'] as String),
          borderRadius: BorderRadius.circular(16),
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
      ),
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
          ? ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: 1,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[0]);
              },
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              // Welcome Hero Section
              Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppTheme.goldenOrange,
                        AppTheme.goldenYellow,
                        AppTheme.lightTeal,
                        AppTheme.darkTealGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'What would you like to do?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Browse Restaurants Card
              AnimatedBuilder(
                animation: _cardAnimationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _card1Animation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _card1Animation.value)),
                      child: Transform.scale(
                        scale: 0.95 + (0.05 * _card1Animation.value),
                        child: _ActionCard(
                          title: 'Browse Restaurants',
                          description: 'Explore menus and discover amazing local restaurants',
                          icon: Icons.restaurant_menu_rounded,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldenOrange,
                              AppTheme.goldenYellow,
                            ],
                          ),
                          shadowColor: AppTheme.goldenYellow,
                          textColor: AppTheme.darkTealGreen,
                          iconColor: AppTheme.darkTealGreen,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _showRestaurants = true;
                              _messages.add(Message(
                                text: "Browse restaurants",
                                isAI: false,
                                timestamp: DateTime.now(),
                              ));
                              _scrollToBottom();
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  setState(() {
                                    _messages.add(Message(
                                      text: "Great! Browse through the restaurants above and tap on any restaurant to start ordering. 🍽️",
                                      isAI: true,
                                      timestamp: DateTime.now(),
                                    ));
                                    _scrollToBottom();
                                  });
                                }
                              });
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Speak with AI Card
              AnimatedBuilder(
                animation: _cardAnimationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _card2Animation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _card2Animation.value)),
                      child: Transform.scale(
                        scale: 0.95 + (0.05 * _card2Animation.value),
                        child: _ActionCard(
                          title: 'Speak with AI',
                          description: 'Order naturally using your voice - just tell me what you crave',
                          icon: Icons.record_voice_over_rounded,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.darkTealGreen,
                              AppTheme.lightTeal,
                            ],
                          ),
                          shadowColor: AppTheme.darkTealGreen,
                          textColor: AppTheme.goldenYellow,
                          iconColor: AppTheme.goldenYellow,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _messages.add(Message(
                                text: "Speak with AI agent",
                                isAI: false,
                                timestamp: DateTime.now(),
                              ));
                              _scrollToBottom();
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  setState(() {
                                    _messages.add(Message(
                                      text: "Perfect! 🎤\n\nJust tell me what you'd like to eat, and I'll help you find the best restaurants and place your order. For example, say \"I want shawarma\" or \"I'm craving pizza\".",
                                      isAI: true,
                                      timestamp: DateTime.now(),
                                    ));
                                    _scrollToBottom();
                                  });
                                }
                              });
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
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
}
