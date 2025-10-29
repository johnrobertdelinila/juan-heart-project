import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'medical_triage_assessment_service.dart';

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
    print('🤖 GENKIT SERVICE: Starting AI assessment...');

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

      print('✅ GENKIT SERVICE: AI assessment complete');
      return validated;

    } catch (e) {
      print('❌ GENKIT SERVICE: Error - $e');
      rethrow; // Let AssessmentStrategy handle fallback
    }
  }

  /// Check internet connectivity by pinging a reliable endpoint
  Future<bool> _checkConnectivity() async {
    try {
      print('🌐 Checking internet connectivity...');
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));

      final connected = response.statusCode == 200;
      print(connected ? '✅ Internet available' : '❌ No internet');
      return connected;

    } catch (e) {
      print('❌ Connectivity check failed: $e');
      return false;
    }
  }

  /// Call the Genkit backend flow with user assessment data
  Future<Map<String, dynamic>> _callGenkitBackend(
    Map<String, dynamic> userInput,
  ) async {
    print('📡 Calling Genkit backend: $_backendUrl');

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

      print('✅ Genkit backend response received');
      return result;

    } catch (e) {
      print('❌ Genkit backend call failed: $e');
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
    print('🔍 Validating AI result against rule-based system...');

    try {
      // Run rule-based assessment
      final ruleBasedService = MedicalTriageAssessmentService();
      final ruleBasedResult = ruleBasedService.assessHeartDiseaseRisk(userInput);

      // Extract scores
      final aiScore = aiResult['finalRiskScore'] as int? ?? 0;
      final ruleBasedScore = ruleBasedResult['finalRiskScore'] as int? ?? 0;

      // Calculate difference
      final scoreDifference = (aiScore - ruleBasedScore).abs();

      print('📊 AI Score: $aiScore | Rule-Based Score: $ruleBasedScore | Difference: $scoreDifference');

      // Add validation metadata
      aiResult['ruleBasedScore'] = ruleBasedScore;
      aiResult['ruleBasedCategory'] = ruleBasedResult['riskCategory'];
      aiResult['ruleBasedRecommendation'] = ruleBasedResult['recommendedAction'];
      aiResult['scoreDifference'] = scoreDifference;
      aiResult['validated'] = true;

      // Add warning if discrepancy is large
      if (scoreDifference > _maxScoreDifference) {
        print('⚠️ Large discrepancy detected! Difference: $scoreDifference points');

        aiResult['hasDiscrepancy'] = true;
        aiResult['discrepancyWarning'] =
            'AI and rule-based assessments differ by $scoreDifference points. Both results are shown for your review.';
      } else {
        aiResult['hasDiscrepancy'] = false;
      }

      // Add full rule-based result for comparison view
      aiResult['ruleBasedFullResult'] = ruleBasedResult;

      print('✅ Validation complete');
      return aiResult;

    } catch (e) {
      print('❌ Validation failed: $e');
      // Still return AI result even if validation fails
      aiResult['validated'] = false;
      aiResult['validationError'] = e.toString();
      return aiResult;
    }
  }

  /// Sanitize user input to ensure it matches Genkit backend schema
  ///
  /// This removes any extra fields and ensures proper data types.
  Map<String, dynamic> _sanitizeInput(Map<String, dynamic> userInput) {
    // Create clean copy with only expected fields
    final sanitized = <String, dynamic>{};

    // Demographics (required)
    if (userInput.containsKey('age')) sanitized['age'] = userInput['age'];
    if (userInput.containsKey('sex')) sanitized['sex'] = userInput['sex'];

    // Symptoms (optional)
    if (userInput.containsKey('chestPainType')) {
      sanitized['chestPainType'] = userInput['chestPainType'];
    }
    if (userInput.containsKey('chestPainDuration')) {
      sanitized['chestPainDuration'] = userInput['chestPainDuration'];
    }
    if (userInput.containsKey('chestPainRadiation')) {
      sanitized['chestPainRadiation'] = userInput['chestPainRadiation'];
    }
    if (userInput.containsKey('chestPainExertional')) {
      sanitized['chestPainExertional'] = userInput['chestPainExertional'];
    }
    if (userInput.containsKey('shortnessOfBreath')) {
      sanitized['shortnessOfBreath'] = userInput['shortnessOfBreath'];
    }
    if (userInput.containsKey('palpitations')) {
      sanitized['palpitations'] = userInput['palpitations'];
    }
    if (userInput.containsKey('palpitationType')) {
      sanitized['palpitationType'] = userInput['palpitationType'];
    }
    if (userInput.containsKey('syncope')) {
      sanitized['syncope'] = userInput['syncope'];
    }
    if (userInput.containsKey('fainting')) {
      sanitized['fainting'] = userInput['fainting'];
    }
    if (userInput.containsKey('neurologicalSymptoms')) {
      sanitized['neurologicalSymptoms'] = userInput['neurologicalSymptoms'];
    }
    if (userInput.containsKey('legSwelling')) {
      sanitized['legSwelling'] = userInput['legSwelling'];
    }

    // Vital Signs (optional)
    if (userInput.containsKey('systolicBP')) {
      sanitized['systolicBP'] = userInput['systolicBP'];
    }
    if (userInput.containsKey('diastolicBP')) {
      sanitized['diastolicBP'] = userInput['diastolicBP'];
    }
    if (userInput.containsKey('heartRate')) {
      sanitized['heartRate'] = userInput['heartRate'];
    }
    if (userInput.containsKey('oxygenSaturation')) {
      sanitized['oxygenSaturation'] = userInput['oxygenSaturation'];
    }
    if (userInput.containsKey('temperature')) {
      sanitized['temperature'] = userInput['temperature'];
    }

    // Medical History (optional)
    if (userInput.containsKey('diabetes')) {
      sanitized['diabetes'] = userInput['diabetes'];
    }
    if (userInput.containsKey('hypertension')) {
      sanitized['hypertension'] = userInput['hypertension'];
    }
    if (userInput.containsKey('ckd')) {
      sanitized['ckd'] = userInput['ckd'];
    }
    if (userInput.containsKey('highCholesterol')) {
      sanitized['highCholesterol'] = userInput['highCholesterol'];
    }
    if (userInput.containsKey('previousHeartDisease')) {
      sanitized['previousHeartDisease'] = userInput['previousHeartDisease'];
    }

    // Lifestyle (optional)
    if (userInput.containsKey('smoking')) {
      sanitized['smoking'] = userInput['smoking'];
    }
    if (userInput.containsKey('obesity')) {
      sanitized['obesity'] = userInput['obesity'];
    }
    if (userInput.containsKey('familyHistory')) {
      sanitized['familyHistory'] = userInput['familyHistory'];
    }

    return sanitized;
  }
}
