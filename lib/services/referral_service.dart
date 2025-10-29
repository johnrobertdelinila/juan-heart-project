/// Referral & Care Navigation Service
/// 
/// Maps risk assessment results to actionable care recommendations
/// Aligned with Philippine Heart Center (PHC) triage guidelines
/// 
/// Risk Score Ranges:
/// - Low (1-4): Self-care, no immediate action
/// - Mild (5-9): Monitor, recheck within 1-2 weeks
/// - Moderate (10-14): Clinic visit within 24-48 hours
/// - High (15-19): Urgent care within 6-24 hours
/// - Critical (20-25): Emergency room immediately

import 'package:flutter/material.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/core/utils/color_constants.dart';

class ReferralService {
  /// Generate care recommendation based on risk assessment result
  /// 
  /// This follows PHC national health app standards and triage protocols
  static CareRecommendation generateRecommendation({
    required String riskCategory,
    required int riskScore,
    String? language, // 'en' or 'fil' for Filipino
  }) {
    final lang = language ?? 'en';
    
    // Map risk score to urgency level and recommendation
    if (riskScore <= 4) {
      return _buildLowRiskRecommendation(riskScore, lang);
    } else if (riskScore <= 9) {
      return _buildMildRiskRecommendation(riskScore, lang);
    } else if (riskScore <= 14) {
      return _buildModerateRiskRecommendation(riskScore, lang);
    } else if (riskScore <= 19) {
      return _buildHighRiskRecommendation(riskScore, lang);
    } else {
      return _buildCriticalRiskRecommendation(riskScore, lang);
    }
  }
  
  /// Low Risk (1-4): Self-care at home
  static CareRecommendation _buildLowRiskRecommendation(int score, String lang) {
    return CareRecommendation(
      riskCategory: 'Low Risk',
      riskScore: score,
      urgency: CareUrgency.none,
      actionTitle: lang == 'fil' 
          ? 'Magpatuloy sa Malusog na Pamumuhay'
          : 'Continue Healthy Habits',
      actionMessage: lang == 'fil'
          ? 'Ang iyong kalusugan ng puso ay mukhang mabuti. Magpatuloy sa malusog na pamumuhay at regular na ehersisyo.'
          : 'Your heart health appears good. Continue maintaining healthy habits and regular exercise.',
      detailedGuidance: lang == 'fil'
          ? '• Kumain ng masustansyang pagkain\n• Regular na ehersisyo (30 minuto, 5 beses sa linggo)\n• Matulog ng sapat (7-8 oras)\n• Iwasan ang labis na stress\n• Magpa-check up tuwing taon'
          : '• Eat a balanced, nutritious diet\n• Exercise regularly (30 min, 5 times/week)\n• Get adequate sleep (7-8 hours)\n• Manage stress effectively\n• Schedule annual health check-ups',
      indicatorColor: ColorConstant.greenlight,
      urgencyIcon: Icons.check_circle_outline,
      recommendedFacilities: [
        FacilityType.barangayHealthCenter,
        FacilityType.primaryCarClinic,
      ],
    );
  }
  
  /// Mild Risk (5-9): Monitor and recheck
  static CareRecommendation _buildMildRiskRecommendation(int score, String lang) {
    return CareRecommendation(
      riskCategory: 'Mild Risk',
      riskScore: score,
      urgency: CareUrgency.monitor,
      actionTitle: lang == 'fil'
          ? 'Bantayan ang Iyong Kalusugan'
          : 'Monitor Your Health',
      actionMessage: lang == 'fil'
          ? 'May ilang risk factors na nakita. Bantayan ang iyong kalusugan at magpatingin sa loob ng 1-2 linggo.'
          : 'Some risk factors detected. Monitor your health closely and schedule a check-up within 1-2 weeks.',
      detailedGuidance: lang == 'fil'
          ? '• Subaybayan ang iyong presyon at pulso\n• Gumawa ng health diary\n• Bawasan ang asin at taba sa pagkain\n• Regular na ehersisyo\n• Magpatingin sa health center sa loob ng 1-2 linggo'
          : '• Monitor your blood pressure and heart rate\n• Keep a health diary\n• Reduce salt and fat intake\n• Continue regular exercise\n• Schedule a check-up within 1-2 weeks at your local health center',
      indicatorColor: ColorConstant.bluelight,
      urgencyIcon: Icons.info_outline,
      recommendedFacilities: [
        FacilityType.barangayHealthCenter,
        FacilityType.primaryCarClinic,
      ],
    );
  }
  
  /// Moderate Risk (10-14): Clinic visit within 24-48 hours
  static CareRecommendation _buildModerateRiskRecommendation(int score, String lang) {
    return CareRecommendation(
      riskCategory: 'Moderate Risk',
      riskScore: score,
      urgency: CareUrgency.routine,
      actionTitle: lang == 'fil'
          ? 'Magpatingin sa Doktor Kaagad'
          : 'See a Doctor Soon',
      actionMessage: lang == 'fil'
          ? 'May mga sintomas na nangangailangan ng atensyon. Magpatingin sa doktor o klinika sa loob ng 24-48 oras.'
          : 'Your symptoms require medical attention. Please visit a doctor or clinic within 24-48 hours.',
      detailedGuidance: lang == 'fil'
          ? '• Huwag balewalain ang mga sintomas\n• Magpatingin sa pinakamalapit na klinika o health center\n• Dalhin ang iyong assessment results\n• Iwasan ang mabigat na gawain\n• Kumunsulta para sa treatment plan'
          : '• Do not ignore your symptoms\n• Visit the nearest clinic or health center\n• Bring your assessment results\n• Avoid strenuous activities\n• Consult for a proper treatment plan',
      indicatorColor: ColorConstant.orangelight,
      urgencyIcon: Icons.warning_amber_outlined,
      recommendedFacilities: [
        FacilityType.primaryCarClinic,
        FacilityType.hospital,
      ],
    );
  }
  
