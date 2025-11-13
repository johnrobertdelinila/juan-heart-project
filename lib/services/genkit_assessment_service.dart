import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'medical_triage_assessment_service.dart';
import 'performance_service.dart';

/// Service for AI-powered heart disease risk assessment using Genkit + Gemini Flash
///
/// This service calls the Firebase Genkit backend flow for AI predictions,
/// validates results against the rule-based system, and handles errors gracefully.
class GenkitAssessmentService {
  /// Backend Genkit flow URL from environment variables
  static String get _backendUrl {
    final url = dotenv.env['GENKIT_BACKEND_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('GENKIT_BACKEND_URL not found in .env file');
    }
    return url;
  }

  /// Timeout duration for API calls
  static const Duration _timeout = Duration(seconds: 10);

  /// Maximum score difference allowed before showing warning
  static const int _maxScoreDifference = 5;

  /// Assess heart disease risk using AI (Gemini Flash via Genkit)
  ///
  /// This method:
  /// 1. Checks internet connectivity
  /// 2. Calls the Genkit backend flow
  /// 3. Validates the AI result against rule-based system
  /// 4. Returns the AI assessment with validation metadata
  ///
  /// If any step fails, it automatically falls back to the rule-based system.
  Future<Map<String, dynamic>> assessHeartDiseaseRisk(
    Map<String, dynamic> userInput,
  ) async {
    debugPrint('🤖 GENKIT SERVICE: Starting AI assessment...');

    try {
      // Step 1: Check internet connectivity
      final hasInternet = await _checkConnectivity();
      if (!hasInternet) {
        throw Exception('No internet connection available');
      }

      // Step 2: Call Genkit backend
      final aiResult = await _callGenkitBackend(userInput);

      // Step 3: Validate against rule-based system
      final validated = await _validateAgainstRuleBasedSystem(
        aiResult,
        userInput,
      );

      debugPrint('✅ GENKIT SERVICE: AI assessment complete');
      return validated;

    } catch (e) {
      debugPrint('❌ GENKIT SERVICE: Error - $e');
      rethrow; // Let AssessmentStrategy handle fallback
    }
  }

  /// Check internet connectivity by pinging a reliable endpoint
  Future<bool> _checkConnectivity() async {
    try {
      debugPrint('🌐 Checking internet connectivity...');
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));

