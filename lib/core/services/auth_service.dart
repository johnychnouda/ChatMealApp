import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

/// Service to manage authentication and onboarding state
class AuthService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _registeredUsersKey = 'registered_users';
  static const String _skipAutoLoginKey = 'skip_auto_login';
  static const String _isGuestModeKey = 'is_guest_mode';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // In-memory fallback storage (used when SharedPreferences fails)
  static final Map<String, dynamic> _memoryStorage = {};

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      // Fallback to in-memory storage
      return _memoryStorage[_onboardingCompletedKey] as bool? ?? false;
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      _memoryStorage[_onboardingCompletedKey] = true; // Update memory cache
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      // Fallback to in-memory storage
      _memoryStorage[_onboardingCompletedKey] = true;
    }
  }

  /// Check if user is logged in (using Firebase Auth)
  Future<bool> isLoggedIn() async {
    try {
      // Check Firebase Auth first
      final user = _auth.currentUser;
      if (user != null) {
        return true;
      }
      // Fallback to SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      debugPrint('AuthService: Error checking login status: $e');
      return _memoryStorage[_isLoggedInKey] as bool? ?? false;
    }
  }

  /// Login user
  Future<void> login(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, userId);
      // Clear skip auto-login flag when user logs in
      await prefs.setBool(_skipAutoLoginKey, false);
      _memoryStorage[_isLoggedInKey] = true; // Update memory cache
      _memoryStorage[_userIdKey] = userId;
      _memoryStorage[_skipAutoLoginKey] = false;
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      // Fallback to in-memory storage
      _memoryStorage[_isLoggedInKey] = true;
      _memoryStorage[_userIdKey] = userId;
      _memoryStorage[_skipAutoLoginKey] = false;
    }
  }

  /// Sign up with email and password
  Future<String?> signUpWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Create user document in Firestore
        await _firebaseService.createOrUpdateUser(
          userId: user.uid,
          email: user.email ?? email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        
        // Also update SharedPreferences for backward compatibility
        await login(user.uid);
        await registerUser(email);
        
        debugPrint('Email sign-up successful: $email');
        return user.uid;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during sign-up: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Email sign-up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Update user document in Firestore (in case it doesn't exist)
        await _firebaseService.createOrUpdateUser(
          userId: user.uid,
          email: user.email ?? email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        
        // Also update SharedPreferences for backward compatibility
        await login(user.uid);
        
        debugPrint('Email sign-in successful: $email');
        return user.uid;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during sign-in: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Email sign-in error: $e');
      rethrow;
    }
  }

  /// Logout user (using Firebase Auth)
  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      // Also sign out from Google if signed in
      await signOutGoogle();
      
      // Update SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userIdKey);
      await prefs.setBool(_skipAutoLoginKey, true);
      _memoryStorage[_isLoggedInKey] = false;
      _memoryStorage.remove(_userIdKey);
      _memoryStorage[_skipAutoLoginKey] = true;
      
      debugPrint('AuthService: User logged out');
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
      rethrow;
    }
  }

  /// Get current user ID (using Firebase Auth)
  Future<String?> getUserId() async {
    try {
      // Get from Firebase Auth first
      final user = _auth.currentUser;
      if (user != null) {
        return user.uid;
      }
      // Fallback to SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      debugPrint('AuthService: Error getting user ID: $e');
      return _memoryStorage[_userIdKey] as String?;
    }
  }

  /// Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign in with Google (using Firebase Auth)
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Create or update user document in Firestore
        await _firebaseService.createOrUpdateUser(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        
        // Also update SharedPreferences for backward compatibility
        await login(user.uid);
        
        debugPrint('Google Sign-In successful: ${user.email}');
        return user.uid;
      }
      
        return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during Google Sign-In: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In unexpected error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple (using Firebase Auth)
  Future<String?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      // Sign in to Firebase with the Apple credential
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      
      if (user != null) {
        // Create or update user document in Firestore
        await _firebaseService.createOrUpdateUser(
          userId: user.uid,
          email: user.email ?? appleCredential.email ?? '',
          displayName: appleCredential.givenName != null && appleCredential.familyName != null
              ? '${appleCredential.givenName} ${appleCredential.familyName}'
              : user.displayName,
          photoUrl: user.photoURL,
        );
      
        // Also update SharedPreferences for backward compatibility
        await login(user.uid);
      
        debugPrint('Apple Sign-In successful: ${user.email ?? user.uid}');
        return user.uid;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during Apple Sign-In: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }
  }

  /// Check if a user is registered (has signed up before)
  Future<bool> isUserRegistered(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsers = prefs.getStringList(_registeredUsersKey) ?? [];
      return registeredUsers.contains(email.toLowerCase());
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      final registeredUsers = _memoryStorage[_registeredUsersKey] as List<String>? ?? [];
      return registeredUsers.contains(email.toLowerCase());
    }
  }

  /// Register a new user (mark as registered)
  Future<void> registerUser(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsers = prefs.getStringList(_registeredUsersKey) ?? [];
      final emailLower = email.toLowerCase();
      if (!registeredUsers.contains(emailLower)) {
        registeredUsers.add(emailLower);
        await prefs.setStringList(_registeredUsersKey, registeredUsers);
        _memoryStorage[_registeredUsersKey] = registeredUsers;
      }
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      final registeredUsers = _memoryStorage[_registeredUsersKey] as List<String>? ?? [];
      final emailLower = email.toLowerCase();
      if (!registeredUsers.contains(emailLower)) {
        registeredUsers.add(emailLower);
        _memoryStorage[_registeredUsersKey] = registeredUsers;
      }
    }
  }

  /// Check if there are any registered users
  Future<bool> hasRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsers = prefs.getStringList(_registeredUsersKey) ?? [];
      return registeredUsers.isNotEmpty;
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      final registeredUsers = (_memoryStorage[_registeredUsersKey] as List<String>?) ?? [];
      return registeredUsers.isNotEmpty;
    }
  }

  /// Get the last registered user email
  Future<String?> getLastRegisteredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsers = prefs.getStringList(_registeredUsersKey) ?? [];
      return registeredUsers.isNotEmpty ? registeredUsers.last : null;
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      final registeredUsers = (_memoryStorage[_registeredUsersKey] as List<String>?) ?? [];
      return registeredUsers.isNotEmpty ? registeredUsers.last : null;
    }
  }

  /// Auto-login if user is registered
  Future<bool> autoLoginIfRegistered() async {
    try {
      // Check if user is already logged in
      if (await isLoggedIn()) {
        return true;
      }

      // Check if auto-login should be skipped (user manually logged out)
      bool skipAutoLogin = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        skipAutoLogin = prefs.getBool(_skipAutoLoginKey) ?? false;
      } catch (e) {
        debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
        skipAutoLogin = _memoryStorage[_skipAutoLoginKey] as bool? ?? false;
      }
      
      if (skipAutoLogin) {
        debugPrint('AuthService: Skipping auto-login (user manually logged out)');
        return false;
      }

      // Get the last registered user email (if any)
      List<String> registeredUsers = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        registeredUsers = prefs.getStringList(_registeredUsersKey) ?? [];
      } catch (e) {
        debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
        registeredUsers = (_memoryStorage[_registeredUsersKey] as List<String>?) ?? [];
      }
      
      if (registeredUsers.isNotEmpty) {
        // Auto-login with the last registered user
        final lastUser = registeredUsers.last;
        await login(lastUser);
        debugPrint('AuthService: Auto-logged in user: $lastUser');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('AuthService: Auto-login error: $e');
      return false;
    }
  }

  /// Enable guest mode (user can use app without account)
  Future<void> enableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestModeKey, true);
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, 'guest');
      _memoryStorage[_isGuestModeKey] = true;
      _memoryStorage[_isLoggedInKey] = true;
      _memoryStorage[_userIdKey] = 'guest';
      debugPrint('AuthService: Guest mode enabled');
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      _memoryStorage[_isGuestModeKey] = true;
      _memoryStorage[_isLoggedInKey] = true;
      _memoryStorage[_userIdKey] = 'guest';
    }
  }

  /// Check if user is in guest mode
  Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isGuestModeKey) ?? false;
    } catch (e) {
      debugPrint('AuthService: SharedPreferences error, using memory fallback: $e');
      return _memoryStorage[_isGuestModeKey] as bool? ?? false;
    }
  }
}
