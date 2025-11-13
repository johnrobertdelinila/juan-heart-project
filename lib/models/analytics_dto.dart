import 'package:juan_heart/models/assessment_history_model.dart';

/// Lightweight DTO for analytics payload optimization
/// Reduces payload size by >50% compared to full AssessmentRecord
///
/// Key optimizations:
/// 1. Abbreviated field names (d vs date, frs vs finalRiskScore)
/// 2. Optional fields only included when present
/// 3. Condensed nested objects
/// 4. Optimized for 2G/3G networks
class AnalyticsRecordDTO {
  final String i; // id
  final String d; // date (ISO8601)
  final int frs; // finalRiskScore
  final int ls; // likelihoodScore
  final int is_; // impactScore
  final String rc; // riskCategory

  // Vital Signs (optional - only if present)
  final int? sbp; // systolicBP
  final int? dbp; // diastolicBP
  final int? hr; // heartRate
  final int? spo2; // oxygenSaturation
  final double? tmp; // temperature

  // Weight & BMI (optional)
  final double? wt; // weight
  final double? bmi;

  // Simplified risk factors (boolean flags only)
  final int rf; // riskFactors bitmask (bit flags for common factors)

  AnalyticsRecordDTO({
    required this.i,
    required this.d,
    required this.frs,
    required this.ls,
    required this.is_,
    required this.rc,
    this.sbp,
    this.dbp,
    this.hr,
    this.spo2,
    this.tmp,
    this.wt,
    this.bmi,
    this.rf = 0,
  });

  /// Convert from full AssessmentRecord to lightweight DTO
  factory AnalyticsRecordDTO.fromAssessmentRecord(AssessmentRecord record) {
    // Convert risk factors to bitmask
    int riskFactorBitmask = 0;
    if (record.riskFactors['hypertension'] == true) riskFactorBitmask |= 1 << 0;
    if (record.riskFactors['smoking'] == true) riskFactorBitmask |= 1 << 1;
    if (record.riskFactors['diabetes'] == true) riskFactorBitmask |= 1 << 2;
    if (record.riskFactors['obesity'] == true) riskFactorBitmask |= 1 << 3;
    if (record.riskFactors['familyHistory'] == true) riskFactorBitmask |= 1 << 4;

    return AnalyticsRecordDTO(
      i: record.id,
      d: record.date.toIso8601String(),
      frs: record.finalRiskScore,
      ls: record.likelihoodScore,
      is_: record.impactScore,
      rc: record.riskCategory,
      sbp: record.systolicBP,
      dbp: record.diastolicBP,
      hr: record.heartRate,
      spo2: record.oxygenSaturation,
      tmp: record.temperature,
      wt: record.weight,
      bmi: record.bmi,
      rf: riskFactorBitmask,
    );
  }

  /// Convert to JSON with minimal size
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'i': i,
      'd': d,
      'frs': frs,
      'ls': ls,
      'is': is_,
      'rc': rc,
    };

    // Only include optional fields if present
    if (sbp != null) json['sbp'] = sbp;
    if (dbp != null) json['dbp'] = dbp;
    if (hr != null) json['hr'] = hr;
    if (spo2 != null) json['spo2'] = spo2;
    if (tmp != null) json['tmp'] = tmp;
    if (wt != null) json['wt'] = wt;
    if (bmi != null) json['bmi'] = bmi;
    if (rf > 0) json['rf'] = rf;

    return json;
  }

  /// Create from JSON
  factory AnalyticsRecordDTO.fromJson(Map<String, dynamic> json) {
    return AnalyticsRecordDTO(
      i: json['i'] as String,
      d: json['d'] as String,
      frs: json['frs'] as int,
      ls: json['ls'] as int,
      is_: json['is'] as int,
      rc: json['rc'] as String,
      sbp: json['sbp'] as int?,
      dbp: json['dbp'] as int?,
      hr: json['hr'] as int?,
      spo2: json['spo2'] as int?,
      tmp: json['tmp'] as double?,
      wt: json['wt'] as double?,
      bmi: json['bmi'] as double?,
      rf: json['rf'] as int? ?? 0,
    );
  }

  /// Convert back to simplified AssessmentRecord for display
  AssessmentRecord toAssessmentRecord() {
    // Decode bitmask to risk factors
    final riskFactors = <String, dynamic>{
      'hypertension': (rf & (1 << 0)) != 0,
      'smoking': (rf & (1 << 1)) != 0,
      'diabetes': (rf & (1 << 2)) != 0,
      'obesity': (rf & (1 << 3)) != 0,
      'familyHistory': (rf & (1 << 4)) != 0,
    };

    return AssessmentRecord(
      id: i,
      date: DateTime.parse(d),
      finalRiskScore: frs,
      likelihoodScore: ls,
      impactScore: is_,
      riskCategory: rc,
      likelihoodLevel: 'Level $ls',
      impactLevel: 'Level $is_',
      recommendedAction: '', // Not stored in DTO
      systolicBP: sbp,
      diastolicBP: dbp,
      heartRate: hr,
      oxygenSaturation: spo2,
      temperature: tmp,
      weight: wt,
      bmi: bmi,
      symptoms: {}, // Not stored in DTO
      riskFactors: riskFactors,
      age: 0, // Not stored in DTO
      sex: '', // Not stored in DTO
    );
  }
}

/// Summary DTO for analytics overview (ultra-lightweight)
/// Used for initial load to show quick stats
class AnalyticsSummaryDTO {
  final int tc; // totalCount
  final double avg; // avgRiskScore
  final String tr; // trend (i/w/s for improving/worsening/stable)
  final String mc; // mostCommonCategory
  final String ld; // lastDate (ISO8601)

  AnalyticsSummaryDTO({
    required this.tc,
    required this.avg,
    required this.tr,
    required this.mc,
    required this.ld,
  });

  Map<String, dynamic> toJson() {
    return {
      'tc': tc,
      'avg': avg,
      'tr': tr,
      'mc': mc,
      'ld': ld,
    };
  }

  factory AnalyticsSummaryDTO.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummaryDTO(
      tc: json['tc'] as int,
      avg: (json['avg'] as num).toDouble(),
      tr: json['tr'] as String,
      mc: json['mc'] as String,
      ld: json['ld'] as String,
    );
  }

  /// Convert to RiskTrendStats
  RiskTrendStats toRiskTrendStats() {
    String trendDirection;
    switch (tr) {
      case 'i':
        trendDirection = 'improving';
        break;
      case 'w':
        trendDirection = 'worsening';
        break;
      default:
        trendDirection = 'stable';
    }

    return RiskTrendStats(
      avgRiskScore: avg,
      trendDirection: trendDirection,
      changePercent: 0, // Not included in summary
      totalAssessments: tc,
      mostCommonCategory: mc,
      lastAssessmentDate: DateTime.parse(ld),
    );
  }
}

/// Paginated response for analytics data
class AnalyticsPaginatedResponse {
  final List<AnalyticsRecordDTO> data;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  AnalyticsPaginatedResponse({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((d) => d.toJson()).toList(),
      'page': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'hasMore': hasMore,
    };
  }

  factory AnalyticsPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsPaginatedResponse(
      data: (json['data'] as List)
          .map((d) => AnalyticsRecordDTO.fromJson(d as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }
}
