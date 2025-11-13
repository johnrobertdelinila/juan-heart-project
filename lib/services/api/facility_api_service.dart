/// Facility API Service
///
/// Handles all backend API requests for healthcare facility data
/// Implements offline-first architecture with error handling and retry logic
///
/// Features:
/// - Fetch facilities with filters (region, type, services, etc.)
/// - Incremental sync - only fetch facilities changed since last sync
/// - Geospatial search - find nearby facilities within radius
/// - Error handling with exponential backoff retry (3 attempts)
/// - Type-safe request/response models
///
/// Backend API Documentation: MOBILE_FACILITY_API_DOCUMENTATION.md

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:juan_heart/models/api/facility_api_models.dart';

class FacilityApiService {
  late final Dio _dio;
  final String baseUrl;
  final int maxRetries;
  final Duration initialRetryDelay;

  /// Create FacilityApiService with custom configuration
  ///
  /// [baseUrl] - API base URL (default: http://localhost:8000/api/v1)
  /// [maxRetries] - Maximum retry attempts (default: 3)
  /// [timeout] - Request timeout in seconds (default: 30)
  FacilityApiService({
    String? baseUrl,
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(seconds: 1),
    int timeout = 30,
  }) : baseUrl = baseUrl ?? 'http://localhost:8000/api/v1' {
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
        logPrint: (obj) => debugPrint('[FacilityAPI] $obj'),
      ));
    }
  }

  /// Fetch facilities with optional query parameters
  ///
  /// [region] - Filter by region (e.g., "National Capital Region")
  /// [type] - Filter by facility type (e.g., "Tertiary Hospital")
  /// [services] - Comma-separated services (e.g., "Cardiology,Emergency")
  /// [emergency] - Set to true to get only facilities with emergency services
  /// [philhealth] - Set to true to get only PhilHealth-accredited facilities
  /// [page] - Page number for pagination (future enhancement)
  /// [perPage] - Items per page (future enhancement)
  ///
  /// Returns list of facilities matching the filters
  /// Throws [FacilityApiException] on error
  Future<List<FacilityApiModel>> fetchFacilities({
    String? region,
    String? type,
    String? services,
    bool? emergency,
    bool? philhealth,
    int? page,
    int? perPage,
  }) async {
    try {
      debugPrint('[FacilityAPI] Fetching facilities with filters: '
          'region=$region, type=$type, services=$services, '
          'emergency=$emergency, philhealth=$philhealth');

      final queryParams = <String, dynamic>{};
      if (region != null) queryParams['region'] = region;
      if (type != null) queryParams['type'] = type;
      if (services != null) queryParams['services'] = services;
      if (emergency != null) queryParams['emergency_only'] = emergency;
      if (philhealth != null) queryParams['philhealth_only'] = philhealth;
      if (page != null) queryParams['page'] = page;
      if (perPage != null) queryParams['per_page'] = perPage;

      final response = await _retryRequest(
        () => _dio.get('/mobile/facilities', queryParameters: queryParams),
      );

      final apiResponse = FacilityApiResponse<List<FacilityApiModel>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((json) => FacilityApiModel.fromJson(json))
            .toList(),
      );

      if (!apiResponse.success) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Failed to fetch facilities',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[FacilityAPI] Successfully fetched ${apiResponse.data?.length ?? 0} facilities');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Incremental sync - fetch only facilities changed since lastSync
  ///
  /// [lastSync] - Timestamp of last successful sync (ISO 8601 format)
  ///
  /// Returns list of facilities updated since the specified timestamp
  /// Throws [FacilityApiException] on error
  Future<List<FacilityApiModel>> syncFacilities(DateTime? lastSync) async {
    try {
      if (lastSync == null) {
        // First sync - fetch all facilities
        debugPrint('[FacilityAPI] First sync - fetching all facilities');
        return fetchFacilities();
      }

      final since = lastSync.toUtc().toIso8601String();
      debugPrint('[FacilityAPI] Incremental sync since: $since');

      final response = await _retryRequest(
        () => _dio.get(
          '/mobile/facilities/sync',
          queryParameters: {'since': since},
        ),
      );

      final apiResponse = FacilityApiResponse<List<FacilityApiModel>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((json) => FacilityApiModel.fromJson(json))
            .toList(),
      );

      if (!apiResponse.success) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Failed to sync facilities',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[FacilityAPI] Sync complete: ${apiResponse.data?.length ?? 0} facilities updated');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Geospatial search - nearby facilities within radius
  ///
  /// [latitude] - Latitude coordinate (-90 to 90)
  /// [longitude] - Longitude coordinate (-180 to 180)
  /// [radiusKm] - Search radius in kilometers (default: 50, max: 100)
  ///
  /// Returns list of facilities sorted by distance (nearest first)
  /// Each facility includes distance field in kilometers
  /// Throws [FacilityApiException] on error
  Future<List<FacilityApiModel>> searchNearbyFacilities(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      // Validate coordinates
      if (latitude < -90 || latitude > 90) {
        throw FacilityApiException(
          message: 'Invalid latitude: must be between -90 and 90',
          statusCode: 422,
        );
      }
      if (longitude < -180 || longitude > 180) {
        throw FacilityApiException(
          message: 'Invalid longitude: must be between -180 and 180',
          statusCode: 422,
        );
      }
      if (radiusKm <= 0 || radiusKm > 100) {
        throw FacilityApiException(
          message: 'Invalid radius: must be between 0 and 100 km',
          statusCode: 422,
        );
      }

      debugPrint('[FacilityAPI] Searching nearby facilities: '
          'lat=$latitude, lon=$longitude, radius=${radiusKm}km');

      final response = await _retryRequest(
        () => _dio.get(
          '/mobile/facilities/nearby',
          queryParameters: {
            'latitude': latitude,
            'longitude': longitude,
            'radius': radiusKm,
          },
        ),
      );

      final apiResponse = FacilityApiResponse<List<FacilityApiModel>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((json) => FacilityApiModel.fromJson(json))
            .toList(),
      );

      if (!apiResponse.success) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Failed to search nearby facilities',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
          '[FacilityAPI] Found ${apiResponse.data?.length ?? 0} nearby facilities');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get single facility by ID
  ///
  /// [id] - Facility ID (integer or string)
  ///
  /// Returns facility details
  /// Throws [FacilityApiException] on error (404 if not found)
  Future<FacilityApiModel> getFacility(String id) async {
    try {
      debugPrint('[FacilityAPI] Fetching facility: $id');

      final response = await _retryRequest(
        () => _dio.get('/mobile/facilities/$id'),
      );

      final apiResponse = FacilityApiResponse<FacilityApiModel>.fromJson(
        response.data,
        (data) => FacilityApiModel.fromJson(data),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Facility not found',
          statusCode: 404,
        );
      }

      debugPrint('[FacilityAPI] Successfully fetched facility: ${apiResponse.data!.name}');
      return apiResponse.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get facility count with filters
  ///
  /// [region] - Filter by region
  /// [type] - Filter by facility type
  /// [services] - Comma-separated services
  /// [emergency] - Set to true to count only emergency facilities
  /// [philhealth] - Set to true to count only PhilHealth-accredited facilities
  ///
  /// Returns statistics including total count and breakdowns by type/region
  /// Throws [FacilityApiException] on error
  Future<FacilityCountModel> getFacilityCount({
    String? region,
    String? type,
    String? services,
    bool? emergency,
    bool? philhealth,
  }) async {
    try {
      debugPrint('[FacilityAPI] Fetching facility count');

      final queryParams = <String, dynamic>{};
      if (region != null) queryParams['region'] = region;
      if (type != null) queryParams['type'] = type;
      if (services != null) queryParams['services'] = services;
      if (emergency != null) queryParams['emergency_only'] = emergency;
      if (philhealth != null) queryParams['philhealth_only'] = philhealth;

      final response = await _retryRequest(
        () => _dio.get('/mobile/facilities/count', queryParameters: queryParams),
      );

      final apiResponse = FacilityApiResponse<FacilityCountModel>.fromJson(
        response.data,
        (data) => FacilityCountModel.fromJson(data),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Failed to fetch facility count',
          statusCode: response.statusCode,
        );
      }

      debugPrint('[FacilityAPI] Total facilities: ${apiResponse.data!.total}');
      return apiResponse.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get available regions
  ///
  /// Returns list of unique region names
  /// Throws [FacilityApiException] on error
  Future<List<String>> getRegions() async {
    try {
      debugPrint('[FacilityAPI] Fetching regions list');

      final response = await _retryRequest(
        () => _dio.get('/mobile/facilities/regions'),
      );

      final apiResponse = FacilityApiResponse<List<String>>.fromJson(
        response.data,
        (data) => (data as List).map((e) => e.toString()).toList(),
      );

      if (!apiResponse.success) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Failed to fetch regions',
          statusCode: response.statusCode,
        );
      }

      debugPrint('[FacilityAPI] Found ${apiResponse.data?.length ?? 0} regions');
      return apiResponse.data ?? [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get available facility types
  ///
  /// Returns list of unique facility type names
  /// Throws [FacilityApiException] on error
  Future<List<String>> getTypes() async {
    try {
      debugPrint('[FacilityAPI] Fetching facility types list');

      final response = await _retryRequest(
        () => _dio.get('/mobile/facilities/types'),
      );

      final apiResponse = FacilityApiResponse<List<String>>.fromJson(
        response.data,
        (data) => (data as List).map((e) => e.toString()).toList(),
      );

      if (!apiResponse.success) {
        throw FacilityApiException(
          message: apiResponse.message ?? 'Failed to fetch facility types',
          statusCode: response.statusCode,
        );
      }

      debugPrint('[FacilityAPI] Found ${apiResponse.data?.length ?? 0} facility types');
      return apiResponse.data ?? [];
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
          debugPrint('[FacilityAPI] Client error - no retry: ${e.response?.statusCode}');
          rethrow;
        }

        if (attempt >= maxRetries) {
          debugPrint('[FacilityAPI] Max retries ($maxRetries) reached');
          rethrow;
        }

        debugPrint('[FacilityAPI] Retry attempt $attempt/$maxRetries after ${delay.inSeconds}s');
        await Future.delayed(delay);

        // Exponential backoff: 1s, 2s, 4s
        delay *= 2;
      }
    }
  }

  /// Convert DioException to FacilityApiException
  FacilityApiException _handleDioError(DioException e) {
    debugPrint('[FacilityAPI] Error: ${e.type} - ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return FacilityApiException(
          message: 'Request timeout. Please check your internet connection.',
          statusCode: 408,
          originalError: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final responseData = e.response?.data;

        String message;
        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'];
        } else if (statusCode == 401) {
          message = 'Unauthorized. Please check API credentials.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode == 422) {
          message = 'Invalid request parameters.';
        } else if (statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Request failed with status code $statusCode';
        }

        return FacilityApiException(
          message: message,
          statusCode: statusCode,
          errors: responseData is Map ? responseData['errors'] : null,
          originalError: e,
        );

      case DioExceptionType.cancel:
        return FacilityApiException(
          message: 'Request cancelled.',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return FacilityApiException(
          message:
              'Connection failed. Please check your internet connection and try again.',
          originalError: e,
        );

      default:
        return FacilityApiException(
          message: e.message ?? 'An unexpected error occurred.',
          originalError: e,
        );
    }
  }
}

/// Custom exception for Facility API errors
class FacilityApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final dynamic originalError;

  FacilityApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.originalError,
  });

  bool get isNetworkError =>
      statusCode == null || statusCode == 408 || statusCode! >= 500;

  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    final buffer = StringBuffer('FacilityApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (errors != null) {
      buffer.write('\nValidation errors: $errors');
    }
    return buffer.toString();
  }
}
