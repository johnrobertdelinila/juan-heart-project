import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:juan_heart/themes/jh_colors.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_spacing.dart';
import 'package:intl/intl.dart';

/// Sync status enumeration
enum SyncStatus {
  synced,
  pending,
  failed,
}

/// Widget that displays sync status with count of failed operations.
///
/// Shows a small badge indicating the number of failed sync operations.
/// Tappable - navigates to Analytics/Appointments screen where user can retry.
class SyncStatusBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const SyncStatusBadge({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final failedCount = SyncQueueService().getFailedCount();

    // Don't show if no failed syncs
    if (failedCount == 0) {
      return const SizedBox.shrink();
    }

    final isFilipino = Get.locale?.languageCode == 'fil';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: JHColors.dangerLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: JHColors.danger, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_problem,
              size: 16,
              color: JHColors.dangerDark,
              semanticLabel: 'Sync failed',
            ),
            const SizedBox(width: 6),
            Text(
              '$failedCount ${isFilipino ? "nabigo" : "failed"}',
              style: JHTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: JHColors.dangerDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: JHColors.dangerDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Detailed sync status widget for analytics screen
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final int count;
  final DateTime? lastSyncTime;
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    required this.count,
    this.lastSyncTime,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadge();
    }
    return _buildFullBadge();
  }

  Widget _buildCompactBadge() {
    if (status == SyncStatus.synced) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getColor(),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIcon(),
        size: 16,
        color: JHColors.cloudWhite,
        semanticLabel: _getSemanticLabel(),
      ),
    );
  }

  Widget _buildFullBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: JHSpacing.md,
        vertical: JHSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 20,
            color: _getColor(),
            semanticLabel: _getSemanticLabel(),
          ),
          const SizedBox(width: JHSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: JHTextStyles.bodyBase.copyWith(
                    color: _getColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastSyncTime != null && status == SyncStatus.synced)
                  Text(
                    'Last synced: ${_formatLastSyncTime()}',
                    style: JHTextStyles.caption.copyWith(
                      color: JHColors.slate500,
                    ),
                  ),
                if (status != SyncStatus.synced)
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: JHTextStyles.caption.copyWith(
                      color: JHColors.slate500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.pending:
        return Icons.cloud_upload;
      case SyncStatus.failed:
        return Icons.sync_problem;
    }
  }

  Color _getColor() {
    switch (status) {
      case SyncStatus.synced:
        return JHColors.success;
      case SyncStatus.pending:
        return JHColors.warning;
      case SyncStatus.failed:
        return JHColors.danger;
    }
  }

  String _getStatusText() {
    switch (status) {
      case SyncStatus.synced:
        return 'All synced';
      case SyncStatus.pending:
        return 'Sync pending';
      case SyncStatus.failed:
        return 'Sync failed';
    }
  }

  String _getSemanticLabel() {
    switch (status) {
      case SyncStatus.synced:
        return 'All data synced to cloud';
      case SyncStatus.pending:
        return '$count items pending sync to cloud';
      case SyncStatus.failed:
        return '$count items failed to sync to cloud';
    }
  }

  String _formatLastSyncTime() {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, y').format(lastSyncTime!);
    }
  }
}

/// Sync status summary widget for analytics screen header
class SyncStatusSummary extends StatelessWidget {
  final int totalAssessments;
  final int syncedCount;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncTime;
  final VoidCallback? onRetryFailed;

  const SyncStatusSummary({
    super.key,
    required this.totalAssessments,
    required this.syncedCount,
    required this.pendingCount,
    required this.failedCount,
    this.lastSyncTime,
    this.onRetryFailed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(JHSpacing.md),
      decoration: BoxDecoration(
        color: JHColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: JHColors.slate200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_sync,
                size: 20,
                color: JHColors.slate700,
              ),
              const SizedBox(width: JHSpacing.sm),
              Text(
                'Sync Status',
                style: JHTextStyles.bodyBase.copyWith(
                  fontWeight: FontWeight.w600,
                  color: JHColors.slate700,
                ),
              ),
            ],
          ),
          const SizedBox(height: JHSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.cloud_done,
                  label: 'Synced',
                  count: syncedCount,
                  color: JHColors.success,
                ),
              ),
              const SizedBox(width: JHSpacing.sm),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.cloud_upload,
                  label: 'Pending',
                  count: pendingCount,
                  color: JHColors.warning,
                ),
              ),
              const SizedBox(width: JHSpacing.sm),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.sync_problem,
                  label: 'Failed',
                  count: failedCount,
                  color: JHColors.danger,
                ),
              ),
            ],
          ),
          if (lastSyncTime != null) ...[
            const SizedBox(height: JHSpacing.sm),
            Text(
              'Last synced: ${_formatLastSyncTime(lastSyncTime!)}',
              style: JHTextStyles.caption.copyWith(
                color: JHColors.slate500,
              ),
            ),
          ],
          if (failedCount > 0 && onRetryFailed != null) ...[
            const SizedBox(height: JHSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetryFailed,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Failed Syncs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JHColors.danger,
                  side: BorderSide(color: JHColors.danger),
                  padding: const EdgeInsets.symmetric(
                    vertical: JHSpacing.sm,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
          semanticLabel: '$label: $count',
        ),
        const SizedBox(height: JHSpacing.xs),
        Text(
          count.toString(),
          style: JHTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: JHTextStyles.caption.copyWith(
            color: JHColors.slate600,
          ),
        ),
      ],
    );
  }

  String _formatLastSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }
}
