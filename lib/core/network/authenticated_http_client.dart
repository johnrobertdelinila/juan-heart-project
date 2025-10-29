import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

/// HTTP client wrapper that automatically adds authentication headers.
///
/// All requests made through this client will include the JWT token
/// from AuthService. Handles 401 responses for token expiration.
class AuthenticatedHttpClient {
  static final AuthenticatedHttpClient _instance = AuthenticatedHttpClient._internal();
  factory AuthenticatedHttpClient() => _instance;
  AuthenticatedHttpClient._internal();

  final http.Client _client = http.Client();

  /// Get authentication headers with Bearer token.
  ///
  /// Returns headers map with Authorization token if authenticated,
  /// or base headers if not authenticated.
  Future<Map<String, String>> _getHeaders({Map<String, String>? additionalHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if available
    final token = await AuthService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle 401 Unauthorized responses.
  ///
  /// Clears auth data and optionally redirects to login.
  Future<void> _handle401Response() async {
    print('⚠️ Received 401 Unauthorized - clearing auth data');
    await AuthService.clearAuthData();
    // TODO: Implement navigation to login screen
    // Get.offAllNamed(AppRoutes.signIn);
  }

  /// Make authenticated POST request.
  ///
  /// [url] - The endpoint URL.
  /// [body] - Request body (will be JSON encoded).
  /// [headers] - Optional additional headers.
  /// [timeout] - Request timeout duration (default: 10 seconds).
  Future<http.Response> post(
    Uri url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      print('📤 POST ${url.toString()}');
      if (body != null) {
        print('📦 Payload: ${jsonEncode(body)}');
      }

      final response = await _client
          .post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      print('📥 Response: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        await _handle401Response();
      }

      return response;
    } catch (e) {
      print('❌ POST request failed: $e');
      rethrow;
    }
  }

  /// Make authenticated GET request.
  ///
  /// [url] - The endpoint URL.
  /// [headers] - Optional additional headers.
  /// [timeout] - Request timeout duration (default: 10 seconds).
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      print('📤 GET ${url.toString()}');

      final response = await _client
          .get(url, headers: requestHeaders)
          .timeout(timeout);

      print('📥 Response: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        await _handle401Response();
      }

      return response;
    } catch (e) {
      print('❌ GET request failed: $e');
      rethrow;
    }
  }

  /// Make authenticated PUT request.
  ///
  /// [url] - The endpoint URL.
  /// [body] - Request body (will be JSON encoded).
  /// [headers] - Optional additional headers.
  /// [timeout] - Request timeout duration (default: 10 seconds).
  Future<http.Response> put(
    Uri url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      print('📤 PUT ${url.toString()}');

      final response = await _client
          .put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      print('📥 Response: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        await _handle401Response();
      }

      return response;
    } catch (e) {
      print('❌ PUT request failed: $e');
      rethrow;
    }
  }

  /// Make authenticated DELETE request.
  ///
  /// [url] - The endpoint URL.
  /// [headers] - Optional additional headers.
  /// [timeout] - Request timeout duration (default: 10 seconds).
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      print('📤 DELETE ${url.toString()}');

      final response = await _client
          .delete(url, headers: requestHeaders)
          .timeout(timeout);

      print('📥 Response: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        await _handle401Response();
      }

      return response;
    } catch (e) {
      print('❌ DELETE request failed: $e');
      rethrow;
    }
  }

  /// Close the underlying HTTP client.
  ///
  /// Call this when the app is disposed.
  void close() {
    _client.close();
  }
}
