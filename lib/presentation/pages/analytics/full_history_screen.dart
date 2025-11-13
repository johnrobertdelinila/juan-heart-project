import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/analytics_pdf_service.dart';
import 'package:juan_heart/services/analytics_csv_service.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';
import 'package:intl/intl.dart';

/// Full History Screen with Advanced Filters and Pagination
///
/// Features:
/// - Pagination (20 items per page)
/// - Advanced filters (date range, risk category, vital signs thresholds)
/// - Search functionality
/// - Export options (PDF/CSV)
/// - Bilingual support (English/Filipino)
class FullHistoryScreen extends StatefulWidget {
  final List<AssessmentRecord> initialHistory;
  final String dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FullHistoryScreen({
    super.key,
    required this.initialHistory,
    required this.dateRange,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  State<FullHistoryScreen> createState() => _FullHistoryScreenState();
}

class _FullHistoryScreenState extends State<FullHistoryScreen> {
  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  // Filters
  List<AssessmentRecord> _filteredHistory = [];
  String _selectedDateRange = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedRiskCategory;
  double? _minSystolic;
  double? _maxSystolic;
  double? _minDiastolic;
  double? _maxDiastolic;
  double? _minHeartRate;
  double? _maxHeartRate;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Loading states
  bool _isLoading = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _filteredHistory = widget.initialHistory;
    _selectedDateRange = widget.dateRange;
    _customStartDate = widget.customStartDate;
    _customEndDate = widget.customEndDate;
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredHistory = widget.initialHistory;

      // Date range filter
      if (_selectedDateRange != 'all') {
        final now = DateTime.now();
        DateTime? filterStartDate;

        switch (_selectedDateRange) {
          case 'week':
            filterStartDate = now.subtract(const Duration(days: 7));
            break;
          case 'month':
            filterStartDate = DateTime(now.year, now.month - 1, now.day);
            break;
          case 'quarter':
            filterStartDate = DateTime(now.year, now.month - 3, now.day);
            break;
          case 'year':
            filterStartDate = DateTime(now.year - 1, now.month, now.day);
            break;
          case 'custom':
            filterStartDate = _customStartDate;
            break;
        }

        if (filterStartDate != null) {
          _filteredHistory = _filteredHistory.where((record) {
            final recordDate = record.date;
            final endDate = _selectedDateRange == 'custom' && _customEndDate != null
                ? _customEndDate!
                : now;
            return recordDate.isAfter(filterStartDate!) &&
                recordDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
        }
      }

      // Risk category filter
      if (_selectedRiskCategory != null && _selectedRiskCategory != 'all') {
        _filteredHistory = _filteredHistory.where((record) {
          return record.riskCategory.toLowerCase() ==
              _selectedRiskCategory!.toLowerCase();
        }).toList();
      }

      // Vital signs filters
      _filteredHistory = _filteredHistory.where((record) {
        bool passesFilters = true;

        if (_minSystolic != null &&
            (record.systolicBP ?? 0) < _minSystolic!) {
          passesFilters = false;
        }
        if (_maxSystolic != null &&
            (record.systolicBP ?? 999) > _maxSystolic!) {
          passesFilters = false;
        }
        if (_minDiastolic != null &&
            (record.diastolicBP ?? 0) < _minDiastolic!) {
          passesFilters = false;
        }
        if (_maxDiastolic != null &&
            (record.diastolicBP ?? 999) > _maxDiastolic!) {
          passesFilters = false;
        }
        if (_minHeartRate != null &&
            (record.heartRate ?? 0) < _minHeartRate!) {
          passesFilters = false;
        }
        if (_maxHeartRate != null &&
            (record.heartRate ?? 999) > _maxHeartRate!) {
          passesFilters = false;
        }

        return passesFilters;
      }).toList();

      // Search filter
      if (_searchQuery.isNotEmpty) {
        _filteredHistory = _filteredHistory.where((record) {
          final searchLower = _searchQuery.toLowerCase();
          final dateMatch = DateFormat('MMM dd, yyyy')
              .format(record.date)
              .toLowerCase()
              .contains(searchLower);
          final categoryMatch =
              record.riskCategory.toLowerCase().contains(searchLower);
          final scoreMatch = record.finalRiskScore.toString().contains(searchLower);
          return dateMatch || categoryMatch || scoreMatch;
        }).toList();
      }

      // Reset to first page when filters change
      _currentPage = 0;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedRiskCategory = null;
      _minSystolic = null;
      _maxSystolic = null;
      _minDiastolic = null;
      _maxDiastolic = null;
      _minHeartRate = null;
      _maxHeartRate = null;
      _searchQuery = '';
      _searchController.clear();
      _currentPage = 0;
    });
    _applyFilters();
  }

  List<AssessmentRecord> get _paginatedHistory {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredHistory.length);
    return _filteredHistory.sublist(
      startIndex.clamp(0, _filteredHistory.length),
      endIndex,
    );
  }

