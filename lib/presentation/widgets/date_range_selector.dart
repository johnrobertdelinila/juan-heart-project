import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:intl/intl.dart';

/// Date Range Selector Widget
///
/// Provides quick date range selection for analytics charts
/// Options: Last 7 days, Last 30 days, Last 90 days, Last Year, Custom Range, All Time
/// Used in analytics_screen.dart to filter chart data

class DateRangeSelector extends StatelessWidget {
  final DateRangeOption selectedRange;
  final Function(DateRangeOption) onRangeSelected;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const DateRangeSelector({
    Key? key,
    required this.selectedRange,
    required this.onRangeSelected,
    this.customStartDate,
    this.customEndDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Select Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(DateRangeOption.last7Days, context),
                const SizedBox(width: 8),
                _buildChip(DateRangeOption.last30Days, context),
                const SizedBox(width: 8),
                _buildChip(DateRangeOption.last90Days, context),
                const SizedBox(width: 8),
                _buildChip(DateRangeOption.lastYear, context),
                const SizedBox(width: 8),
                _buildChip(DateRangeOption.custom, context),
                const SizedBox(width: 8),
                _buildChip(DateRangeOption.allTime, context),
              ],
            ),
          ),

          // Custom Date Range Display
          if (selectedRange == DateRangeOption.custom &&
              customStartDate != null &&
              customEndDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.lightBlueBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorConstant.trustBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: ColorConstant.trustBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat.yMMMd().format(customStartDate!)} - ${DateFormat.yMMMd().format(customEndDate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorConstant.trustBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(DateRangeOption option, BuildContext context) {
    final isSelected = selectedRange == option;

    return GestureDetector(
      onTap: () async {
        if (option == DateRangeOption.custom) {
          // Show custom date picker dialog
          final result = await _showCustomDatePicker(context);
          if (result != null) {
            onRangeSelected(option);
          }
        } else {
          onRangeSelected(option);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.trustBlue
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorConstant.trustBlue
                : ColorConstant.cardBorder,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorConstant.trustBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option == DateRangeOption.custom)
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isSelected ? Colors.white : ColorConstant.gentleGray,
              ),
            if (option == DateRangeOption.custom) const SizedBox(width: 6),
            Text(
              _getOptionLabel(option),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : ColorConstant.gentleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOptionLabel(DateRangeOption option) {
    final language = Get.locale?.languageCode ?? 'en';

    switch (option) {
      case DateRangeOption.last7Days:
        return language == 'fil' ? '7 Araw' : '7 Days';
      case DateRangeOption.last30Days:
        return language == 'fil' ? '30 Araw' : '30 Days';
      case DateRangeOption.last90Days:
        return language == 'fil' ? '90 Araw' : '90 Days';
      case DateRangeOption.lastYear:
        return language == 'fil' ? '1 Taon' : '1 Year';
      case DateRangeOption.custom:
        return language == 'fil' ? 'Custom' : 'Custom';
      case DateRangeOption.allTime:
        return language == 'fil' ? 'Lahat' : 'All Time';
    }
  }

  Future<DateTimeRange?> _showCustomDatePicker(BuildContext context) async {
    final language = Get.locale?.languageCode ?? 'en';

    return await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstant.trustBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
      helpText: language == 'fil' ? 'Pumili ng Date Range' : 'Select Date Range',
      cancelText: language == 'fil' ? 'Kanselahin' : 'Cancel',
      confirmText: language == 'fil' ? 'OK' : 'OK',
      saveText: language == 'fil' ? 'I-save' : 'Save',
    );
  }
}

/// Date Range Options
enum DateRangeOption {
  last7Days,
  last30Days,
  last90Days,
  lastYear,
  custom,
  allTime,
}

/// Extension to get date range from option
extension DateRangeExtension on DateRangeOption {
  DateTimeRange getDateRange({DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (this) {
      case DateRangeOption.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today,
        );
      case DateRangeOption.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
        );
      case DateRangeOption.last90Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 90)),
          end: today,
        );
      case DateRangeOption.lastYear:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 365)),
          end: today,
        );
      case DateRangeOption.custom:
        if (customStart != null && customEnd != null) {
          return DateTimeRange(start: customStart, end: customEnd);
        }
        // Fallback to last 30 days if custom dates not set
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
        );
      case DateRangeOption.allTime:
        return DateTimeRange(
          start: DateTime(2020), // App start date
          end: today,
        );
    }
  }

  String getLabel() {
    final language = Get.locale?.languageCode ?? 'en';

    switch (this) {
      case DateRangeOption.last7Days:
        return language == 'fil' ? 'Huling 7 Araw' : 'Last 7 Days';
      case DateRangeOption.last30Days:
        return language == 'fil' ? 'Huling 30 Araw' : 'Last 30 Days';
      case DateRangeOption.last90Days:
        return language == 'fil' ? 'Huling 90 Araw' : 'Last 90 Days';
      case DateRangeOption.lastYear:
        return language == 'fil' ? 'Huling Taon' : 'Last Year';
      case DateRangeOption.custom:
        return language == 'fil' ? 'Custom na Date Range' : 'Custom Date Range';
      case DateRangeOption.allTime:
        return language == 'fil' ? 'Lahat ng Oras' : 'All Time';
    }
  }
}

/// Helper class for date range filtering
class DateRangeFilter {
  final DateRangeOption option;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  DateRangeFilter({
    required this.option,
    this.customStartDate,
    this.customEndDate,
  });

  /// Get the actual date range
  DateTimeRange getDateRange() {
    return option.getDateRange(
      customStart: customStartDate,
      customEnd: customEndDate,
    );
  }

  /// Check if a date is within the selected range
  bool isDateInRange(DateTime date) {
    final range = getDateRange();
    return date.isAfter(range.start) && date.isBefore(range.end);
  }

  /// Filter a list of dates
  List<DateTime> filterDates(List<DateTime> dates) {
    return dates.where((date) => isDateInRange(date)).toList();
  }

  /// Get range description for display
  String getRangeDescription() {
    final range = getDateRange();
    return '${DateFormat.yMMMd().format(range.start)} - ${DateFormat.yMMMd().format(range.end)}';
  }
}
