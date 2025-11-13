import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import '../../repositories/token_repository.dart';

/// HTTP interceptor service with automatic token refresh on 401 errors.
///
/// Provides a wrapper around http.Client that:
/// - Automatically adds Authorization headers with access token
/// - Detects 401 (Unauthorized) responses
/// - Attempts token refresh and retries original request
/// - Queues concurrent requests during token refresh
/// - Handles network errors and timeouts
///
/// USAGE:
/// ```dart
/// final client = HttpInterceptorService();
/// final response = await client.get(Uri.parse('https://api.example.com/data'));
/// ```
///
/// SECURITY NOTES:
/// - Automatically injects Bearer token in Authorization header
/// - Never logs full tokens (only first 10 chars for debugging)
/// - Queues requests during refresh to prevent race conditions
///
/// NOT VERIFIED AND TESTED - Backend refresh endpoint required
class HttpInterceptorService {
  static final http.Client _client = http.Client();
  static bool _isRefreshing = false;
  static final List<_PendingRequest> _pendingRequests = [];

  /// Execute GET request with automatic token refresh on 401.
  ///
  /// [url] - Target URL
  /// [headers] - Additional headers (Authorization added automatically)
  ///
  /// Returns HTTP response or throws exception
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return await _executeWithRetry(
      () async => _client.get(url, headers: await _buildHeaders(headers)),
      url,
      'GET',
      headers,
    );
  }

  /// Execute POST request with automatic token refresh on 401.
  ///
  /// [url] - Target URL
  /// [headers] - Additional headers (Authorization added automatically)
  /// [body] - Request body
  /// [encoding] - Body encoding (defaults to utf-8)
  ///
  /// Returns HTTP response or throws exception
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return await _executeWithRetry(
      () async => _client.post(
        url,
        headers: await _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
      url,
      'POST',
      headers,
    );
  }

  /// Execute PUT request with automatic token refresh on 401.
  ///
  /// [url] - Target URL
  /// [headers] - Additional headers (Authorization added automatically)
  /// [body] - Request body
  /// [encoding] - Body encoding (defaults to utf-8)
  ///
  /// Returns HTTP response or throws exception
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return await _executeWithRetry(
      () async => _client.put(
        url,
        headers: await _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
      url,
      'PUT',
      headers,
    );
  }

  /// Execute DELETE request with automatic token refresh on 401.
  ///
  /// [url] - Target URL
  /// [headers] - Additional headers (Authorization added automatically)
  ///
  /// Returns HTTP response or throws exception
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return await _executeWithRetry(
      () async => _client.delete(url, headers: await _buildHeaders(headers)),
      url,
      'DELETE',
      headers,
    );
  }

  /// Execute PATCH request with automatic token refresh on 401.
  ///
  /// [url] - Target URL
  /// [headers] - Additional headers (Authorization added automatically)
  /// [body] - Request body
  /// [encoding] - Body encoding (defaults to utf-8)
  ///
  /// Returns HTTP response or throws exception
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return await _executeWithRetry(
      () async => _client.patch(
        url,
        headers: await _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
      url,
      'PATCH',
      headers,
    );
  }

  /// Build headers with Authorization token.
  ///
  /// Retrieves access token from secure storage and adds Bearer token header.
  /// Merges with provided headers (provided headers take precedence).
  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? additionalHeaders,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    // Add Authorization header if token exists
    final token = await TokenRepository.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      // Log only first 10 chars for security
      debugPrint('Added auth header: Bearer ${token.substring(0, 10)}...');
    }

    return headers;
  }

  /// Execute HTTP request with automatic retry on 401.
  ///
  /// If request returns 401 (Unauthorized):
  /// 1. Queue request if refresh already in progress
  /// 2. Attempt token refresh
  /// 3. Retry original request with new token
  /// 4. Return response or throw exception
  ///
  /// Implements request queueing to prevent concurrent refresh attempts.
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
    Uri url,
    String method,
    Map<String, String>? headers,
  ) async {
    try {
      // Execute original request
      final response = await request();

      // Check for 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('Received 401 for $method $url - attempting token refresh');

        // If refresh in progress, queue this request
        if (_isRefreshing) {
          debugPrint('Refresh in progress, queueing request');
          return await _queueRequest(
            request,
            url,
            method,
            headers,
          );
        }

        // Attempt token refresh
        final newToken = await _refreshTokenAndRetry();

        if (newToken != null) {
          // Retry original request with new token
          debugPrint('Retrying $method $url with new token');
          final retryResponse = await request();

          // Process queued requests with new token
          await _processQueuedRequests();

          return retryResponse;
        } else {
          // Refresh failed - clear queued requests
          _clearQueuedRequests();
          throw UnauthorizedException('Token refresh failed');
        }
      }

      return response;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('HTTP request error for $method $url: $e');
      rethrow;
    }
  }

  /// Refresh token and notify queued requests.
  ///
  /// Sets refresh lock, calls AuthService.refreshToken(), and releases lock.
  static Future<String?> _refreshTokenAndRetry() async {
    _isRefreshing = true;

    try {
      final newToken = await AuthService.refreshToken();
      return newToken;
    } catch (e) {
      debugPrint('Token refresh error in interceptor: $e');
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Queue request during token refresh.
  ///
  /// Adds request to pending queue and waits for refresh to complete.
  /// Once refresh completes, retries the request with new token.
  Future<http.Response> _queueRequest(
    Future<http.Response> Function() request,
    Uri url,
    String method,
    Map<String, String>? headers,
  ) async {
    final completer = Completer<http.Response>();

    _pendingRequests.add(_PendingRequest(
      request: request,
      completer: completer,
      url: url,
      method: method,
    ));

    return completer.future;
  }

  /// Process all queued requests after successful refresh.
  ///
  /// Retries each queued request with new token and completes their futures.
  static Future<void> _processQueuedRequests() async {
    debugPrint('Processing ${_pendingRequests.length} queued requests');

    for (final pendingRequest in _pendingRequests) {
      try {
        final response = await pendingRequest.request();
        pendingRequest.completer.complete(response);
      } catch (e) {
        pendingRequest.completer.completeError(e);
      }
    }

    _pendingRequests.clear();
  }

  /// Clear queued requests on refresh failure.
  ///
  /// Completes all pending requests with UnauthorizedException.
  static void _clearQueuedRequests() {
    debugPrint('Clearing ${_pendingRequests.length} queued requests');

    for (final pendingRequest in _pendingRequests) {
      pendingRequest.completer.completeError(
        UnauthorizedException('Token refresh failed'),
      );
    }

    _pendingRequests.clear();
  }

  /// Close HTTP client and release resources.
  void close() {
    _client.close();
  }
}

/// Pending HTTP request during token refresh.
class _PendingRequest {
  final Future<http.Response> Function() request;
  final Completer<http.Response> completer;
  final Uri url;
  final String method;

  _PendingRequest({
    required this.request,
    required this.completer,
    required this.url,
    required this.method,
  });
}

/// Exception thrown when authentication fails and refresh cannot recover.
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
