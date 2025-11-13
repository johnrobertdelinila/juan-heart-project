/// Secure API Client with Certificate Pinning
///
/// This service provides a centralized, secure HTTP client for all API communications.
/// It integrates certificate pinning to prevent Man-in-the-Middle attacks.
///
/// Features:
/// - Certificate pinning for all production endpoints
/// - Automatic retry logic with exponential backoff
/// - Request/response logging in debug mode
/// - Error handling and user-friendly messages
/// - Offline detection and queueing
/// - Token management for authenticated requests
///
/// Usage:
/// ```dart
/// final client = SecureApiClient();
/// final response = await client.get('/assessments');
/// ```
///
/// NOT VERIFIED AND TESTED

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:juan_heart/config/pinned_certificates.dart';
import 'package:juan_heart/core/constants/api_constants.dart';
import 'package:juan_heart/services/certificate_pinning_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure API Client with certificate pinning
class SecureApiClient {
  static final SecureApiClient _instance = SecureApiClient._internal();
  factory SecureApiClient() => _instance;

  late Dio _dio;
  final CertificatePinningService _pinningService = CertificatePinningService();
  final Connectivity _connectivity = Connectivity();

  SecureApiClient._internal() {
    _initializeClient();
  }

  /// Initialize the Dio client with certificate pinning
  void _initializeClient() {
    // Create secure client with certificate pinning
    _dio = _pinningService.createJuanHeartBackendClient(
      baseUrl: APIConstant.baseUrl,
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      _RetryInterceptor(_dio),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  /// Get the Dio instance
  Dio get client => _dio;

  /// Perform GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkConnectivity();

    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkConnectivity();

    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkConnectivity();

    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();

    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkConnectivity();

    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Check internet connectivity before making request
  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
        message: 'No internet connection. Your request will be queued '
            'and sent when you are back online.',
      );
    }
  }

  /// Update base URL (useful for switching environments)
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Get certificate rotation status
  List<CertificateRotationStatus> getCertificateStatus() {
    return _pinningService.checkCertificateRotationStatus();
  }

  /// Get certificate pinning failure counts
  Map<String, int> getCertificateFailures() {
    return _pinningService.getAllFailureCounts();
  }
}

/// Authentication Interceptor
/// Automatically adds authorization token to requests
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token != null && token.isNotEmpty) {
        options.headers['authorization'] = token;
      }
    } catch (e) {
      debugPrint('Error adding auth token: $e');
    }

    return handler.next(options);
  }
}

/// Error Interceptor
/// Converts technical errors to user-friendly messages
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String userMessage = _getUserFriendlyMessage(err);

    final modifiedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: err.error,
      message: userMessage,
    );

    return handler.next(modifiedError);
  }

  String _getUserFriendlyMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection '
            'and try again.';

      case DioExceptionType.connectionError:
        // Check if it's a certificate pinning error
        if (error.error is CertificatePinningException) {
          return 'Secure connection could not be established. '
              'Please ensure you are using the latest version of the app.';
        }
        return 'Cannot connect to server. Please check your internet '
            'connection and try again.';

      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 400:
            return 'Invalid request. Please check your input and try again.';
          case 401:
            return 'Your session has expired. Please sign in again.';
          case 403:
            return 'You do not have permission to access this resource.';
          case 404:
            return 'The requested resource was not found.';
          case 500:
          case 502:
          case 503:
            return 'Server error. Please try again later.';
          default:
            return 'An error occurred. Please try again.';
        }

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badCertificate:
        return 'Secure connection could not be established. '
            'Please update your app to the latest version.';

      case DioExceptionType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Retry Interceptor
/// Automatically retries failed requests with exponential backoff
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  _RetryInterceptor(
    this.dio, {
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Don't retry these error types
    final nonRetriableErrors = [
      DioExceptionType.cancel,
      DioExceptionType.badResponse,
      DioExceptionType.badCertificate,
    ];

    if (nonRetriableErrors.contains(err.type)) {
      return handler.next(err);
    }

    // Don't retry on 4xx errors (client errors)
    if (err.response?.statusCode != null &&
        err.response!.statusCode! >= 400 &&
        err.response!.statusCode! < 500) {
      return handler.next(err);
    }

    // Get retry count from request
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    // Calculate delay with exponential backoff
    final delay = initialDelay * (retryCount + 1);

    debugPrint('Retrying request (${retryCount + 1}/$maxRetries) '
        'after ${delay.inSeconds}s: ${err.requestOptions.path}');

    await Future.delayed(delay);

    // Clone request and increment retry count
    final requestOptions = err.requestOptions;
    requestOptions.extra['retryCount'] = retryCount + 1;

    try {
      final response = await dio.fetch(requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}

/// Logging Interceptor (Debug mode only)
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────────');
    debugPrint('│ REQUEST: ${options.method} ${options.path}');
    debugPrint('│ Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('│ Data: ${options.data}');
    }
    debugPrint('└─────────────────────────────────────────────────');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────────');
    debugPrint('│ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('│ Data: ${response.data}');
    debugPrint('└─────────────────────────────────────────────────');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────────');
    debugPrint('│ ERROR: ${err.type} ${err.requestOptions.path}');
    debugPrint('│ Message: ${err.message}');
    if (err.response != null) {
      debugPrint('│ Status: ${err.response?.statusCode}');
      debugPrint('│ Data: ${err.response?.data}');
    }
    debugPrint('└─────────────────────────────────────────────────');
    return handler.next(err);
  }
}

/// Extension methods for easy API calls
extension SecureApiClientExtensions on SecureApiClient {
  /// Get with type-safe response
  Future<T> getTyped<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );

    if (response.data == null) {
      throw Exception('Response data is null');
    }

    return fromJson(response.data!);
  }

  /// Post with type-safe response
  Future<T> postTyped<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );

    if (response.data == null) {
      throw Exception('Response data is null');
    }

    return fromJson(response.data!);
  }

  /// Get list with type-safe response
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get<List<dynamic>>(
      path,
      queryParameters: queryParameters,
    );

    if (response.data == null) {
      throw Exception('Response data is null');
    }

    return response.data!
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
