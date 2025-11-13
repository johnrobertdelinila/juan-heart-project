/// Healthcare Facility Service (Updated with Backend Integration)
///
/// Manages healthcare facility data with hybrid online/offline strategy
/// Supports both backend API (online) and local cache (offline)
///
/// Features:
/// - Fetch nearby facilities based on GPS location
/// - Calculate distance from user
/// - Filter by facility type
/// - Sort by distance or urgency
/// - Hybrid mode: Online fetches from backend, offline uses cache
/// - Automatic sync with backend API
///
/// Data sources:
/// 1. Backend API (primary) - via FacilityApiService
/// 2. Local Drift database (cache) - via AppDatabase
/// 3. Mock data (fallback) - via mock_facilities.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/data/mock_facilities.dart';
import 'package:juan_heart/services/api/facility_api_service.dart';
import 'package:juan_heart/database/app_database.dart';

enum FacilityDataSource {
  backend, // Backend API (online)
  cache, // Local Drift database
  mock, // Mock data (fallback)
}

class FacilityService {
  // Singleton pattern
  static FacilityService? _instance;
  static FacilityService get instance {
    _instance ??= FacilityService._();
    return _instance!;
  }

  FacilityService._();

  // Dependencies
  late final FacilityApiService _apiService;
  late final AppDatabase _database;

  // Configuration
  bool _useBackendApi = false; // Feature flag: enable backend API
  FacilityDataSource _lastDataSource = FacilityDataSource.mock;

  // Sync state
  DateTime? _lastSyncTimestamp;
  bool _isSyncing = false;

  /// Initialize service with dependencies
  void initialize({
    FacilityApiService? apiService,
    AppDatabase? database,
    bool useBackendApi = false,
  }) {
    _apiService = apiService ?? FacilityApiService();
    _database = database ?? AppDatabase();
    _useBackendApi = useBackendApi;
    _loadLastSyncTimestamp();
  }

