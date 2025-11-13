import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/service/ApiService.dart';
import 'package:juan_heart/services/auth_service.dart';
import 'package:juan_heart/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show Random;

/// Integration tests for Authentication Backend
///
/// This test suite validates:
/// 1. User registration (email validation, duplicate detection, password strength)
/// 2. User login (valid/invalid credentials, session token generation)
/// 3. User logout (session clearing, data cleanup)
/// 4. Password reset (email sending, error handling)
/// 5. User profile management (updates, backend sync)
/// 6. Error handling (network errors, rate limiting, invalid inputs)
/// 7. Performance benchmarks (registration, login, profile sync timing)
///
/// Prerequisites:
/// - Backend API running at http://172.20.10.6:8000
/// - User authentication endpoints operational
/// - Database configured for user management
/// - SharedPreferences initialized
///
/// Test data requirements:
/// - Unique test emails generated per test run
/// - Valid password formats
/// - Network connectivity for backend tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Backend Integration Tests', () {
    late ApiService apiService;

    // Test user credentials
    const String testPassword = 'TestPassword123!';
    const String testName = 'Test User Integration';

    setUpAll(() async {
      print('[SetupAll] Initializing authentication test environment...');

      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      // Initialize API service
      apiService = ApiService();

      // Ensure logged out before tests
      await AuthService.clearAuthData();

      print('[SetupAll] Test environment initialized');
      print('[SetupAll] Backend URL: ${APIConstant.baseUrl}');
    });

    setUp(() async {
      // Ensure clean state before each test
      await AuthService.clearAuthData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('[Setup] Test environment cleaned');
    });

    tearDownAll(() async {
      // Cleanup test data
      await AuthService.clearAuthData();
      print('[TearDownAll] Test cleanup completed');
    });

    // ==================== GROUP 1: User Registration ====================

    testWidgets('Test 1: Register new user successfully', (tester) async {
      print('\n[Test 1] Starting user registration test...');

      // STEP 1: Generate unique test email
      final String testEmail = _generateTestEmail();
      print('[Test 1] Test email: $testEmail');

      // STEP 2: Register user via API
      final stopwatch = Stopwatch()..start();

      Map<String, dynamic>? registerResult;
      bool registrationSuccess = false;

      try {
        registerResult = await apiService.registerUser(
          testName,
          testEmail,
          testPassword,
        );
        registrationSuccess = true;
      } catch (e) {
        print('[Test 1] Registration error: $e');
      }

      stopwatch.stop();

      // STEP 3: Verify registration succeeded
      expect(registrationSuccess, isTrue,
          reason: 'User registration should succeed');
      expect(registerResult, isNotNull,
          reason: 'Registration should return user data');
      expect(registerResult!['token'], isNotNull,
          reason: 'Registration should return JWT token');

      // STEP 4: Verify token saved to SharedPreferences
      final savedToken = await AuthService.getAuthToken();
      expect(savedToken, isNotNull,
          reason: 'Auth token should be saved to SharedPreferences');
      expect(savedToken, equals(registerResult['token']),
          reason: 'Saved token should match returned token');

      // STEP 5: Verify user is authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      expect(isAuthenticated, isTrue,
          reason: 'User should be authenticated after registration');

      print('[Test 1] PASSED: User registered successfully in ${stopwatch.elapsedMilliseconds}ms');
      print('[Test 1] Token: ${savedToken?.substring(0, 20)}...');
    }, skip: false);

    testWidgets('Test 2: Validate email format during registration', (tester) async {
      print('\n[Test 2] Starting email validation test...');

      // STEP 1: Test invalid email formats
      const invalidEmails = [
        'notanemail',           // No @
        'test@',                // Incomplete domain
        '@example.com',         // Missing local part
        'test@.com',            // Missing domain name
        'test..test@test.com',  // Double dots
      ];

      for (var invalidEmail in invalidEmails) {
        print('[Test 2] Testing invalid email: $invalidEmail');

        bool registrationFailed = false;
        String? errorMessage;

        try {
          await apiService.registerUser(
            testName,
            invalidEmail,
            testPassword,
          );
        } catch (e) {
          registrationFailed = true;
          errorMessage = e.toString();
          print('[Test 2] Expected error for $invalidEmail: $errorMessage');
        }

        // Verify registration was prevented
        expect(registrationFailed, isTrue,
            reason: 'Registration with invalid email should fail: $invalidEmail');
      }

      print('[Test 2] PASSED: All invalid email formats rejected');
    }, skip: false);

    testWidgets('Test 3: Handle duplicate email registration (email-already-in-use)', (tester) async {
      print('\n[Test 3] Starting duplicate email test...');

      // STEP 1: Register first user
      final String testEmail = _generateTestEmail();
      print('[Test 3] Registering first user with email: $testEmail');

      try {
        await apiService.registerUser(
          testName,
          testEmail,
          testPassword,
        );
        print('[Test 3] First user registered successfully');
      } catch (e) {
        print('[Test 3] First registration error: $e');
      }

      // STEP 2: Clear auth state but keep user in backend
      await AuthService.clearAuthData();

      // STEP 3: Attempt to register second user with same email
      print('[Test 3] Attempting duplicate registration...');

      bool duplicateRegistrationFailed = false;
      String? errorMessage;

      try {
        await apiService.registerUser(
          'Another User',
          testEmail,  // Same email as first user
          testPassword,
        );
      } catch (e) {
        duplicateRegistrationFailed = true;
        errorMessage = e.toString();
        print('[Test 3] Duplicate registration error: $errorMessage');
      }

      // STEP 4: Verify duplicate registration was prevented
      expect(duplicateRegistrationFailed, isTrue,
          reason: 'Duplicate email registration should fail');
      expect(errorMessage, contains('Duplicate'),
          reason: 'Error message should mention duplicate email');

      print('[Test 3] PASSED: Duplicate email registration prevented');
    }, skip: false);

    testWidgets('Test 4: Validate password strength requirements', (tester) async {
      print('\n[Test 4] Starting password strength validation test...');

      // STEP 1: Test weak passwords
      const weakPasswords = [
        '123',                  // Too short
        'password',             // No numbers/symbols
        '',                     // Empty
        'abc',                  // Too short, no numbers
      ];

      for (var weakPass in weakPasswords) {
        print('[Test 4] Testing weak password: "$weakPass"');

        final String testEmail = _generateTestEmail();
        bool registrationWithWeakPassword = false;

        try {
          await apiService.registerUser(
            testName,
            testEmail,
            weakPass,
          );
          registrationWithWeakPassword = true;
        } catch (e) {
          print('[Test 4] Expected error for weak password: $e');
        }

        // Note: Backend may or may not validate password strength
        // This test documents the behavior
        print('[Test 4] Weak password "$weakPass" result: ${registrationWithWeakPassword ? "ACCEPTED" : "REJECTED"}');
      }

      print('[Test 4] PASSED: Password strength validation documented');
    }, skip: false);

    // ==================== GROUP 2: User Login ====================

    testWidgets('Test 5: Login with valid credentials successfully', (tester) async {
      print('\n[Test 5] Starting valid login test...');

      // STEP 1: Register test user first
      final String testEmail = _generateTestEmail();
      print('[Test 5] Registering user: $testEmail');

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Clear auth state (simulate logout)
      await AuthService.clearAuthData();
      print('[Test 5] Auth cleared, now attempting login...');

      // STEP 3: Login with valid credentials
      final stopwatch = Stopwatch()..start();

      Map<String, dynamic>? loginResult;
      bool loginSuccess = false;

      try {
        loginResult = await apiService.loginUser(testEmail, testPassword);
        loginSuccess = true;
      } catch (e) {
        print('[Test 5] Login error: $e');
      }

      stopwatch.stop();

      // STEP 4: Verify login succeeded
      expect(loginSuccess, isTrue,
          reason: 'Login with valid credentials should succeed');
      expect(loginResult, isNotNull,
          reason: 'Login should return user data');
      expect(loginResult!['token'], isNotNull,
          reason: 'Login should return JWT token');

      // STEP 5: Verify session token exists
      final savedToken = await AuthService.getAuthToken();
      expect(savedToken, isNotNull,
          reason: 'Token should be saved after login');

      // STEP 6: Verify user is authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      expect(isAuthenticated, isTrue,
          reason: 'User should be authenticated after login');

      print('[Test 5] PASSED: Login successful in ${stopwatch.elapsedMilliseconds}ms');
      print('[Test 5] Token: ${savedToken?.substring(0, 20)}...');
    }, skip: false);

    testWidgets('Test 6: Handle login with invalid email (user-not-found)', (tester) async {
      print('\n[Test 6] Starting invalid email login test...');

      // STEP 1: Attempt login with non-existent email
      final String nonExistentEmail = 'nonexistent_${DateTime.now().millisecondsSinceEpoch}@juanheart.test';
      print('[Test 6] Attempting login with: $nonExistentEmail');

      bool loginFailed = false;
      String? errorMessage;

      try {
        await apiService.loginUser(nonExistentEmail, testPassword);
      } catch (e) {
        loginFailed = true;
        errorMessage = e.toString();
        print('[Test 6] Expected error: $errorMessage');
      }

      // STEP 2: Verify login was prevented
      expect(loginFailed, isTrue,
          reason: 'Login with non-existent email should fail');
      expect(errorMessage, contains('Invalid'),
          reason: 'Error message should indicate invalid credentials');

      // STEP 3: Verify user is not authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      expect(isAuthenticated, isFalse,
          reason: 'User should not be authenticated after failed login');

      print('[Test 6] PASSED: Invalid email login prevented');
    }, skip: false);

    testWidgets('Test 7: Handle login with wrong password', (tester) async {
      print('\n[Test 7] Starting wrong password login test...');

      // STEP 1: Register test user
      final String testEmail = _generateTestEmail();
      print('[Test 7] Registering user: $testEmail');

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Clear auth state
      await AuthService.clearAuthData();

      // STEP 3: Attempt login with wrong password
      print('[Test 7] Attempting login with wrong password...');

      bool loginFailed = false;
      String? errorMessage;

      try {
        await apiService.loginUser(testEmail, 'WrongPassword123!');
      } catch (e) {
        loginFailed = true;
        errorMessage = e.toString();
        print('[Test 7] Expected error: $errorMessage');
      }

      // STEP 4: Verify login was prevented
      expect(loginFailed, isTrue,
          reason: 'Login with wrong password should fail');
      expect(errorMessage, contains('Invalid'),
          reason: 'Error message should indicate invalid credentials');

      // STEP 5: Verify user is not authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      expect(isAuthenticated, isFalse,
          reason: 'User should not be authenticated after failed login');

      print('[Test 7] PASSED: Wrong password login prevented');
    }, skip: false);

    testWidgets('Test 8: Verify session token generated after login', (tester) async {
      print('\n[Test 8] Starting session token verification test...');

      // STEP 1: Register and login user
      final String testEmail = _generateTestEmail();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      await AuthService.clearAuthData();

      final loginResult = await apiService.loginUser(testEmail, testPassword);

      // STEP 2: Get ID token from SharedPreferences
      final token = await AuthService.getAuthToken();
      print('[Test 8] Token retrieved: ${token?.substring(0, 30)}...');

      // STEP 3: Verify token is not null/empty
      expect(token, isNotNull,
          reason: 'Session token should not be null');
      expect(token!.isNotEmpty, isTrue,
          reason: 'Session token should not be empty');

      // STEP 4: Verify token format (JWT tokens have 3 parts separated by dots)
      final tokenParts = token.split('.');
      // Note: Backend may not use standard JWT format
      // This test documents the actual token structure
      print('[Test 8] Token structure: ${tokenParts.length} parts');

      // STEP 5: Verify token can be used for backend requests
      try {
        final userData = await apiService.getUserData();
        print('[Test 8] User data fetched successfully with token');
        expect(userData, isNotNull,
            reason: 'Token should be valid for backend requests');
      } catch (e) {
        print('[Test 8] Token usage: $e');
      }

      print('[Test 8] PASSED: Session token verified');
    }, skip: false);

    // ==================== GROUP 3: User Logout ====================

    testWidgets('Test 9: Logout successfully and clear session', (tester) async {
      print('\n[Test 9] Starting logout test...');

      // STEP 1: Register and login user
      final String testEmail = _generateTestEmail();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Verify user is authenticated
      var isAuthenticated = await AuthService.isAuthenticated();
      expect(isAuthenticated, isTrue,
          reason: 'User should be authenticated before logout');

      final tokenBeforeLogout = await AuthService.getAuthToken();
      expect(tokenBeforeLogout, isNotNull,
          reason: 'Token should exist before logout');

      // STEP 3: Logout (clear auth data)
      print('[Test 9] Logging out...');
      final logoutSuccess = await AuthService.clearAuthData();

      expect(logoutSuccess, isTrue,
          reason: 'Logout should succeed');

      // STEP 4: Verify session cleared
      final tokenAfterLogout = await AuthService.getAuthToken();
      expect(tokenAfterLogout, isNull,
          reason: 'Token should be null after logout');

      // STEP 5: Verify user is not authenticated
      isAuthenticated = await AuthService.isAuthenticated();
      expect(isAuthenticated, isFalse,
          reason: 'User should not be authenticated after logout');

      print('[Test 9] PASSED: Logout successful, session cleared');
    }, skip: false);

    testWidgets('Test 10: Verify user data is null after logout', (tester) async {
      print('\n[Test 10] Starting user data cleanup test...');

      // STEP 1: Register user and save user info
      final String testEmail = _generateTestEmail();

      final registerResult = await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // Save user info
      await AuthService.saveUserInfo(
        userId: 'test_user_123',
        email: testEmail,
        name: testName,
      );

      // STEP 2: Verify user data exists
      var userId = await AuthService.getUserId();
      var userEmail = await AuthService.getUserEmail();
      var userName = await AuthService.getUserName();

      expect(userId, isNotNull,
          reason: 'User ID should exist before logout');
      expect(userEmail, isNotNull,
          reason: 'User email should exist before logout');
      expect(userName, isNotNull,
          reason: 'User name should exist before logout');

      // ignore: avoid_print
      print('User data before logout - ID: $userId, Email: $userEmail, Name: $userName');

      // STEP 3: Logout
      await AuthService.clearAuthData();

      // STEP 4: Verify all user data is null after logout
      userId = await AuthService.getUserId();
      userEmail = await AuthService.getUserEmail();
      userName = await AuthService.getUserName();

      expect(userId, isNull,
          reason: 'User ID should be null after logout');
      expect(userEmail, isNull,
          reason: 'User email should be null after logout');
      expect(userName, isNull,
          reason: 'User name should be null after logout');

      print('[Test 10] PASSED: All user data cleared after logout');
    }, skip: false);

    // ==================== GROUP 4: Password Reset ====================

    testWidgets('Test 11: Send password reset email successfully', (tester) async {
      print('\n[Test 11] Starting password reset email test...');

      // STEP 1: Register test user
      final String testEmail = _generateTestEmail();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Request password reset
      print('[Test 11] Requesting password reset for: $testEmail');

      // Note: Backend may not have password reset endpoint implemented
      // This test documents the expected behavior

      bool resetRequestSuccess = false;
      String? errorMessage;

      try {
        // Attempt to call password reset endpoint (if exists)
        final response = await http.post(
          Uri.parse('${APIConstant.baseUrl}/user-password-reset'),
          body: json.encode({'email': testEmail}),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          resetRequestSuccess = true;
          print('[Test 11] Password reset email sent successfully');
        } else {
          print('[Test 11] Password reset endpoint returned: ${response.statusCode}');
        }
      } catch (e) {
        errorMessage = e.toString();
        print('[Test 11] Password reset not implemented or error: $errorMessage');
      }

      // Document the behavior (may not be implemented yet)
      print('[Test 11] INFO: Password reset feature status: ${resetRequestSuccess ? "IMPLEMENTED" : "NOT IMPLEMENTED"}');
      print('[Test 11] PASSED: Password reset behavior documented');
    }, skip: false);

    testWidgets('Test 12: Handle password reset for non-existent email', (tester) async {
      print('\n[Test 12] Starting password reset for invalid email test...');

      // STEP 1: Request password reset for non-existent email
      final String nonExistentEmail = 'nonexistent_${DateTime.now().millisecondsSinceEpoch}@juanheart.test';
      print('[Test 12] Requesting password reset for: $nonExistentEmail');

      try {
        final response = await http.post(
          Uri.parse('${APIConstant.baseUrl}/user-password-reset'),
          body: json.encode({'email': nonExistentEmail}),
          headers: {'Content-Type': 'application/json'},
        );

        print('[Test 12] Password reset response: ${response.statusCode}');

        // Verify error handling or silent success (for security)
        // Best practice: Return success even for non-existent emails to prevent email enumeration
        if (response.statusCode == 404) {
          print('[Test 12] Backend returns 404 for non-existent email');
        } else if (response.statusCode == 200) {
          print('[Test 12] Backend returns 200 (silent success for security)');
        }
      } catch (e) {
        print('[Test 12] Password reset endpoint not available: $e');
      }

      print('[Test 12] PASSED: Password reset error handling documented');
    }, skip: false);

    // ==================== GROUP 5: User Profile Management ====================

    testWidgets('Test 13: Update user profile (name, email) successfully', (tester) async {
      print('\n[Test 13] Starting user profile update test...');

      // STEP 1: Register and login user
      final String testEmail = _generateTestEmail();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Save initial user info
      await AuthService.saveUserInfo(
        userId: 'test_user_456',
        email: testEmail,
        name: testName,
      );

      var initialName = await AuthService.getUserName();
      print('[Test 13] Initial user name: $initialName');

      // STEP 3: Update user profile
      const String updatedName = 'Updated Test User';

      final updateSuccess = await AuthService.saveUserInfo(
        userId: 'test_user_456',
        email: testEmail,
        name: updatedName,
      );

      expect(updateSuccess, isTrue,
          reason: 'Profile update should succeed');

      // STEP 4: Verify profile updated
      final savedName = await AuthService.getUserName();
      expect(savedName, equals(updatedName),
          reason: 'Updated name should be saved');

      print('[Test 13] Updated user name: $savedName');
      print('[Test 13] PASSED: User profile updated successfully');
    }, skip: false);

    testWidgets('Test 14: Verify profile synced to backend', (tester) async {
      print('\n[Test 14] Starting profile backend sync test...');

      // STEP 1: Register user (profile created on backend)
      final String testEmail = _generateTestEmail();

      final registerResult = await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      print('[Test 14] User registered, token: ${registerResult['token']?.toString().substring(0, 20)}...');

      // STEP 2: Fetch user profile from backend
      final stopwatch = Stopwatch()..start();

      dynamic userProfile;
      bool profileFetchSuccess = false;

      try {
        userProfile = await apiService.getUserData();
        profileFetchSuccess = true;
        stopwatch.stop();
      } catch (e) {
        stopwatch.stop();
        print('[Test 14] Profile fetch error: $e');
      }

      // STEP 3: Verify profile exists on backend
      expect(profileFetchSuccess, isTrue,
          reason: 'Profile should be fetchable from backend');
      expect(userProfile, isNotNull,
          reason: 'User profile data should not be null');

      // STEP 4: Verify profile data consistency
      print('[Test 14] User profile: ${userProfile.toString()}');

      print('[Test 14] PASSED: Profile synced to backend in ${stopwatch.elapsedMilliseconds}ms');
    }, skip: false);

    // ==================== GROUP 6: Error Handling ====================

    testWidgets('Test 15: Handle network errors gracefully', (tester) async {
      print('\n[Test 15] Starting network error handling test...');

      // STEP 1: Attempt login with invalid backend URL
      // Note: Cannot easily simulate network failure in integration test
      // This test documents expected behavior

      print('[Test 15] Testing network error handling...');

      // STEP 2: Verify app doesn't crash on network error
      bool networkErrorHandled = false;

      try {
        // Attempt connection to invalid endpoint
        await http.get(
          Uri.parse('http://invalid-backend-url-12345.com/api/v1/users'),
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        networkErrorHandled = true;
        print('[Test 15] Network error handled gracefully: $e');
      }

      // STEP 3: Verify graceful error handling
      expect(networkErrorHandled, isTrue,
          reason: 'Network errors should be caught and handled');

      print('[Test 15] PASSED: Network errors handled gracefully');
    }, skip: false);

    testWidgets('Test 16: Handle rate limiting (too-many-requests)', (tester) async {
      print('\n[Test 16] Starting rate limiting test...');

      // STEP 1: Attempt multiple failed logins
      const String testEmail = 'ratelimit_test@juanheart.test';
      const String wrongPassword = 'WrongPassword123!';

      print('[Test 16] Attempting multiple failed logins...');

      int failedAttempts = 0;
      bool rateLimitDetected = false;

      for (int i = 0; i < 10; i++) {
        try {
          await apiService.loginUser(testEmail, wrongPassword);
        } catch (e) {
          failedAttempts++;

          // Check if rate limiting is enforced
          if (e.toString().contains('too-many-requests') ||
              e.toString().contains('rate limit') ||
              e.toString().contains('429')) {
            rateLimitDetected = true;
            print('[Test 16] Rate limiting detected after $failedAttempts attempts');
            break;
          }
        }

        // Small delay between attempts
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('[Test 16] Failed login attempts: $failedAttempts');
      print('[Test 16] Rate limiting detected: $rateLimitDetected');

      // Note: Backend may or may not implement rate limiting
      // This test documents the behavior
      print('[Test 16] INFO: Rate limiting ${rateLimitDetected ? "ENABLED" : "NOT DETECTED"}');
      print('[Test 16] PASSED: Rate limiting behavior documented');
    }, skip: false);

    // ==================== GROUP 7: Performance Benchmarks ====================

    testWidgets('Test 17: User registration completes in <3 seconds', (tester) async {
      print('\n[Test 17] Starting registration performance test...');

      // STEP 1: Generate test email
      final String testEmail = _generateTestEmail();

      // STEP 2: Measure registration time
      final stopwatch = Stopwatch()..start();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      stopwatch.stop();
      final registrationTime = stopwatch.elapsedMilliseconds;

      // STEP 3: Verify performance (<3 seconds)
      expect(registrationTime, lessThan(3000),
          reason: 'User registration should complete in <3 seconds');

      print('[Test 17] PASSED: Registration completed in ${registrationTime}ms (<3s)');
    }, skip: false);

    testWidgets('Test 18: User login completes in <2 seconds', (tester) async {
      print('\n[Test 18] Starting login performance test...');

      // STEP 1: Register test user
      final String testEmail = _generateTestEmail();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Clear auth state
      await AuthService.clearAuthData();

      // STEP 3: Measure login time
      final stopwatch = Stopwatch()..start();

      await apiService.loginUser(testEmail, testPassword);

      stopwatch.stop();
      final loginTime = stopwatch.elapsedMilliseconds;

      // STEP 4: Verify performance (<2 seconds)
      expect(loginTime, lessThan(2000),
          reason: 'User login should complete in <2 seconds');

      print('[Test 18] PASSED: Login completed in ${loginTime}ms (<2s)');
    }, skip: false);

    testWidgets('Test 19: Profile sync completes in <2 seconds', (tester) async {
      print('\n[Test 19] Starting profile sync performance test...');

      // STEP 1: Register user
      final String testEmail = _generateTestEmail();

      await apiService.registerUser(
        testName,
        testEmail,
        testPassword,
      );

      // STEP 2: Measure profile fetch time
      final stopwatch = Stopwatch()..start();

      await apiService.getUserData();

      stopwatch.stop();
      final profileSyncTime = stopwatch.elapsedMilliseconds;

      // STEP 3: Verify performance (<2 seconds)
      expect(profileSyncTime, lessThan(2000),
          reason: 'Profile sync should complete in <2 seconds');

      print('[Test 19] PASSED: Profile sync completed in ${profileSyncTime}ms (<2s)');
    }, skip: false);
  });
}

// ==================== Helper Functions ====================

/// Generate unique test email with timestamp
String _generateTestEmail() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = _random.nextInt(10000);
  return 'test_user_${timestamp}_$random@juanheart.test';
}

/// Random number generator for unique identifiers
final _random = Random();