  /// High Risk (15-19): Urgent care within 6-24 hours
  static CareRecommendation _buildHighRiskRecommendation(int score, String lang) {
    return CareRecommendation(
      riskCategory: 'High Risk',
      riskScore: score,
      urgency: CareUrgency.urgent,
      actionTitle: lang == 'fil'
          ? 'Kailangan ang Agarang Medikal na Tulong'
          : 'Urgent Medical Care Needed',
      actionMessage: lang == 'fil'
          ? 'Mayroon kang mataas na panganib. Pumunta sa ospital o emergency clinic sa loob ng 6-24 oras.'
          : 'You have significant risk factors. Go to a hospital or urgent care clinic within 6-24 hours.',
      detailedGuidance: lang == 'fil'
          ? '• Pumunta sa ospital o emergency clinic kaagad\n• Dalhin ang iyong mga gamot at medical records\n• Iwasan ang anumang physical stress\n• Huwag mag-isa; magsama ng kasama\n• Tawagan ang 911 o emergency hotline kung lumala'
          : '• Go to a hospital or emergency clinic immediately\n• Bring your medications and medical records\n• Avoid any physical stress\n• Do not go alone; bring a companion\n• Call 911 or emergency hotline if symptoms worsen',
      indicatorColor: ColorConstant.redlight,
      urgencyIcon: Icons.error_outline,
      recommendedFacilities: [
        FacilityType.hospital,
        FacilityType.emergencyFacility,
      ],
    );
  }
  
  /// Critical Risk (20-25): Emergency room immediately
  static CareRecommendation _buildCriticalRiskRecommendation(int score, String lang) {
    return CareRecommendation(
      riskCategory: 'Critical Risk',
      riskScore: score,
      urgency: CareUrgency.emergency,
      actionTitle: lang == 'fil'
          ? 'PUMUNTA SA EMERGENCY ROOM NGAYON'
          : 'GO TO EMERGENCY ROOM NOW',
      actionMessage: lang == 'fil'
          ? 'KRITIKAL: Kailangan mo ng emergency care NGAYON. Pumunta sa pinakamalapit na emergency room o tawagan ang 911.'
          : 'CRITICAL: You need emergency care NOW. Go to the nearest emergency room or call 911 immediately.',
      detailedGuidance: lang == 'fil'
          ? '⚠️ EMERGENCY - Gawin KAAGAD:\n\n• Tawagan ang 911 o emergency hotline\n• Pumunta sa pinakamalapit na emergency room\n• HUWAG mag-drive; magpasama o tumawag ng ambulansya\n• Umupo at manatiling kalmado\n• Sabihin sa staff na may chest pain/heart symptoms'
          : '⚠️ EMERGENCY - Do IMMEDIATELY:\n\n• Call 911 or emergency hotline\n• Go to the nearest emergency room\n• DO NOT drive yourself; have someone take you or call ambulance\n• Sit down and stay calm\n• Tell medical staff about chest pain/heart symptoms',
      indicatorColor: ColorConstant.redAccent,
      urgencyIcon: Icons.local_hospital,
      recommendedFacilities: [
        FacilityType.emergencyFacility,
        FacilityType.hospital,
      ],
    );
  }
  
  /// Get emergency disclaimer text
  static String getEmergencyDisclaimer(String lang) {
    if (lang == 'fil') {
      return '⚠️ Kung mayroon kang matinding chest pain, pagkahilo, o hirap sa paghinga, pumunta sa ER kaagad o tawagan ang 911.';
    }
    return '⚠️ If you have severe chest pain, fainting, or difficulty breathing, go to the ER immediately or call 911.';
  }
  
  /// Get general medical disclaimer
  static String getMedicalDisclaimer(String lang) {
    if (lang == 'fil') {
      return 'Ang app na ito ay hindi gumagawa ng medikal na diagnosis. Ito ay gabay lamang batay sa iyong mga sagot. Para sa tumpak na diagnosis at treatment, kumunsulta sa lisensyadong doktor.';
    }
    return 'This app does not provide medical diagnosis. It only provides guidance based on your responses. For accurate diagnosis and treatment, please consult a licensed physician.';
  }
  
  /// Get reassuring message for low-risk users
  static String getReassuranceMessage(String lang) {
    if (lang == 'fil') {
      return 'Mahusay! Patuloy na alagaan ang iyong puso sa pamamagitan ng malusog na pamumuhay.';
    }
    return 'Great job! Continue taking care of your heart through healthy lifestyle choices.';
  }
  
  /// Get action button text based on urgency
  static String getActionButtonText(CareUrgency urgency, String lang) {
    if (lang == 'fil') {
      switch (urgency) {
        case CareUrgency.none:
          return 'Tingnan ang Health Tips';
        case CareUrgency.monitor:
          return 'Maghanap ng Health Center';
        case CareUrgency.routine:
          return 'Maghanap ng Klinika';
        case CareUrgency.urgent:
          return 'Maghanap ng Ospital';
        case CareUrgency.emergency:
          return 'Maghanap ng Emergency Room';
      }
    }
    
    switch (urgency) {
      case CareUrgency.none:
        return 'View Health Tips';
      case CareUrgency.monitor:
        return 'Find Health Center';
      case CareUrgency.routine:
        return 'Find Clinic';
      case CareUrgency.urgent:
        return 'Find Hospital';
      case CareUrgency.emergency:
        return 'Find Emergency Room';
    }
  }
}

