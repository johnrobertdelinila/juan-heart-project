import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/themes/jh_colors.dart';

class AppointmentHistoryPdfService {
  static Future<void> export({
    required BuildContext context,
    required List<Appointment> appointments,
    DateTimeRange? dateRange,
    String? facility,
    AppointmentStatus? status,
  }) async {
    if (appointments.isEmpty) {
      _showSnack(context, _t(context, 'No data to export', 'Walang data'));
      return;
    }

    _showLoading(context);

    try {
      final doc = await _buildDocument(
        appointments: appointments,
        dateRange: dateRange,
        facility: facility,
        status: status,
      );
      final file = await _saveDocument(doc);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _t(context, 'Appointment History', 'Kasaysayan ng Appointment'),
      );
    } catch (e) {
      _showSnack(
        context,
        _t(context, 'Failed to export: $e', 'Hindi ma-export: $e'),
      );
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Future<pw.Document> _buildDocument({
    required List<Appointment> appointments,
    DateTimeRange? dateRange,
    String? facility,
    AppointmentStatus? status,
  }) async {
    final pdf = pw.Document();
    final rows = appointments
        .map(
          (apt) => [
            DateFormat('MMM dd, yyyy').format(apt.appointmentDate),
            apt.appointmentTime,
            apt.facilityName,
            apt.doctorName,
            apt.getStatusText('en'),
          ],
        )
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 16),
          _buildFilters(dateRange, facility, status),
          pw.SizedBox(height: 16),
          _buildTable(rows),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Juan Heart — Appointment History',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now()),
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildFilters(
    DateTimeRange? range,
    String? facility,
    AppointmentStatus? status,
  ) {
    final chips = <String>[];

    if (range != null) {
      final start = DateFormat.yMMMd().format(range.start);
      final end = DateFormat.yMMMd().format(range.end);
      chips.add('Range: $start - $end');
    }

    if (facility != null) {
      chips.add('Facility: $facility');
    }

    if (status != null) {
      chips.add('Status: ${status.name}');
    }

    if (chips.isEmpty) {
      chips.add('Filters: All');
    }

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (chip) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(JHColors.infoLight.value),
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Text(
                chip,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildTable(List<List<String>> rows) {
    final headers = ['Date', 'Time', 'Facility', 'Doctor', 'Status'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.indigo,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerHeight: 28,
      cellHeight: 24,
    );
  }

  static Future<File> _saveDocument(pw.Document doc) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/appointment_history.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _t(BuildContext context, String en, String fil) {
    return Localizations.localeOf(context).languageCode == 'fil' ? fil : en;
  }
}
