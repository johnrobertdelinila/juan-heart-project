import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/assessment_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user's assessment history and analytics
class AnalyticsService {
  static const String _storageKey = 'assessment_history';

  /// Save a new assessment to history and sync to backend
  static Future<void> saveAssessment(AssessmentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getAssessmentHistory();

    history.add(record);

    // Keep only last 50 assessments to avoid storage bloat
    if (history.length > 50) {
      history.removeRange(0, history.length - 50);
    }

    final jsonList = history.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));

    // Sync to backend database (non-blocking)
    try {
      print('🔄 Attempting to sync assessment to backend database...');
      final syncResult = await AssessmentSyncService.syncAssessmentToBackend(record);

      if (syncResult['success'] == true) {
        print('✅ Assessment synced to database successfully!');
        print('📊 Database ID: ${syncResult['data']?['id']}');
      } else {
        print('⚠️ Assessment saved locally but sync failed: ${syncResult['message']}');
      }
    } catch (e) {
      print('⚠️ Assessment saved locally but sync error: $e');
      // Don't throw error - assessment is still saved locally
    }
  }

  /// Get all assessment records from history
  static Future<List<AssessmentRecord>> getAssessmentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => AssessmentRecord.fromJson(json)).toList();
  }

  /// Get risk trend statistics
  static Future<RiskTrendStats> getRiskTrendStats() async {
    final history = await getAssessmentHistory();
    
    if (history.isEmpty) {
      return RiskTrendStats(
        avgRiskScore: 0,
        trendDirection: 'stable',
        changePercent: 0,
        totalAssessments: 0,
        mostCommonCategory: 'N/A',
      );
    }
    
    // Calculate average risk score
    final avgScore = history.fold<double>(
          0, (sum, record) => sum + record.finalRiskScore) /
        history.length;
    
    // Determine trend direction
    String trendDirection = 'stable';
    double changePercent = 0;
    
    if (history.length >= 2) {
      // Compare recent assessments (last 3) vs older ones
      final recentCount = history.length < 3 ? 1 : 3;
      final recent = history.sublist(history.length - recentCount);
      final older = history.length <= recentCount
          ? recent
          : history.sublist(0, history.length - recentCount);
      
      final recentAvg = recent.fold<double>(
            0, (sum, r) => sum + r.finalRiskScore) / recent.length;
      final olderAvg = older.fold<double>(
            0, (sum, r) => sum + r.finalRiskScore) / older.length;
      
      if (olderAvg > 0) {
        changePercent = ((recentAvg - olderAvg) / olderAvg) * 100;
        
        if (changePercent < -5) {
          trendDirection = 'improving';
        } else if (changePercent > 5) {
          trendDirection = 'worsening';
        }
      }
    }
    
    // Find most common category
    final categoryCount = <String, int>{};
    for (final record in history) {
      categoryCount[record.riskCategory] =
          (categoryCount[record.riskCategory] ?? 0) + 1;
    }
    final mostCommon = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return RiskTrendStats(
      avgRiskScore: avgScore,
      trendDirection: trendDirection,
      changePercent: changePercent.abs(),
      totalAssessments: history.length,
      lastAssessmentDate: history.last.date,
      mostCommonCategory: mostCommon,
    );
  }

  /// Get vital signs trends
  static Future<Map<String, List<VitalSignTrend>>> getVitalSignsTrends() async {
    final history = await getAssessmentHistory();

    final trends = <String, List<VitalSignTrend>>{
      'systolicBP': [],
      'diastolicBP': [],
      'heartRate': [],
      'oxygenSaturation': [],
      'temperature': [],
      'weight': [],
      'bmi': [],
    };

    for (final record in history) {
      if (record.systolicBP != null) {
        trends['systolicBP']!.add(VitalSignTrend(
          date: record.date,
          value: record.systolicBP!.toDouble(),
          isNormal: record.systolicBP! >= 90 && record.systolicBP! <= 120,
        ));
      }

      if (record.diastolicBP != null) {
        trends['diastolicBP']!.add(VitalSignTrend(
          date: record.date,
          value: record.diastolicBP!.toDouble(),
          isNormal: record.diastolicBP! >= 60 && record.diastolicBP! <= 80,
        ));
      }

      if (record.heartRate != null) {
        trends['heartRate']!.add(VitalSignTrend(
          date: record.date,
          value: record.heartRate!.toDouble(),
          isNormal: record.heartRate! >= 60 && record.heartRate! <= 100,
        ));
      }

      if (record.oxygenSaturation != null) {
        trends['oxygenSaturation']!.add(VitalSignTrend(
          date: record.date,
          value: record.oxygenSaturation!.toDouble(),
          isNormal: record.oxygenSaturation! >= 95,
        ));
      }

      if (record.temperature != null) {
        trends['temperature']!.add(VitalSignTrend(
          date: record.date,
          value: record.temperature!,
          isNormal: record.temperature! >= 36.1 && record.temperature! <= 37.2,
        ));
      }

      if (record.weight != null) {
        trends['weight']!.add(VitalSignTrend(
          date: record.date,
          value: record.weight!,
          isNormal: true, // Weight normality is individual, shown in BMI instead
        ));
      }

      if (record.bmi != null) {
        trends['bmi']!.add(VitalSignTrend(
          date: record.date,
          value: record.bmi!,
          isNormal: record.bmi! >= 18.5 && record.bmi! <= 24.9, // Normal BMI range
        ));
      }
    }

    return trends;
  }

  /// Get risk factor contributions analysis
  static Future<Map<String, List<RiskFactorContribution>>> getRiskFactorAnalysis() async {
    final history = await getAssessmentHistory();
    
    if (history.isEmpty) {
      return {
        'contributors': [],
        'improved': [],
        'stable': [],
      };
    }
    
    final factorCount = <String, int>{};
    final factorTrend = <String, List<bool>>{}; // Track presence over time
    
    // Count occurrences and track trends
    for (final record in history) {
      record.riskFactors.forEach((key, value) {
        if (value == true) {
          factorCount[key] = (factorCount[key] ?? 0) + 1;
          factorTrend[key] = factorTrend[key] ?? [];
          factorTrend[key]!.add(true);
        } else {
          factorTrend[key] = factorTrend[key] ?? [];
          factorTrend[key]!.add(false);
        }
      });
    }
    
    final contributors = <RiskFactorContribution>[];
    final improved = <RiskFactorContribution>[];
    final stable = <RiskFactorContribution>[];
    
    factorCount.forEach((factor, count) {
      final trend = factorTrend[factor] ?? [];
      final recentlyPresent = trend.length >= 3
          ? trend.sublist(trend.length - 3).where((x) => x).length >= 2
          : trend.where((x) => x).isNotEmpty;
      
      final improving = trend.length >= 2 && trend.last == false && trend[trend.length - 2] == true;
      
      final contribution = RiskFactorContribution(
        factorName: _formatFactorName(factor),
        occurrences: count,
        status: improving ? 'improved' : (recentlyPresent ? 'contributor' : 'stable'),
        description: _getFactorDescription(factor, improving, recentlyPresent),
      );
      
      if (improving) {
        improved.add(contribution);
      } else if (recentlyPresent) {
        contributors.add(contribution);
      } else {
        stable.add(contribution);
      }
    });
    
    // Sort by occurrences
    contributors.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    improved.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    stable.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    
    return {
      'contributors': contributors.take(5).toList(),
      'improved': improved.take(3).toList(),
      'stable': stable.take(3).toList(),
    };
  }

  /// Generate personalized health insights based on trends - Culturally Refined
  static Future<List<HealthInsight>> generateHealthInsights() async {
    final insights = <HealthInsight>[];
    final stats = await getRiskTrendStats();
    final history = await getAssessmentHistory();
    
    if (history.isEmpty) {
      insights.add(HealthInsight(
        title: 'Simulan ang Inyong Journey',
        message: 'Kumpletuhin ang inyong unang pagsusuri para masimulan ang pagsubaybay sa kalusugan ng puso.',
        icon: Icons.favorite,
        color: const Color(0xFF4A90E2),
        type: 'neutral',
      ));
      return insights;
    }
    
    // Trend-based insights - Encouraging & Cultural
    if (stats.trendDirection == 'improving') {
      insights.add(HealthInsight(
        title: '🎉 Magaling na Pag-unlad!',
        message: 'Gumaganda ang inyong puso! Patuloy na subaybayan at panatilihin ang malusog na gawi.',
        icon: Icons.trending_down,
        color: const Color(0xFF32CD32),
        type: 'positive',
      ));
    } else if (stats.trendDirection == 'worsening') {
      insights.add(HealthInsight(
        title: '⚠️ Kailangan ng Atensyon',
        message: 'Konsultahin ang inyong doktor para sa payo. Hindi pa huli ang lahat!',
        icon: Icons.trending_up,
        color: const Color(0xFFFF6347),
        type: 'warning',
      ));
    } else {
      insights.add(HealthInsight(
        title: '✅ Patuloy na Subaybayan',
        message: 'Patuloy na subaybayan ang inyong kalusugan. Consistency is key!',
        icon: Icons.favorite,
        color: const Color(0xFF4A90E2),
        type: 'neutral',
      ));
    }
    
    // Latest assessment insights - Gentle & Supportive
    final latest = history.last;
    if (latest.riskCategory.toLowerCase() == 'critical' || 
        latest.riskCategory.toLowerCase() == 'high') {
      insights.add(HealthInsight(
        title: '🚨 Kailangan ng Medikal na Atensyon',
        message: 'Ang inyong pagsusuri ay nagpapakita ng mataas na panganib. Kumonsulta sa doktor agad.',
        icon: Icons.medical_services,
        color: const Color(0xFFDC143C),
        type: 'critical',
      ));
    }
    
    // Vital signs insights - Practical & Encouraging
    if (latest.systolicBP != null && latest.systolicBP! > 130) {
      insights.add(HealthInsight(
        title: 'Altapresyon - Bawasan ang Asin',
        message: 'Ang inyong BP ay mataas. Bawasan ang pagkain ng maalat at uminom ng maraming tubig.',
        icon: Icons.monitor_heart,
        color: const Color(0xFFFFA500),
        type: 'warning',
      ));
    }
    
    if (latest.heartRate != null && latest.heartRate! > 100) {
      insights.add(HealthInsight(
        title: 'Mataas na Heart Rate',
        message: 'Mag-relax at mag-ehersisyo nang regular. Deep breathing exercises ay makakatulong.',
        icon: Icons.favorite,
        color: const Color(0xFFFFA500),
        type: 'warning',
      ));
    }
    
    // Lifestyle insights - Cultural & Practical
    if (latest.riskFactors['smoking'] == true) {
      insights.add(HealthInsight(
        title: '💪 Para sa Pamilya',
        message: 'Ang pagtigil sa paninigarilyo ay para sa inyong pamilya. Kayang-kaya ninyo!',
        icon: Icons.smoke_free,
        color: const Color(0xFF4CAF50),
        type: 'positive',
      ));
    }
    
    if (latest.riskFactors['hypertension'] == true) {
      insights.add(HealthInsight(
        title: '🥗 Malusog na Pagkain',
        message: 'Kumain ng mas maraming gulay at prutas. Iwasan ang processed foods.',
        icon: Icons.restaurant,
        color: const Color(0xFF4CAF50),
        type: 'positive',
      ));
    }
    
    // Frequency insights - Encouraging
    if (history.length >= 3) {
      insights.add(HealthInsight(
        title: '📊 Consistent Monitoring',
        message: 'Magaling! Patuloy na subaybayan ang inyong kalusugan. Consistency is key!',
        icon: Icons.calendar_today,
        color: const Color(0xFF32CD32),
        type: 'positive',
      ));
    }
    
    // Cultural encouragement
    if (stats.totalAssessments >= 5) {
      insights.add(HealthInsight(
        title: '🏆 Health Champion!',
        message: 'Kayo ay isang health champion! Patuloy na alagaan ang inyong puso.',
        icon: Icons.emoji_events,
        color: const Color(0xFFFFD700),
        type: 'positive',
      ));
    }
    
    return insights;
  }

  /// Get risk category distribution for pie chart
  static Future<Map<String, int>> getRiskCategoryDistribution() async {
    final history = await getAssessmentHistory();
    final distribution = <String, int>{
      'Low': 0,
      'Mild': 0,
      'Moderate': 0,
      'High': 0,
      'Critical': 0,
    };
    
    for (final record in history) {
      distribution[record.riskCategory] = (distribution[record.riskCategory] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Helper: Format factor name for display
  static String _formatFactorName(String key) {
    final formatted = key.replaceFirst('risk_', '').replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Helper: Get factor description
  static String _getFactorDescription(String factor, bool improving, bool present) {
    if (improving) {
      return 'Great! This risk factor has been addressed.';
    } else if (present) {
      return 'Currently affecting your heart health.';
    } else {
      return 'Well managed and stable.';
    }
  }

  /// Clear all history (for testing/reset)
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Generate mock data for testing (removes after real data accumulates)
  static Future<void> generateMockData() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);
    
    // Only generate if no data exists
    if (existing != null) return;
    
    final now = DateTime.now();
    final mockRecords = <AssessmentRecord>[];
    
    // Generate 10 mock assessments over the past 2 months
    for (int i = 0; i < 10; i++) {
      final daysAgo = 60 - (i * 6);
      final date = now.subtract(Duration(days: daysAgo));
      
      // Simulate improving trend
      final baseScore = 15 - i;
      final likelihoodScore = (baseScore / 5).ceil().clamp(1, 5);
      final impactScore = (baseScore % 5) + 1;
      final finalScore = (likelihoodScore * impactScore).clamp(1, 25);
      
      String category;
      if (finalScore >= 20) {
        category = 'Critical';
      } else if (finalScore >= 15) {
        category = 'High';
      } else if (finalScore >= 10) {
        category = 'Moderate';
      } else if (finalScore >= 5) {
        category = 'Mild';
      } else {
        category = 'Low';
      }
      
      // Simulate weight loss journey: starting at 85kg, gradually reducing
      final weight = 85.0 - (i * 0.8); // Losing ~0.8kg every 6 days
      final height = 170.0; // Fixed height in cm
      final bmi = weight / ((height / 100) * (height / 100)); // BMI calculation

      mockRecords.add(AssessmentRecord(
        id: 'mock_$i',
        date: date,
        finalRiskScore: finalScore,
        likelihoodScore: likelihoodScore,
        impactScore: impactScore,
        riskCategory: category,
        likelihoodLevel: 'Level $likelihoodScore',
        impactLevel: 'Level $impactScore',
        recommendedAction: 'Mock action for $category',
        systolicBP: 120 + (i % 20),
        diastolicBP: 75 + (i % 10),
        heartRate: 70 + (i % 25),
        oxygenSaturation: 96 + (i % 4),
        temperature: 36.5 + (i % 2) * 0.3,
        weight: weight,
        height: height,
        bmi: bmi,
        symptoms: {'chestPain': i % 3 == 0, 'shortnessOfBreath': i % 4 == 0},
        riskFactors: {
          'hypertension': i < 5,
          'smoking': i < 3,
          'diabetes': i < 4,
        },
        age: 45,
        sex: 'Male',
      ));
    }
    
    // Save mock data
    final jsonList = mockRecords.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}

