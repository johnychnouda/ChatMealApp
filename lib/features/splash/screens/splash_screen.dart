import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Ensure navigation happens after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNextScreen();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.splashAnimationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      // Wait for splash duration (3 seconds)
      await Future.delayed(AppConstants.splashDuration);
      
      if (!mounted) {
        debugPrint('Splash: Widget not mounted, skipping navigation');
        return;
      }

      debugPrint('Splash: Checking onboarding status...');
      // Check if user has completed onboarding
      final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();
      debugPrint('Splash: Onboarding completed: $hasCompletedOnboarding');
      
      if (!mounted) {
        debugPrint('Splash: Widget not mounted after auth check');
        return;
      }
      
      if (!hasCompletedOnboarding) {
        // Navigate to onboarding
        debugPrint('Splash: Navigating to onboarding');
        if (mounted) {
          context.go('/onboarding');
        }
      } else {
        // Check if user is logged in
        debugPrint('Splash: Checking login status...');
        final isLoggedIn = await _authService.isLoggedIn();
        debugPrint('Splash: Is logged in: $isLoggedIn');
        
        if (!mounted) {
          debugPrint('Splash: Widget not mounted after login check');
          return;
        }
        
        if (isLoggedIn) {
          // Navigate to home
          debugPrint('Splash: Navigating to home');
          if (mounted) {
            context.go('/home');
          }
        } else {
          // Check if user is registered (auto-login)
          debugPrint('Splash: Checking for registered user...');
          final autoLoggedIn = await _authService.autoLoginIfRegistered();
          if (autoLoggedIn) {
            debugPrint('Splash: Auto-logged in, navigating to home');
            if (mounted) {
              context.go('/home');
            }
          } else {
            // New user - go directly to signup
            debugPrint('Splash: New user, navigating to auth');
            if (mounted) {
              context.go('/auth');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      // If there's an error, try to navigate to onboarding as fallback
      debugPrint('Splash: Navigation error: $e');
      debugPrint('Splash: Stack trace: $stackTrace');
      if (mounted) {
        try {
          debugPrint('Splash: Attempting fallback navigation to onboarding');
          context.go('/onboarding');
        } catch (e2) {
          debugPrint('Splash: Fallback navigation also failed: $e2');
          // Last resort: try to show an error dialog or default screen
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Navigation Error'),
                content: Text('Error: $e\n\nPlease restart the app.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      try {
                        context.go('/onboarding');
                      } catch (_) {}
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Allow tap to manually navigate after animation completes (fallback)
        onTap: () {
          if (_animationController.isCompleted) {
            debugPrint('Splash: Manual tap detected, navigating to onboarding');
            context.go('/onboarding');
          }
        },
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Logo
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image doesn't exist yet
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A4D4D),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 100,
                                color: Color(0xFFF4A460),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // App Name with fade-in animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tagline
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: const Text(
                        AppConstants.appTagline,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFF4A460),
                          letterSpacing: 1,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Loading indicator
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF4A460),
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
