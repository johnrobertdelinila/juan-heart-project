/// Educational Content Sync Worker
///
/// Handles automatic synchronization of educational content with backend
/// Implements weekly sync schedule and manual sync triggers
///
/// Features:
/// - Weekly automatic sync (configurable schedule: Sunday 2 AM default)
/// - Manual sync trigger for on-demand updates
/// - Sync status tracking (idle, syncing, success, error)
/// - Last sync timestamp persistence
/// - Configurable sync intervals

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/educational_content_service.dart';

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync result model
class SyncResult {
  final SyncStatus status;
  final int itemsSynced;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.status,
    required this.itemsSynced,
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SyncResult(status: $status, itemsSynced: $itemsSynced, '
        'timestamp: $timestamp, error: $errorMessage)';
  }
}

/// Educational Content Sync Worker
///
/// Manages automatic and manual synchronization of educational content
class EducationalContentSyncWorker {
  static final EducationalContentSyncWorker _instance =
      EducationalContentSyncWorker._internal();

  static EducationalContentSyncWorker get instance => _instance;

  EducationalContentSyncWorker._internal();

  Timer? _syncTimer;
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSync;
  SyncResult? _lastSyncResult;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();

  final EducationalContentService _contentService =
      EducationalContentService.instance;

  /// Get current sync status
  SyncStatus get status => _status;

  /// Get last sync timestamp
  DateTime? get lastSync => _lastSync;

  /// Get last sync result
  SyncResult? get lastSyncResult => _lastSyncResult;

  /// Stream of sync status changes
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Stream of sync results
  Stream<SyncResult> get resultStream => _resultController.stream;

  /// Check if sync is enabled
  bool get isSyncEnabled => _syncTimer != null && _syncTimer!.isActive;

  /// Initialize sync worker
  ///
  /// Loads last sync timestamp and optionally starts weekly sync schedule
  /// [enableWeeklySync] - Start weekly sync timer (default: true)
  Future<void> initialize({bool enableWeeklySync = true}) async {
    try {
      _lastSync = await _getLastSyncTimestamp();
      debugPrint('EducationalContentSyncWorker initialized (lastSync: $_lastSync)');

      if (enableWeeklySync) {
        _scheduleWeeklySync();
      }
    } catch (e) {
      debugPrint('Error initializing sync worker: $e');
    }
  }

  /// Manual sync trigger
  ///
  /// Performs immediate content synchronization
  /// Returns number of items synced or throws exception on error
  Future<int> syncNow() async {
    if (_status == SyncStatus.syncing) {
      debugPrint('Sync already in progress, skipping');
      return 0;
    }

    try {
      _updateStatus(SyncStatus.syncing);
      debugPrint('Starting manual content sync...');

      final itemsSynced = await _contentService.syncFromBackend();

      _lastSync = DateTime.now();
      await _setLastSyncTimestamp(_lastSync!);

      final result = SyncResult(
        status: SyncStatus.success,
        itemsSynced: itemsSynced,
        timestamp: _lastSync!,
      );

      _lastSyncResult = result;
      _resultController.add(result);
      _updateStatus(SyncStatus.success);

      debugPrint('Manual sync complete: $itemsSynced items synced');
      return itemsSynced;
    } catch (e) {
      debugPrint('Sync failed: $e');

      final result = SyncResult(
        status: SyncStatus.error,
        itemsSynced: 0,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );

      _lastSyncResult = result;
      _resultController.add(result);
      _updateStatus(SyncStatus.error);

      rethrow;
    }
  }

  /// Enable weekly sync schedule
  ///
  /// Default: Every Sunday at 2 AM
  /// Can be customized with different intervals
  void enableWeeklySync() {
    if (_syncTimer != null && _syncTimer!.isActive) {
      debugPrint('Weekly sync already enabled');
      return;
    }

    _scheduleWeeklySync();
  }

  /// Disable weekly sync schedule
  void disableWeeklySync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Weekly sync disabled');
  }

  /// Schedule weekly sync (every Sunday at 2 AM)
  void _scheduleWeeklySync() {
    // Calculate time until next Sunday 2 AM
    final now = DateTime.now();
    final nextSync = _calculateNextSyncTime(now);
    final duration = nextSync.difference(now);

    debugPrint('Next automatic sync scheduled for: $nextSync '
        '(${duration.inHours} hours from now)');

    // Schedule first sync
    _syncTimer = Timer(duration, () {
      _performScheduledSync();

      // Set up recurring weekly sync
      _syncTimer = Timer.periodic(
        const Duration(days: 7),
        (_) => _performScheduledSync(),
      );
    });
  }

  /// Calculate next sync time (next Sunday at 2 AM)
  DateTime _calculateNextSyncTime(DateTime from) {
    // Sunday = 7
    final daysUntilSunday = (7 - from.weekday) % 7;
    final nextSunday = from.add(Duration(days: daysUntilSunday));

    // Set to 2 AM
    final nextSyncTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      2, // 2 AM
      0,
      0,
    );

    // If calculated time is in the past (e.g., it's Sunday 3 AM),
    // add 7 days to get next Sunday
    if (nextSyncTime.isBefore(from)) {
      return nextSyncTime.add(const Duration(days: 7));
    }

    return nextSyncTime;
  }

  /// Perform scheduled sync
  Future<void> _performScheduledSync() async {
    try {
      debugPrint('Performing scheduled content sync...');
      await syncNow();
      debugPrint('Scheduled sync completed successfully');
    } catch (e) {
      debugPrint('Scheduled sync failed: $e');
      // Don't throw - let it retry on next scheduled time
    }
  }

  /// Update sync status and notify listeners
  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  /// Get last sync timestamp from SharedPreferences
  Future<DateTime?> _getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('educational_content_last_sync');
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last sync timestamp: $e');
      return null;
    }
  }

  /// Set last sync timestamp in SharedPreferences
  Future<void> _setLastSyncTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'educational_content_last_sync',
        timestamp.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error setting last sync timestamp: $e');
    }
  }

  /// Check if sync is needed based on last sync time
  ///
  /// Returns true if last sync was more than [threshold] ago
  /// Default threshold: 7 days
  bool isSyncNeeded({Duration threshold = const Duration(days: 7)}) {
    if (_lastSync == null) {
      return true; // Never synced before
    }

    final timeSinceSync = DateTime.now().difference(_lastSync!);
    return timeSinceSync > threshold;
  }

  /// Get time remaining until next scheduled sync
  Duration? getTimeUntilNextSync() {
    if (_syncTimer == null || !_syncTimer!.isActive) {
      return null;
    }

    final now = DateTime.now();
    final nextSync = _calculateNextSyncTime(now);
    return nextSync.difference(now);
  }

  /// Force reset sync state (for testing)
  Future<void> reset() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _status = SyncStatus.idle;
    _lastSync = null;
    _lastSyncResult = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('educational_content_last_sync');
      debugPrint('Sync worker reset');
    } catch (e) {
      debugPrint('Error resetting sync worker: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _statusController.close();
    _resultController.close();
  }
}
