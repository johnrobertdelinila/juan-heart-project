import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PDFReportService {
  static Future<void> generateAndShareReport(
    Map<String, dynamic> assessmentResult,
    Map<String, dynamic> userInput,
    BuildContext context,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF
      final pdf = await _generatePDF(assessmentResult, userInput);
      
      // Save to file
      final file = await _savePDF(pdf);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Share the PDF
      await _sharePDF(file, context);
      
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> generateAndDownloadReport(
    Map<String, dynamic> assessmentResult,
    Map<String, dynamic> userInput,
    BuildContext context,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF
      final pdf = await _generatePDF(assessmentResult, userInput);
      
      // Save to Downloads folder
      final file = await _savePDFToDownloads(pdf);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded successfully to: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<pw.Document> _generatePDF(
    Map<String, dynamic> assessmentResult,
    Map<String, dynamic> userInput,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(),
            pw.SizedBox(height: 20),
            
            // Assessment Summary
            _buildAssessmentSummary(assessmentResult),
            pw.SizedBox(height: 20),
            
            // Risk Details
            _buildRiskDetails(assessmentResult),
            pw.SizedBox(height: 20),
            
            // Recommendations
            _buildRecommendations(assessmentResult),
            pw.SizedBox(height: 20),
            
            // User Input Summary
            _buildUserInputSummary(userInput),
            pw.SizedBox(height: 20),
            
            // Footer
            _buildFooter(now, dateFormat, timeFormat),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.red400,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '♥',
                    style: pw.TextStyle(
                      fontSize: 20,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 15),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Juan Heart - Medical Triage Assessment Report',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Philippine Heart Center',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.blue700,
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

  static pw.Widget _buildAssessmentSummary(Map<String, dynamic> result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _getRiskColorLight(result['riskCategory']),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _getRiskColor(result['riskCategory'])),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assessment Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _getRiskColor(result['riskCategory']),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Risk Category:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                result['riskCategory'],
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _getRiskColor(result['riskCategory']),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Final Risk Score:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${result['finalRiskScore']}/25',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Likelihood:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${result['likelihoodScore']} (${result['likelihoodLevel']})',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Impact:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${result['impactScore']} (${result['impactLevel']})',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Recommended Action:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            result['recommendedAction'],
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRiskDetails(Map<String, dynamic> result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Risk Assessment Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            result['explanation'],
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Safety Message:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            result['safetyMessage'],
            style: pw.TextStyle(fontSize: 12, color: PdfColors.red700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRecommendations(Map<String, dynamic> result) {
    // Generate recommendations (simplified version for PDF)
    List<String> recommendations = _generateSimpleRecommendations(result);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Personalized Recommendations',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...recommendations.map((rec) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '• $rec',
              style: pw.TextStyle(fontSize: 12),
            ),
          )).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildUserInputSummary(Map<String, dynamic> userInput) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assessment Input Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInputRow('Age', userInput['age']?.toString() ?? 'Not provided'),
          _buildInputRow('Sex', userInput['sex']?.toString() ?? 'Not provided'),
          _buildInputRow('Chest Pain Type', userInput['chestPainType']?.toString() ?? 'Not provided'),
          _buildInputRow('Chest Pain Duration', '${userInput['chestPainDuration']?.toString() ?? '0'} minutes'),
          _buildInputRow('Shortness of Breath', userInput['shortnessOfBreathLevel']?.toString() ?? 'Not provided'),
          _buildInputRow('Blood Pressure', '${userInput['systolicBP']?.toString() ?? 'N/A'}/${userInput['diastolicBP']?.toString() ?? 'N/A'} mmHg'),
          _buildInputRow('Heart Rate', '${userInput['heartRate']?.toString() ?? 'N/A'} bpm'),
          _buildInputRow('Oxygen Saturation', '${userInput['oxygenSaturation']?.toString() ?? 'N/A'}%'),
        ],
      ),
    );
  }

  static pw.Widget _buildInputRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$label:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(DateTime now, DateFormat dateFormat, DateFormat timeFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Report Generated: ${dateFormat.format(now)} at ${timeFormat.format(now)}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This report is generated by Juan Heart - Medical Triage Assessment System',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'IMPORTANT: This assessment is for triage guidance only and does not replace professional medical consultation. Always consult with qualified healthcare professionals for proper medical evaluation.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.red700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static PdfColor _getRiskColor(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return PdfColors.red;
      case 'high':
        return PdfColors.orange;
      case 'moderate':
        return PdfColors.yellow;
      case 'mild':
        return PdfColors.lightGreen;
      case 'low':
        return PdfColors.green;
      default:
        return PdfColors.blue;
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
        return PdfColors.blue50;
    }
  }

  static List<String> _generateSimpleRecommendations(Map<String, dynamic> result) {
    List<String> recommendations = [];
    
    int finalScore = result['finalRiskScore'] ?? 0;
    String riskCategory = result['riskCategory'] ?? 'Low';
    
    if (finalScore >= 20) {
      recommendations.add("URGENT: Your risk level is very high. Seek immediate medical attention.");
      recommendations.add("• Go to the emergency room immediately");
      recommendations.add("• Call emergency services if experiencing severe symptoms");
    } else if (finalScore >= 15) {
      recommendations.add("WARNING: Your risk level is high. Schedule urgent medical consultation.");
      recommendations.add("• Contact your doctor within 6-24 hours");
      recommendations.add("• Monitor symptoms closely");
    } else if (finalScore >= 10) {
      recommendations.add("MODERATE: Your risk level is moderate. Schedule medical consultation.");
      recommendations.add("• Book an appointment with your doctor within 24-48 hours");
      recommendations.add("• Follow up on any concerning symptoms");
    } else {
      recommendations.add("GOOD: Your risk level is low. Continue maintaining a healthy lifestyle.");
      recommendations.add("• Regular exercise and balanced diet");
      recommendations.add("• Annual health checkups");
    }
    
    recommendations.add("• Always consult healthcare professionals for medical advice");
    recommendations.add("• Keep this report for your medical records");
    
    return recommendations;
  }

  static Future<File> _savePDF(pw.Document pdf) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/juan_heart_assessment_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> _savePDFToDownloads(pw.Document pdf) async {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/Juan_Heart_Assessment_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> _sharePDF(File file, BuildContext context) async {
    try {
      // Try to get the render box for share position origin
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      
      if (renderBox != null) {
        // Use the render box position for iOS
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Juan Heart - Medical Triage Assessment Report\n\nPlease find attached my heart health assessment report from the Juan Heart app.',
          subject: 'Juan Heart Assessment Report',
          sharePositionOrigin: renderBox.localToGlobal(Offset.zero) & renderBox.size,
        );
      } else {
        // Fallback without sharePositionOrigin
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Juan Heart - Medical Triage Assessment Report\n\nPlease find attached my heart health assessment report from the Juan Heart app.',
          subject: 'Juan Heart Assessment Report',
        );
      }
    } catch (e) {
      // If there's any error with sharePositionOrigin, try without it
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Juan Heart - Medical Triage Assessment Report\n\nPlease find attached my heart health assessment report from the Juan Heart app.',
        subject: 'Juan Heart Assessment Report',
      );
    }
  }
}