  /// Enable or disable backend API usage
  void setBackendApiEnabled(bool enabled) {
    _useBackendApi = enabled;
    debugPrint('[FacilityService] Backend API ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get last data source used
  FacilityDataSource get lastDataSource => _lastDataSource;

  /// Check if sync is needed (last sync > 24 hours ago)
  bool get syncNeeded {
    if (_lastSyncTimestamp == null) return true;
    final hoursSinceSync = DateTime.now().difference(_lastSyncTimestamp!).inHours;
    return hoursSinceSync >= 24;
  }

  /// Get nearby healthcare facilities
  ///
  /// Hybrid strategy:
  /// 1. If backend API enabled and online: Fetch from backend, cache in database
  /// 2. If offline or API fails: Use cached database
  /// 3. If database empty: Fallback to mock data
  ///
  /// [userLocation] - Current GPS position of user
  /// [facilityTypes] - Filter by specific facility types (optional)
  /// [maxDistance] - Maximum distance in kilometers (default: 25 km)
  /// [maxResults] - Maximum number of results (default: 10)
  static Future<List<HealthcareFacility>> getNearbyFacilities({
    required Position userLocation,
    List<FacilityType>? facilityTypes,
    double maxDistance = 25.0,
    int maxResults = 10,
  }) async {
    final service = FacilityService.instance;

    try {
      List<HealthcareFacility> facilities;

      // Strategy 1: Try backend API if enabled
      if (service._useBackendApi) {
        try {
          debugPrint('[FacilityService] Fetching from backend API');
          final apiModels = await service._apiService.searchNearbyFacilities(
            userLocation.latitude,
            userLocation.longitude,
            maxDistance,
          );

          // Convert API models to HealthcareFacility
          facilities = apiModels
              .map((model) => model.toHealthcareFacility())
              .toList();

          // Cache in database for offline use
          await service._cacheApiModels(apiModels);

          service._lastDataSource = FacilityDataSource.backend;
          debugPrint('[FacilityService] Fetched ${facilities.length} facilities from backend');
        } catch (e) {
          debugPrint('[FacilityService] Backend API failed: $e');
          // Fallback to cache
          facilities = await service._getFacilitiesFromCache(
            userLocation,
            maxDistance,
          );
          service._lastDataSource = FacilityDataSource.cache;
        }
      } else {
        // Strategy 2: Use cached database
        facilities = await service._getFacilitiesFromCache(
          userLocation,
          maxDistance,
        );
        service._lastDataSource = FacilityDataSource.cache;
      }

      // Strategy 3: Fallback to mock data if cache empty
      if (facilities.isEmpty) {
        debugPrint('[FacilityService] Cache empty, using mock data');
        facilities = _getMockFacilities();
        service._lastDataSource = FacilityDataSource.mock;
      }

      // Filter by facility type if specified
      if (facilityTypes != null && facilityTypes.isNotEmpty) {
        facilities = facilities
            .where((f) => facilityTypes.contains(f.type))
            .toList();
      }

      // Calculate distance for each facility
      for (var facility in facilities) {
        facility.distanceKm = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          facility.latitude,
          facility.longitude,
        );
      }

      // Filter by max distance
      facilities = facilities.where((f) => f.distanceKm! <= maxDistance).toList();

      // Sort by distance
      facilities.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

      // Limit results
      if (facilities.length > maxResults) {
        facilities = facilities.sublist(0, maxResults);
      }

      return facilities;
    } catch (e) {
      debugPrint('[FacilityService] Error getting nearby facilities: $e');
      rethrow;
    }
  }

  /// Get facilities from cached database
  Future<List<HealthcareFacility>> _getFacilitiesFromCache(
    Position userLocation,
    double maxDistance,
  ) async {
    try {
      // Calculate bounding box for efficient query
      final boundingBox = _calculateBoundingBox(
        userLocation.latitude,
        userLocation.longitude,
        maxDistance,
      );

      // Query database with bounding box
      final entities = await _database.getFacilitiesInBoundingBox(
        minLat: boundingBox['minLat']!,
        maxLat: boundingBox['maxLat']!,
        minLon: boundingBox['minLon']!,
        maxLon: boundingBox['maxLon']!,
      );

      debugPrint('[FacilityService] Fetched ${entities.length} facilities from cache');

      // Convert to HealthcareFacility
      return entities.map((entity) => _convertEntityToFacility(entity)).toList();
    } catch (e) {
      debugPrint('[FacilityService] Error fetching from cache: $e');
      return [];
    }
  }

  /// Cache API models in database
  Future<void> _cacheApiModels(List<dynamic> apiModels) async {
    try {
      await _database.importFacilitiesFromBackend(apiModels);
      debugPrint('[FacilityService] Cached ${apiModels.length} facilities in database');
    } catch (e) {
      debugPrint('[FacilityService] Error caching facilities: $e');
    }
  }

  /// Convert database entity to HealthcareFacility
  HealthcareFacility _convertEntityToFacility(FacilityEntity entity) {
    // Map database type to FacilityType enum
    FacilityType facilityType;
    switch (entity.type.toLowerCase()) {
      case 'health_center':
      case 'barangay_health_center':
        facilityType = FacilityType.barangayHealthCenter;
        break;
      case 'clinic':
      case 'primary_care_clinic':
        facilityType = FacilityType.primaryCarClinic;
        break;
      case 'emergency':
        facilityType = FacilityType.emergencyFacility;
        break;
      default:
        facilityType = entity.hasEmergencyService && entity.is24Hours
            ? FacilityType.emergencyFacility
            : FacilityType.hospital;
    }

    return HealthcareFacility(
      id: entity.id,
      name: entity.name,
      type: facilityType,
      address: _buildFullAddress(entity),
      latitude: entity.latitude,
      longitude: entity.longitude,
      contactNumber: entity.contactNumber,
      emergencyNumber:
          entity.hasEmergencyService ? entity.contactNumber : null,
      is24Hours: entity.is24Hours,
      services: entity.services.split(',').map((s) => s.trim()).toList(),
      description: null,
    );
  }

  /// Build full address from entity
  String _buildFullAddress(FacilityEntity entity) {
    final parts = [
      entity.address,
      entity.municipality,
      entity.province,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }

  /// Calculate bounding box for geospatial queries
  ///
  /// Returns min/max latitude and longitude for a square around the center point
  /// Used to pre-filter database queries before precise distance calculation
  Map<String, double> _calculateBoundingBox(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    // Approximate degrees per km (at equator)
    // 1 degree latitude ≈ 111 km
    // 1 degree longitude ≈ 111 km * cos(latitude)
    final latDelta = radiusKm / 111.0;
    final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180));

    return {
      'minLat': latitude - latDelta,
      'maxLat': latitude + latDelta,
      'minLon': longitude - lonDelta,
      'maxLon': longitude + lonDelta,
    };
  }

