/// Data models for the Referral & Care Navigation System
/// 
/// Supports risk-based care recommendations and facility referrals
/// Aligned with Philippine Heart Center (PHC) triage guidelines

import 'package:flutter/material.dart';

/// Urgency levels for medical care
enum CareUrgency {
  none,        // Self-care at home
  monitor,     // Monitor and recheck within 1-2 weeks
  routine,     // Schedule check-up within 48 hours
  urgent,      // Visit clinic/hospital within 6-24 hours
  emergency,   // Go to ER immediately
}

/// Healthcare facility types
enum FacilityType {
  barangayHealthCenter,
  primaryCarClinic,
  hospital,
  emergencyFacility,
}

/// Care recommendation based on risk assessment
class CareRecommendation {
  final String riskCategory;
  final int riskScore;
  final CareUrgency urgency;
  final String actionTitle;
  final String actionMessage;
  final String detailedGuidance;
  final Color indicatorColor;
  final IconData urgencyIcon;
  final List<FacilityType> recommendedFacilities;
  
  CareRecommendation({
    required this.riskCategory,
    required this.riskScore,
    required this.urgency,
    required this.actionTitle,
    required this.actionMessage,
    required this.detailedGuidance,
    required this.indicatorColor,
    required this.urgencyIcon,
    required this.recommendedFacilities,
  });
  
  /// Get urgency timeframe text
  String get timeframe {
    switch (urgency) {
      case CareUrgency.none:
        return 'No immediate action required';
      case CareUrgency.monitor:
        return 'Within 1-2 weeks';
      case CareUrgency.routine:
        return 'Within 24-48 hours';
      case CareUrgency.urgent:
        return 'Within 6-24 hours';
      case CareUrgency.emergency:
        return 'Immediately';
    }
  }
  
  /// Check if this is an emergency situation
  bool get isEmergency => urgency == CareUrgency.emergency;
  
  /// Check if urgent care is needed
  bool get isUrgent => urgency == CareUrgency.urgent || urgency == CareUrgency.emergency;
  
  Map<String, dynamic> toMap() {
    return {
      'riskCategory': riskCategory,
      'riskScore': riskScore,
      'urgency': urgency.toString(),
      'actionTitle': actionTitle,
      'actionMessage': actionMessage,
      'detailedGuidance': detailedGuidance,
      'timeframe': timeframe,
      'isEmergency': isEmergency,
    };
  }
}

/// Healthcare facility information
class HealthcareFacility {
  final String id;
  final String name;
  final FacilityType type;
  final String address;
  final double latitude;
  final double longitude;
  final String? contactNumber;
  final String? emergencyNumber;
  final bool is24Hours;
  final List<String> services;
  final String? description;
  
  // Distance from user (calculated dynamically)
  double? distanceKm;
  
  HealthcareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.contactNumber,
    this.emergencyNumber,
    this.is24Hours = false,
    this.services = const [],
    this.description,
    this.distanceKm,
  });
  
  /// Get facility type display name
  String get typeName {
    switch (type) {
      case FacilityType.barangayHealthCenter:
        return 'Barangay Health Center';
      case FacilityType.primaryCarClinic:
        return 'Primary Care Clinic';
      case FacilityType.hospital:
        return 'Hospital';
      case FacilityType.emergencyFacility:
        return 'Emergency Facility';
    }
  }
  
  /// Get facility type icon
  IconData get typeIcon {
    switch (type) {
      case FacilityType.barangayHealthCenter:
        return Icons.local_hospital_outlined;
      case FacilityType.primaryCarClinic:
        return Icons.medical_services_outlined;
      case FacilityType.hospital:
        return Icons.local_hospital;
      case FacilityType.emergencyFacility:
        return Icons.emergency;
    }
  }
  
  /// Get primary contact number (emergency if available, otherwise regular)
  String? get primaryContact => emergencyNumber ?? contactNumber;
  
  /// Format distance for display
  String get distanceText {
    if (distanceKm == null) return 'Distance unknown';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} meters away';
    }
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }
  
  /// Get Google Maps URL
  String get mapsUrl {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'typeName': typeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contactNumber': contactNumber,
      'emergencyNumber': emergencyNumber,
      'is24Hours': is24Hours,
      'services': services,
      'description': description,
      'distanceKm': distanceKm,
    };
  }
  
  factory HealthcareFacility.fromMap(Map<String, dynamic> map) {
    return HealthcareFacility(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: _facilityTypeFromString(map['type'] ?? 'hospital'),
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      contactNumber: map['contactNumber'],
      emergencyNumber: map['emergencyNumber'],
      is24Hours: map['is24Hours'] ?? false,
      services: List<String>.from(map['services'] ?? []),
      description: map['description'],
      distanceKm: map['distanceKm']?.toDouble(),
    );
  }
  
  static FacilityType _facilityTypeFromString(String type) {
    switch (type) {
      case 'barangayHealthCenter':
        return FacilityType.barangayHealthCenter;
      case 'primaryCarClinic':
        return FacilityType.primaryCarClinic;
      case 'hospital':
        return FacilityType.hospital;
      case 'emergencyFacility':
        return FacilityType.emergencyFacility;
      default:
        return FacilityType.hospital;
    }
  }
}

/// Referral summary for PDF generation and sharing
class ReferralSummary {
  final CareRecommendation recommendation;
  final HealthcareFacility? selectedFacility;
  final DateTime assessmentDate;
  final String patientName;
  final int patientAge;
  final String patientSex;
  
  ReferralSummary({
    required this.recommendation,
    this.selectedFacility,
    required this.assessmentDate,
    required this.patientName,
    required this.patientAge,
    required this.patientSex,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'recommendation': recommendation.toMap(),
      'selectedFacility': selectedFacility?.toMap(),
      'assessmentDate': assessmentDate.toIso8601String(),
      'patientName': patientName,
      'patientAge': patientAge,
      'patientSex': patientSex,
    };
  }
}