  int get _totalPages => (_filteredHistory.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isFilipino ? 'Buong Kasaysayan' : 'Full History',
          style: JHTextStyles.h4.copyWith(color: ColorConstant.bluedark),
        ),
        actions: [
          // Filter toggle
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? ColorConstant.trustBlue : ColorConstant.gentleGray,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: isFilipino ? 'Mga Filter' : 'Filters',
          ),
          // Export menu
          PopupMenuButton<String>(
            icon: Icon(Icons.download, color: ColorConstant.trustBlue),
            tooltip: isFilipino ? 'I-export' : 'Export',
            onSelected: (value) {
              if (value == 'pdf') _exportPDF();
              if (value == 'csv') _exportCSV();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      isFilipino ? 'I-export bilang PDF' : 'Export as PDF',
                      style: JHTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      isFilipino ? 'I-export bilang CSV' : 'Export as CSV',
                      style: JHTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorConstant.whiteBackground,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isFilipino
                    ? 'Maghanap ng date, risk category, o score...'
                    : 'Search by date, risk category, or score...',
                prefixIcon: Icon(Icons.search, color: ColorConstant.gentleGray),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: ColorConstant.gentleGray),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConstant.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConstant.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConstant.trustBlue, width: 2),
                ),
                filled: true,
                fillColor: ColorConstant.softWhite,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (query) {
                setState(() => _searchQuery = query);
                _applyFilters();
              },
            ),
          ),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(isFilipino),

          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ColorConstant.whiteBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFilipino
                      ? '${_filteredHistory.length} resulta'
                      : '${_filteredHistory.length} results',
                  style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.gentleGray),
                ),
                if (_selectedRiskCategory != null ||
                    _minSystolic != null ||
                    _searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: Icon(Icons.clear_all, size: 16, color: ColorConstant.trustBlue),
                    label: Text(
                      isFilipino ? 'I-clear ang filters' : 'Clear filters',
                      style: JHTextStyles.caption.copyWith(color: ColorConstant.trustBlue),
                    ),
                  ),
              ],
            ),
          ),

          // Assessment history list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: ColorConstant.trustBlue),
                  )
                : _filteredHistory.isEmpty
                    ? _buildEmptyState(isFilipino)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _paginatedHistory.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAssessmentCard(_paginatedHistory[index], isFilipino),
                          );
                        },
                      ),
          ),

          // Pagination controls
          if (_totalPages > 1) _buildPaginationControls(isFilipino),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(bool isFilipino) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ColorConstant.whiteBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFilipino ? 'Mga Advanced Filter' : 'Advanced Filters',
            style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 16),

          // Risk Category Filter
          DropdownButtonFormField<String>(
            value: _selectedRiskCategory,
            decoration: InputDecoration(
              labelText: isFilipino ? 'Risk Category' : 'Risk Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(isFilipino ? 'Lahat' : 'All')),
              const DropdownMenuItem(value: 'very-low', child: Text('Very Low')),
              const DropdownMenuItem(value: 'low', child: Text('Low')),
              const DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
              const DropdownMenuItem(value: 'high', child: Text('High')),
              const DropdownMenuItem(value: 'very-high', child: Text('Very High')),
            ],
            onChanged: (value) {
              setState(() => _selectedRiskCategory = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),

          // Blood Pressure Range
          Text(
            isFilipino ? 'Saklaw ng Blood Pressure (mmHg)' : 'Blood Pressure Range (mmHg)',
            style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.gentleGray),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: isFilipino ? 'Min Systolic' : 'Min Systolic',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _minSystolic = double.tryParse(value));
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: isFilipino ? 'Max Systolic' : 'Max Systolic',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _maxSystolic = double.tryParse(value));
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: isFilipino ? 'Min Diastolic' : 'Min Diastolic',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _minDiastolic = double.tryParse(value));
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: isFilipino ? 'Max Diastolic' : 'Max Diastolic',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _maxDiastolic = double.tryParse(value));
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isFilipino) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: ColorConstant.gentleGray),
          const SizedBox(height: 16),
          Text(
            isFilipino ? 'Walang nakitang resulta' : 'No results found',
            style: JHTextStyles.h5.copyWith(color: ColorConstant.gentleGray),
          ),
          const SizedBox(height: 8),
          Text(
            isFilipino
                ? 'Subukang baguhin ang inyong filters'
                : 'Try adjusting your filters',
            style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.gentleGray),
          ),
          const SizedBox(height: 24),
          StandardButton.outline(
            text: isFilipino ? 'I-clear ang Filters' : 'Clear Filters',
            onPressed: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(AssessmentRecord record, bool isFilipino) {
    return StandardCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a')
                      .format(record.date),
                  style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskColor(record.riskCategory).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.riskCategory.toUpperCase(),
                    style: JHTextStyles.caption.copyWith(
                      color: _getRiskColor(record.riskCategory),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVitalSignChip(
                  Icons.favorite,
                  '${record.systolicBP ?? '-'}/${record.diastolicBP ?? '-'}',
                  'mmHg',
                ),
                const SizedBox(width: 12),
                _buildVitalSignChip(
                  Icons.monitor_heart,
                  '${record.heartRate ?? '-'}',
                  'bpm',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${isFilipino ? "Risk Score" : "Risk Score"}: ${record.finalRiskScore}/25',
              style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.gentleGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignChip(IconData icon, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ColorConstant.softWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorConstant.trustBlue),
          const SizedBox(width: 6),
          Text(
            value,
            style: JHTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConstant.bluedark,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: JHTextStyles.caption.copyWith(color: ColorConstant.gentleGray),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(bool isFilipino) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.whiteBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() {
                      _currentPage--;
                      _applyFilters();
                    })
                : null,
            color: _currentPage > 0 ? ColorConstant.trustBlue : ColorConstant.gentleGray,
          ),

          // Page indicator
          Text(
            isFilipino
                ? 'Pahina ${_currentPage + 1} ng $_totalPages'
                : 'Page ${_currentPage + 1} of $_totalPages',
            style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.gentleGray),
          ),

          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() {
                      _currentPage++;
                      _applyFilters();
                    })
                : null,
            color: _currentPage < _totalPages - 1
                ? ColorConstant.trustBlue
                : ColorConstant.gentleGray,
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String category) {
    switch (category.toLowerCase()) {
      case 'very-low':
        return JHColors.successLight;
      case 'low':
        return JHColors.success;
      case 'moderate':
        return JHColors.warning;
      case 'high':
        return JHColors.dangerLight;
      case 'very-high':
        return JHColors.danger;
      default:
        return ColorConstant.gentleGray;
    }
  }

  Future<void> _exportPDF() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.trustBlue),
              const SizedBox(height: 16),
              Text(
                isFilipino ? 'Ginagawa ang PDF...' : 'Generating PDF...',
                style: JHTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Get analytics data
      final trendStats = await AnalyticsService.getRiskTrendStats();
      final vitalTrends = await AnalyticsService.getVitalSignsTrends();
      final insights = await AnalyticsService.generateHealthInsights();
      final categoryDistribution = await AnalyticsService.getRiskCategoryDistribution();

      await AnalyticsPDFService.generateAndShareHealthReport(
        history: _filteredHistory,
        trendStats: trendStats,
        vitalTrends: vitalTrends,
        insights: insights,
        categoryDistribution: categoryDistribution,
        language: isFilipino ? 'fil' : 'en',
      );

      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Tagumpay!' : 'Success!',
        isFilipino
            ? 'PDF report ay na-generate na!'
            : 'PDF report generated successfully!',
        backgroundColor: JHColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino ? 'Hindi ma-generate ang PDF: $e' : 'Failed to generate PDF: $e',
        backgroundColor: JHColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _exportCSV() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.trustBlue),
              const SizedBox(height: 16),
              Text(
                isFilipino ? 'Ginagawa ang CSV...' : 'Generating CSV...',
                style: JHTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await AnalyticsCSVService.exportAndShareAssessmentHistory(
        history: _filteredHistory,
        language: isFilipino ? 'fil' : 'en',
      );

      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Tagumpay!' : 'Success!',
        isFilipino
            ? 'CSV file ay na-export na!'
            : 'CSV file exported successfully!',
        backgroundColor: JHColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino ? 'Hindi ma-export ang CSV: $e' : 'Failed to export CSV: $e',
        backgroundColor: JHColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
