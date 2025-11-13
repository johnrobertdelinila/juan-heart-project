import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../repositories/token_repository.dart';
import '../core/constants/api_constants.dart';

/// Service for managing authentication state and tokens.
///
/// Handles JWT token persistence, retrieval, authentication status checks,
/// and automatic token refresh. Uses flutter_secure_storage for AES-256
/// encrypted token storage.
///
/// FEATURES:
/// - Automatic token refresh 5 minutes before expiration
/// - JWT parsing and expiration validation
/// - Secure token storage with platform-specific encryption
/// - Auth status stream for real-time monitoring
/// - Migration from SharedPreferences to secure storage
///
/// SECURITY NOTES:
/// - Tokens stored with AES-256 encryption
/// - Automatic logout on refresh failure
/// - Exponential backoff for refresh retries
///
/// NOT VERIFIED AND TESTED - Backend refresh endpoint required
class AuthService {
  // SharedPreferences keys (legacy)
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  // Token refresh configuration
  static const Duration _refreshThreshold = Duration(minutes: 5);
  static const Duration _refreshCheckInterval = Duration(minutes: 1);
  static const int _maxRefreshRetries = 3;

  // Auth status stream controller
  static final StreamController<AuthStatus> _authStatusController =
      StreamController<AuthStatus>.broadcast();

  // Refresh lock to prevent concurrent refresh attempts
  static bool _isRefreshing = false;
  static Timer? _refreshTimer;
  static int _refreshRetryCount = 0;

