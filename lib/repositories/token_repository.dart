import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for secure token storage and retrieval.
///
/// Uses flutter_secure_storage for storing sensitive authentication tokens
/// with AES-256 encryption. Provides migration support from SharedPreferences.
///
/// SECURITY NOTES:
/// - All tokens are encrypted at rest using platform-specific secure storage
/// - iOS: Keychain with kSecAttrAccessibleAfterFirstUnlock
/// - Android: EncryptedSharedPreferences with AES-256-GCM
/// - Never expose raw tokens in logs or error messages
///
/// NOT VERIFIED AND TESTED - Backend refresh endpoint required
class TokenRepository {
  // Secure storage instance with iOS/Android encryption
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Secure storage keys
  static const String _keyAccessToken = 'secure_access_token';
  static const String _keyRefreshToken = 'secure_refresh_token';
  static const String _keyTokenExpiry = 'secure_token_expiry';

  // Legacy SharedPreferences keys for migration
  static const String _legacyKeyAuthToken = 'AuthState.authToken';

  /// Save access token to secure storage.
  ///
  /// [token] - JWT access token from backend authentication
  /// Returns true if save successful, false otherwise
  static Future<bool> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(
        key: _keyAccessToken,
        value: token,
      );
      debugPrint('Access token saved to secure storage');
      return true;
    } catch (e) {
      debugPrint('Error saving access token: $e');
      return false;
    }
  }

  /// Save refresh token to secure storage.
  ///
  /// [token] - JWT refresh token for obtaining new access tokens
  /// Returns true if save successful, false otherwise
  static Future<bool> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(
        key: _keyRefreshToken,
        value: token,
      );
      debugPrint('Refresh token saved to secure storage');
      return true;
    } catch (e) {
      debugPrint('Error saving refresh token: $e');
      return false;
    }
  }

  /// Save token expiry timestamp.
  ///
  /// [expiryTimestamp] - Unix timestamp (seconds) when token expires
  static Future<bool> saveTokenExpiry(int expiryTimestamp) async {
    try {
      await _secureStorage.write(
        key: _keyTokenExpiry,
        value: expiryTimestamp.toString(),
      );
      debugPrint('Token expiry saved: $expiryTimestamp');
      return true;
    } catch (e) {
      debugPrint('Error saving token expiry: $e');
      return false;
    }
  }

  /// Retrieve access token from secure storage.
  ///
  /// Returns stored access token or null if not found
  static Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _keyAccessToken);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  /// Retrieve refresh token from secure storage.
  ///
  /// Returns stored refresh token or null if not found
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  /// Retrieve token expiry timestamp.
  ///
  /// Returns Unix timestamp (seconds) or null if not found
  static Future<int?> getTokenExpiry() async {
    try {
      final expiryStr = await _secureStorage.read(key: _keyTokenExpiry);
      if (expiryStr == null) return null;
      return int.tryParse(expiryStr);
    } catch (e) {
      debugPrint('Error reading token expiry: $e');
      return null;
    }
  }

  /// Clear all stored tokens (logout).
  ///
  /// Removes access token, refresh token, and expiry from secure storage.
  /// Call this on logout or when refresh token is invalid.
  static Future<bool> clearTokens() async {
    try {
      await _secureStorage.delete(key: _keyAccessToken);
      await _secureStorage.delete(key: _keyRefreshToken);
      await _secureStorage.delete(key: _keyTokenExpiry);
      debugPrint('All tokens cleared from secure storage');
      return true;
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
      return false;
    }
  }

  /// Migrate tokens from SharedPreferences to secure storage.
  ///
  /// Called once during app upgrade to move existing tokens to encrypted storage.
  /// Removes legacy tokens from SharedPreferences after successful migration.
  ///
  /// Returns true if migration successful or no tokens to migrate
  static Future<bool> migrateFromSharedPreferences() async {
    try {
      // Check if already migrated
      final existingToken = await getAccessToken();
      if (existingToken != null && existingToken.isNotEmpty) {
        debugPrint('Tokens already in secure storage, skipping migration');
        return true;
      }

      // Retrieve legacy token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_legacyKeyAuthToken);

      if (legacyToken == null || legacyToken.isEmpty) {
        debugPrint('No legacy tokens to migrate');
        return true;
      }

      // Migrate to secure storage
      final success = await saveAccessToken(legacyToken);
      if (success) {
        // Remove from SharedPreferences
        await prefs.remove(_legacyKeyAuthToken);
        debugPrint('Token migration successful');
        return true;
      } else {
        debugPrint('Token migration failed');
        return false;
      }
    } catch (e) {
      debugPrint('Error during token migration: $e');
      return false;
    }
  }

  /// Check if secure storage has any tokens.
  ///
  /// Returns true if access token exists in secure storage
  static Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all secure storage (for testing/debugging only).
  ///
  /// WARNING: This clears ALL data from secure storage, not just tokens.
  /// Use clearTokens() for normal logout operations.
  static Future<void> clearAllSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('All secure storage cleared');
    } catch (e) {
      debugPrint('Error clearing all secure storage: $e');
    }
  }
}
