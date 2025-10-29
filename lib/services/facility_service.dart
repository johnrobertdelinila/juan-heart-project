/// Healthcare Facility Service
/// 
/// Manages healthcare facility data and location-based queries
/// Supports both static data (for testing) and API integration (for production)
/// 
/// Features:
/// - Fetch nearby facilities based on GPS location
/// - Calculate distance from user
/// - Filter by facility type
/// - Sort by distance or urgency
/// 
/// Data source can be:
/// 1. Static mock data (current implementation)
/// 2. Local JSON file
/// 3. Remote API (future enhancement)

import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:juan_heart/models/referral_data.dart';

class FacilityService {
  /// Get nearby healthcare facilities
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
    // Get all available facilities
    List<HealthcareFacility> facilities = _getMockFacilities();
    
    // Filter by facility type if specified
    if (facilityTypes != null && facilityTypes.isNotEmpty) {
      facilities = facilities.where((f) => facilityTypes.contains(f.type)).toList();
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
      print('Error getting location: $e');
      return null;
    }
  }
  
  /// Mock facility data for testing
  /// 
  /// In production, this should be replaced with:
  /// 1. API call to fetch real facility data
  /// 2. Local database with facility information
  /// 3. Integration with Google Places API or similar
  /// 
  /// Current data includes facilities in Metro Manila area
  static List<HealthcareFacility> _getMockFacilities() {
    return [
      // Philippine Heart Center (Quezon City)
      HealthcareFacility(
        id: 'phc-001',
        name: 'Philippine Heart Center',
        type: FacilityType.hospital,
        address: 'East Avenue, Diliman, Quezon City, 1100 Metro Manila',
        latitude: 14.6490,
        longitude: 121.0479,
        contactNumber: '(02) 8925-2401',
        emergencyNumber: '(02) 8925-2401',
        is24Hours: true,
        services: ['Cardiology', 'Emergency Care', 'ICU', 'Cardiac Surgery'],
        description: 'National tertiary cardiovascular center providing specialized heart care',
      ),
      
      // National Center for Mental Health (Mandaluyong)
      HealthcareFacility(
        id: 'ncmh-001',
        name: 'National Center for Mental Health',
        type: FacilityType.hospital,
        address: 'Nueve de Febrero Street, Mauway, Mandaluyong, Metro Manila',
        latitude: 14.5728,
        longitude: 121.0288,
        contactNumber: '(02) 8531-9001',
        is24Hours: true,
        services: ['Emergency Care', 'General Medicine', 'Mental Health'],
        description: 'National government hospital providing comprehensive health services',
      ),
      
      // Quezon City General Hospital
      HealthcareFacility(
        id: 'qcgh-001',
        name: 'Quezon City General Hospital',
        type: FacilityType.emergencyFacility,
        address: 'Seminary Road, Bahay Toro, Project 8, Quezon City',
        latitude: 14.6869,
        longitude: 121.0525,
        contactNumber: '(02) 8426-1314',
        emergencyNumber: '(02) 8426-1314',
        is24Hours: true,
        services: ['Emergency Care', 'General Medicine', 'Surgery', 'Cardiology'],
        description: 'City-run hospital with 24/7 emergency services',
      ),
      
      // Manila Doctors Hospital
      HealthcareFacility(
        id: 'mdh-001',
        name: 'Manila Doctors Hospital',
        type: FacilityType.hospital,
        address: '667 United Nations Avenue, Ermita, Manila',
        latitude: 14.5831,
        longitude: 120.9831,
        contactNumber: '(02) 8558-0888',
        emergencyNumber: '(02) 8524-3011',
        is24Hours: true,
        services: ['Emergency Care', 'Cardiology', 'ICU', 'General Medicine'],
        description: 'Private tertiary hospital with comprehensive cardiac services',
      ),
      
      // St. Luke\'s Medical Center - Quezon City
      HealthcareFacility(
        id: 'slmc-qc-001',
        name: 'St. Luke\'s Medical Center - Quezon City',
        type: FacilityType.hospital,
        address: '279 E Rodriguez Sr. Avenue, Cathedral Heights, Quezon City',
        latitude: 14.6231,
        longitude: 121.0344,
        contactNumber: '(02) 8723-0101',
        emergencyNumber: '(02) 8723-0301',
        is24Hours: true,
        services: ['Emergency Care', 'Cardiology', 'Cardiac Surgery', 'ICU'],
        description: 'Premier tertiary hospital with world-class cardiac care',
      ),
      
      // Barangay Health Center - Batasan Hills
      HealthcareFacility(
        id: 'bhc-batasan-001',
        name: 'Batasan Hills Barangay Health Center',
        type: FacilityType.barangayHealthCenter,
        address: 'Batasan Hills, Quezon City',
        latitude: 14.6833,
        longitude: 121.1098,
        contactNumber: '(02) 8937-5432',
        is24Hours: false,
        services: ['Primary Care', 'Consultation', 'Blood Pressure Monitoring'],
        description: 'Community health center providing basic medical services',
      ),
      
      // Makati Medical Center
      HealthcareFacility(
        id: 'mmc-001',
        name: 'Makati Medical Center',
        type: FacilityType.hospital,
        address: '2 Amorsolo Street, Legaspi Village, Makati City',
        latitude: 14.5623,
        longitude: 121.0166,
        contactNumber: '(02) 8888-8999',
        emergencyNumber: '(02) 8815-9911',
        is24Hours: true,
        services: ['Emergency Care', 'Cardiology', 'ICU', 'Cardiac Surgery'],
        description: 'Leading private hospital with comprehensive heart care',
      ),
      
      // Primary Care Clinic - Cubao
      HealthcareFacility(
        id: 'pcc-cubao-001',
        name: 'Cubao Medical Clinic',
        type: FacilityType.primaryCarClinic,
        address: 'P. Tuazon Boulevard, Cubao, Quezon City',
        latitude: 14.6189,
        longitude: 121.0512,
        contactNumber: '(02) 8912-3456',
        is24Hours: false,
        services: ['General Consultation', 'ECG', 'Blood Pressure Monitoring'],
        description: 'Walk-in clinic for routine medical consultations',
      ),
      
      // Veterans Memorial Medical Center
      HealthcareFacility(
        id: 'vmmc-001',
        name: 'Veterans Memorial Medical Center',
        type: FacilityType.hospital,
        address: 'North Avenue, Diliman, Quezon City',
        latitude: 14.6518,
        longitude: 121.0425,
        contactNumber: '(02) 8927-0181',
        emergencyNumber: '(02) 8927-0181',
        is24Hours: true,
        services: ['Emergency Care', 'General Medicine', 'Surgery', 'Cardiology'],
        description: 'Government tertiary hospital providing affordable healthcare',
      ),
      
      // Barangay Health Center - Commonwealth
      HealthcareFacility(
        id: 'bhc-commonwealth-001',
        name: 'Commonwealth Barangay Health Center',
        type: FacilityType.barangayHealthCenter,
        address: 'Commonwealth Avenue, Quezon City',
        latitude: 14.7079,
        longitude: 121.0889,
        contactNumber: '(02) 8953-7890',
        is24Hours: false,
        services: ['Primary Care', 'Health Monitoring', 'Referrals'],
        description: 'Community health center for basic healthcare needs',
      ),
    ];
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
  static HealthcareFacility? getFacilityById(String id) {
    try {
      return _getMockFacilities().firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }
}

