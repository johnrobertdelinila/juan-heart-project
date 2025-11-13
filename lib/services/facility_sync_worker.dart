/// Facility Sync Worker
///
/// Handles automatic background synchronization of facility data
/// Implements periodic sync (daily at 3 AM local time)
///
/// Features:
/// - Daily automatic sync at 3 AM local time
/// - Manual sync trigger via syncNow()
/// - Sync status tracking
/// - Error handling and retry logic
/// - Background execution support (via workmanager package)
///
/// Integration:
/// 1. Initialize in main.dart: FacilitySyncWorker.initialize()
/// 2. Enable daily sync: FacilitySyncWorker.enableDailySync()
/// 3. Manual sync: FacilitySyncWorker.instance.syncNow()

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/facility_service.dart';

enum FacilitySyncStatus {
  idle, // Not syncing
  syncing, // Sync in progress
  success, // Last sync successful
  failed, // Last sync failed
}

class FacilitySyncWorker {
  // Singleton pattern
  static FacilitySyncWorker? _instance;
  static FacilitySyncWorker get instance {
    _instance ??= FacilitySyncWorker._();
    return _instance!;
  }

  FacilitySyncWorker._();

  // State
  FacilitySyncStatus _status = FacilitySyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  Timer? _dailySyncTimer;

  // Configuration
  static const String _lastSyncKey = 'last_facility_sync';
  static const String _lastSyncErrorKey = 'last_facility_sync_error';
  static const Duration _dailySyncInterval = Duration(hours: 24);

  /// Initialize the sync worker
  ///
  /// Loads last sync state from SharedPreferences
  /// Call this in main.dart before runApp()
  static Future<void> initialize() async {
    final worker = FacilitySyncWorker.instance;
    await worker._loadSyncState();
    debugPrint('[FacilitySyncWorker] Initialized');
  }

  /// Enable daily sync at 3 AM local time
  ///
  /// Calculates time until next 3 AM and schedules sync
  /// Reschedules after each sync for continuous daily operation
  void enableDailySync() {
    _cancelDailySync();

    final now = DateTime.now();
    var next3AM = DateTime(now.year, now.month, now.day, 3, 0, 0);

    // If it's already past 3 AM today, schedule for tomorrow
    if (now.isAfter(next3AM)) {
      next3AM = next3AM.add(const Duration(days: 1));
    }

    final timeUntilSync = next3AM.difference(now);

    debugPrint('[FacilitySyncWorker] Daily sync enabled. '
        'Next sync at: $next3AM (in ${timeUntilSync.inHours}h ${timeUntilSync.inMinutes % 60}m)');

    // Schedule first sync
    _dailySyncTimer = Timer(timeUntilSync, () {
      _performDailySync();
    });
  }

  /// Disable daily sync
  void disableDailySync() {
    _cancelDailySync();
    debugPrint('[FacilitySyncWorker] Daily sync disabled');
  }

  /// Cancel existing daily sync timer
  void _cancelDailySync() {
    _dailySyncTimer?.cancel();
    _dailySyncTimer = null;
  }

  /// Perform daily sync and reschedule for next day
  Future<void> _performDailySync() async {
    debugPrint('[FacilitySyncWorker] Executing scheduled daily sync');

    try {
      await syncNow();

      // Reschedule for next day at 3 AM
      _dailySyncTimer = Timer(_dailySyncInterval, () {
        _performDailySync();
      });

      debugPrint('[FacilitySyncWorker] Next sync scheduled in 24 hours');
    } catch (e) {
      debugPrint('[FacilitySyncWorker] Daily sync failed: $e');

      // Retry in 1 hour if sync fails
      _dailySyncTimer = Timer(const Duration(hours: 1), () {
        _performDailySync();
      });

      debugPrint('[FacilitySyncWorker] Retry scheduled in 1 hour');
    }
  }