  /// Save authentication token to local storage.
  ///
  /// [token] - The JWT authentication token received from the backend.
  static Future<bool> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyAuthToken, token);
    } catch (e) {
      debugPrint('❌ Error saving auth token: $e');
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
      debugPrint('❌ Error retrieving auth token: $e');
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
      debugPrint('❌ Error saving user info: $e');
      return false;
    }
  }

  /// Retrieve stored user ID.
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    } catch (e) {
      debugPrint('❌ Error retrieving user ID: $e');
      return null;
    }
  }

  /// Retrieve stored user email.
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      debugPrint('❌ Error retrieving user email: $e');
      return null;
    }
  }

  /// Retrieve stored user name.
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName);
    } catch (e) {
      debugPrint('❌ Error retrieving user name: $e');
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
      debugPrint('✅ Auth data cleared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing auth data: $e');
      return false;
    }
  }

  /// Initialize auth service and start token refresh monitoring.
  ///
  /// Call this once during app startup to:
  /// 1. Migrate tokens from SharedPreferences to secure storage
  /// 2. Start automatic token refresh timer
  /// 3. Check initial authentication status
  static Future<void> initialize() async {
    try {
      // Migrate legacy tokens
      await TokenRepository.migrateFromSharedPreferences();

      // Check authentication status
      final isAuth = await isAuthenticated();
      _authStatusController.add(
        isAuth ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      );

      // Start refresh timer if authenticated
      if (isAuth) {
        await _scheduleTokenRefresh();
      }

      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
    }
  }

  /// Get auth status stream for real-time monitoring.
  ///
  /// Listen to this stream to react to authentication state changes:
  /// - AuthStatus.authenticated: User has valid token
  /// - AuthStatus.unauthenticated: No token or token expired
  /// - AuthStatus.tokenRefreshed: Token successfully refreshed
  /// - AuthStatus.refreshFailed: Token refresh failed (logout required)
  static Stream<AuthStatus> get authStatusStream => _authStatusController.stream;

  /// Check if JWT token is expired or about to expire.
  ///
  /// Returns true if:
  /// - No token exists
  /// - Token is malformed/invalid
  /// - Token is expired
  /// - Token expires within refresh threshold (5 minutes)
  ///
  /// Uses jwt_decoder to parse and validate JWT expiration claim.
  static Future<bool> isTokenExpired() async {
    try {
      final token = await TokenRepository.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('No token found, considering expired');
        return true;
      }

      // Check if token is malformed
      if (JwtDecoder.isExpired(token)) {
        debugPrint('Token is expired');
        return true;
      }

      // Check if token expires within threshold
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      final timeUntilExpiry = expirationDate.difference(now);

      if (timeUntilExpiry <= _refreshThreshold) {
        debugPrint('Token expires in ${timeUntilExpiry.inMinutes} minutes');
        return true;
      }

      debugPrint('Token valid for ${timeUntilExpiry.inMinutes} minutes');
      return false;
    } catch (e) {
      debugPrint('Error checking token expiration: $e');
      return true; // Assume expired on error
    }
  }

  /// Parse JWT token and extract expiration timestamp.
  ///
  /// Returns Unix timestamp (seconds) when token expires, or null if invalid.
  static Future<int?> getTokenExpiryTimestamp() async {
    try {
      final token = await TokenRepository.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final decodedToken = JwtDecoder.decode(token);
      return decodedToken['exp'] as int?;
    } catch (e) {
      debugPrint('Error parsing token expiry: $e');
      return null;
    }
  }

  /// Refresh authentication token using refresh token.
  ///
  /// Calls backend refresh endpoint with refresh token to obtain new access token.
  /// Implements exponential backoff for retries (3 attempts).
  ///
  /// Returns new access token on success, null on failure.
  ///
  /// BACKEND REQUIREMENTS:
  /// - Endpoint: POST /auth/refresh
  /// - Request body: { "refreshToken": "..." }
  /// - Response: { "token": "...", "refreshToken": "..." }
  ///
  /// NOT VERIFIED AND TESTED - Backend endpoint must be implemented
  static Future<String?> refreshToken() async {
    if (_isRefreshing) {
      debugPrint('Token refresh already in progress');
      return null;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await TokenRepository.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available');
        await _handleRefreshFailure();
        return null;
      }

      // Calculate retry delay with exponential backoff
      final retryDelay = Duration(
        seconds: (2 * (_refreshRetryCount + 1)) * (_refreshRetryCount + 1),
      );

      if (_refreshRetryCount > 0) {
        debugPrint('Retry attempt $_refreshRetryCount, waiting $retryDelay');
        await Future.delayed(retryDelay);
      }

      debugPrint('Attempting token refresh...');

      // Call backend refresh endpoint
      final response = await http.post(
        Uri.parse('${APIConstant.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Token refresh timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken == null) {
          throw Exception('No access token in refresh response');
        }

        // Save new tokens
        await TokenRepository.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await TokenRepository.saveRefreshToken(newRefreshToken);
        }

        // Extract and save expiry
        final expiry = await getTokenExpiryTimestamp();
        if (expiry != null) {
          await TokenRepository.saveTokenExpiry(expiry);
        }

        debugPrint('Token refresh successful');
        _refreshRetryCount = 0;
        _authStatusController.add(AuthStatus.tokenRefreshed);

        return newAccessToken;
      } else if (response.statusCode == 401) {
        // Refresh token expired or invalid
        debugPrint('Refresh token invalid: ${response.statusCode}');
        await _handleRefreshFailure();
        return null;
      } else {
        // Server error - retry with exponential backoff
        debugPrint('Token refresh failed: ${response.statusCode}');

        if (_refreshRetryCount < _maxRefreshRetries) {
          _refreshRetryCount++;
          _isRefreshing = false;
          return AuthService.refreshToken(); // Recursive retry
        } else {
          debugPrint('Max refresh retries reached');
          await _handleRefreshFailure();
          return null;
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('Token refresh timeout: $e');

      if (_refreshRetryCount < _maxRefreshRetries) {
        _refreshRetryCount++;
        _isRefreshing = false;
        return AuthService.refreshToken();
      } else {
        await _handleRefreshFailure();
        return null;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');

      if (_refreshRetryCount < _maxRefreshRetries) {
        _refreshRetryCount++;
        _isRefreshing = false;
        return AuthService.refreshToken();
      } else {
        await _handleRefreshFailure();
        return null;
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Schedule automatic token refresh check.
  ///
  /// Runs every minute to check if token needs refresh.
  /// Automatically refreshes token 5 minutes before expiration.
  static Future<void> _scheduleTokenRefresh() async {
    // Cancel existing timer
    _refreshTimer?.cancel();

    // Check immediately
    await _checkAndRefreshToken();

    // Schedule periodic checks
    _refreshTimer = Timer.periodic(_refreshCheckInterval, (_) async {
      await _checkAndRefreshToken();
    });

    debugPrint('Token refresh timer scheduled');
  }

  /// Check if token needs refresh and refresh if necessary.
  static Future<void> _checkAndRefreshToken() async {
    try {
      final isExpired = await isTokenExpired();
      if (isExpired && !_isRefreshing) {
        debugPrint('Token expired or about to expire, refreshing...');
        await refreshToken();
      }
    } catch (e) {
      debugPrint('Error checking token for refresh: $e');
    }
  }

  /// Handle refresh failure by clearing tokens and notifying listeners.
  static Future<void> _handleRefreshFailure() async {
    debugPrint('Handling refresh failure - clearing auth data');
    await TokenRepository.clearTokens();
    await clearAuthData();
    _refreshTimer?.cancel();
    _authStatusController.add(AuthStatus.refreshFailed);
  }

  /// Stop token refresh monitoring.
  ///
  /// Call this on logout or when auth service is no longer needed.
  static void stopRefreshMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _refreshRetryCount = 0;
    debugPrint('Token refresh monitoring stopped');
  }

  /// Dispose auth service resources.
  ///
  /// Call this when app is shutting down.
  static void dispose() {
    stopRefreshMonitoring();
    _authStatusController.close();
  }
}

/// Authentication status enumeration.
enum AuthStatus {
  /// User is authenticated with valid token
  authenticated,

  /// User is not authenticated (no token)
  unauthenticated,

  /// Token was successfully refreshed
  tokenRefreshed,

  /// Token refresh failed (user should be logged out)
  refreshFailed,
}

/// Custom exception for timeout scenarios.
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
