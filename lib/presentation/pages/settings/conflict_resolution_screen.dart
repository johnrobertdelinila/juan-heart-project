import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/services/conflict_resolver.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Conflict Resolution Screen
///
/// Allows users to manually resolve data synchronization conflicts
/// by choosing between local and server versions.
///
/// Features:
/// - List of conflicts requiring manual review
/// - Side-by-side comparison of local vs server data
/// - Resolution buttons (Keep Local / Keep Server)
/// - Empty state when no conflicts exist
/// - Bilingual support (English/Filipino)
class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  List<ConflictItem> _conflicts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    setState(() => _isLoading = true);

    try {
      final conflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      setState(() {
        _conflicts = conflicts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading conflicts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveConflict({
    required ConflictItem conflict,
    required ManualResolutionChoice choice,
  }) async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Apply resolution
      await ConflictResolver.instance.applyManualResolution(
        conflictId: conflict.id,
        choice: choice,
      );

      Get.back(); // Close loading dialog

      // Show success snackbar
      Get.snackbar(
        isFilipino ? 'Tapos Na!' : 'Resolved!',
        isFilipino
            ? 'Ang salungatan ay matagumpay na nalutas.'
            : 'Conflict has been successfully resolved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstant.reassuringGreen,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );

      // Refresh list
      await _loadConflicts();
    } catch (e) {
      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Hindi malutas ang salungatan. Subukan ulit.'
            : 'Failed to resolve conflict. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFilipino ? 'Ayusin ang Salungatan' : 'Resolve Conflicts',
              style: JHTextStyles.h4.copyWith(
                color: ColorConstant.bluedark,
              ),
            ),
            if (_conflicts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColorConstant.warningColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_conflicts.length}',
                  style: JHTextStyles.label.copyWith(
                    color: ColorConstant.bluedark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? _buildEmptyState(isFilipino)
              : _buildConflictList(isFilipino),
    );
  }

  Widget _buildEmptyState(bool isFilipino) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: ColorConstant.reassuringGreen,
            ),
            const SizedBox(height: 24),
            Text(
              isFilipino ? 'Walang Salungatan' : 'No Conflicts to Resolve',
              style: JHTextStyles.h4.copyWith(
                color: ColorConstant.bluedark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isFilipino
                  ? 'Lahat ng data ay nakaayos na. Magandang trabaho!'
                  : 'All your data is in sync. Great job!',
              style: JHTextStyles.bodySmall.copyWith(
                color: ColorConstant.gentleGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictList(bool isFilipino) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conflicts.length,
      itemBuilder: (context, index) {
        final conflict = _conflicts[index];
        return _buildConflictCard(conflict, isFilipino);
      },
    );
  }

  Widget _buildConflictCard(ConflictItem conflict, bool isFilipino) {
    final differences = conflict.getDifferences();
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                conflict.getIcon(),
                color: ColorConstant.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEntityTypeName(conflict.entityType, isFilipino),
                      style: JHTextStyles.bodyBase.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.bluedark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFilipino
                          ? 'Nadetect: ${dateFormat.format(conflict.timestamp)}'
                          : 'Detected: ${dateFormat.format(conflict.timestamp)}',
                      style: JHTextStyles.caption.copyWith(
                        color: ColorConstant.gentleGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (conflict.reason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ColorConstant.warningColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conflict.reason!,
                      style: JHTextStyles.caption.copyWith(
                        color: ColorConstant.bluedark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Comparison section
          Text(
            isFilipino ? 'Paghahambing ng Bersyon' : 'Version Comparison',
            style: JHTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConstant.bluedark,
            ),
          ),
          const SizedBox(height: 12),

          // Local version
          _buildVersionCard(
            title: isFilipino ? 'Lokal na Bersyon' : 'Local Version',
            accentColor: ColorConstant.trustBlue,
            data: conflict.localData,
            timestamp: conflict.localData['updatedAt'],
            differences: differences,
            isLocal: true,
          ),
          const SizedBox(height: 12),

          // Server version
          _buildVersionCard(
            title: isFilipino ? 'Server na Bersyon' : 'Server Version',
            accentColor: ColorConstant.reassuringGreen,
            data: conflict.serverData,
            timestamp: conflict.serverData['updatedAt'],
            differences: differences,
            isLocal: false,
          ),

          const SizedBox(height: 16),

          // Resolution buttons
          Row(
            children: [
              Expanded(
                child: StandardButton.secondary(
                  text: isFilipino ? 'Gamitin ang Lokal' : 'Keep Local',
                  onPressed: () => _resolveConflict(
                    conflict: conflict,
                    choice: ManualResolutionChoice.keepLocal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StandardButton.primary(
                  text: isFilipino ? 'Gamitin ang Server' : 'Keep Server',
                  onPressed: () => _resolveConflict(
                    conflict: conflict,
                    choice: ManualResolutionChoice.keepServer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard({
    required String title,
    required Color accentColor,
    required Map<String, dynamic> data,
    required dynamic timestamp,
    required List<ConflictDifference> differences,
    required bool isLocal,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    DateTime? parsedTimestamp;

    try {
      if (timestamp is String) {
        parsedTimestamp = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        parsedTimestamp = timestamp;
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return AccentCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLocal ? Icons.phone_android : Icons.cloud,
                color: accentColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: JHTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          if (parsedTimestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              dateFormat.format(parsedTimestamp),
              style: JHTextStyles.caption.copyWith(
                color: ColorConstant.gentleGray,
              ),
            ),
          ],
          if (differences.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...differences.map((diff) {
              final value = isLocal ? diff.localValue : diff.serverValue;
              final isDifferent = diff.localValue != diff.serverValue;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDifferent)
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: accentColor,
                      ),
                    if (isDifferent) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatFieldName(diff.field),
                            style: JHTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.gentleGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: JHTextStyles.caption.copyWith(
                              color: ColorConstant.bluedark,
                              fontWeight: isDifferent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  String _getEntityTypeName(String entityType, bool isFilipino) {
    switch (entityType) {
      case 'user_profile':
        return isFilipino ? 'Profile ng Gumagamit' : 'User Profile';
      case 'facility':
        return isFilipino ? 'Pasilidad' : 'Facility';
      case 'assessment':
        return isFilipino ? 'Pagsusuri' : 'Assessment';
      case 'appointment':
        return isFilipino ? 'Appointment' : 'Appointment';
      default:
        return entityType;
    }
  }

  String _formatFieldName(String field) {
    // Convert camelCase to Title Case
    final result = field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}