  /// Sync facilities from backend
  ///
  /// Performs incremental sync: only fetches facilities updated since last sync
  /// Caches results in database for offline use
  ///
  /// Returns number of facilities synced
  Future<int> syncFacilities() async {
    if (_isSyncing) {
      debugPrint('[FacilityService] Sync already in progress');
      return 0;
    }

    _isSyncing = true;
    try {
      debugPrint('[FacilityService] Starting facility sync');

      final apiModels = await _apiService.syncFacilities(_lastSyncTimestamp);

      if (apiModels.isNotEmpty) {
        await _cacheApiModels(apiModels);
        _lastSyncTimestamp = DateTime.now();
        await _saveLastSyncTimestamp();
        debugPrint('[FacilityService] Synced ${apiModels.length} facilities');
      } else {
        debugPrint('[FacilityService] No facilities to sync');
      }

      return apiModels.length;
    } catch (e) {
      debugPrint('[FacilityService] Sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Manual sync trigger - forces immediate sync
  Future<int> syncNow() async {
    return syncFacilities();
  }

  /// Load last sync timestamp from SharedPreferences
  Future<void> _loadLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('last_facility_sync');
      if (timestamp != null) {
        _lastSyncTimestamp = DateTime.parse(timestamp);
        debugPrint('[FacilityService] Last sync: $_lastSyncTimestamp');
      }
    } catch (e) {
      debugPrint('[FacilityService] Error loading last sync timestamp: $e');
    }
  }

  /// Save last sync timestamp to SharedPreferences
  Future<void> _saveLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_facility_sync',
        _lastSyncTimestamp!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('[FacilityService] Error saving last sync timestamp: $e');
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth radius in km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Check and request location permissions
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Open device location settings
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionDeniedForever() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  /// Mock facility data for testing (fallback)
  static List<HealthcareFacility> _getMockFacilities() {
    final mockData = MockFacilityData.getAllFacilities();
    return mockData.map((data) => _convertMockDataToFacility(data)).toList();
  }

  /// Convert mock data map to HealthcareFacility object
  static HealthcareFacility _convertMockDataToFacility(
      Map<String, dynamic> data) {
    FacilityType facilityType;
    switch (data['type']) {
      case 'Hospital':
        facilityType = FacilityType.hospital;
        break;
      case 'Clinic':
        facilityType = FacilityType.primaryCarClinic;
        break;
      case 'Health Center':
        facilityType = FacilityType.barangayHealthCenter;
        break;
      case 'Emergency Facility':
        facilityType = FacilityType.emergencyFacility;
        break;
      default:
        facilityType = FacilityType.hospital;
    }

    List<String> servicesList = [];
    if (data['services'] != null && data['services'] is String) {
      servicesList = (data['services'] as String)
          .split(',')
          .map((s) => s.trim())
          .toList();
    }

    String? emergencyNum;
    if (data['emergencyServices'] == true && data['contactNumber'] != null) {
      emergencyNum = data['contactNumber'];
    }

    return HealthcareFacility(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: facilityType,
      address: '${data['address']}, ${data['municipality']}, ${data['province']}',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      contactNumber: data['contactNumber'],
      emergencyNumber: emergencyNum,
      is24Hours: data['open24Hours'] ?? false,
      services: servicesList,
      description: data['description'],
    );
  }

  /// Get emergency facilities only
  static Future<List<HealthcareFacility>> getEmergencyFacilities({
    required Position userLocation,
    double maxDistance = 25.0,
  }) async {
    return getNearbyFacilities(
      userLocation: userLocation,
      facilityTypes: [
        FacilityType.emergencyFacility,
        FacilityType.hospital,
      ],
      maxDistance: maxDistance,
      maxResults: 5,
    );
  }

  /// Get facility by ID
  static Future<HealthcareFacility?> getFacilityById(String id) async {
    final service = FacilityService.instance;

    try {
      // Try backend API first if enabled
      if (service._useBackendApi) {
        try {
          final apiModel = await service._apiService.getFacility(id);
          return apiModel.toHealthcareFacility();
        } catch (e) {
          debugPrint('[FacilityService] Backend API failed for ID $id: $e');
        }
      }

      // Try cache
      final entity = await service._database.getFacilityById(id);
      if (entity != null) {
        return service._convertEntityToFacility(entity);
      }

      // Fallback to mock data
      return _getMockFacilities().firstWhere(
        (f) => f.id == id,
        orElse: () => throw Exception('Facility not found'),
      );
    } catch (e) {
      debugPrint('[FacilityService] Error getting facility by ID: $e');
      return null;
    }
  }
}
