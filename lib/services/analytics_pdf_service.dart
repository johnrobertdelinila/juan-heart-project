/// Analytics PDF Report Service
///
/// Generates comprehensive health analytics PDF reports
/// Includes:
/// - Risk trend history
/// - Vital signs trends (BP, HR, SpO2, Temp, Weight, BMI)
/// - Risk heatmap visualization
/// - Health insights and recommendations
/// - Assessment history timeline
/// - Risk factor analysis
///
/// Part of the Analytics & Insights Platform
/// Supports bilingual (English/Filipino) output
/// Branded with Philippine Heart Center partnership

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/models/assessment_history_model.dart';

class AnalyticsPDFService {
  /// Generate and share comprehensive analytics PDF report
  static Future<String> generateAndShareHealthReport({
    required List<AssessmentRecord> history,
    required RiskTrendStats trendStats,
    required Map<String, List<VitalSignTrend>> vitalTrends,
    required List<HealthInsight> insights,
    required Map<String, int> categoryDistribution,
    String language = 'en',
  }) async {
    try {
      final pdf = await _generateHealthReportPDF(
        history: history,
        trendStats: trendStats,
        vitalTrends: vitalTrends,
        insights: insights,
        categoryDistribution: categoryDistribution,
        language: language,
      );

      final file = await _savePDF(
        pdf,
        'Juan_Heart_Analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      await _sharePDF(file, language);

      return language == 'fil'
          ? 'Health report na-share na!'
          : 'Health report shared successfully!';
    } catch (e) {
      throw Exception('Error generating analytics report: $e');
    }
  }

  /// Generate and download comprehensive analytics PDF report
  static Future<String> generateAndDownloadHealthReport({
    required List<AssessmentRecord> history,
    required RiskTrendStats trendStats,
    required Map<String, List<VitalSignTrend>> vitalTrends,
    required List<HealthInsight> insights,
    required Map<String, int> categoryDistribution,
    String language = 'en',
  }) async {
    try {
      final pdf = await _generateHealthReportPDF(
        history: history,
        trendStats: trendStats,
        vitalTrends: vitalTrends,
        insights: insights,
        categoryDistribution: categoryDistribution,
        language: language,
      );

      final file = await _savePDFToDownloads(
        pdf,
        'Juan_Heart_Analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      return language == 'fil'
          ? 'Health report na-download sa: ${file.path}'
          : 'Health report downloaded to: ${file.path}';
    } catch (e) {
      throw Exception('Error downloading analytics report: $e');
    }
  }

  /// Generate comprehensive health report PDF document
  static Future<pw.Document> _generateHealthReportPDF({
    required List<AssessmentRecord> history,
    required RiskTrendStats trendStats,
    required Map<String, List<VitalSignTrend>> vitalTrends,
    required List<HealthInsight> insights,
    required Map<String, int> categoryDistribution,
    required String language,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header with PHC Branding
          _buildHeader(language),
          pw.SizedBox(height: 20),

          // Executive Summary
          _buildExecutiveSummary(trendStats, history, language),
          pw.SizedBox(height: 20),

          // Health Progress Overview
          _buildHealthProgress(trendStats, language),
          pw.SizedBox(height: 20),

          // Vital Signs Summary
          _buildVitalSignsSummary(vitalTrends, language),
          pw.SizedBox(height: 20),

          // Page break indicator
          pw.Divider(thickness: 2, color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          // Health Insights & Recommendations
          _buildHealthInsights(insights, language),
          pw.SizedBox(height: 20),

          // Assessment History Summary
          _buildAssessmentHistory(history, language),
          pw.SizedBox(height: 20),

          // Risk Category Distribution
          _buildRiskDistribution(categoryDistribution, language),
          pw.SizedBox(height: 30),

          // Disclaimer
          _buildDisclaimer(language),
          pw.SizedBox(height: 20),

          // Footer with PHC Partnership
          _buildFooter(language),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue900, PdfColors.blue700],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Juan Heart',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    language == 'fil'
                        ? 'Health Analytics Report'
                        : 'Health Analytics Report',
                    style: const pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '♥',
                    style: pw.TextStyle(
                      fontSize: 36,
                      color: PdfColors.red700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                language == 'fil'
                    ? 'Cardiovascular Health Insights'
                    : 'Cardiovascular Health Insights',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExecutiveSummary(
    RiskTrendStats trendStats,
    List<AssessmentRecord> history,
    String language,
  ) {
    final latest = history.isNotEmpty ? history.last : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? '📊 Buod ng Kalusugan' : '📊 Executive Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  language == 'fil' ? 'Total Assessments' : 'Total Assessments',
                  '${trendStats.totalAssessments}',
                  PdfColors.blue700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildSummaryCard(
                  language == 'fil' ? 'Average Risk' : 'Average Risk',
                  trendStats.avgRiskScore.toStringAsFixed(1),
                  PdfColors.orange700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildSummaryCard(
                  language == 'fil' ? 'Trend' : 'Trend',
                  _getTrendEmoji(trendStats.trendDirection),
                  _getTrendColor(trendStats.trendDirection),
                ),
              ),
            ],
          ),
          if (latest != null) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    language == 'fil'
                        ? 'Pinakabagong Assessment'
                        : 'Latest Assessment',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        DateFormat('MMM dd, yyyy').format(latest.date),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _getRiskColorLight(latest.riskCategory),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(12),
                          ),
                        ),
                        child: pw.Text(
                          '${latest.riskCategory} - ${latest.finalRiskScore}/25',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _getRiskColorDark(latest.riskCategory),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: color.shade(0.3)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHealthProgress(RiskTrendStats trendStats, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _getTrendBackgroundColor(trendStats.trendDirection),
        border: pw.Border.all(color: _getTrendColor(trendStats.trendDirection)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? '📈 Pag-unlad sa Kalusugan' : '📈 Health Progress',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    language == 'fil' ? 'Trend Direction' : 'Trend Direction',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _getTrendText(trendStats.trendDirection, language),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _getTrendColor(trendStats.trendDirection),
                    ),
                  ),
                ],
              ),
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  color: _getTrendColor(trendStats.trendDirection),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    _getTrendEmoji(trendStats.trendDirection),
                    style: const pw.TextStyle(
                      fontSize: 36,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            language == 'fil'
                ? 'Pinakakaraniwang Kategorya: ${trendStats.mostCommonCategory}'
                : 'Most Common Category: ${trendStats.mostCommonCategory}',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVitalSignsSummary(
    Map<String, List<VitalSignTrend>> vitalTrends,
    String language,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? '🩺 Mga Vital Signs' : '🩺 Vital Signs Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildVitalSignRow(
            language == 'fil' ? 'Blood Pressure' : 'Blood Pressure',
            vitalTrends['systolicBP'] ?? [],
            vitalTrends['diastolicBP'] ?? [],
            'mmHg',
          ),
          pw.Divider(color: PdfColors.grey200),
          _buildVitalSignRow(
            language == 'fil' ? 'Heart Rate' : 'Heart Rate',
            vitalTrends['heartRate'] ?? [],
            null,
            'bpm',
          ),
          pw.Divider(color: PdfColors.grey200),
          _buildVitalSignRow(
            language == 'fil' ? 'Oxygen Saturation' : 'Oxygen Saturation',
            vitalTrends['oxygenSaturation'] ?? [],
            null,
            '%',
          ),
          pw.Divider(color: PdfColors.grey200),
          _buildVitalSignRow(
            language == 'fil' ? 'Temperature' : 'Temperature',
            vitalTrends['temperature'] ?? [],
            null,
            '°C',
          ),
          pw.Divider(color: PdfColors.grey200),
          _buildVitalSignRow(
            language == 'fil' ? 'Weight' : 'Weight',
            vitalTrends['weight'] ?? [],
            null,
            'kg',
          ),
          pw.Divider(color: PdfColors.grey200),
          _buildVitalSignRow(
            language == 'fil' ? 'BMI' : 'BMI',
            vitalTrends['bmi'] ?? [],
            null,
            '',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVitalSignRow(
    String label,
    List<VitalSignTrend> primary,
    List<VitalSignTrend>? secondary,
    String unit,
  ) {
    if (primary.isEmpty) return pw.SizedBox();

    final latest = primary.last.value;
    final first = primary.first.value;
    final change = latest - first;

    String valueText;
    if (secondary != null && secondary.isNotEmpty) {
      valueText = '${latest.toStringAsFixed(0)}/${secondary.last.value.toStringAsFixed(0)} $unit';
    } else {
      valueText = '${latest.toStringAsFixed(1)} $unit';
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Row(
            children: [
              pw.Text(
                valueText,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: change.abs() < 0.1
                      ? PdfColors.grey200
                      : change < 0
                          ? PdfColors.green100
                          : PdfColors.orange100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  change.abs() < 0.1
                      ? 'Stable'
                      : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: change.abs() < 0.1
                        ? PdfColors.grey700
                        : change < 0
                            ? PdfColors.green800
                            : PdfColors.orange800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHealthInsights(
    List<HealthInsight> insights,
    String language,
  ) {
    if (insights.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil'
                ? '💡 Mga Health Insights'
                : '💡 Personalized Health Insights',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          ...insights.take(5).map((insight) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 20,
                      height: 20,
                      decoration: pw.BoxDecoration(
                        color: _getInsightColor(insight.type),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          _getInsightEmoji(insight.type),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            insight.title,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            insight.message,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              lineSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentHistory(
    List<AssessmentRecord> history,
    String language,
  ) {
    final recent = history.reversed.take(10).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil'
                ? '📅 Kasaysayan ng Assessment (Last 10)'
                : '📅 Assessment History (Last 10)',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableHeader(language == 'fil' ? 'Petsa' : 'Date'),
                  _buildTableHeader(language == 'fil' ? 'Kategorya' : 'Category'),
                  _buildTableHeader(language == 'fil' ? 'Score' : 'Score'),
                  _buildTableHeader('L × I'),
                ],
              ),
              // Data rows
              ...recent.map((record) => pw.TableRow(
                    children: [
                      _buildTableCell(DateFormat('MMM dd').format(record.date)),
                      _buildTableCell(record.riskCategory),
                      _buildTableCell('${record.finalRiskScore}'),
                      _buildTableCell('${record.likelihoodScore} × ${record.impactScore}'),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildRiskDistribution(
    Map<String, int> distribution,
    String language,
  ) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil'
                ? '📊 Pamamahagi ng Risk Category'
                : '📊 Risk Category Distribution',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          ...distribution.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 100,
                    child: pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          height: 20,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                        ),
                        pw.Container(
                          width: (entry.value / total) * 300,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            color: _getRiskColorDark(entry.key),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '$percentage%',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildDisclaimer(String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? '⚠ MAHALAGANG PAALALA' : '⚠ IMPORTANT DISCLAIMER',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            language == 'fil'
                ? 'Ang report na ito ay batay sa self-assessment at hindi medikal na diagnosis. Ito ay para lamang sa triage guidance at hindi kapalit ng propesyonal na konsultasyon. Para sa tumpak na diagnosis at treatment, kumunsulta sa lisensyadong doktor o healthcare provider.'
                : 'This report is based on self-assessment and does not constitute a medical diagnosis. It is for triage guidance only and not a substitute for professional medical consultation. For accurate diagnosis and treatment, please consult a licensed physician or healthcare provider.',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
              lineSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String language) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 2, color: PdfColors.grey400),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  language == 'fil'
                      ? 'Generated ng Juan Heart App'
                      : 'Generated by Juan Heart App',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  language == 'fil'
                      ? 'Philippine Heart Center x University of the Cordilleras'
                      : 'Philippine Heart Center x University of the Cordilleras',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
            pw.Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now()),
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            language == 'fil'
                ? '🩺 Keep this report for your medical records. Show it to your healthcare provider during consultations.'
                : '🩺 Keep this report for your medical records. Show it to your healthcare provider during consultations.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blue900,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Helper methods
  static String _getTrendEmoji(String trend) {
    switch (trend) {
      case 'improving':
        return '↓';
      case 'worsening':
        return '↑';
      default:
        return '→';
    }
  }

  static String _getTrendText(String trend, String language) {
    if (language == 'fil') {
      switch (trend) {
        case 'improving':
          return 'Bumubuti';
        case 'worsening':
          return 'Lumalala';
        default:
          return 'Matatag';
      }
    } else {
      switch (trend) {
        case 'improving':
          return 'Improving';
        case 'worsening':
          return 'Worsening';
        default:
          return 'Stable';
      }
    }
  }

  static PdfColor _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return PdfColors.green700;
      case 'worsening':
        return PdfColors.red700;
      default:
        return PdfColors.blue700;
    }
  }

  static PdfColor _getTrendBackgroundColor(String trend) {
    switch (trend) {
      case 'improving':
        return PdfColors.green50;
      case 'worsening':
        return PdfColors.red50;
      default:
        return PdfColors.blue50;
    }
  }

  static PdfColor _getRiskColorLight(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return PdfColors.red50;
      case 'high':
        return PdfColors.orange50;
      case 'moderate':
        return PdfColors.yellow50;
      case 'mild':
        return PdfColors.green50;
      case 'low':
        return PdfColors.green50;
      default:
        return PdfColors.grey50;
    }
  }

  static PdfColor _getRiskColorDark(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return PdfColors.red700;
      case 'high':
        return PdfColors.orange700;
      case 'moderate':
        return PdfColors.yellow700;
      case 'mild':
        return PdfColors.green600;
      case 'low':
        return PdfColors.green700;
      default:
        return PdfColors.grey700;
    }
  }

  static PdfColor _getInsightColor(String type) {
    switch (type) {
      case 'positive':
        return PdfColors.green700;
      case 'warning':
        return PdfColors.orange700;
      case 'critical':
        return PdfColors.red700;
      default:
        return PdfColors.blue700;
    }
  }

  static String _getInsightEmoji(String type) {
    switch (type) {
      case 'positive':
        return '✓';
      case 'warning':
        return '⚠';
      case 'critical':
        return '!';
      default:
        return 'i';
    }
  }

  static Future<File> _savePDF(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File> _savePDFToDownloads(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> _sharePDF(File file, String language) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: language == 'fil'
            ? 'Ang aking Juan Heart Health Analytics Report\n\nMakikita ang detalyadong resulta ng aking cardiovascular health assessment.'
            : 'My Juan Heart Health Analytics Report\n\nDetailed cardiovascular health assessment results from the Juan Heart app.',
        subject: language == 'fil'
            ? 'Juan Heart - Health Analytics Report'
            : 'Juan Heart - Health Analytics Report',
      );
    } catch (e) {
      throw Exception('Error sharing PDF: $e');
    }
  }
}
