import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (context.mounted) {
      // Redirect to auth screen (signup form) after logout
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.darkTealGreen,
        elevation: 0,
        title: const Text('ChatMeal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon')),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            color: Colors.grey[900],
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // TODO: Navigate to profile
                },
              ),
              PopupMenuItem(
                child: const Text('Orders', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // TODO: Navigate to orders
                },
              ),
              PopupMenuItem(
                child: const Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // TODO: Navigate to settings
                },
              ),
              PopupMenuItem(
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice order button (prominent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkTealGreen, AppTheme.darkTealGreen.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.goldenYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        size: 40,
                        color: AppTheme.goldenYellow,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Order with Your Voice',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the mic to start ordering',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Open voice ordering interface
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voice ordering feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.mic, color: Colors.black),
                      label: const Text(
                        'Start Voice Order',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldenYellow,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Section title
              const Text(
                'Nearby Restaurants',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Restaurant list placeholder
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No restaurants yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Restaurant listings coming soon!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Quick voice order button
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice ordering feature coming soon!')),
          );
        },
        backgroundColor: AppTheme.goldenYellow,
        child: const Icon(Icons.mic, color: Colors.black),
      ),
    );
  }
}
