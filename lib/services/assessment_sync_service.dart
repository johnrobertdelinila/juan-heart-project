import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:juan_heart/core/constants/api_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';

/// Service to sync assessment data to backend database
class AssessmentSyncService {
  /// Sync assessment to backend database
  static Future<Map<String, dynamic>> syncAssessmentToBackend(
    AssessmentRecord record,
  ) async {
    print('\n' + '='*80);
    print('🚀 JUAN HEART - ASSESSMENT SYNC TO DATABASE STARTED');
    print('='*80);
    print('📅 Timestamp: ${DateTime.now()}');
    print('🆔 Assessment ID: ${record.id}');
    print('⚠️  Risk Level: ${record.riskCategory} (Score: ${record.finalRiskScore})');

    try {
      final url = Uri.parse('${APIConstant.baseUrl}${APIConstant.assessmentsEndpoint}');
      print('🌐 Backend URL: $url');
      print('📡 API Base: ${APIConstant.baseUrl}');

      // Map urgency to backend ENUM values
      String mapUrgency(String riskCategory) {
        switch (riskCategory.toLowerCase()) {
          case 'critical':
          case 'high':
            print('🚨 Mapping "$riskCategory" → Emergency');
            return 'Emergency';
          case 'moderate':
            print('⚠️  Mapping "$riskCategory" → Urgent');
            return 'Urgent';
          default:
            print('✅ Mapping "$riskCategory" → Routine');
            return 'Routine';
        }
      }

      // Map risk level to backend ENUM values (Low, Moderate, High)
      String mapRiskLevel(String riskCategory) {
        switch (riskCategory.toLowerCase()) {
          case 'critical':
          case 'high':
            print('🔴 Mapping "$riskCategory" → High');
            return 'High';
          case 'moderate':
            print('🟡 Mapping "$riskCategory" → Moderate');
            return 'Moderate';
          case 'low':
          default:
            print('🟢 Mapping "$riskCategory" → Low');
            return 'Low';
        }
      }

      // Helper to map gender to valid ENUM values
      String? mapGender(String? gender) {
        if (gender == null || gender.isEmpty) {
          print('👤 Gender is null/empty, sending null to backend');
          return null;
        }

        final normalized = gender.toLowerCase();
        if (normalized.contains('male') && !normalized.contains('female')) {
          print('👤 Mapping "$gender" → Male');
          return 'Male';
        } else if (normalized.contains('female')) {
          print('👤 Mapping "$gender" → Female');
          return 'Female';
        } else if (normalized.contains('other')) {
          print('👤 Mapping "$gender" → Other');
          return 'Other';
        }
        print('⚠️  Unknown gender "$gender", sending null');
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
        'region': 'Metro Manila', // TODO: Get from user location
        'city': 'Quezon City', // TODO: Get from user location
        'latitude': 14.6760, // TODO: Get from device GPS
        'longitude': 121.0437, // TODO: Get from device GPS
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
        'device_platform': 'iOS', // TODO: Detect actual platform
        'device_version': '17.0', // TODO: Get device version
        'app_version': '1.0.0',
        'mobile_created_at': record.date.toIso8601String(),
      };

      print('\n📦 PAYLOAD BEING SENT TO BACKEND:');
      print('-' * 80);
      final payloadJson = jsonEncode(payload);
      print(payloadJson);
      print('-' * 80);
      print('📏 Payload size: ${payloadJson.length} bytes');

      print('\n🔄 Sending POST request to backend...');
      print('⏱️  Timeout: 10 seconds');

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
          print('❌ TIMEOUT ERROR: Backend did not respond within 10 seconds');
          print('💡 Suggestion: Check if Docker containers are running');
          print('💡 Run: docker ps | grep juan_heart');
          throw Exception('Connection timeout - Please check your network');
        },
      );

      print('\n📡 BACKEND RESPONSE RECEIVED:');
      print('-' * 80);
      print('📊 HTTP Status Code: ${response.statusCode}');
      print('📨 Response Headers: ${response.headers}');
      print('📄 Response Body:');
      print(response.body);
      print('-' * 80);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('\n🎯 Processing successful response...');
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('\n' + '='*80);
          print('✅ SUCCESS - ASSESSMENT SYNCED TO DATABASE');
          print('='*80);
          print('📊 Database Record ID: ${data['data']?['id'] ?? 'N/A'}');
          print('⏰ Synced At: ${data['data']?['synced_at'] ?? DateTime.now()}');
          print('📱 Assessment External ID: ${record.id}');
          print('🎉 Status: Successfully saved to MySQL database');
          print('='*80 + '\n');

