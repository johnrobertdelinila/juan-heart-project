import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing authentication state and tokens.
///
/// Handles JWT token persistence, retrieval, and authentication status checks.
/// Uses SharedPreferences for secure local storage of authentication tokens.
class AuthService {
  // SharedPreferences keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  /// Save authentication token to local storage.
  ///
  /// [token] - The JWT authentication token received from the backend.
  static Future<bool> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyAuthToken, token);
    } catch (e) {
      print('❌ Error saving auth token: $e');
      return false;
    }
  }

  /// Retrieve stored authentication token.
  ///
  /// Returns the stored JWT token, or null if not authenticated.
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAuthToken);
    } catch (e) {
      print('❌ Error retrieving auth token: $e');
      return null;
    }
  }

  /// Check if user is authenticated.
  ///
  /// Returns true if a valid auth token exists in local storage.
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user profile information.
  ///
  /// Stores user metadata alongside the auth token.
  static Future<bool> saveUserInfo({
    required String userId,
    required String email,
    String? name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      if (name != null) {
        await prefs.setString(_keyUserName, name);
      }
      return true;
    } catch (e) {
      print('❌ Error saving user info: $e');
      return false;
    }
  }

  /// Retrieve stored user ID.
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    } catch (e) {
      print('❌ Error retrieving user ID: $e');
      return null;
    }
  }

  /// Retrieve stored user email.
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('❌ Error retrieving user email: $e');
      return null;
    }
  }

  /// Retrieve stored user name.
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName);
    } catch (e) {
      print('❌ Error retrieving user name: $e');
      return null;
    }
  }

  /// Clear all authentication data (logout).
  ///
  /// Removes token and user information from local storage.
  /// Call this when user logs out or token expires.
  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
      print('✅ Auth data cleared successfully');
      return true;
    } catch (e) {
      print('❌ Error clearing auth data: $e');
      return false;
    }
  }

  /// Check if token is likely expired (basic check).
  ///
  /// Note: For production, implement proper JWT expiration validation.
  /// This is a placeholder for future JWT decode logic.
  static Future<bool> isTokenExpired() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
      return true;
    }

    // TODO: Implement JWT expiration check
    // For now, assume token is valid if it exists
    return false;
  }

  /// Refresh authentication token.
  ///
  /// Note: Implement this when backend provides token refresh endpoint.
  static Future<String?> refreshToken() async {
    // TODO: Implement token refresh logic
    // This would call a backend refresh token endpoint
    throw UnimplementedError('Token refresh not yet implemented');
  }
}
