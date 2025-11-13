/// Educational Content API Service
///
/// Handles all backend API requests for educational content data
/// Implements offline-first architecture with error handling and retry logic
///
/// Features:
/// - Fetch educational content with filters (category, language, search)
/// - Incremental sync - only fetch content changed since last sync
/// - Get single content by ID and track views
/// - Fetch available categories
/// - Get content statistics
/// - Error handling with exponential backoff retry (3 attempts)
/// - Type-safe request/response models
///
/// Backend API Documentation: EDUCATIONAL_CONTENT_API_INTEGRATION.md

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:juan_heart/models/api/educational_content_api_models.dart';

class EducationalContentApiService {
  late final Dio _dio;
  final String baseUrl;
  final int maxRetries;
  final Duration initialRetryDelay;

  /// Create EducationalContentApiService with custom configuration
  ///
  /// [baseUrl] - API base URL (default: http://localhost:8000/api/v1/mobile)
  /// [maxRetries] - Maximum retry attempts (default: 3)
  /// [timeout] - Request timeout in seconds (default: 30)
  EducationalContentApiService({
    String? baseUrl,
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(seconds: 1),
    int timeout = 30,
  }) : baseUrl = baseUrl ?? 'http://localhost:8000/api/v1/mobile' {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: Duration(seconds: timeout),
      receiveTimeout: Duration(seconds: timeout),
      sendTimeout: Duration(seconds: timeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[EducationalContentAPI] $obj'),
      ));
    }
  }

  /// Fetch educational content with optional filters
  ///
  /// [category] - Filter by category (e.g., "cvd_prevention", "heart_health")
  /// [language] - Filter by language code ('en' or 'fil')
  /// [search] - Search query string (searches in title, description, body)
  /// [page] - Page number for pagination (default: 1)
  /// [perPage] - Items per page (default: 10, max: 50)
  ///
  /// Returns list of educational content matching the filters
  /// Throws [EducationalContentApiException] on error
  Future<List<EducationalContentApiModel>> fetchContent({
    String? category,
    String? language,
    String? search,
    int? page,
    int? perPage,
  }) async {
    try {
      debugPrint('[EducationalContentAPI] Fetching content with filters: '
          'category=$category, language=$language, search=$search, '
          'page=$page, perPage=$perPage');

      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (language != null) queryParams['language'] = language;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;
      if (perPage != null) queryParams['per_page'] = perPage;

      final response = await _retryRequest(
        () => _dio.get('/educational-content', queryParameters: queryParams),
      );

      final apiResponse =
          EducationalContentApiResponse<List<EducationalContentApiModel>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((json) => EducationalContentApiModel.fromJson(json))
            .toList(),
      );

      if (!apiResponse.success) {
        throw EducationalContentApiException(
          message: apiResponse.error ?? 'Failed to fetch educational content',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[EducationalContentAPI] Successfully fetched ${apiResponse.data?.length ?? 0} content items');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Incremental sync - fetch only content added/updated since lastSync
  ///
  /// [lastSync] - Timestamp of last successful sync (UTC)
  ///
  /// Returns list of content updated since the specified timestamp
  /// If lastSync is null, returns all content (first sync)
  /// Throws [EducationalContentApiException] on error
  Future<List<EducationalContentApiModel>> syncContent(DateTime? lastSync) async {
    try {
      if (lastSync == null) {
        // First sync - fetch all content
        debugPrint('[EducationalContentAPI] First sync - fetching all content');
        return fetchContent();
      }

      final since = lastSync.toUtc().toIso8601String();
      debugPrint('[EducationalContentAPI] Incremental sync since: $since');

      final response = await _retryRequest(
        () => _dio.get(
          '/educational-content/sync',
          queryParameters: {'since': since},
        ),
      );

      final apiResponse =
          EducationalContentApiResponse<List<EducationalContentApiModel>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((json) => EducationalContentApiModel.fromJson(json))
            .toList(),
      );

      if (!apiResponse.success) {
        throw EducationalContentApiException(
          message: apiResponse.error ?? 'Failed to sync educational content',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[EducationalContentAPI] Sync complete: ${apiResponse.data?.length ?? 0} content items updated');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get single content by ID and increment view count
  ///
  /// [id] - Content ID (string identifier)
  ///
  /// Returns educational content details
  /// Automatically increments view count on backend
  /// Throws [EducationalContentApiException] on error (404 if not found)
  Future<EducationalContentApiModel> getContent(String id) async {
    try {
      debugPrint('[EducationalContentAPI] Fetching content: $id');

      final response = await _retryRequest(
        () => _dio.get('/educational-content/$id'),
      );

      final apiResponse =
          EducationalContentApiResponse<EducationalContentApiModel>.fromJson(
        response.data,
        (data) => EducationalContentApiModel.fromJson(data),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw EducationalContentApiException(
          message: apiResponse.error ?? 'Content not found',
          statusCode: 404,
        );
      }

      debugPrint(
          '[EducationalContentAPI] Successfully fetched content: ${apiResponse.data!.title}');
      return apiResponse.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get available content categories
  ///
  /// Returns list of category identifiers (e.g., "cvd_prevention", "heart_health")
  /// Throws [EducationalContentApiException] on error
  Future<List<String>> getCategories() async {
    try {
      debugPrint('[EducationalContentAPI] Fetching categories list');

      final response = await _retryRequest(
        () => _dio.get('/educational-content/categories'),
      );

      final apiResponse =
          EducationalContentApiResponse<List<String>>.fromJson(
        response.data,
        (data) => (data as List).map((e) => e.toString()).toList(),
      );

      if (!apiResponse.success) {
        throw EducationalContentApiException(
          message: apiResponse.error ?? 'Failed to fetch categories',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[EducationalContentAPI] Found ${apiResponse.data?.length ?? 0} categories');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get content statistics
  ///
  /// Returns statistics including:
  /// - Total content count
  /// - Total views across all content
  /// - Breakdown by category with counts
  ///
  /// Throws [EducationalContentApiException] on error
  Future<ContentStatsModel> getStats() async {
    try {
      debugPrint('[EducationalContentAPI] Fetching content statistics');

      final response = await _retryRequest(
        () => _dio.get('/educational-content/stats'),
      );

      final apiResponse =
          EducationalContentApiResponse<ContentStatsModel>.fromJson(
        response.data,
        (data) => ContentStatsModel.fromJson(data),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw EducationalContentApiException(
          message: apiResponse.error ?? 'Failed to fetch statistics',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[EducationalContentAPI] Total content: ${apiResponse.data!.totalContent}');
      return apiResponse.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Retry request with exponential backoff
  ///
  /// Implements retry logic:
  /// - Attempt 1: Immediate
  /// - Attempt 2: Wait 1 second
  /// - Attempt 3: Wait 2 seconds
  /// - Attempt 4: Wait 4 seconds
  ///
  /// [request] - Function that returns a Future<Response>
  ///
  /// Returns response from successful request
  /// Throws DioException if all retries fail
  Future<Response> _retryRequest(Future<Response> Function() request) async {
    int attempt = 0;
    Duration delay = initialRetryDelay;

    while (true) {
      attempt++;
      try {
        return await request();
      } on DioException catch (e) {
        // Don't retry on client errors (4xx) except 408 (timeout)
        if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 400 &&
            e.response!.statusCode! < 500 &&
            e.response!.statusCode! != 408) {
          debugPrint(
              '[EducationalContentAPI] Client error - no retry: ${e.response?.statusCode}');
          rethrow;
        }

        if (attempt >= maxRetries) {
          debugPrint('[EducationalContentAPI] Max retries ($maxRetries) reached');
          rethrow;
        }

        debugPrint(
            '[EducationalContentAPI] Retry attempt $attempt/$maxRetries after ${delay.inSeconds}s');
        await Future.delayed(delay);

        // Exponential backoff: 1s, 2s, 4s
        delay *= 2;
      }
    }
  }

  /// Convert DioException to EducationalContentApiException
  EducationalContentApiException _handleDioError(DioException e) {
    debugPrint('[EducationalContentAPI] Error: ${e.type} - ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return EducationalContentApiException(
          message: 'Request timeout. Please check your internet connection.',
          statusCode: 408,
          error: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final responseData = e.response?.data;

        String message;
        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'];
        } else if (responseData is Map && responseData.containsKey('error')) {
          message = responseData['error'];
        } else if (statusCode == 401) {
          message = 'Unauthorized. Please check API credentials.';
        } else if (statusCode == 404) {
          message = 'Content not found.';
        } else if (statusCode == 422) {
          message = 'Invalid request parameters.';
        } else if (statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Request failed with status code $statusCode';
        }

        return EducationalContentApiException(
          message: message,
          statusCode: statusCode,
          error: e,
        );

      case DioExceptionType.cancel:
        return EducationalContentApiException(
          message: 'Request cancelled.',
          error: e,
        );

      case DioExceptionType.connectionError:
        return EducationalContentApiException(
          message:
              'Connection failed. Please check your internet connection and try again.',
          error: e,
        );

      default:
        return EducationalContentApiException(
          message: e.message ?? 'An unexpected error occurred.',
          error: e,
        );
    }
  }
}
