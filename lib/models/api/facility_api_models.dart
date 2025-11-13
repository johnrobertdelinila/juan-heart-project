/// API Request and Response Models for Facility API
///
/// Provides type-safe models for backend facility endpoints
/// Matches backend JSON structure from Laravel API

import 'package:juan_heart/models/referral_data.dart';

/// Response wrapper for all facility API endpoints
class FacilityApiResponse<T> {
  final bool success;
  final T? data;
  final FacilityApiMeta? meta;
  final String? message;
  final Map<String, dynamic>? errors;

  const FacilityApiResponse({
    required this.success,
    this.data,
    this.meta,
    this.message,
    this.errors,
  });

  factory FacilityApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return FacilityApiResponse<T>(
      success: json['success'] ?? false,
      data: dataParser != null && json['data'] != null
          ? dataParser(json['data'])
          : json['data'] as T?,
      meta: json['meta'] != null
          ? FacilityApiMeta.fromJson(json['meta'])
          : null,
      message: json['message'] as String?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

/// Metadata included in API responses
class FacilityApiMeta {
  final int? total;
  final DateTime? lastUpdated;
  final String? version;
  final Map<String, dynamic>? filtersApplied;
  final String? since;
  final bool? hasMore;
  final DateTime? generatedAt;
  final Map<String, dynamic>? center;
  final double? radiusKm;

  const FacilityApiMeta({
    this.total,
    this.lastUpdated,
    this.version,
    this.filtersApplied,
    this.since,
    this.hasMore,
    this.generatedAt,
    this.center,
    this.radiusKm,
  });

  factory FacilityApiMeta.fromJson(Map<String, dynamic> json) {
    return FacilityApiMeta(
      total: json['total'] as int?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      version: json['version'] as String?,
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
      since: json['since'] as String?,
      hasMore: json['has_more'] as bool?,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : null,
      center: json['center'] as Map<String, dynamic>?,
      radiusKm: json['radius_km'] != null
          ? (json['radius_km'] as num).toDouble()
          : null,
    );
  }
}

/// Facility model matching backend API structure
class FacilityApiModel {
  final int id;
  final String code;
  final String name;
  final String type;
  final String level;
  final double latitude;
  final double longitude;
  final String address;
  final String? municipality;
  final String? city;
  final String? province;
  final String? region;
  final String? contactNumber;
  final String? phone;
  final String? email;
  final String? website;
  final List<String> services;
  final bool emergencyServices;
  final bool open24Hours;
  final bool acceptsPhilhealth;
  final int? capacity;
  final int? bedCapacity;
  final int? icuCapacity;
  final int? currentBedAvailability;
  final Map<String, dynamic>? operatingHours;
  final bool isPublic;
  final bool isDohAccredited;
  final List<String>? accreditations;
  final bool acceptsReferrals;
  final int? averageResponseTimeHours;
  final List<String>? preferredReferralTypes;
  final bool isActive;
  final String? statusNotes;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? distance;
  final double? bedOccupancyPercentage;

  const FacilityApiModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.level,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.municipality,
    this.city,
    this.province,
    this.region,
    this.contactNumber,
    this.phone,
    this.email,
    this.website,
    required this.services,
    required this.emergencyServices,
    required this.open24Hours,
    required this.acceptsPhilhealth,
    this.capacity,
    this.bedCapacity,
    this.icuCapacity,
    this.currentBedAvailability,
    this.operatingHours,
    required this.isPublic,
    required this.isDohAccredited,
    this.accreditations,
    required this.acceptsReferrals,
    this.averageResponseTimeHours,
    this.preferredReferralTypes,
    required this.isActive,
    this.statusNotes,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.distance,
    this.bedOccupancyPercentage,
  });

