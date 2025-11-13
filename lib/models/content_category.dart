import 'package:hive/hive.dart';

part 'content_category.g.dart';

/// Categories for educational content in Juan Heart Mobile.
/// Covers comprehensive cardiovascular disease prevention topics.
@HiveType(typeId: 11)
enum ContentCategory {
  @HiveField(0)
  cvdPrevention,

  @HiveField(1)
  symptomRecognition,

  @HiveField(2)
  lifestyleModification,

  @HiveField(3)
  medicationCompliance,

  @HiveField(4)
  emergencyResponse,

  @HiveField(5)
  riskFactors,

  @HiveField(6)
  nutrition,

  @HiveField(7)
  exercise,
}

/// Extension to provide localized labels for content categories.
extension ContentCategoryExtension on ContentCategory {
  /// Get English label for the category
  String get labelEn {
    switch (this) {
      case ContentCategory.cvdPrevention:
        return 'CVD Prevention';
      case ContentCategory.symptomRecognition:
        return 'Symptom Recognition';
      case ContentCategory.lifestyleModification:
        return 'Healthy Lifestyle';
      case ContentCategory.medicationCompliance:
        return 'Medication Guide';
      case ContentCategory.emergencyResponse:
        return 'Emergency Response';
      case ContentCategory.riskFactors:
        return 'Risk Factors';
      case ContentCategory.nutrition:
        return 'Nutrition';
      case ContentCategory.exercise:
        return 'Exercise';
    }
  }

  /// Get Filipino (Tagalog) label for the category
  String get labelFil {
    switch (this) {
      case ContentCategory.cvdPrevention:
        return 'Pag-iwas sa Sakit sa Puso';
      case ContentCategory.symptomRecognition:
        return 'Pagkilala sa Sintomas';
      case ContentCategory.lifestyleModification:
        return 'Malusog na Pamumuhay';
      case ContentCategory.medicationCompliance:
        return 'Gabay sa Gamot';
      case ContentCategory.emergencyResponse:
        return 'Emerhensya';
      case ContentCategory.riskFactors:
        return 'Panganib';
      case ContentCategory.nutrition:
        return 'Nutrisyon';
      case ContentCategory.exercise:
        return 'Ehersisyo';
    }
  }

  /// Get category from string value
  static ContentCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cvdprevention':
      case 'cvd_prevention':
        return ContentCategory.cvdPrevention;
      case 'symptomrecognition':
      case 'symptom_recognition':
        return ContentCategory.symptomRecognition;
      case 'lifestylemodification':
      case 'lifestyle_modification':
        return ContentCategory.lifestyleModification;
      case 'medicationcompliance':
      case 'medication_compliance':
        return ContentCategory.medicationCompliance;
      case 'emergencyresponse':
      case 'emergency_response':
        return ContentCategory.emergencyResponse;
      case 'riskfactors':
      case 'risk_factors':
        return ContentCategory.riskFactors;
      case 'nutrition':
        return ContentCategory.nutrition;
      case 'exercise':
        return ContentCategory.exercise;
      default:
        return ContentCategory.cvdPrevention;
    }
  }

  /// Convert to string representation
  String get value {
    return toString().split('.').last;
  }
}