          return {
            'success': true,
            'message': 'Assessment synced to database successfully',
            'data': data['data'],
          };
        } else {
          print('\n' + '='*80);
          print('⚠️  WARNING - Backend returned success=false');
          print('='*80);
          print('📄 Response Data: ${data.toString()}');
          print('💬 Message: ${data['message'] ?? 'No message provided'}');
          print('='*80 + '\n');

          return {
            'success': false,
            'message': data['message'] ?? 'Failed to sync assessment',
          };
        }
      } else {
        print('\n' + '='*80);
        print('❌ ERROR - HTTP ${response.statusCode}');
        print('='*80);

        try {
          final errorData = jsonDecode(response.body);
          print('📄 Error Response: ${errorData.toString()}');
          print('💬 Message: ${errorData['message'] ?? 'No message'}');
          print('🔍 Error Details: ${errorData['error'] ?? 'No details'}');

          if (errorData['errors'] != null) {
            print('📋 Validation Errors:');
            (errorData['errors'] as Map).forEach((key, value) {
              print('   - $key: $value');
            });
          }
        } catch (parseError) {
          print('⚠️  Could not parse error response as JSON');
          print('📄 Raw Response: ${response.body}');
        }

        print('='*80 + '\n');

        return {
          'success': false,
          'message': 'Failed to sync assessment - HTTP ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e, stackTrace) {
      print('\n' + '='*80);
      print('💥 EXCEPTION DURING SYNC');
      print('='*80);
      print('🔴 Exception Type: ${e.runtimeType}');
      print('💬 Error Message: $e');
      print('📚 Stack Trace:');
      print(stackTrace.toString());
      print('='*80);
      print('💡 Troubleshooting Tips:');
      print('   1. Verify Docker containers are running: docker ps');
      print('   2. Check backend logs: docker logs juan_heart_backend');
      print('   3. Test API manually: curl http://localhost:8000/api/v1/assessments');
      print('   4. Verify network connectivity');
      print('='*80 + '\n');

      return {
        'success': false,
        'message': 'Error syncing assessment',
        'error': e.toString(),
      };
    } finally {
      print('🏁 Assessment sync attempt completed\n');
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
    print('\n' + '='*80);
    print('📦 BATCH SYNC STARTED');
    print('='*80);
    print('📊 Total Assessments to Sync: ${records.length}');
    print('⏱️  Start Time: ${DateTime.now()}');
    print('='*80 + '\n');

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];
    final startTime = DateTime.now();

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      print('🔄 Syncing assessment ${i + 1}/${records.length}: ${record.id}');

      final result = await syncAssessmentToBackend(record);
      if (result['success'] == true) {
        successCount++;
        print('   ✅ Success (${successCount}/${records.length})');
      } else {
        failureCount++;
        errors.add('${record.id}: ${result['message'] ?? 'Unknown error'}');
        print('   ❌ Failed (${failureCount}/${records.length})');
      }
      print('');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('\n' + '='*80);
    print('📦 BATCH SYNC COMPLETED');
    print('='*80);
    print('✅ Successful: $successCount');
    print('❌ Failed: $failureCount');
    print('📊 Total: ${records.length}');
    print('⏱️  Duration: ${duration.inSeconds}s');
    print('📈 Success Rate: ${((successCount / records.length) * 100).toStringAsFixed(1)}%');

    if (errors.isNotEmpty) {
      print('\n❌ Failed Assessments:');
      for (final error in errors) {
        print('   - $error');
      }
    }

    print('='*80 + '\n');

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
    print('\n🔍 Checking backend connectivity...');
    final startTime = DateTime.now();

    try {
      final url = Uri.parse('${APIConstant.baseUrl}${APIConstant.assessmentsEndpoint}/statistics');
      print('📡 Testing URL: $url');
      print('⏱️  Timeout: 5 seconds');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Connectivity check timed out after 5 seconds');
          throw Exception('Connection timeout');
        },
      );

      final duration = DateTime.now().difference(startTime);
      print('📊 HTTP Status: ${response.statusCode}');
      print('⚡ Response Time: ${duration.inMilliseconds}ms');

      if (response.statusCode == 200) {
        print('✅ Backend is ONLINE and responding\n');
        return true;
      } else {
        print('⚠️  Backend returned status ${response.statusCode}');
        print('❌ Backend connectivity: FAILED\n');
        return false;
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('❌ Connectivity check FAILED after ${duration.inMilliseconds}ms');
      print('🔴 Error: $e');
      print('💡 Troubleshooting:');
      print('   1. Check Docker containers: docker ps');
      print('   2. Verify backend is running: curl http://localhost:8000/api/v1/health');
      print('   3. Check network connection');
      print('   4. Ensure API base URL is correct: ${APIConstant.baseUrl}\n');
      return false;
    }
  }
}