  /// Manual sync trigger
  ///
  /// Forces immediate sync regardless of last sync time
  /// Updates sync status and persists state
  ///
  /// Returns number of facilities synced
  /// Throws exception on error
  Future<int> syncNow() async {
    if (_status == FacilitySyncStatus.syncing) {
      debugPrint('[FacilitySyncWorker] Sync already in progress');
      return 0;
    }

    _setStatus(FacilitySyncStatus.syncing);

    try {
      debugPrint('[FacilitySyncWorker] Starting manual sync');

      // Perform sync via FacilityService
      final facilitiesCount = await FacilityService.instance.syncFacilities();

      // Update state
      _lastSyncTime = DateTime.now();
      _lastSyncError = null;
      _setStatus(FacilitySyncStatus.success);

      // Persist state
      await _saveSyncState();

      debugPrint('[FacilitySyncWorker] Sync complete: $facilitiesCount facilities');
      return facilitiesCount;
    } catch (e) {
      _lastSyncError = e.toString();
      _setStatus(FacilitySyncStatus.failed);
      await _saveSyncState();

      debugPrint('[FacilitySyncWorker] Sync failed: $e');
      rethrow;
    }
  }

  /// Get current sync status
  FacilitySyncStatus get status => _status;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get last sync error message
  String? get lastSyncError => _lastSyncError;

  /// Check if sync is needed (>24 hours since last sync)
  bool get syncNeeded {
    if (_lastSyncTime == null) return true;
    final hoursSinceSync = DateTime.now().difference(_lastSyncTime!).inHours;
    return hoursSinceSync >= 24;
  }

  /// Get human-readable status message
  String get statusMessage {
    switch (_status) {
      case FacilitySyncStatus.idle:
        if (_lastSyncTime == null) {
          return 'Not synced yet';
        } else {
          return 'Last synced: ${_formatLastSyncTime()}';
        }
      case FacilitySyncStatus.syncing:
        return 'Syncing facilities...';
      case FacilitySyncStatus.success:
        return 'Synced successfully at ${_formatLastSyncTime()}';
      case FacilitySyncStatus.failed:
        return 'Sync failed: ${_lastSyncError ?? "Unknown error"}';
    }
  }

  /// Format last sync time for display
  String _formatLastSyncTime() {
    if (_lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${_lastSyncTime!.month}/${_lastSyncTime!.day}/${_lastSyncTime!.year}';
    }
  }

  /// Set sync status and notify listeners (future: add stream controller)
  void _setStatus(FacilitySyncStatus status) {
    _status = status;
    // TODO: Notify UI via StreamController if needed
  }

  /// Load sync state from SharedPreferences
  Future<void> _loadSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      }

      _lastSyncError = prefs.getString(_lastSyncErrorKey);

      // Set status based on loaded state
      if (_lastSyncError != null) {
        _status = FacilitySyncStatus.failed;
      } else if (_lastSyncTime != null) {
        _status = FacilitySyncStatus.success;
      } else {
        _status = FacilitySyncStatus.idle;
      }

      debugPrint('[FacilitySyncWorker] Loaded sync state: '
          'lastSync=$_lastSyncTime, status=$_status');
    } catch (e) {
      debugPrint('[FacilitySyncWorker] Error loading sync state: $e');
    }
  }

  /// Save sync state to SharedPreferences
  Future<void> _saveSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_lastSyncTime != null) {
        await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
      }

      if (_lastSyncError != null) {
        await prefs.setString(_lastSyncErrorKey, _lastSyncError!);
      } else {
        await prefs.remove(_lastSyncErrorKey);
      }

      debugPrint('[FacilitySyncWorker] Saved sync state');
    } catch (e) {
      debugPrint('[FacilitySyncWorker] Error saving sync state: $e');
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'status': _status.toString(),
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastSyncError': _lastSyncError,
      'syncNeeded': syncNeeded,
      'hoursSinceSync': _lastSyncTime != null
          ? DateTime.now().difference(_lastSyncTime!).inHours
          : null,
    };
  }
}
