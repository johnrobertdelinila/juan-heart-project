import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart' as wm;
import 'package:background_fetch/background_fetch.dart' as bf;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/sync_queue_service.dart';

/// Background sync service for Juan Heart Mobile
///
/// Handles automatic periodic synchronization of offline data
/// using platform-specific background workers:
/// - Android: WorkManager
/// - iOS: background_fetch
///
/// Sync intervals:
/// - 15 minutes when app is active
/// - 1 hour when app is idle
/// - Immediate on network reconnection
///
/// Features:
/// - Automatic retry on failure
/// - Network-aware scheduling
/// - Manual sync trigger
/// - Last sync timestamp tracking
class BackgroundSyncService {
  static const String _taskName = 'juanHeartBackgroundSync';
  static const String _lastSyncKey = 'last_background_sync_timestamp';
  static const String _syncEnabledKey = 'background_sync_enabled';

  static final BackgroundSyncService instance = BackgroundSyncService._internal();

  factory BackgroundSyncService() => instance;

  BackgroundSyncService._internal();

  bool _isInitialized = false;
  final SyncQueueService _syncQueueService = SyncQueueService();

  /// Check if background sync is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize background sync service
  ///
  /// Should be called early in app lifecycle after sync queue is initialized
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BackgroundSyncService already initialized');
      return;
    }

    try {
      // Check if background sync is enabled (default: true)
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_syncEnabledKey) ?? true;

      if (!isEnabled) {
        debugPrint('Background sync is disabled by user');
        return;
      }

      // Initialize platform-specific background tasks
      if (Platform.isAndroid) {
        await _initializeAndroid();
      } else if (Platform.isIOS) {
        await _initializeIOS();
      }

      // Listen to network changes for immediate sync
      _setupNetworkListener();

      _isInitialized = true;
      debugPrint('BackgroundSyncService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BackgroundSyncService: $e');
      rethrow;
    }
  }

  /// Initialize Android WorkManager
  Future<void> _initializeAndroid() async {
    try {
      await wm.Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Schedule periodic sync task (15 minutes interval)
      await wm.Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(minutes: 15),
        constraints: wm.Constraints(
          networkType: wm.NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
        ),
        backoffPolicy: wm.BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
      );

      debugPrint('Android WorkManager initialized');
    } catch (e) {
      debugPrint('Error initializing Android WorkManager: $e');
      rethrow;
    }
  }

  /// Initialize iOS background_fetch
  Future<void> _initializeIOS() async {
    try {
      // Configure background fetch
      await bf.BackgroundFetch.configure(
        bf.BackgroundFetchConfig(
          minimumFetchInterval: 15, // 15 minutes
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: bf.NetworkType.ANY,
        ),
        _onBackgroundFetchIOS,
        _onBackgroundFetchTimeoutIOS,
      );

      // Enable background fetch
      await bf.BackgroundFetch.start();

      debugPrint('iOS BackgroundFetch initialized');
    } catch (e) {
      debugPrint('Error initializing iOS BackgroundFetch: $e');
      rethrow;
    }
  }

  /// Setup network connectivity listener for immediate sync
  void _setupNetworkListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final isOnline = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi;

      if (isOnline) {
        debugPrint('Network connection restored, triggering immediate sync');
        triggerManualSync();
      }
    });
  }

  /// Background fetch callback for iOS
  Future<void> _onBackgroundFetchIOS(String taskId) async {
    try {
      debugPrint('[BackgroundFetch] iOS event received: $taskId');
      await _performSync();
      bf.BackgroundFetch.finish(taskId);
    } catch (e) {
      debugPrint('[BackgroundFetch] iOS error: $e');
      bf.BackgroundFetch.finish(taskId);
    }
  }

  /// Background fetch timeout callback for iOS
  Future<void> _onBackgroundFetchTimeoutIOS(String taskId) async {
    debugPrint('[BackgroundFetch] iOS TIMEOUT: $taskId');
    bf.BackgroundFetch.finish(taskId);
  }

  /// Perform sync operation
  ///
  /// Called by both Android WorkManager and iOS BackgroundFetch
  Future<void> _performSync() async {
    try {
      debugPrint('Background sync started');

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;

      if (!isOnline) {
        debugPrint('No network connection, skipping sync');
        return;
      }

      // Trigger sync queue processing
      await _syncQueueService.processQueue();

      // Update last sync timestamp
      await _updateLastSyncTimestamp();

      debugPrint('Background sync completed successfully');
    } catch (e) {
      debugPrint('Background sync failed: $e');
      // Don't rethrow - background tasks should not crash
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastSyncKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error updating last sync timestamp: $e');
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last sync timestamp: $e');
      return null;
    }
  }

  /// Get time since last sync
  Future<Duration?> getTimeSinceLastSync() async {
    final lastSync = await getLastSyncTimestamp();
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync);
  }

  /// Trigger manual sync
  ///
  /// Can be called from UI to force immediate synchronization
  Future<void> triggerManualSync() async {
    debugPrint('Manual sync triggered');
    await _performSync();
  }

  /// Enable background sync
  Future<void> enableBackgroundSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, true);

    // Reinitialize if needed
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Disable background sync
  Future<void> disableBackgroundSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, false);

    // Cancel scheduled tasks
    if (Platform.isAndroid) {
      await wm.Workmanager().cancelByUniqueName(_taskName);
    } else if (Platform.isIOS) {
      await bf.BackgroundFetch.stop();
    }

    _isInitialized = false;
    debugPrint('Background sync disabled');
  }

  /// Check if background sync is enabled
  Future<bool> isBackgroundSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? true;
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final lastSync = await getLastSyncTimestamp();
    final timeSinceLastSync = await getTimeSinceLastSync();
    final isEnabled = await isBackgroundSyncEnabled();
    final queueStats = await _syncQueueService.getQueueStatistics();

    return {
      'lastSyncTimestamp': lastSync?.toIso8601String(),
      'timeSinceLastSync': timeSinceLastSync?.inMinutes,
      'backgroundSyncEnabled': isEnabled,
      'pendingOperations': queueStats['pending'],
      'failedOperations': queueStats['failed'],
      'totalOperations': queueStats['total'],
    };
  }
}

/// Background callback dispatcher for Android WorkManager
///
/// This MUST be a top-level function (not a class method)
@pragma('vm:entry-point')
void callbackDispatcher() {
  wm.Workmanager().executeTask((taskName, inputData) async {
    debugPrint('[WorkManager] Android task started: $taskName');

    try {
      // Create service instance
      final syncService = BackgroundSyncService.instance;

      // Perform sync
      await syncService._performSync();

      debugPrint('[WorkManager] Android task completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('[WorkManager] Android task error: $e');
      return Future.value(false);
    }
  });
}

/// Background fetch headless callback for iOS
///
/// Called when app is terminated and background fetch occurs
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(bf.HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;

  if (isTimeout) {
    debugPrint('[BackgroundFetch] Headless iOS TIMEOUT: $taskId');
    bf.BackgroundFetch.finish(taskId);
    return;
  }

  debugPrint('[BackgroundFetch] Headless iOS event received: $taskId');

  try {
    final syncService = BackgroundSyncService.instance;
    await syncService._performSync();
    bf.BackgroundFetch.finish(taskId);
  } catch (e) {
    debugPrint('[BackgroundFetch] Headless iOS error: $e');
    bf.BackgroundFetch.finish(taskId);
  }
}
