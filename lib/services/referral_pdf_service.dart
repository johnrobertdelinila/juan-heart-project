/// Referral PDF Service
/// 
/// Generates PDF documents for referral summaries
/// Includes assessment results, recommendations, and facility information
/// Supports bilingual (English/Filipino) output
/// 
/// Part of the Referral & Care Navigation System

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:intl/intl.dart';

class ReferralPDFService {
  /// Generate and share referral summary PDF
  static Future<String> generateAndShareReferral(
    ReferralSummary summary, {
    String language = 'en',
  }) async {
    try {
      final pdf = await _generateReferralPDF(summary, language);
      final file = await _savePDF(pdf, 'referral_summary_${DateTime.now().millisecondsSinceEpoch}.pdf');
      
      await _sharePDF(file);
      
      return language == 'fil'
          ? 'Referral summary na-share na'
          : 'Referral summary shared successfully';
    } catch (e) {
      throw Exception('Error generating referral report: $e');
    }
  }
  
  /// Generate and download referral summary PDF
  static Future<String> generateAndDownloadReferral(
    ReferralSummary summary, {
    String language = 'en',
  }) async {
    try {
      final pdf = await _generateReferralPDF(summary, language);
      final file = await _savePDFToDownloads(
        pdf,
        'Juan_Heart_Referral_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
      
      return language == 'fil'
          ? 'Referral summary na-download sa: ${file.path}'
          : 'Referral summary downloaded to: ${file.path}';
    } catch (e) {
      throw Exception('Error generating referral report: $e');
    }
  }
  
  /// Generate referral PDF document
  static Future<pw.Document> _generateReferralPDF(
    ReferralSummary summary,
    String language,
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(summary, language),
          pw.SizedBox(height: 20),
          
          // Patient Information
          _buildPatientInfo(summary, language),
          pw.SizedBox(height: 20),
          
          // Risk Assessment Results
          _buildRiskResults(summary, language),
          pw.SizedBox(height: 20),
          
          // Care Recommendation
          _buildCareRecommendation(summary, language),
          pw.SizedBox(height: 20),
          
          // Selected Facility
          _buildFacilityInfo(summary, language),
          pw.SizedBox(height: 20),
          
          // Disclaimer
          _buildDisclaimer(language),
          
          pw.SizedBox(height: 30),
          
          // Footer
          _buildFooter(summary, language),
        ],
      ),
    );
    
    return pdf;
  }
  
  static pw.Widget _buildHeader(ReferralSummary summary, String language) {
    return pw.Column(
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
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  language == 'fil'
                      ? 'Cardiovascular Risk Assessment App'
                      : 'Cardiovascular Risk Assessment App',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _getRiskColorLight(summary.recommendation),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                language == 'fil' ? 'REFERRAL FORM' : 'REFERRAL FORM',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
      ],
    );
  }
  
  static pw.Widget _buildPatientInfo(ReferralSummary summary, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? 'Impormasyon ng Pasyente' : 'Patient Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoField(
                  language == 'fil' ? 'Pangalan' : 'Name',
                  summary.patientName,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildInfoField(
                  language == 'fil' ? 'Edad' : 'Age',
                  '${summary.patientAge} ${language == "fil" ? "taong gulang" : "years old"}',
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildInfoField(
                  language == 'fil' ? 'Kasarian' : 'Sex',
                  summary.patientSex,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildInfoField(
            language == 'fil' ? 'Petsa ng Assessment' : 'Assessment Date',
            DateFormat('MMMM dd, yyyy - hh:mm a').format(summary.assessmentDate),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildRiskResults(ReferralSummary summary, String language) {
    final rec = summary.recommendation;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _getRiskColorLight(rec),
        border: pw.Border.all(color: _getRiskColorDark(rec), width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? 'Resulta ng Risk Assessment' : 'Risk Assessment Result',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  color: _getRiskColorDark(rec),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '${rec.riskScore}',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      rec.riskCategory,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _getRiskColorDark(rec),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${language == "fil" ? "Puntos" : "Score"}: ${rec.riskScore}/25',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(12),
                        ),
                      ),
                      child: pw.Text(
                        '${language == "fil" ? "Kaagaran" : "Urgency"}: ${rec.timeframe}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _getRiskColorDark(rec),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildCareRecommendation(ReferralSummary summary, String language) {
    final rec = summary.recommendation;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '♥ ',
                style: const pw.TextStyle(fontSize: 18, color: PdfColors.red),
              ),
              pw.Text(
                language == 'fil' ? 'Rekomendasyon sa Pag-aalaga' : 'Care Recommendation',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            rec.actionTitle,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            rec.actionMessage,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey800,
              lineSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              rec.detailedGuidance,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey900,
                lineSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFacilityInfo(ReferralSummary summary, String language) {
    final facility = summary.selectedFacility;
    if (facility == null) return pw.SizedBox();
    
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
            language == 'fil' ? 'Nirerekomendang Pasilidad' : 'Recommended Facility',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            facility.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            facility.typeName,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildFacilityDetail(
            '→ ${language == "fil" ? "Address" : "Address"}',
            facility.address,
          ),
          if (facility.primaryContact != null) ...[
            pw.SizedBox(height: 6),
            _buildFacilityDetail(
              '→ ${language == "fil" ? "Telepono" : "Phone"}',
              facility.primaryContact!,
            ),
          ],
          pw.SizedBox(height: 6),
          _buildFacilityDetail(
            '→ ${language == "fil" ? "Layo" : "Distance"}',
            facility.distanceText,
          ),
          if (facility.is24Hours) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              '→ ${language == "fil" ? "Bukas 24/7" : "Open 24/7"}',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.green700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _buildFacilityDetail(String label, String value) {
    return pw.Text(
      '$label: $value',
      style: const pw.TextStyle(
        fontSize: 11,
        color: PdfColors.grey800,
        lineSpacing: 1.4,
      ),
    );
  }
  
  static pw.Widget _buildDisclaimer(String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            language == 'fil' ? '⚠ PAALALA' : '⚠ IMPORTANT NOTICE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            language == 'fil'
                ? 'Ang dokumentong ito ay hindi medikal na diagnosis. Ito ay batay lamang sa risk assessment tool at hindi kapalit ng propesyonal na konsultasyon. Para sa tumpak na diagnosis at treatment, kumunsulta sa lisensyadong doktor.'
                : 'This document does not constitute a medical diagnosis. It is based on a risk assessment tool and is not a substitute for professional medical consultation. For accurate diagnosis and treatment, please consult a licensed physician.',
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
  
  static pw.Widget _buildFooter(ReferralSummary summary, String language) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              language == 'fil'
                  ? 'Generated ng Juan Heart App'
                  : 'Generated by Juan Heart App',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now()),
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
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
    );
  }
  
  static pw.Widget _buildInfoField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }
  
  static PdfColor _getRiskColorLight(CareRecommendation rec) {
    if (rec.riskScore <= 4) {
      return PdfColors.green50;
    } else if (rec.riskScore <= 9) {
      return PdfColors.blue50;
    } else if (rec.riskScore <= 14) {
      return PdfColors.orange50;
    } else if (rec.riskScore <= 19) {
      return PdfColors.red50;
    } else {
      return PdfColors.red100;
    }
  }
  
  static PdfColor _getRiskColorDark(CareRecommendation rec) {
    if (rec.riskScore <= 4) {
      return PdfColors.green700;
    } else if (rec.riskScore <= 9) {
      return PdfColors.blue700;
    } else if (rec.riskScore <= 14) {
      return PdfColors.orange700;
    } else if (rec.riskScore <= 19) {
      return PdfColors.red700;
    } else {
      return PdfColors.red900;
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
  
  static Future<void> _sharePDF(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Juan Heart - Referral Summary',
      );
    } catch (e) {
      throw Exception('Error sharing PDF: $e');
    }
  }
}

