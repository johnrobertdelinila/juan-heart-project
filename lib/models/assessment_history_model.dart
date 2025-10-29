import 'package:flutter/material.dart';

/// Model representing a single assessment record in user's history
class AssessmentRecord {
  final String id;
  final DateTime date;
  final int finalRiskScore; // 1-25 scale (Likelihood × Impact)
  final int likelihoodScore; // 1-5
  final int impactScore; // 1-5
  final String riskCategory; // Low, Mild, Moderate, High, Critical
  final String likelihoodLevel;
  final String impactLevel;
  final String recommendedAction;
  
  // Vital Signs
  final int? systolicBP;
  final int? diastolicBP;
  final int? heartRate;
  final int? oxygenSaturation;
  final double? temperature;

  // Weight & BMI Tracking
  final double? weight; // in kg
  final double? height; // in cm
  final double? bmi;

  // Symptoms
  final Map<String, dynamic> symptoms;
  
  // Risk Factors
  final Map<String, dynamic> riskFactors;
  
  // User demographics at time of assessment
  final int age;
  final String sex;

  // Additional fields for backend sync
  final String? userId;
  final String? userName;
  final String? userGender;
  final String? timeframe;
  final String? recommendation;
  final Map<String, dynamic>? vitalSigns;
  final Map<String, dynamic>? medicalHistory;
  final Map<String, dynamic>? lifestyleFactors;
  final List<dynamic>? medications;

  AssessmentRecord({
    required this.id,
    required this.date,
    required this.finalRiskScore,
    required this.likelihoodScore,
    required this.impactScore,
    required this.riskCategory,
    required this.likelihoodLevel,
    required this.impactLevel,
    required this.recommendedAction,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.oxygenSaturation,
    this.temperature,
    this.weight,
    this.height,
    this.bmi,
    required this.symptoms,
    required this.riskFactors,
    required this.age,
    required this.sex,
    this.userId,
    this.userName,
    this.userGender,
    this.timeframe,
    this.recommendation,
    this.vitalSigns,
    this.medicalHistory,
    this.lifestyleFactors,
    this.medications,
  });

  /// Get risk color based on category
  Color getRiskColor() {
    switch (riskCategory.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC143C); // Crimson Red
      case 'high':
        return const Color(0xFFFF6347); // Tomato Red
      case 'moderate':
        return const Color(0xFFFFA500); // Orange
      case 'mild':
        return const Color(0xFFFFD700); // Gold/Yellow
      case 'low':
        return const Color(0xFF32CD32); // Lime Green
      default:
        return Colors.grey;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'finalRiskScore': finalRiskScore,
      'likelihoodScore': likelihoodScore,
      'impactScore': impactScore,
      'riskCategory': riskCategory,
      'likelihoodLevel': likelihoodLevel,
      'impactLevel': impactLevel,
      'recommendedAction': recommendedAction,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'symptoms': symptoms,
      'riskFactors': riskFactors,
      'age': age,
      'sex': sex,
      'userId': userId,
      'userName': userName,
      'userGender': userGender,
      'timeframe': timeframe,
      'recommendation': recommendation,
      'vitalSigns': vitalSigns,
      'medicalHistory': medicalHistory,
      'lifestyleFactors': lifestyleFactors,
      'medications': medications,
    };
  }

  /// Create from JSON
  factory AssessmentRecord.fromJson(Map<String, dynamic> json) {
    return AssessmentRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      finalRiskScore: json['finalRiskScore'] as int,
      likelihoodScore: json['likelihoodScore'] as int,
      impactScore: json['impactScore'] as int,
      riskCategory: json['riskCategory'] as String,
      likelihoodLevel: json['likelihoodLevel'] as String,
      impactLevel: json['impactLevel'] as String,
      recommendedAction: json['recommendedAction'] as String,
      systolicBP: json['systolicBP'] as int?,
      diastolicBP: json['diastolicBP'] as int?,
      heartRate: json['heartRate'] as int?,
      oxygenSaturation: json['oxygenSaturation'] as int?,
      temperature: json['temperature'] as double?,
      weight: json['weight'] as double?,
      height: json['height'] as double?,
      bmi: json['bmi'] as double?,
      symptoms: json['symptoms'] as Map<String, dynamic>,
      riskFactors: json['riskFactors'] as Map<String, dynamic>,
      age: json['age'] as int,
      sex: json['sex'] as String,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userGender: json['userGender'] as String?,
      timeframe: json['timeframe'] as String?,
      recommendation: json['recommendation'] as String?,
      vitalSigns: json['vitalSigns'] as Map<String, dynamic>?,
      medicalHistory: json['medicalHistory'] as Map<String, dynamic>?,
      lifestyleFactors: json['lifestyleFactors'] as Map<String, dynamic>?,
      medications: json['medications'] as List<dynamic>?,
    );
  }
}

/// Model for vital signs trend data
class VitalSignTrend {
  final DateTime date;
  final double value;
  final bool isNormal;
  
  VitalSignTrend({
    required this.date,
    required this.value,
    required this.isNormal,
  });
}

/// Model for risk factor contribution analysis
class RiskFactorContribution {
  final String factorName;
  final int occurrences;
  final String status; // 'contributor', 'improved', 'stable'
  final String description;
  
  RiskFactorContribution({
    required this.factorName,
    required this.occurrences,
    required this.status,
    required this.description,
  });
}

/// Model for health insights
class HealthInsight {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String type; // 'positive', 'warning', 'neutral', 'critical'
  
  HealthInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
  });
}

/// Model for risk trend statistics
class RiskTrendStats {
  final double avgRiskScore;
  final String trendDirection; // 'improving', 'worsening', 'stable'
  final double changePercent;
  final int totalAssessments;
  final DateTime? lastAssessmentDate;
  final String mostCommonCategory;
  
  RiskTrendStats({
    required this.avgRiskScore,
    required this.trendDirection,
    required this.changePercent,
    required this.totalAssessments,
    this.lastAssessmentDate,
    required this.mostCommonCategory,
  });
}

