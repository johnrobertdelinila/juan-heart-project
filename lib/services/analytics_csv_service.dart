/// Analytics CSV Export Service
///
/// Exports analytics data to CSV format for data portability
/// Includes:
/// - Assessment history (all records with full details)
/// - Vital signs trends (time-series data)
/// - Risk factor analysis
///
/// CSV format allows import into Excel, Google Sheets, or other tools
/// Part of the Analytics & Insights Platform

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/models/assessment_history_model.dart';

class AnalyticsCSVService {
  /// Export assessment history to CSV and share
  static Future<String> exportAndShareAssessmentHistory({
    required List<AssessmentRecord> history,
    String language = 'en',
  }) async {
    try {
      final csv = _generateAssessmentHistoryCSV(history, language);
      final file = await _saveCSV(
        csv,
        'Juan_Heart_Assessment_History_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );

      await _shareFile(file, language);

      return language == 'fil'
          ? 'Assessment history CSV na-share na!'
          : 'Assessment history CSV shared successfully!';
    } catch (e) {
      throw Exception('Error exporting assessment history: $e');
    }
  }

  /// Export vital signs trends to CSV and share
  static Future<String> exportAndShareVitalSigns({
    required Map<String, List<VitalSignTrend>> vitalTrends,
    String language = 'en',
  }) async {
    try {
      final csv = _generateVitalSignsCSV(vitalTrends, language);
      final file = await _saveCSV(
        csv,
        'Juan_Heart_Vital_Signs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );

      await _shareFile(file, language);

      return language == 'fil'
          ? 'Vital signs CSV na-share na!'
          : 'Vital signs CSV shared successfully!';
    } catch (e) {
      throw Exception('Error exporting vital signs: $e');
    }
  }

  /// Export complete analytics package (combined CSV)
  static Future<String> exportAndShareCompleteAnalytics({
    required List<AssessmentRecord> history,
    required Map<String, List<VitalSignTrend>> vitalTrends,
    String language = 'en',
  }) async {
    try {
      final assessmentCsv = _generateAssessmentHistoryCSV(history, language);
      final vitalCsv = _generateVitalSignsCSV(vitalTrends, language);

      final assessmentFile = await _saveCSV(
        assessmentCsv,
        'Juan_Heart_Assessment_History_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      );

      final vitalFile = await _saveCSV(
        vitalCsv,
        'Juan_Heart_Vital_Signs_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      );

      await _shareMultipleFiles([assessmentFile, vitalFile], language);

      return language == 'fil'
          ? 'Complete analytics CSV na-share na!'
          : 'Complete analytics CSV shared successfully!';
    } catch (e) {
      throw Exception('Error exporting complete analytics: $e');
    }
  }

  /// Generate CSV content for assessment history
  static String _generateAssessmentHistoryCSV(
    List<AssessmentRecord> history,
    String language,
  ) {
    if (history.isEmpty) {
      return language == 'fil'
          ? 'Walang assessment history'
          : 'No assessment history available';
    }

    final buffer = StringBuffer();

    // CSV Header
    if (language == 'fil') {
      buffer.writeln(
          'Petsa,Oras,Risk Category,Final Risk Score,Likelihood Score,Impact Score,'
          'Systolic BP,Diastolic BP,Heart Rate,Oxygen Saturation,Temperature,'
          'Weight,Height,BMI,Edad,Kasarian,Recommended Action');
    } else {
      buffer.writeln(
          'Date,Time,Risk Category,Final Risk Score,Likelihood Score,Impact Score,'
          'Systolic BP,Diastolic BP,Heart Rate,Oxygen Saturation,Temperature,'
          'Weight,Height,BMI,Age,Sex,Recommended Action');
    }

    // Data rows
    for (final record in history) {
      final date = DateFormat('yyyy-MM-dd').format(record.date);
      final time = DateFormat('HH:mm:ss').format(record.date);

      buffer.writeln(
        '"$date","$time","${record.riskCategory}",${record.finalRiskScore},'
        '${record.likelihoodScore},${record.impactScore},'
        '${record.systolicBP ?? 'N/A'},${record.diastolicBP ?? 'N/A'},'
        '${record.heartRate ?? 'N/A'},${record.oxygenSaturation ?? 'N/A'},'
        '${record.temperature ?? 'N/A'},${record.weight ?? 'N/A'},'
        '${record.height ?? 'N/A'},${record.bmi?.toStringAsFixed(1) ?? 'N/A'},'
        '${record.age},"${record.sex}","${_escapeCSV(record.recommendedAction)}"',
      );
    }

    return buffer.toString();
  }

  /// Generate CSV content for vital signs trends
  static String _generateVitalSignsCSV(
    Map<String, List<VitalSignTrend>> vitalTrends,
    String language,
  ) {
    final buffer = StringBuffer();

    // CSV Header
    if (language == 'fil') {
      buffer.writeln(
          'Petsa,Oras,Systolic BP,Diastolic BP,Heart Rate,Oxygen Saturation,'
          'Temperature,Weight,BMI');
    } else {
      buffer.writeln(
          'Date,Time,Systolic BP,Diastolic BP,Heart Rate,Oxygen Saturation,'
          'Temperature,Weight,BMI');
    }

    // Collect all unique dates
    final allDates = <DateTime>{};
    vitalTrends.values.forEach((trends) {
      trends.forEach((trend) => allDates.add(trend.date));
    });

    final sortedDates = allDates.toList()..sort();

    // Data rows
    for (final date in sortedDates) {
      final systolic = _findTrendValue(vitalTrends['systolicBP'] ?? [], date);
      final diastolic = _findTrendValue(vitalTrends['diastolicBP'] ?? [], date);
      final heartRate = _findTrendValue(vitalTrends['heartRate'] ?? [], date);
      final oxygenSat = _findTrendValue(vitalTrends['oxygenSaturation'] ?? [], date);
      final temp = _findTrendValue(vitalTrends['temperature'] ?? [], date);
      final weight = _findTrendValue(vitalTrends['weight'] ?? [], date);
      final bmi = _findTrendValue(vitalTrends['bmi'] ?? [], date);

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final timeStr = DateFormat('HH:mm:ss').format(date);

      buffer.writeln(
        '"$dateStr","$timeStr",'
        '${systolic != null ? systolic.toStringAsFixed(0) : 'N/A'},'
        '${diastolic != null ? diastolic.toStringAsFixed(0) : 'N/A'},'
        '${heartRate != null ? heartRate.toStringAsFixed(0) : 'N/A'},'
        '${oxygenSat != null ? oxygenSat.toStringAsFixed(0) : 'N/A'},'
        '${temp != null ? temp.toStringAsFixed(1) : 'N/A'},'
        '${weight != null ? weight.toStringAsFixed(1) : 'N/A'},'
        '${bmi != null ? bmi.toStringAsFixed(1) : 'N/A'}',
      );
    }

    return buffer.toString();
  }

  /// Find trend value for a specific date
  static double? _findTrendValue(List<VitalSignTrend> trends, DateTime date) {
    try {
      return trends.firstWhere((t) => t.date == date).value;
    } catch (e) {
      return null;
    }
  }

  /// Escape CSV special characters
  static String _escapeCSV(String value) {
    if (value.contains('"') || value.contains(',') || value.contains('\n')) {
      return value.replaceAll('"', '""');
    }
    return value;
  }

  /// Save CSV content to file
  static Future<File> _saveCSV(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  /// Save CSV to Downloads folder
  static Future<File> _saveCSVToDownloads(String content, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  /// Share a single CSV file
  static Future<void> _shareFile(File file, String language) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: language == 'fil'
            ? 'Ang aking Juan Heart analytics data (CSV format)\n\nPwede i-import sa Excel o Google Sheets.'
            : 'My Juan Heart analytics data (CSV format)\n\nCan be imported into Excel or Google Sheets.',
        subject: language == 'fil'
            ? 'Juan Heart - Analytics Data (CSV)'
            : 'Juan Heart - Analytics Data (CSV)',
      );
    } catch (e) {
      throw Exception('Error sharing CSV: $e');
    }
  }

  /// Share multiple CSV files
  static Future<void> _shareMultipleFiles(List<File> files, String language) async {
    try {
      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
        text: language == 'fil'
            ? 'Ang aking Juan Heart complete analytics data (CSV format)\n\nKasama ang assessment history at vital signs trends.'
            : 'My Juan Heart complete analytics data (CSV format)\n\nIncludes assessment history and vital signs trends.',
        subject: language == 'fil'
            ? 'Juan Heart - Complete Analytics (CSV)'
            : 'Juan Heart - Complete Analytics (CSV)',
      );
    } catch (e) {
      throw Exception('Error sharing CSV files: $e');
    }
  }

  /// Export assessment history to Downloads folder
  static Future<String> downloadAssessmentHistory({
    required List<AssessmentRecord> history,
    String language = 'en',
  }) async {
    try {
      final csv = _generateAssessmentHistoryCSV(history, language);
      final file = await _saveCSVToDownloads(
        csv,
        'Juan_Heart_Assessment_History_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );

      return language == 'fil'
          ? 'Assessment history CSV na-download sa: ${file.path}'
          : 'Assessment history CSV downloaded to: ${file.path}';
    } catch (e) {
      throw Exception('Error downloading assessment history: $e');
    }
  }

  /// Export vital signs to Downloads folder
  static Future<String> downloadVitalSigns({
    required Map<String, List<VitalSignTrend>> vitalTrends,
    String language = 'en',
  }) async {
    try {
      final csv = _generateVitalSignsCSV(vitalTrends, language);
      final file = await _saveCSVToDownloads(
        csv,
        'Juan_Heart_Vital_Signs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );

      return language == 'fil'
          ? 'Vital signs CSV na-download sa: ${file.path}'
          : 'Vital signs CSV downloaded to: ${file.path}';
    } catch (e) {
      throw Exception('Error downloading vital signs: $e');
    }
  }
}