      final connected = response.statusCode == 200;
      debugPrint(connected ? '✅ Internet available' : '❌ No internet');
      return connected;

    } catch (e) {
      debugPrint('❌ Connectivity check failed: $e');
      return false;
    }
  }

  /// Call the Genkit backend flow with user assessment data
  Future<Map<String, dynamic>> _callGenkitBackend(
    Map<String, dynamic> userInput,
  ) async {
    debugPrint('📡 Calling Genkit backend: $_backendUrl');

    // Start Genkit API call trace
    final apiTrace = await PerformanceService.instance.startGenkitApiTrace();
    bool success = false;
    int responseSize = 0;

    try {
      // Prepare request body (Genkit expects data wrapped in "data" field)
      final requestBody = {
        'data': _sanitizeInput(userInput),
      };

      // Call the backend
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        _timeout,
        onTimeout: () => throw Exception('Genkit API timeout (>10s)'),
      );

      // Track response size
      responseSize = response.bodyBytes.length;

      // Handle response
      if (response.statusCode != 200) {
        throw Exception(
          'Genkit API error: ${response.statusCode} - ${response.body}',
        );
      }

      // Parse response
      final data = jsonDecode(response.body);

      // Genkit returns result in "result" field
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        throw Exception('Invalid response format from Genkit backend');
      }

      success = true;
      debugPrint('✅ Genkit backend response received');

      // Stop trace with success metrics
      await PerformanceService.instance.stopGenkitApiTrace(
        apiTrace,
        success: success,
        responseSize: responseSize,
      );

      return result;

    } catch (e) {
      debugPrint('❌ Genkit backend call failed: $e');

      // Stop trace with failure metrics
      await PerformanceService.instance.stopGenkitApiTrace(
        apiTrace,
        success: false,
        responseSize: responseSize,
      );

      rethrow;
    }
  }

  /// Validate AI result against rule-based system
  ///
  /// This compares the AI's scores with the rule-based algorithm's scores
  /// and adds validation metadata to help users understand discrepancies.
  Future<Map<String, dynamic>> _validateAgainstRuleBasedSystem(
    Map<String, dynamic> aiResult,
    Map<String, dynamic> userInput,
  ) async {
    debugPrint('🔍 Validating AI result against rule-based system...');

    try {
      // Run rule-based assessment
      final ruleBasedService = MedicalTriageAssessmentService();
      final ruleBasedResult = ruleBasedService.assessHeartDiseaseRisk(userInput);

      // Extract scores
      final aiScore = aiResult['finalRiskScore'] as int? ?? 0;
      final ruleBasedScore = ruleBasedResult['finalRiskScore'] as int? ?? 0;

      // Calculate difference
      final scoreDifference = (aiScore - ruleBasedScore).abs();

      debugPrint('📊 AI Score: $aiScore | Rule-Based Score: $ruleBasedScore | Difference: $scoreDifference');

      // Add validation metadata
      aiResult['ruleBasedScore'] = ruleBasedScore;
      aiResult['ruleBasedCategory'] = ruleBasedResult['riskCategory'];
      aiResult['ruleBasedRecommendation'] = ruleBasedResult['recommendedAction'];
      aiResult['scoreDifference'] = scoreDifference;
      aiResult['validated'] = true;

      // Add warning if discrepancy is large
      if (scoreDifference > _maxScoreDifference) {
        debugPrint('⚠️ Large discrepancy detected! Difference: $scoreDifference points');

        aiResult['hasDiscrepancy'] = true;
        aiResult['discrepancyWarning'] =
            'AI and rule-based assessments differ by $scoreDifference points. Both results are shown for your review.';
      } else {
        aiResult['hasDiscrepancy'] = false;
      }

      // Add full rule-based result for comparison view
      aiResult['ruleBasedFullResult'] = ruleBasedResult;

      // Add missing UI fields for compatibility with existing views
      // Calculate heatmap position from AI scores (0-based index for 5x5 grid)
      aiResult['heatmapPosition'] = {
        'x': (aiResult['likelihoodScore'] as int) - 1,
        'y': (aiResult['impactScore'] as int) - 1,
      };

      // Use rule-based color code and safety message for consistency
      aiResult['colorCode'] = ruleBasedResult['colorCode'];
      aiResult['safetyMessage'] = ruleBasedResult['safetyMessage'];

      debugPrint('✅ Validation complete');
      return aiResult;

    } catch (e) {
      debugPrint('❌ Validation failed: $e');
      // Still return AI result even if validation fails
      aiResult['validated'] = false;
      aiResult['validationError'] = e.toString();
      return aiResult;
    }
  }

  /// Sanitize user input to ensure it matches Genkit backend schema
  ///
  /// This removes any extra fields, excludes empty values, and ensures proper data types.
  Map<String, dynamic> _sanitizeInput(Map<String, dynamic> userInput) {
    // Create clean copy with only expected fields
    final sanitized = <String, dynamic>{};

    // Helper to check if value is not empty
    bool isNotEmpty(dynamic value) {
      if (value == null) return false;
      if (value is String) return value.trim().isNotEmpty;
      return true; // booleans and numbers are always included
    }

    // Helper to parse integer values
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String && value.trim().isNotEmpty) {
        return int.tryParse(value.trim());
      }
      return null;
    }

    // Helper to parse double values
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String && value.trim().isNotEmpty) {
        return double.tryParse(value.trim());
      }
      return null;
    }

    // Demographics (required)
    final age = parseInt(userInput['age']);
    if (age != null) sanitized['age'] = age;

    if (isNotEmpty(userInput['sex'])) {
      sanitized['sex'] = userInput['sex'];
    }

    // Symptoms - String fields (only include if not empty)
    if (isNotEmpty(userInput['chestPainType'])) {
      sanitized['chestPainType'] = userInput['chestPainType'];
    }
    if (isNotEmpty(userInput['shortnessOfBreath'])) {
      sanitized['shortnessOfBreath'] = userInput['shortnessOfBreath'];
    }
    if (isNotEmpty(userInput['palpitationType'])) {
      sanitized['palpitationType'] = userInput['palpitationType'];
    }

    // Symptoms - Numeric fields (only include if not empty)
    final chestPainDuration = parseInt(userInput['chestPainDuration']);
    if (chestPainDuration != null) {
      sanitized['chestPainDuration'] = chestPainDuration;
    }

    // Symptoms - Boolean fields (always include)
    sanitized['chestPainRadiation'] = userInput['chestPainRadiation'] == true;
    sanitized['chestPainExertional'] = userInput['chestPainExertional'] == true;
    sanitized['palpitations'] = userInput['palpitations'] == true;
    sanitized['syncope'] = userInput['syncope'] == true;
    sanitized['fainting'] = userInput['fainting'] == true;
    sanitized['neurologicalSymptoms'] = userInput['neurologicalSymptoms'] == true;
    sanitized['legSwelling'] = userInput['legSwelling'] == true;
    sanitized['sweating'] = userInput['sweating'] == true;
    sanitized['dizziness'] = userInput['dizziness'] == true;
    sanitized['nausea'] = userInput['nausea'] == true;

    // Vital Signs (only include if not empty - CRITICAL FIX)
    final systolicBP = parseInt(userInput['systolicBP']);
    if (systolicBP != null) sanitized['systolicBP'] = systolicBP;

    final diastolicBP = parseInt(userInput['diastolicBP']);
    if (diastolicBP != null) sanitized['diastolicBP'] = diastolicBP;

    final heartRate = parseInt(userInput['heartRate']);
    if (heartRate != null) sanitized['heartRate'] = heartRate;

    final oxygenSaturation = parseDouble(userInput['oxygenSaturation']);
    if (oxygenSaturation != null) sanitized['oxygenSaturation'] = oxygenSaturation;

    final temperature = parseDouble(userInput['temperature']);
    if (temperature != null) sanitized['temperature'] = temperature;

    // Medical History - Boolean fields (always include)
    sanitized['diabetes'] = userInput['diabetes'] == true;
    sanitized['hypertension'] = userInput['hypertension'] == true;
    sanitized['ckd'] = userInput['ckd'] == true;
    sanitized['highCholesterol'] = userInput['highCholesterol'] == true;
    sanitized['previousHeartDisease'] = userInput['previousHeartDisease'] == true;

    // Lifestyle - Boolean fields (always include)
    sanitized['smoking'] = userInput['smoking'] == true;
    sanitized['obesity'] = userInput['obesity'] == true;
    sanitized['familyHistory'] = userInput['familyHistory'] == true;

    return sanitized;
  }
}