  factory FacilityApiModel.fromJson(Map<String, dynamic> json) {
    return FacilityApiModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      level: json['level'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      municipality: json['municipality'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      region: json['region'] as String?,
      contactNumber: json['contact_number'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      emergencyServices: json['emergency_services'] ?? false,
      open24Hours: json['open_24_hours'] ?? false,
      acceptsPhilhealth: json['accepts_philhealth'] ?? false,
      capacity: json['capacity'] as int?,
      bedCapacity: json['bed_capacity'] as int?,
      icuCapacity: json['icu_capacity'] as int?,
      currentBedAvailability: json['current_bed_availability'] as int?,
      operatingHours: json['operating_hours'] as Map<String, dynamic>?,
      isPublic: json['is_public'] ?? true,
      isDohAccredited: json['is_doh_accredited'] ?? false,
      accreditations:
          (json['accreditations'] as List?)?.map((e) => e.toString()).toList(),
      acceptsReferrals: json['accepts_referrals'] ?? true,
      averageResponseTimeHours: json['average_response_time_hours'] as int?,
      preferredReferralTypes: (json['preferred_referral_types'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      isActive: json['is_active'] ?? true,
      statusNotes: json['status_notes'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      distance:
          json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      bedOccupancyPercentage: json['bed_occupancy_percentage'] != null
          ? (json['bed_occupancy_percentage'] as num).toDouble()
          : null,
    );
  }

  /// Convert API model to app's HealthcareFacility model
  HealthcareFacility toHealthcareFacility() {
    // Map backend type to app FacilityType enum
    FacilityType facilityType;
    switch (type.toLowerCase()) {
      case 'health_center':
        facilityType = FacilityType.barangayHealthCenter;
        break;
      case 'clinic':
        facilityType = FacilityType.primaryCarClinic;
        break;
      case 'emergency':
        facilityType = FacilityType.emergencyFacility;
        break;
      case 'hospital':
      case 'medical_center':
      case 'specialty_center':
      default:
        facilityType = emergencyServices && open24Hours
            ? FacilityType.emergencyFacility
            : FacilityType.hospital;
    }

    return HealthcareFacility(
      id: id.toString(),
      name: name,
      type: facilityType,
      address: _buildFullAddress(),
      latitude: latitude,
      longitude: longitude,
      contactNumber: contactNumber ?? phone,
      emergencyNumber: emergencyServices ? (contactNumber ?? phone) : null,
      is24Hours: open24Hours,
      services: services,
      description: description,
      distanceKm: distance,
    );
  }

  /// Build full address string
  String _buildFullAddress() {
    final parts = [
      address,
      municipality ?? city,
      province,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'level': level,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'municipality': municipality,
      'city': city,
      'province': province,
      'region': region,
      'contact_number': contactNumber,
      'phone': phone,
      'email': email,
      'website': website,
      'services': services,
      'emergency_services': emergencyServices,
      'open_24_hours': open24Hours,
      'accepts_philhealth': acceptsPhilhealth,
      'capacity': capacity,
      'bed_capacity': bedCapacity,
      'icu_capacity': icuCapacity,
      'current_bed_availability': currentBedAvailability,
      'operating_hours': operatingHours,
      'is_public': isPublic,
      'is_doh_accredited': isDohAccredited,
      'accreditations': accreditations,
      'accepts_referrals': acceptsReferrals,
      'average_response_time_hours': averageResponseTimeHours,
      'preferred_referral_types': preferredReferralTypes,
      'is_active': isActive,
      'status_notes': statusNotes,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'distance': distance,
      'bed_occupancy_percentage': bedOccupancyPercentage,
    };
  }
}

/// Statistics response model for /count endpoint
class FacilityCountModel {
  final int total;
  final Map<String, int> byType;
  final Map<String, int> byRegion;
  final int withEmergency;
  final int philhealthAccredited;
  final int open24Hours;

  const FacilityCountModel({
    required this.total,
    required this.byType,
    required this.byRegion,
    required this.withEmergency,
    required this.philhealthAccredited,
    required this.open24Hours,
  });

  factory FacilityCountModel.fromJson(Map<String, dynamic> json) {
    return FacilityCountModel(
      total: json['total'] as int,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      byRegion: Map<String, int>.from(json['by_region'] ?? {}),
      withEmergency: json['with_emergency'] as int,
      philhealthAccredited: json['philhealth_accredited'] as int,
      open24Hours: json['open_24_hours'] as int,
    );
  }
}
