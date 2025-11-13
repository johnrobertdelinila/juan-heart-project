import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:juan_heart/core/constants/api_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/geospatial_service.dart';

/// Service to sync assessment data to backend database
class AssessmentSyncService {
  /// Sync assessment to backend database
  static Future<Map<String, dynamic>> syncAssessmentToBackend(
    AssessmentRecord record,
  ) async {
    debugPrint('\n${'='*80}');
    debugPrint('🚀 JUAN HEART - ASSESSMENT SYNC TO DATABASE STARTED');
    debugPrint('='*80);
    debugPrint('📅 Timestamp: ${DateTime.now()}');
    debugPrint('🆔 Assessment ID: ${record.id}');
    debugPrint('⚠️  Risk Level: ${record.riskCategory} (Score: ${record.finalRiskScore})');

    try {
      // Fetch GPS location and device info
      debugPrint('\n📍 Fetching GPS location and device info...');
      final geoService = GeospatialService();

      // Get current location
      final position = await geoService.getCurrentLocation();
      double latitude = position?.latitude ?? 0.0;
      double longitude = position?.longitude ?? 0.0;

      // Get region and city via reverse geocoding
      Map<String, String>? geocodingResult;
      if (position != null) {
        geocodingResult = await geoService.geocodeCoordinates(latitude, longitude);
      }

      final region = geocodingResult?['region'] ?? 'Unknown';
      final city = geocodingResult?['city'] ?? 'Unknown';

      // Get device info
      final deviceInfo = await geoService.getDeviceInfo();
      final devicePlatform = deviceInfo['platform'] ?? 'Unknown';
      final deviceVersion = deviceInfo['version'] ?? 'Unknown';

      debugPrint('✅ GPS: $latitude, $longitude');
      debugPrint('✅ Location: $city, $region');
      debugPrint('✅ Device: $devicePlatform $deviceVersion');

      final url = Uri.parse('${APIConstant.baseUrl}${APIConstant.assessmentsEndpoint}');
      debugPrint('🌐 Backend URL: $url');
      debugPrint('📡 API Base: ${APIConstant.baseUrl}');

      // Map urgency to backend ENUM values
      String mapUrgency(String riskCategory) {
        switch (riskCategory.toLowerCase()) {
          case 'critical':
          case 'high':
            debugPrint('🚨 Mapping "$riskCategory" → Emergency');
            return 'Emergency';
          case 'moderate':
            debugPrint('⚠️  Mapping "$riskCategory" → Urgent');
            return 'Urgent';
          default:
            debugPrint('✅ Mapping "$riskCategory" → Routine');
            return 'Routine';
        }
      }

      // Map risk level to backend ENUM values (Low, Moderate, High)
      String mapRiskLevel(String riskCategory) {
        switch (riskCategory.toLowerCase()) {
          case 'critical':
          case 'high':
            debugPrint('🔴 Mapping "$riskCategory" → High');
            return 'High';
          case 'moderate':
            debugPrint('🟡 Mapping "$riskCategory" → Moderate');
            return 'Moderate';
          case 'low':
          default:
            debugPrint('🟢 Mapping "$riskCategory" → Low');
            return 'Low';
        }
      }

      // Helper to map gender to valid ENUM values
      String? mapGender(String? gender) {
        if (gender == null || gender.isEmpty) {
          debugPrint('👤 Gender is null/empty, sending null to backend');
          return null;
        }

        final normalized = gender.toLowerCase();
        if (normalized.contains('male') && !normalized.contains('female')) {
          debugPrint('👤 Mapping "$gender" → Male');
          return 'Male';
        } else if (normalized.contains('female')) {
          debugPrint('👤 Mapping "$gender" → Female');
          return 'Female';
        } else if (normalized.contains('other')) {
          debugPrint('👤 Mapping "$gender" → Other');
          return 'Other';
        }
        debugPrint('⚠️  Unknown gender "$gender", sending null');
        return null; // Send null if unknown
      }

      // Prepare payload matching backend expectations
      final payload = {
        'mobile_user_id': record.userId ?? 'MOBILE_USER_${DateTime.now().millisecondsSinceEpoch}',
        'session_id': 'SESSION_${DateTime.now().millisecondsSinceEpoch}',
        'assessment_external_id': record.id,
        'patient_first_name': record.userName?.split(' ').first ?? 'Anonymous',
        'patient_last_name': record.userName?.split(' ').skip(1).join(' ') ?? 'Patient',
        'patient_sex': mapGender(record.userGender) ?? mapGender(record.sex),
        'assessment_date': record.date.toIso8601String(),
        'version': '1.0.0',
        'region': region,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'final_risk_score': record.finalRiskScore,
        'final_risk_level': mapRiskLevel(record.riskCategory),
        'urgency': mapUrgency(record.riskCategory),
        'recommended_action': record.recommendation,
        'vital_signs': {
          'systolic_bp': record.vitalSigns?['systolic_bp'] ?? record.systolicBP,
          'diastolic_bp': record.vitalSigns?['diastolic_bp'] ?? record.diastolicBP,
          'heart_rate': record.vitalSigns?['heart_rate'] ?? record.heartRate,
          'oxygen_saturation': record.vitalSigns?['oxygen_saturation'] ?? record.oxygenSaturation,
          'temperature': record.vitalSigns?['temperature'] ?? record.temperature,
          'weight': record.vitalSigns?['weight'] ?? record.weight,
          'height': record.vitalSigns?['height'] ?? record.height,
          'bmi': record.vitalSigns?['bmi'] ?? record.bmi,
        },
        'symptoms': record.symptoms,
        'medical_history': record.medicalHistory,
        'medications': record.medications ?? [],
        'lifestyle': record.lifestyleFactors,
        'recommendations': {
          'action': record.recommendation,
          'timeframe': record.timeframe,
        },
        'device_platform': devicePlatform,
        'device_version': deviceVersion,
        'app_version': '1.0.0',
        'mobile_created_at': record.date.toIso8601String(),
      };

      debugPrint('\n📦 PAYLOAD BEING SENT TO BACKEND:');
      debugPrint('-' * 80);
      final payloadJson = jsonEncode(payload);
      debugPrint(payloadJson);
      debugPrint('-' * 80);
      debugPrint('📏 Payload size: ${payloadJson.length} bytes');

      debugPrint('\n🔄 Sending POST request to backend...');
      debugPrint('⏱️  Timeout: 10 seconds');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: payloadJson,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ TIMEOUT ERROR: Backend did not respond within 10 seconds');
          debugPrint('💡 Suggestion: Check if Docker containers are running');
          debugPrint('💡 Run: docker ps | grep juan_heart');
          throw Exception('Connection timeout - Please check your network');
        },
      );

