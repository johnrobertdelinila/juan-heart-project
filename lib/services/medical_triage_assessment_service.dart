import '../models/medical_triage_assessment_data.dart';

class MedicalTriageAssessmentService {
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🧠 MEDICAL TRIAGE ASSESSMENT: Initializing...');
    _isInitialized = true;
    print('✅ MEDICAL TRIAGE ASSESSMENT: Initialization complete');
  }

  /// Main prediction method that combines likelihood and impact scoring
  Map<String, dynamic> assessHeartDiseaseRisk(Map<String, dynamic> userInput) {
    print('🧠 MEDICAL TRIAGE ASSESSMENT: Starting risk assessment...');
    print('Input data: $userInput');
    
    try {
      // Validate input
      _validateInput(userInput);
      
      // Calculate likelihood score (1-5)
      int likelihoodScore = _calculateLikelihoodScore(userInput);
      String likelihoodLevel = _getLikelihoodLevel(likelihoodScore);
      
      // Calculate impact score (1-5)
      int impactScore = _calculateImpactScore(userInput);
      String impactLevel = _getImpactLevel(impactScore);
      
      // Calculate final risk score (1-25)
      int finalRiskScore = likelihoodScore * impactScore;
      
      // Get risk classification
      Map<String, dynamic> riskClassification = _getRiskClassification(finalRiskScore);
      
      // Create assessment summary
      Map<String, dynamic> assessment = {
        'likelihoodScore': likelihoodScore,
        'likelihoodLevel': likelihoodLevel,
        'impactScore': impactScore,
        'impactLevel': impactLevel,
        'finalRiskScore': finalRiskScore,
        'riskCategory': riskClassification['category'],
        'colorCode': riskClassification['colorCode'],
        'recommendedAction': riskClassification['action'],
        'safetyMessage': 'If you experience severe chest pain, fainting, or difficulty breathing, seek emergency care immediately.',
        'explanation': _generateExplanation(userInput, likelihoodScore, impactScore, finalRiskScore),
        'heatmapPosition': _getHeatmapPosition(likelihoodScore, impactScore)
      };
      
      print('🎯 MEDICAL TRIAGE ASSESSMENT: Assessment complete');
      print('   Likelihood: $likelihoodScore ($likelihoodLevel)');
      print('   Impact: $impactScore ($impactLevel)');
      print('   Final Risk: $finalRiskScore (${riskClassification['category']})');
      
      return assessment;
      
    } catch (e) {
      print('❌ Error in medical triage assessment: $e');
      rethrow;
    }
  }

  /// Calculate likelihood score based on symptoms and risk factors (Enhanced AHA/ACC Guidelines)
  int _calculateLikelihoodScore(Map<String, dynamic> input) {
    double score = 1.0; // Start from 1 (Improbable)
    
    // Chest pain symptoms - Enhanced scoring
    String chestPainType = input['chestPainType']?.toString().toLowerCase() ?? '';
    int chestPainDuration = int.tryParse(input['chestPainDuration']?.toString() ?? '0') ?? 0;
    bool chestPainRadiation = input['chestPainRadiation'] == true || input['chestPainRadiation'] == 'true';
    bool chestPainExertional = input['chestPainExertional'] == true || input['chestPainExertional'] == 'true';
    
    // +2 for typical chest pain (pressure, exertional, radiating, >10 min)
    bool isTypicalChestPain = (chestPainType.contains('pressure') || chestPainType.contains('crushing')) &&
                             chestPainDuration > 10 && chestPainRadiation && chestPainExertional;
    
    if (isTypicalChestPain) {
      score += 2; // Typical chest pain
    } else if (chestPainType.contains('pressure') || chestPainType.contains('crushing')) {
      score += 1.5; // Atypical but concerning chest pain
    } else if (chestPainType.contains('sharp') || chestPainType.contains('stabbing')) {
      score += 0.5; // Less concerning chest pain
    }
    
    // Shortness of breath - Enhanced scoring
    String sobLevel = input['shortnessOfBreath']?.toString().toLowerCase() ?? '';
    if (sobLevel.contains('at rest') || sobLevel.contains('severe')) {
      score += 2; // +2 for SOB at rest
    } else if (sobLevel.contains('moderate') || sobLevel.contains('exertion')) {
      score += 1; // Moderate SOB
    }
    
    // Syncope or neurological symptoms - +2 each
    if (input['syncope'] == true || input['syncope'] == 'true' || 
        input['fainting'] == true || input['fainting'] == 'true') {
      score += 2; // Syncope
    }
    
    if (input['neurologicalSymptoms'] == true || input['neurologicalSymptoms'] == 'true') {
      score += 2; // Neurological symptoms
    }
    
    // Palpitations with HR >120 or irregular - +1
    int heartRate = int.tryParse(input['heartRate']?.toString() ?? '0') ?? 0;
    String palpitationType = input['palpitationType']?.toString().toLowerCase() ?? '';
    if ((input['palpitations'] == true || input['palpitations'] == 'true') && 
        (heartRate > 120 || palpitationType.contains('irregular'))) {
      score += 1;
    }
    
    // Count major risk factors - +1 for ≥2 major risk factors
    int majorRiskFactors = 0;
    if (input['diabetes'] == true || input['diabetes'] == 'true') majorRiskFactors++;
    if (input['hypertension'] == true || input['hypertension'] == 'true') majorRiskFactors++;
    if (input['ckd'] == true || input['ckd'] == 'true') majorRiskFactors++;
    if (input['highCholesterol'] == true || input['highCholesterol'] == 'true') majorRiskFactors++;
    if (input['previousHeartDisease'] == true || input['previousHeartDisease'] == 'true') majorRiskFactors++;
    if (input['smoking'] == true || input['smoking'] == 'true') majorRiskFactors++;
    
    if (majorRiskFactors >= 2) {
      score += 1; // +1 for ≥2 major risk factors
    }
    
    // Age and sex risk - +1 for age ≥55 (male) or ≥65 (female)
    int age = int.tryParse(input['age']?.toString() ?? '0') ?? 0;
    String sex = input['sex']?.toString().toLowerCase() ?? '';
    if ((sex == 'male' && age >= 55) || (sex == 'female' && age >= 65)) {
      score += 1;
    }
    
    // Map to likelihood bands (Enhanced mapping)
    if (score <= 1) return 1; // Improbable
    if (score <= 3) return 2; // Remote
    if (score <= 5) return 3; // Occasional
    if (score <= 7) return 4; // Probable
    return 5; // Very Probable (≥8)
  }

  /// Calculate impact score based on vital signs and severity (Enhanced AHA/ACC Guidelines)
  int _calculateImpactScore(Map<String, dynamic> input) {
    double score = 1.0; // Start from 1 (Negligible)
    
    // Blood pressure and heart rate - Auto 5 (Critical Override) conditions
    int systolicBP = int.tryParse(input['systolicBP']?.toString() ?? '0') ?? 0;
    int diastolicBP = int.tryParse(input['diastolicBP']?.toString() ?? '0') ?? 0;
    int heartRate = int.tryParse(input['heartRate']?.toString() ?? '0') ?? 0;
    
    // Auto 5 (Critical Override) conditions
    if (systolicBP < 90 || systolicBP > 180 || diastolicBP > 120 || 
        heartRate < 40 || heartRate > 130) {
      return 5; // Critical Override
    }
    
    // Oxygen saturation scoring
    int oxygenSaturation = int.tryParse(input['oxygenSaturation']?.toString() ?? '0') ?? 0;
    if (oxygenSaturation < 92) {
      score += 2; // +2 for SpO₂ <92%
    } else if (oxygenSaturation >= 92 && oxygenSaturation <= 94) {
      score += 1; // +1 for SpO₂ 92-94%
    }
    
    // Persistent chest pain >20 min - +2
    int chestPainDuration = int.tryParse(input['chestPainDuration']?.toString() ?? '0') ?? 0;
    if (chestPainDuration > 20) {
      score += 2; // +2 for persistent chest pain >20 min
    }
    
    // Severe dyspnea (cannot speak full sentences) - +2
    String sobLevel = input['shortnessOfBreath']?.toString().toLowerCase() ?? '';
    if (sobLevel.contains('cannot speak') || sobLevel.contains('severe')) {
      score += 2; // +2 for severe dyspnea
    }
    
    // Leg swelling - +1
    if (input['legSwelling'] == true || input['legSwelling'] == 'true') {
      score += 1; // +1 for leg swelling
    }
    
    // Fever >38.5°C with chest pain or SOB - +1
    double temperature = double.tryParse(input['temperature']?.toString() ?? '0') ?? 0;
    String chestPainType = input['chestPainType']?.toString().toLowerCase() ?? '';
    bool hasChestPain = chestPainType.isNotEmpty && !chestPainType.contains('no');
    bool hasSOB = sobLevel.isNotEmpty && !sobLevel.contains('none');
    
    if (temperature > 38.5 && (hasChestPain || hasSOB)) {
      score += 1; // +1 for fever with chest pain or SOB
    }
    
    // Map to impact bands (Enhanced mapping)
    if (score <= 1) return 1; // Negligible
    if (score <= 2) return 2; // Low
    if (score <= 4) return 3; // Moderate
    if (score <= 6) return 4; // Significant
    return 5; // Critical (≥7 or Auto 5)
  }

  /// Get likelihood level description (Enhanced AHA/ACC Guidelines)
  String _getLikelihoodLevel(int score) {
    switch (score) {
      case 1: return 'Improbable';
      case 2: return 'Remote';
      case 3: return 'Occasional';
      case 4: return 'Probable';
      case 5: return 'Very Probable';
      default: return 'Unknown';
    }
  }

  /// Get impact level description (Enhanced AHA/ACC Guidelines)
  String _getImpactLevel(int score) {
    switch (score) {
      case 1: return 'Negligible';
      case 2: return 'Low';
      case 3: return 'Moderate';
      case 4: return 'Significant';
      case 5: return 'Critical';
      default: return 'Unknown';
    }
  }

  /// Get risk classification based on final score (Enhanced AHA/ACC Guidelines)
  Map<String, dynamic> _getRiskClassification(int finalScore) {
    if (finalScore >= 20) {
      return {
        'category': 'Critical',
        'colorCode': '🟥 Red',
        'action': 'Go to ER immediately and call emergency number'
      };
    } else if (finalScore >= 15) {
      return {
        'category': 'High',
        'colorCode': '🔴 Orange-red',
        'action': 'Urgent clinic or ER advice within 6–24h'
      };
    } else if (finalScore >= 10) {
      return {
        'category': 'Moderate',
        'colorCode': '🟠 Yellow-orange',
        'action': 'Book clinic / teleconsult in 24–48h'
      };
    } else if (finalScore >= 5) {
      return {
        'category': 'Mild',
        'colorCode': '💚 Yellow-green',
        'action': 'Monitor + health tips'
      };
    } else {
      return {
        'category': 'Low',
        'colorCode': '🟢 Green',
        'action': 'Self-care / monitor symptoms'
      };
    }
  }

  /// Get heatmap position for visualization
  Map<String, int> _getHeatmapPosition(int likelihoodScore, int impactScore) {
    return {
      'x': likelihoodScore - 1, // Convert to 0-based index
      'y': impactScore - 1,     // Convert to 0-based index
    };
  }

  /// Generate explanation for the assessment (Enhanced AHA/ACC Guidelines)
  String _generateExplanation(Map<String, dynamic> input, int likelihoodScore, int impactScore, int finalScore) {
    List<String> factors = [];
    
    // Likelihood factors
    if (likelihoodScore >= 4) {
      factors.add('Your pattern suggests a cardiac condition');
    } else if (likelihoodScore >= 3) {
      factors.add('Your pattern may indicate a cardiac condition');
    }
    
    // Impact factors
    if (impactScore >= 4) {
      factors.add('Physiologic impact appears critical');
    } else if (impactScore >= 3) {
      factors.add('Physiologic impact shows concerning signs');
    }
    
    // Specific symptom mentions
    String chestPainType = input['chestPainType']?.toString().toLowerCase() ?? '';
    if (chestPainType.contains('crushing') || chestPainType.contains('pressure')) {
      factors.add('You reported typical chest pain symptoms');
    }
    
    int chestPainDuration = int.tryParse(input['chestPainDuration']?.toString() ?? '0') ?? 0;
    if (chestPainDuration > 20) {
      factors.add('Your chest pain has lasted over 20 minutes');
    }
    
    String sobLevel = input['shortnessOfBreath']?.toString().toLowerCase() ?? '';
    if (sobLevel.contains('at rest')) {
      factors.add('You have shortness of breath at rest');
    }
    
    if (input['syncope'] == true || input['syncope'] == 'true' || 
        input['fainting'] == true || input['fainting'] == 'true') {
      factors.add('You experienced syncope or fainting');
    }
    
    if (factors.isEmpty) {
      return 'Based on your current symptoms and vital signs, your risk level has been assessed.';
    }
    
    return 'Based on your assessment: ${factors.join(', ')}. This contributes to your overall risk level.';
  }

  /// Validate input data
  void _validateInput(Map<String, dynamic> input) {
    // Check for required fields
    List<String> requiredFields = ['age', 'sex'];
    for (String field in requiredFields) {
      if (!input.containsKey(field) || input[field] == null) {
        throw Exception('Required field missing: $field');
      }
    }
    
    // Validate age
    int age = int.tryParse(input['age']?.toString() ?? '0') ?? 0;
    if (age < 0 || age > 120) {
      throw Exception('Age must be between 0 and 120');
    }
    
    // Validate vital signs if provided and not empty
    if (input.containsKey('systolicBP') && input['systolicBP']?.toString().isNotEmpty == true) {
      int systolicBP = int.tryParse(input['systolicBP']?.toString() ?? '0') ?? 0;
      if (systolicBP < 50 || systolicBP > 300) {
        throw Exception('Systolic blood pressure must be between 50 and 300');
      }
    }
    
    if (input.containsKey('diastolicBP') && input['diastolicBP']?.toString().isNotEmpty == true) {
      int diastolicBP = int.tryParse(input['diastolicBP']?.toString() ?? '0') ?? 0;
      if (diastolicBP < 30 || diastolicBP > 200) {
        throw Exception('Diastolic blood pressure must be between 30 and 200');
      }
    }
    
    if (input.containsKey('heartRate') && input['heartRate']?.toString().isNotEmpty == true) {
      int heartRate = int.tryParse(input['heartRate']?.toString() ?? '0') ?? 0;
      if (heartRate < 30 || heartRate > 250) {
        throw Exception('Heart rate must be between 30 and 250');
      }
    }
    
    if (input.containsKey('oxygenSaturation') && input['oxygenSaturation']?.toString().isNotEmpty == true) {
      int oxygenSaturation = int.tryParse(input['oxygenSaturation']?.toString() ?? '0') ?? 0;
      if (oxygenSaturation < 70 || oxygenSaturation > 100) {
        throw Exception('Oxygen saturation must be between 70 and 100');
      }
    }
    
    if (input.containsKey('temperature') && input['temperature']?.toString().isNotEmpty == true) {
      int temperature = int.tryParse(input['temperature']?.toString() ?? '0') ?? 0;
      if (temperature < 30 || temperature > 45) {
        throw Exception('Temperature must be between 30 and 45°C');
      }
    }
  }

  /// Get input field categories for UI (Enhanced AHA/ACC Guidelines)
  List<String> getChestPainTypes() {
    return [
      'No chest pain',
      'Sharp/stabbing pain',
      'Pressure/pressure-like',
      'Crushing/crushing-like',
      'Burning sensation',
      'Aching pain',
      'Other'
    ];
  }

  List<String> getShortnessOfBreathLevels() {
    return [
      'None',
      'Mild (only with heavy exertion)',
      'Moderate (with normal activity)',
      'Severe (at rest)',
      'Cannot speak in full sentences'
    ];
  }

  List<String> getPalpitationTypes() {
    return [
      'No palpitations',
      'Fast heart rate (>120 bpm)',
      'Irregular rhythm',
      'Both fast and irregular',
      'Other'
    ];
  }

  List<String> getYesNoOptions() {
    return ['No', 'Yes'];
  }

  List<String> getSexOptions() {
    return ['Male', 'Female'];
  }

  /// Generate personalized recommendations based on assessment results
  List<String> generateRecommendations(MedicalTriageAssessmentData data, int finalScore, String riskLevel) {
    List<String> recommendations = [];
    
    // Risk level based recommendations
    if (finalScore >= 20) {
      recommendations.add("🚨 Your risk level is very high. Here are some recommendations to reduce your risk:");
    } else if (finalScore >= 15) {
      recommendations.add("⚠️ Your risk level is high. Here are some recommendations to reduce your risk:");
    } else if (finalScore >= 10) {
      recommendations.add("📊 Your risk level is moderate. Here are some recommendations to reduce your risk:");
    } else {
      recommendations.add("✅ Your risk level is low. Keep up the good work and continue to maintain a healthy lifestyle.");
    }
    
    // Only generate detailed recommendations for moderate to high risk
    if (finalScore >= 10) {
      // Age-related recommendations
      if (data.age >= 55) {
        recommendations.add("• Age factor: While you can't change your age, maintaining a healthy lifestyle can mitigate risks associated with aging. Ensure regular check-ups, eat a balanced diet, stay active, and avoid smoking.");
      }
      
      // Chest pain recommendations
      if (data.chestPainType == "crushing" || data.chestPainType == "pressure") {
        recommendations.add("• Chest pain: Your chest pain symptoms are concerning. Seek immediate medical attention if you experience severe, crushing, or pressure-like chest pain that lasts more than a few minutes.");
      } else if (data.chestPainType == "burning" || data.chestPainType == "sharp") {
        recommendations.add("• Chest pain: Monitor your chest pain symptoms closely. If they worsen or become more frequent, consult your doctor immediately.");
      }
      
      // Shortness of breath recommendations
      if (data.shortnessOfBreathLevel == "severe" || data.shortnessOfBreathLevel == "moderate") {
        recommendations.add("• Breathing difficulties: Your shortness of breath requires medical attention. Avoid strenuous activities and seek medical care if breathing becomes more difficult.");
      } else if (data.shortnessOfBreathLevel == "mild") {
        recommendations.add("• Breathing: Monitor your breathing patterns. If shortness of breath worsens or occurs at rest, contact your doctor.");
      }
      
      // Blood pressure recommendations
      if (data.systolicBP >= 180 || data.diastolicBP >= 110) {
        recommendations.add("• Blood pressure: Your blood pressure is critically high. Seek immediate medical attention and avoid activities that could increase blood pressure.");
      } else if (data.systolicBP >= 140 || data.diastolicBP >= 90) {
        recommendations.add("• Blood pressure: Your blood pressure is elevated. Consult your doctor about blood pressure management strategies including diet, exercise, and possibly medication.");
      }
      
      // Heart rate recommendations
      if (data.heartRate >= 100) {
        recommendations.add("• Heart rate: Your heart rate is elevated. Avoid caffeine and stimulants, practice relaxation techniques, and consult your doctor if rapid heart rate persists.");
      } else if (data.heartRate <= 50) {
        recommendations.add("• Heart rate: Your heart rate is low. Monitor for dizziness or fainting and consult your doctor if these symptoms occur.");
      }
      
      // Oxygen saturation recommendations
      if (data.oxygenSaturation < 95) {
        recommendations.add("• Oxygen levels: Your oxygen saturation is below normal. Seek medical attention immediately as this may indicate a serious respiratory or cardiac condition.");
      } else if (data.oxygenSaturation < 98) {
        recommendations.add("• Oxygen levels: Monitor your oxygen saturation. If it drops further or you experience breathing difficulties, contact your doctor.");
      }
      
      // Temperature recommendations
      if (data.temperature >= 100.4) {
        recommendations.add("• Temperature: You have a fever which may indicate infection. Rest, stay hydrated, and consult your doctor if fever persists or worsens.");
      }
      
      // Medical history recommendations
      if (data.hasHeartAttack) {
        recommendations.add("• Heart attack history: Regularly visit your cardiologist and adhere to prescribed medications. Monitor any new or worsening symptoms and seek immediate medical attention if needed.");
      }
      
      if (data.hasStroke) {
        recommendations.add("• Stroke history: Follow your neurologist's recommendations and take prescribed medications consistently. Engage in approved physical therapy or exercises to maintain strength and mobility.");
      }
      
      if (data.hasDiabetes) {
        recommendations.add("• Diabetes: Manage your diabetes through diet, exercise, and medication as prescribed by your doctor. Monitor blood sugar levels regularly.");
      }
      
      if (data.hasHighBloodPressure) {
        recommendations.add("• High blood pressure: Follow your doctor's treatment plan, monitor blood pressure regularly, maintain a low-sodium diet, and take medications as prescribed.");
      }
      
      if (data.hasHighCholesterol) {
        recommendations.add("• High cholesterol: Follow a heart-healthy diet low in saturated fats, exercise regularly, and take cholesterol medications as prescribed by your doctor.");
      }
      
      // Lifestyle recommendations
      if (data.smokes) {
        recommendations.add("• Smoking: Quit smoking immediately to significantly reduce your risk of heart disease. Consider seeking support from smoking cessation programs or your doctor.");
      }
      
      if (data.drinksAlcohol) {
        recommendations.add("• Alcohol consumption: Limit alcohol consumption to moderate levels (1 drink per day for women, 2 for men) or consider eliminating alcohol entirely.");
      }
      
      if (!data.exercisesRegularly) {
        recommendations.add("• Exercise: Engage in regular physical activity for at least 150 minutes per week of moderate-intensity exercise. Start slowly and gradually increase intensity.");
      }
      
      if (data.stressLevel == "high") {
        recommendations.add("• Stress management: Practice stress-reducing activities such as meditation, deep breathing, yoga, or counseling. Chronic stress can negatively impact heart health.");
      }
      
      // General health recommendations
      recommendations.add("• Diet: Follow a heart-healthy diet rich in fruits, vegetables, whole grains, lean proteins, and healthy fats. Limit processed foods, sodium, and saturated fats.");
      recommendations.add("• Weight management: Maintain a healthy weight through balanced diet and regular exercise. If overweight, work with your doctor to develop a safe weight loss plan.");
      recommendations.add("• Regular checkups: Schedule regular health checkups with your primary care doctor and specialists as recommended. Early detection of health issues is crucial.");
      recommendations.add("• Medication adherence: If prescribed medications, take them exactly as directed by your doctor. Don't stop or change medications without consulting your healthcare provider.");
    }
    
    return recommendations;
  }

  void dispose() {
    _isInitialized = false;
  }
}
