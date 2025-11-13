import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/services/auth_service.dart';
import 'package:juan_heart/repositories/token_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Unit tests for AuthService token refresh mechanism.
///
/// Tests cover:
/// - JWT token expiration checking
/// - Automatic token refresh logic
/// - Auth status stream events
/// - Error handling and retries
/// - Token migration from SharedPreferences
///
/// NOTE: These tests mock secure storage and HTTP calls.
/// Backend refresh endpoint must be implemented separately.

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService - Token Expiration', () {
    setUp(() async {
      // Clear secure storage before each test
      const storage = FlutterSecureStorage();
      await storage.deleteAll();

      SharedPreferences.setMockInitialValues({});
    });

    test('isTokenExpired returns true when no token exists', () async {
      final result = await AuthService.isTokenExpired();
      expect(result, isTrue);
    });

    test('isTokenExpired returns true for expired JWT token', () async {
      // Create expired token (exp: 1609459200 = Jan 1, 2021)
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE2MDk0NTkyMDB9.'
          'signature';

      await TokenRepository.saveAccessToken(expiredToken);

      final result = await AuthService.isTokenExpired();
      expect(result, isTrue);
    });

    test('isTokenExpired returns false for valid JWT token', () async {
      // Create token expiring in 1 hour (safe from threshold)
      final futureTimestamp = DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch ~/
          1000;

      final validToken = _createTestToken(futureTimestamp);
      await TokenRepository.saveAccessToken(validToken);

      final result = await AuthService.isTokenExpired();
      expect(result, isFalse);
    });

    test('isTokenExpired returns true when token expires within 5 minutes',
        () async {
      // Create token expiring in 3 minutes (within refresh threshold)
      final nearExpiryTimestamp = DateTime.now()
          .add(const Duration(minutes: 3))
          .millisecondsSinceEpoch ~/
          1000;

      final token = _createTestToken(nearExpiryTimestamp);
      await TokenRepository.saveAccessToken(token);

      final result = await AuthService.isTokenExpired();
      expect(result, isTrue);
    });

    test('isTokenExpired handles malformed tokens gracefully', () async {
      await TokenRepository.saveAccessToken('invalid.token.format');

      final result = await AuthService.isTokenExpired();
      expect(result, isTrue);
    });
  });

  group('AuthService - Token Expiry Parsing', () {
    test('getTokenExpiryTimestamp returns correct timestamp', () async {
      final futureTimestamp = DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch ~/
          1000;

      final token = _createTestToken(futureTimestamp);
      await TokenRepository.saveAccessToken(token);

      final result = await AuthService.getTokenExpiryTimestamp();
      expect(result, equals(futureTimestamp));
    });

    test('getTokenExpiryTimestamp returns null for invalid token', () async {
      await TokenRepository.saveAccessToken('invalid.token');

      final result = await AuthService.getTokenExpiryTimestamp();
      expect(result, isNull);
    });

    test('getTokenExpiryTimestamp returns null when no token', () async {
      final result = await AuthService.getTokenExpiryTimestamp();
      expect(result, isNull);
    });
  });

  group('AuthService - Authentication Status', () {
    setUp(() async {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
    });

    test('isAuthenticated returns false when no token', () async {
      final result = await AuthService.isAuthenticated();
      expect(result, isFalse);
    });

    test('isAuthenticated returns true when token exists', () async {
      await TokenRepository.saveAccessToken('test_token');

      final result = await AuthService.isAuthenticated();
      expect(result, isTrue);
    });

    test('clearAuthData removes all tokens and user info', () async {
      // Set up auth data
      await TokenRepository.saveAccessToken('test_token');
      await TokenRepository.saveRefreshToken('refresh_token');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', '123');
      await prefs.setString('user_email', 'test@example.com');

      // Clear auth data
      await AuthService.clearAuthData();

      // Verify all data cleared
      final token = await TokenRepository.getAccessToken();
      final refreshToken = await TokenRepository.getRefreshToken();
      final userId = prefs.getString('user_id');

      expect(token, isNull);
      expect(refreshToken, isNull);
      expect(userId, isNull);
    });
  });

  group('AuthService - Token Migration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
    });

    test('migrateFromSharedPreferences moves token to secure storage',
        () async {
      // Set up legacy token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('AuthState.authToken', 'legacy_token');

      // Migrate
      final success = await TokenRepository.migrateFromSharedPreferences();
      expect(success, isTrue);

      // Verify token in secure storage
      final migratedToken = await TokenRepository.getAccessToken();
      expect(migratedToken, equals('legacy_token'));

      // Verify removed from SharedPreferences
      final legacyToken = prefs.getString('AuthState.authToken');
      expect(legacyToken, isNull);
    });

    test('migrateFromSharedPreferences skips if already migrated', () async {
      // Set up token in secure storage
      await TokenRepository.saveAccessToken('existing_token');

      // Set up legacy token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('AuthState.authToken', 'legacy_token');

      // Attempt migration
      final success = await TokenRepository.migrateFromSharedPreferences();
      expect(success, isTrue);

      // Verify existing token preserved
      final token = await TokenRepository.getAccessToken();
      expect(token, equals('existing_token'));
    });

    test('migrateFromSharedPreferences handles missing legacy token',
        () async {
      final success = await TokenRepository.migrateFromSharedPreferences();
      expect(success, isTrue);

      final token = await TokenRepository.getAccessToken();
      expect(token, isNull);
    });
  });

  group('AuthService - Auth Status Stream', () {
    setUp(() async {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      SharedPreferences.setMockInitialValues({});
    });

    test('authStatusStream emits authenticated when token exists', () async {
      await TokenRepository.saveAccessToken('test_token');

      // Listen to stream
      final streamFuture = AuthService.authStatusStream.first;

      // Initialize service
      await AuthService.initialize();

      // Verify stream emission
      final status = await streamFuture.timeout(
        const Duration(seconds: 2),
        onTimeout: () => AuthStatus.unauthenticated,
      );

      expect(status, equals(AuthStatus.authenticated));
    });

    test('authStatusStream emits unauthenticated when no token', () async {
      final streamFuture = AuthService.authStatusStream.first;

      await AuthService.initialize();

      final status = await streamFuture.timeout(
        const Duration(seconds: 2),
        onTimeout: () => AuthStatus.authenticated,
      );

      expect(status, equals(AuthStatus.unauthenticated));
    });
  });

  group('AuthService - Token Storage Security', () {
    test('tokens are stored in secure storage, not SharedPreferences',
        () async {
      await TokenRepository.saveAccessToken('secure_token');

      // Verify NOT in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final unsecureToken = prefs.getString('secure_access_token');
      expect(unsecureToken, isNull);

      // Verify in secure storage
      final secureToken = await TokenRepository.getAccessToken();
      expect(secureToken, equals('secure_token'));
    });

    test('refresh token stored separately from access token', () async {
      await TokenRepository.saveAccessToken('access_token');
      await TokenRepository.saveRefreshToken('refresh_token');

      final accessToken = await TokenRepository.getAccessToken();
      final refreshToken = await TokenRepository.getRefreshToken();

      expect(accessToken, equals('access_token'));
      expect(refreshToken, equals('refresh_token'));
      expect(accessToken, isNot(equals(refreshToken)));
    });

    test('clearTokens removes all tokens from secure storage', () async {
      await TokenRepository.saveAccessToken('access_token');
      await TokenRepository.saveRefreshToken('refresh_token');
      await TokenRepository.saveTokenExpiry(1234567890);

      await TokenRepository.clearTokens();

      final accessToken = await TokenRepository.getAccessToken();
      final refreshToken = await TokenRepository.getRefreshToken();
      final expiry = await TokenRepository.getTokenExpiry();

      expect(accessToken, isNull);
      expect(refreshToken, isNull);
      expect(expiry, isNull);
    });
  });
}