      debugPrint('\n📡 BACKEND RESPONSE RECEIVED:');
      debugPrint('-' * 80);
      debugPrint('📊 HTTP Status Code: ${response.statusCode}');
      debugPrint('📨 Response Headers: ${response.headers}');
      debugPrint('📄 Response Body:');
      debugPrint(response.body);
      debugPrint('-' * 80);

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('\n🎯 Processing successful response...');
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          debugPrint('\n${'='*80}');
          debugPrint('✅ SUCCESS - ASSESSMENT SYNCED TO DATABASE');
          debugPrint('='*80);
          debugPrint('📊 Database Record ID: ${data['data']?['id'] ?? 'N/A'}');
          debugPrint('⏰ Synced At: ${data['data']?['synced_at'] ?? DateTime.now()}');
          debugPrint('📱 Assessment External ID: ${record.id}');
          debugPrint('🎉 Status: Successfully saved to MySQL database');
          debugPrint('='*80 + '\n');

          return {
            'success': true,
            'message': 'Assessment synced to database successfully',
            'data': data['data'],
          };
        } else {
          debugPrint('\n${'='*80}');
          debugPrint('⚠️  WARNING - Backend returned success=false');
          debugPrint('='*80);
          debugPrint('📄 Response Data: ${data.toString()}');
          debugPrint('💬 Message: ${data['message'] ?? 'No message provided'}');
          debugPrint('='*80 + '\n');

          return {
            'success': false,
            'message': data['message'] ?? 'Failed to sync assessment',
          };
        }
      } else {
        debugPrint('\n${'='*80}');
        debugPrint('❌ ERROR - HTTP ${response.statusCode}');
        debugPrint('='*80);

        try {
          final errorData = jsonDecode(response.body);
          debugPrint('📄 Error Response: ${errorData.toString()}');
          debugPrint('💬 Message: ${errorData['message'] ?? 'No message'}');
          debugPrint('🔍 Error Details: ${errorData['error'] ?? 'No details'}');

          if (errorData['errors'] != null) {
            debugPrint('📋 Validation Errors:');
            (errorData['errors'] as Map).forEach((key, value) {
              debugPrint('   - $key: $value');
            });
          }
        } catch (parseError) {
          debugPrint('⚠️  Could not parse error response as JSON');
          debugPrint('📄 Raw Response: ${response.body}');
        }

        debugPrint('='*80 + '\n');

        return {
          'success': false,
          'message': 'Failed to sync assessment - HTTP ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('\n${'='*80}');
      debugPrint('💥 EXCEPTION DURING SYNC');
      debugPrint('='*80);
      debugPrint('🔴 Exception Type: ${e.runtimeType}');
      debugPrint('💬 Error Message: $e');
      debugPrint('📚 Stack Trace:');
      debugPrint(stackTrace.toString());
      debugPrint('='*80);
      debugPrint('💡 Troubleshooting Tips:');
      debugPrint('   1. Verify Docker containers are running: docker ps');
      debugPrint('   2. Check backend logs: docker logs juan_heart_backend');
      debugPrint('   3. Test API manually: curl http://localhost:8000/api/v1/assessments');
      debugPrint('   4. Verify network connectivity');
      debugPrint('='*80 + '\n');

      return {
        'success': false,
        'message': 'Error syncing assessment',
        'error': e.toString(),
      };
    } finally {
      debugPrint('🏁 Assessment sync attempt completed\n');
    }
  }

  /// Capitalize first letter of string
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Batch sync multiple assessments
  static Future<Map<String, dynamic>> syncBatchAssessments(
    List<AssessmentRecord> records,
  ) async {
    debugPrint('\n${'='*80}');
    debugPrint('📦 BATCH SYNC STARTED');
    debugPrint('='*80);
    debugPrint('📊 Total Assessments to Sync: ${records.length}');
    debugPrint('⏱️  Start Time: ${DateTime.now()}');
    debugPrint('='*80 + '\n');

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];
    final startTime = DateTime.now();

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      debugPrint('🔄 Syncing assessment ${i + 1}/${records.length}: ${record.id}');

      final result = await syncAssessmentToBackend(record);
      if (result['success'] == true) {
        successCount++;
        debugPrint('   ✅ Success ($successCount/${records.length})');
      } else {
        failureCount++;
        errors.add('${record.id}: ${result['message'] ?? 'Unknown error'}');
        debugPrint('   ❌ Failed ($failureCount/${records.length})');
      }
      debugPrint('');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    debugPrint('\n${'='*80}');
    debugPrint('📦 BATCH SYNC COMPLETED');
    debugPrint('='*80);
    debugPrint('✅ Successful: $successCount');
    debugPrint('❌ Failed: $failureCount');
    debugPrint('📊 Total: ${records.length}');
    debugPrint('⏱️  Duration: ${duration.inSeconds}s');
    debugPrint('📈 Success Rate: ${((successCount / records.length) * 100).toStringAsFixed(1)}%');

    if (errors.isNotEmpty) {
      debugPrint('\n❌ Failed Assessments:');
      for (final error in errors) {
        debugPrint('   - $error');
      }
    }

    debugPrint('='*80 + '\n');

    return {
      'success': failureCount == 0,
      'total': records.length,
      'synced': successCount,
      'failed': failureCount,
      'errors': errors,
    };
  }

  /// Check backend connectivity
  static Future<bool> checkBackendConnectivity() async {
    debugPrint('\n🔍 Checking backend connectivity...');
    final startTime = DateTime.now();

    try {
      final url = Uri.parse('${APIConstant.baseUrl}${APIConstant.assessmentsEndpoint}/statistics');
      debugPrint('📡 Testing URL: $url');
      debugPrint('⏱️  Timeout: 5 seconds');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ Connectivity check timed out after 5 seconds');
          throw Exception('Connection timeout');
        },
      );

      final duration = DateTime.now().difference(startTime);
      debugPrint('📊 HTTP Status: ${response.statusCode}');
      debugPrint('⚡ Response Time: ${duration.inMilliseconds}ms');

      if (response.statusCode == 200) {
        debugPrint('✅ Backend is ONLINE and responding\n');
        return true;
      } else {
        debugPrint('⚠️  Backend returned status ${response.statusCode}');
        debugPrint('❌ Backend connectivity: FAILED\n');
        return false;
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Connectivity check FAILED after ${duration.inMilliseconds}ms');
      debugPrint('🔴 Error: $e');
      debugPrint('💡 Troubleshooting:');
      debugPrint('   1. Check Docker containers: docker ps');
      debugPrint('   2. Verify backend is running: curl http://localhost:8000/api/v1/health');
      debugPrint('   3. Check network connection');
      debugPrint('   4. Ensure API base URL is correct: ${APIConstant.baseUrl}\n');
      return false;
    }
  }
}
