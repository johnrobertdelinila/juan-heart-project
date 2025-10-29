import 'medical_triage_assessment_service.dart';
import 'genkit_assessment_service.dart';

/// Abstract strategy for heart disease risk assessment
///
/// This allows switching between different assessment methods:
/// - Rule-Based: PHC-validated clinical algorithm (offline)
/// - AI-Powered: Gemini Flash via Genkit backend (online)
abstract class AssessmentStrategy {
  /// Assess heart disease risk from user input data
  /// Returns a map containing risk scores, category, and recommendations
  Future<Map<String, dynamic>> assessHeartDiseaseRisk(
    Map<String, dynamic> userInput,
  );

  /// Human-readable name of this assessment method
  String get strategyName;

  /// Short description of how this method works
  String get description;

  /// Badge text (e.g., "VALIDATED", "AI-POWERED", "EXPERIMENTAL")
  String get badgeText;

  /// Whether this strategy requires internet connection
  bool get requiresInternet;

  /// Whether this strategy is clinically validated
  bool get isValidated;
}

/// Rule-based assessment strategy using PHC-validated algorithm
///
/// This is the default, offline-capable assessment method that uses
/// the clinically validated Likelihood × Impact scoring system.
class RuleBasedAssessmentStrategy implements AssessmentStrategy {
  final MedicalTriageAssessmentService _service = MedicalTriageAssessmentService();

  @override
  String get strategyName => 'PHC Rule-Based Algorithm';

  @override
  String get description => 'Clinically validated scoring system based on AHA/ACC guidelines';

  @override
  String get badgeText => 'VALIDATED';

  @override
  bool get requiresInternet => false;

  @override
  bool get isValidated => true;

  @override
  Future<Map<String, dynamic>> assessHeartDiseaseRisk(
    Map<String, dynamic> userInput,
  ) async {
    print('📊 RULE-BASED ASSESSMENT: Starting...');

    // Call the existing rule-based service
    final result = _service.assessHeartDiseaseRisk(userInput);

    // Add metadata to indicate this is from rule-based system
    result['assessmentMethod'] = 'rule_based';
    result['validated'] = true;

    print('✅ RULE-BASED ASSESSMENT: Complete');
    return result;
  }
}

/// AI-powered assessment strategy using Genkit + Gemini Flash
///
/// This experimental method uses Google's Gemini Flash model to analyze
/// patient data and provide risk assessments. It validates results against
/// the rule-based system and requires internet connectivity.
class AIAssessmentStrategy implements AssessmentStrategy {
  final GenkitAssessmentService _genkitService = GenkitAssessmentService();

  @override
  String get strategyName => 'Gemini AI Prediction';

  @override
  String get description => 'Advanced AI-powered assessment with contextual insights';

  @override
  String get badgeText => 'EXPERIMENTAL';

  @override
  bool get requiresInternet => true;

  @override
  bool get isValidated => false; // Experimental, validated against rule-based

  @override
  Future<Map<String, dynamic>> assessHeartDiseaseRisk(
    Map<String, dynamic> userInput,
  ) async {
    print('🤖 AI ASSESSMENT: Starting...');

    try {
      // Call Genkit backend
      final result = await _genkitService.assessHeartDiseaseRisk(userInput);

      // Add metadata
      result['assessmentMethod'] = 'ai';
      result['validated'] = result['validated'] ?? false;

      print('✅ AI ASSESSMENT: Complete');
      return result;

    } catch (e) {
      print('❌ AI ASSESSMENT: Failed - $e');

      // Fallback to rule-based system
      print('🔄 Falling back to rule-based assessment...');
      final fallbackStrategy = RuleBasedAssessmentStrategy();
      final fallbackResult = await fallbackStrategy.assessHeartDiseaseRisk(userInput);

      // Mark that fallback was used
      fallbackResult['assessmentMethod'] = 'ai_fallback';
      fallbackResult['fallbackReason'] = e.toString();
      fallbackResult['fallbackUsed'] = true;

      return fallbackResult;
    }
  }
}

/// Context class for managing assessment strategy selection
///
/// This class maintains the current assessment strategy and provides
/// methods to switch between strategies at runtime.
class AssessmentContext {
  AssessmentStrategy _strategy;

  AssessmentContext(this._strategy);

  /// Set a new assessment strategy
  void setStrategy(AssessmentStrategy strategy) {
    _strategy = strategy;
    print('🔄 Assessment strategy changed to: ${_strategy.strategyName}');
  }

  /// Get the current strategy
  AssessmentStrategy get currentStrategy => _strategy;

  /// Perform assessment using the current strategy
  Future<Map<String, dynamic>> performAssessment(
    Map<String, dynamic> userInput,
  ) async {
    return await _strategy.assessHeartDiseaseRisk(userInput);
  }

  /// Get the current strategy name
  String get currentStrategyName => _strategy.strategyName;

  /// Check if current strategy requires internet
  bool get requiresInternet => _strategy.requiresInternet;
}