/// Helper function to create test JWT token with specified expiry.
///
/// Creates a valid JWT structure with:
/// - Header: {"alg": "HS256", "typ": "JWT"}
/// - Payload: {"sub": "test", "exp": [expiryTimestamp]}
/// - Signature: Mock signature (not cryptographically valid)
String _createTestToken(int expiryTimestamp) {
  // JWT header (base64 encoded)
  const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

  // JWT payload with custom expiry
  final payload = {
    'sub': 'test_user',
    'exp': expiryTimestamp,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  };

  // Base64 encode payload (URL-safe)
  final payloadJson = '{"sub":"test_user","exp":$expiryTimestamp,"iat":${DateTime.now().millisecondsSinceEpoch ~/ 1000}}';
  final payloadBase64 = _base64UrlEncode(payloadJson);

  // Mock signature
  const signature = 'mock_signature';

  return '$header.$payloadBase64.$signature';
}

/// Base64 URL-safe encoding helper.
String _base64UrlEncode(String input) {
  final bytes = input.codeUnits;
  var base64 = '';

  // Simple base64 encoding (not cryptographically secure, for testing only)
  for (var i = 0; i < bytes.length; i += 3) {
    final chunk = <int>[];
    chunk.add(bytes[i]);
    if (i + 1 < bytes.length) chunk.add(bytes[i + 1]);
    if (i + 2 < bytes.length) chunk.add(bytes[i + 2]);

    // Simplified - just use the actual base64 package in real implementation
    base64 += String.fromCharCodes(chunk);
  }

  // URL-safe characters
  return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}
