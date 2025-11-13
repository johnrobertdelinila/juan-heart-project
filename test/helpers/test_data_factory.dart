import 'dart:math';
import 'package:juan_heart/database/entities/assessment_entity.dart';
import 'package:juan_heart/database/entities/facility_entity.dart';
import 'package:juan_heart/database/entities/appointment_entity.dart';
import 'package:juan_heart/database/entities/user_entity.dart';
import 'package:juan_heart/database/entities/educational_content_entity.dart';

/// Factory for creating test data entities with sensible defaults.
///
/// Reduces test boilerplate and ensures consistent test data across test files.
/// All factory methods accept optional parameters for customization.
class TestDataFactory {
  static final _random = Random();

  /// Create test assessment entity
  static AssessmentEntity createAssessment({
    String? id,
    String? userId,
    int? likelihoodScore,
    int? impactScore,
    int? finalRiskScore,
    String? riskCategory,
    String? symptomsData,
    String? vitalSignsData,
    String? recommendationsData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return AssessmentEntity(
      id: id ?? 'test-assessment-${_random.nextInt(10000)}',
      userId: userId ?? 'test-user-1',
      likelihoodScore: likelihoodScore ?? 3,
      impactScore: impactScore ?? 4,
      finalRiskScore: finalRiskScore ?? 12,
      riskCategory: riskCategory ?? 'moderate',
      symptomsData: symptomsData ?? '{"chest_pain": true, "shortness_of_breath": false}',
      vitalSignsData: vitalSignsData ?? '{"systolic": 130, "diastolic": 85, "heart_rate": 72}',
      recommendationsData: recommendationsData ?? '["lifestyle_changes", "follow_up"]',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? false,
    );
  }

  /// Create test facility entity
  static FacilityEntity createFacility({
    String? id,
    String? name,
    String? type,
    double? latitude,
    double? longitude,
    String? address,
    String? municipality,
    String? province,
    String? services,
    String? contactNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FacilityEntity(
      id: id ?? 'facility-${_random.nextInt(10000)}',
      name: name ?? 'Test Hospital ${_random.nextInt(100)}',
      type: type ?? 'hospital',
      latitude: latitude ?? 14.5995,
      longitude: longitude ?? 120.9842,
      address: address ?? '123 Test St, Manila',
      municipality: municipality ?? 'Manila',
      province: province ?? 'Metro Manila',
      services: services ?? '["emergency", "cardiology", "general_medicine"]',
      contactNumber: contactNumber ?? '+63 2 8888 8888',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create test appointment entity
  static AppointmentEntity createAppointment({
    String? id,
    String? userId,
    String? facilityId,
    DateTime? appointmentDateTime,
    String? status,
    String? priority,
    String? visitType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return AppointmentEntity(
      id: id ?? 'appointment-${_random.nextInt(10000)}',
      userId: userId ?? 'test-user-1',
      facilityId: facilityId ?? 'facility-1',
      appointmentDateTime: appointmentDateTime ?? DateTime.now().add(const Duration(days: 7)),
      status: status ?? 'pending',
      priority: priority ?? 'routine',
      visitType: visitType ?? 'consultation',
      notes: notes,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? false,
    );
  }

  /// Create test user entity
  static UserEntity createUser({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    String? municipality,
    String? province,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return UserEntity(
      id: id ?? 'user-${_random.nextInt(10000)}',
      email: email ?? 'test${_random.nextInt(1000)}@example.com',
      firstName: firstName ?? 'Test',
      lastName: lastName ?? 'User',
      age: age ?? 35,
      gender: gender ?? 'male',
      phoneNumber: phoneNumber ?? '+63 912 345 6789',
      address: address ?? '123 Test St',
      municipality: municipality ?? 'Manila',
      province: province ?? 'Metro Manila',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? false,
    );
  }

  /// Create test educational content entity
  static EducationalContentEntity createEducationalContent({
    String? id,
    String? titleEn,
    String? titleFil,
    String? summaryEn,
    String? summaryFil,
    String? contentEn,
    String? contentFil,
    String? category,
    String? imageUrl,
    int? readingTimeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EducationalContentEntity(
      id: id ?? 'content-${_random.nextInt(10000)}',
      titleEn: titleEn ?? 'Heart Health Tips',
      titleFil: titleFil ?? 'Mga Tip para sa Kalusugan ng Puso',
      summaryEn: summaryEn ?? 'Learn about heart health',
      summaryFil: summaryFil ?? 'Matuto tungkol sa kalusugan ng puso',
      contentEn: contentEn ?? 'Heart health is important...',
      contentFil: contentFil ?? 'Ang kalusugan ng puso ay mahalaga...',
      category: category ?? 'cvd_prevention',
      imageUrl: imageUrl ?? 'https://example.com/heart.jpg',
      readingTimeMinutes: readingTimeMinutes ?? 5,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create list of test assessments
  static List<AssessmentEntity> createAssessments(int count, {String? userId}) {
    return List.generate(count, (index) => createAssessment(
      id: 'assessment-$index',
      userId: userId,
      finalRiskScore: 5 + _random.nextInt(20),
      createdAt: DateTime.now().subtract(Duration(days: count - index)),
    ));
  }

  /// Create list of test facilities
  static List<FacilityEntity> createFacilities(int count) {
    return List.generate(count, (index) => createFacility(
      id: 'facility-$index',
      name: 'Hospital ${index + 1}',
      latitude: 14.5995 + (_random.nextDouble() * 0.1),
      longitude: 120.9842 + (_random.nextDouble() * 0.1),
    ));
  }

  /// Create list of test appointments
  static List<AppointmentEntity> createAppointments(int count, {String? userId}) {
    return List.generate(count, (index) => createAppointment(
      id: 'appointment-$index',
      userId: userId,
      appointmentDateTime: DateTime.now().add(Duration(days: index + 1)),
      status: index % 3 == 0 ? 'confirmed' : 'pending',
    ));
  }

  /// Create test conflict scenario data
  static Map<String, dynamic> createConflictScenario({
    required String id,
    required String type,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? serverData,
  }) {
    return {
      'id': id,
      'type': type,
      'local': localData ?? {
        'id': id,
        'data': 'local_value',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'server': serverData ?? {
        'id': id,
        'data': 'server_value',
        'updatedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
    };
  }

  /// Create GPS coordinate pair
  static Map<String, double> createGPSCoordinates({
    double? latitude,
    double? longitude,
  }) {
    return {
      'latitude': latitude ?? (14.5 + _random.nextDouble()),
      'longitude': longitude ?? (120.5 + _random.nextDouble()),
    };
  }

  /// Create Manila coordinates (default user location)
  static Map<String, double> getManilaCoordinates() {
    return {
      'latitude': 14.5995,
      'longitude': 120.9842,
    };
  }

  /// Create Quezon City coordinates
  static Map<String, double> getQuezonCityCoordinates() {
    return {
      'latitude': 14.6760,
      'longitude': 121.0437,
    };
  }

  /// Create Cebu City coordinates
  static Map<String, double> getCebuCityCoordinates() {
    return {
      'latitude': 10.3157,
      'longitude': 123.8854,
    };
  }
}
