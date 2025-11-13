import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/conflict_resolver.dart';
import 'package:juan_heart/services/performance_service.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:juan_heart/core/constants/sync_error_types.dart';

/// Represents a sync operation in the queue.
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  DateTime? lastAttemptAt;
  String? lastError;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Increment retry count and update last attempt time.
  void incrementRetry({String? error}) {
    retryCount++;
    lastAttemptAt = DateTime.now();
    lastError = error;
  }

  /// Check if operation has exceeded max retries.
  bool hasExceededMaxRetries() {
    return retryCount >= 3;
  }

  /// Get exponential backoff delay in seconds.
  ///
  /// Uses error-aware backoff based on error type.
  /// Network/timeout errors: Standard exponential backoff (2^retry)
  /// Server errors: Longer backoff (2 * 2^retry)
  /// Authentication/validation errors: No auto-retry (returns high value to prevent retry)
  int getBackoffDelay() {
    if (lastError == null) {
      return pow(2, retryCount).toInt();
    }

    // Classify error for smart backoff
    final errorType = SyncErrorClassifier.fromErrorMessage(lastError!);
    final baseDelay = pow(2, retryCount).toInt();

    // Apply multiplier based on error type
    final multiplier = errorType.backoffMultiplier;
    if (multiplier == 0) {
      // No auto-retry for these errors
      return 3600; // 1 hour delay to effectively prevent auto-retry
    }

    return baseDelay * multiplier;
  }

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  /// Create from JSON.
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Types of sync operations.
enum SyncOperationType {
  syncAppointment,
  updateAppointment,
  cancelAppointment,
  syncAssessment,
}

/// Callback for executing sync operations.
typedef SyncExecutor = Future<Map<String, dynamic>> Function(SyncOperation operation);

/// Callback for fetching server data for conflict detection.
typedef ServerDataFetcher = Future<Map<String, dynamic>?> Function(String entityId);

/// Callback for fetching local data for conflict detection.
typedef LocalDataFetcher = Future<Map<String, dynamic>?> Function(String entityId);

/// Service for managing sync queue with retry logic.
///
/// Provides offline-first sync capability with:
/// - Automatic retry with exponential backoff
/// - Connectivity monitoring
/// - Persistent queue storage
/// - Background processing
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  static const String _queueKey = 'sync_queue';
  static const String _failedQueueKey = 'sync_queue_failed';
  static const String _manualReviewQueueKey = 'conflict_manual_review_queue';

  final Queue<SyncOperation> _queue = Queue();
  final List<SyncOperation> _failedOperations = [];
  final List<Map<String, dynamic>> _manualReviewConflicts = [];
  bool _isProcessing = false;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final Map<SyncOperationType, SyncExecutor> _executors = {};
  final Map<SyncOperationType, ServerDataFetcher> _serverDataFetchers = {};
  final Map<SyncOperationType, LocalDataFetcher> _localDataFetchers = {};

  /// Connectivity provider for testing (defaults to Connectivity())
  Connectivity? _connectivityProvider;

  /// Set connectivity provider (for testing)
  void setConnectivityProvider(Connectivity provider) {
    _connectivityProvider = provider;
  }

  /// Get connectivity provider (defaults to Connectivity())
  Connectivity get _connectivity => _connectivityProvider ?? Connectivity();

  /// Initialize the sync queue service.
  ///
  /// Loads persisted queue and sets up connectivity listener.
  Future<void> initialize() async {
    await _loadPersistedQueue();
    _setupConnectivityListener();
    debugPrint('✅ SyncQueue initialized with ${_queue.length} pending operations');
  }

  /// Register a sync executor for a specific operation type.
  ///
  /// [type] - The type of sync operation.
  /// [executor] - Function that executes the sync operation.
  void registerExecutor(SyncOperationType type, SyncExecutor executor) {
    _executors[type] = executor;
  }

  /// Register data fetchers for conflict detection.
  ///
  /// [type] - The type of sync operation.
  /// [serverFetcher] - Function to fetch server data.
  /// [localFetcher] - Function to fetch local data.
  void registerDataFetchers({
    required SyncOperationType type,
    required ServerDataFetcher serverFetcher,
    required LocalDataFetcher localFetcher,
  }) {
    _serverDataFetchers[type] = serverFetcher;
    _localDataFetchers[type] = localFetcher;
    debugPrint('✅ Data fetchers registered for $type');
  }

  /// Add operation to sync queue.
  ///
  /// [operation] - The sync operation to queue.
  /// Prevents duplicate operations with the same ID from being added.
  Future<void> addOperation(SyncOperation operation) async {
    // 🔧 FIX: Check for duplicate operation ID before adding
    final existingOperation = _queue.cast<SyncOperation?>().firstWhere(
      (op) => op?.id == operation.id,
      orElse: () => null,
    );

    if (existingOperation != null) {
      debugPrint('⚠️ Operation already in queue, skipping: ${operation.id}');
      return;
    }

    _queue.add(operation);
    await _persistQueue();
    debugPrint('📝 Added ${operation.type} to sync queue (ID: ${operation.id})');

    // Start processing if not already running
    _processQueue();
  }

  /// Remove operation from queue.
  /// Uses ID-based comparison to ensure operations are properly removed.
  Future<void> _removeOperation(SyncOperation operation) async {
    // 🔧 FIX: Remove by ID instead of reference equality
    _queue.removeWhere((op) => op.id == operation.id);
    await _persistQueue();
  }

  /// Move operation to failed queue.
  /// Uses ID-based comparison to ensure operations are properly removed.
  Future<void> _moveToFailed(SyncOperation operation) async {
    // 🔧 FIX: Remove by ID instead of reference equality
    _queue.removeWhere((op) => op.id == operation.id);
    _failedOperations.add(operation);
    await _persistQueue();
    await _persistFailedQueue();
    debugPrint('❌ Moved ${operation.type} to failed queue (ID: ${operation.id})');
  }

  /// Process sync queue.
  ///
  /// Executes queued operations sequentially with retry logic.
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    if (!await _isOnline()) {
      debugPrint('⚠️ Offline - waiting for connection to process queue');
      return;
    }

    _isProcessing = true;
    debugPrint('🔄 Processing sync queue (${_queue.length} operations)');

    // Start appointment sync performance trace
    final appointmentSyncTrace = await PerformanceService.instance.startAppointmentSyncTrace();
    int syncedCount = 0;
    int failedCount = 0;
    final Map<SyncOperationType, int> failedByType = {};
    String? lastError;

    while (_queue.isNotEmpty && await _isOnline()) {
      final operation = _queue.first;

      // Check if we need to wait for backoff delay
      if (operation.lastAttemptAt != null) {
        final backoffDelay = operation.getBackoffDelay();
        final timeSinceLastAttempt = DateTime.now().difference(operation.lastAttemptAt!).inSeconds;

        if (timeSinceLastAttempt < backoffDelay) {
          final waitTime = backoffDelay - timeSinceLastAttempt;
          debugPrint('⏳ Waiting ${waitTime}s before retry (attempt ${operation.retryCount + 1})');
          await Future.delayed(Duration(seconds: waitTime));
        }
      }

      try {
        await _executeOperation(operation);
        await _removeOperation(operation);
        syncedCount++;
        debugPrint('✅ Successfully synced ${operation.type} (ID: ${operation.id})');
      } catch (e) {
        operation.incrementRetry(error: e.toString());
        lastError = e.toString();
        debugPrint('⚠️ Sync failed for ${operation.type} (attempt ${operation.retryCount}/3): $e');

        if (operation.hasExceededMaxRetries()) {
          await _moveToFailed(operation);
          failedCount++;

          // Track failed operations by type for notifications
          failedByType[operation.type] = (failedByType[operation.type] ?? 0) + 1;

          debugPrint('❌ Operation ${operation.id} exceeded max retries - moved to failed queue');
        } else {
          await _persistQueue();
          // Continue to next operation and retry this one later
          break;
        }
      }
    }

    _isProcessing = false;

    // Stop appointment sync trace with metrics
    await PerformanceService.instance.stopAppointmentSyncTrace(
      appointmentSyncTrace,
      syncedCount: syncedCount,
      failedCount: failedCount,
    );

    // Trigger notifications for failed operations after max retries
    if (failedCount > 0) {
      await _notifyFailedOperations(failedByType, lastError);
    }

    if (_queue.isNotEmpty) {
      debugPrint('📊 Sync queue status: ${_queue.length} pending, ${_failedOperations.length} failed');
    } else {
      debugPrint('✅ Sync queue processed successfully');
    }
  }

  /// Notify user of failed operations after max retries exceeded
  Future<void> _notifyFailedOperations(
    Map<SyncOperationType, int> failedByType,
    String? lastError,
  ) async {
    try {
      final notificationService = NotificationService.instance;

      // Notify for failed assessment syncs
      final failedAssessments = failedByType[SyncOperationType.syncAssessment] ?? 0;
      if (failedAssessments > 0) {
        await notificationService.notifyAssessmentSyncFailure(
          failedCount: failedAssessments,
          errorMessage: lastError,
        );
        debugPrint('📲 Sent sync failure notification for $failedAssessments assessment(s)');
      }

      // Notify for failed appointment operations
      final failedAppointmentSyncs = failedByType[SyncOperationType.syncAppointment] ?? 0;
      final failedAppointmentUpdates = failedByType[SyncOperationType.updateAppointment] ?? 0;
      final failedAppointmentCancellations = failedByType[SyncOperationType.cancelAppointment] ?? 0;
      final totalFailedAppointments = failedAppointmentSyncs +
                                       failedAppointmentUpdates +
                                       failedAppointmentCancellations;

      if (totalFailedAppointments > 0) {
        await notificationService.notifyAppointmentSyncFailure(
          failedCount: totalFailedAppointments,
          errorMessage: lastError,
        );
        debugPrint('📲 Sent sync failure notification for $totalFailedAppointments appointment(s)');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to send sync failure notification: $e');
      // Don't throw - notification failure shouldn't break sync
    }
  }

  /// Execute a single sync operation with conflict detection.
  ///
  /// Steps:
  /// 1. Fetch server and local data
  /// 2. Detect conflicts using ConflictResolver
  /// 3. Apply resolution strategy based on entity type
  /// 4. Execute sync with resolved data
  Future<Map<String, dynamic>> _executeOperation(
    SyncOperation operation,
  ) async {
    try {
      final executor = _executors[operation.type];

      if (executor == null) {
        throw Exception('No executor registered for ${operation.type}');
      }

      debugPrint('🔄 Executing ${operation.type} (ID: ${operation.id})');

      // Check if data fetchers are registered for conflict detection
      final serverFetcher = _serverDataFetchers[operation.type];
      final localFetcher = _localDataFetchers[operation.type];

      if (serverFetcher != null && localFetcher != null) {
        // Perform conflict detection
        final resolvedData = await _detectAndResolveConflict(
          operation: operation,
          serverFetcher: serverFetcher,
          localFetcher: localFetcher,
        );

        if (resolvedData != null) {
          // Create new operation with resolved data
          final resolvedOperation = SyncOperation(
            id: operation.id,
            type: operation.type,
            data: resolvedData,
            createdAt: operation.createdAt,
            retryCount: operation.retryCount,
            lastAttemptAt: operation.lastAttemptAt,
            lastError: operation.lastError,
          );

          return await executor(resolvedOperation);
        }
      }

      // No conflict detection needed or no fetchers registered
      return await executor(operation);
    } catch (e) {
      debugPrint('❌ Error executing operation: $e');
      rethrow;
    }
  }

  /// Detect and resolve conflicts for a sync operation.
  ///
  /// Returns resolved data to use for sync, or null if no conflict.
  Future<Map<String, dynamic>?> _detectAndResolveConflict({
    required SyncOperation operation,
    required ServerDataFetcher serverFetcher,
    required LocalDataFetcher localFetcher,
  }) async {
    try {
      final entityId = operation.data['id'] as String?;
      if (entityId == null) {
        debugPrint('⚠️ No entity ID found, skipping conflict detection');
        return null;
      }

      // Fetch server and local data
      final serverData = await serverFetcher(entityId);
      final localData = await localFetcher(entityId);

      // No server data means this is a new entity
      if (serverData == null) {
        debugPrint('✅ No server data, no conflict detected');
        return null;
      }

      // No local data means we should use server data
      if (localData == null) {
        debugPrint('✅ No local data, using server data');
        return serverData;
      }

      // Detect conflict
      final hasConflict = ConflictResolver.instance.detectConflict(
        localData: localData,
        serverData: serverData,
      );

      if (!hasConflict) {
        debugPrint('✅ No conflict detected, proceeding with sync');
        return null;
      }

      debugPrint('⚠️ Conflict detected, applying resolution strategy');

      // Apply resolution based on operation type
      return await _applyResolutionStrategy(
        operation: operation,
        localData: localData,
        serverData: serverData,
      );
    } catch (e) {
      debugPrint('❌ Error in conflict detection: $e');
      // On error, proceed with original operation data
      return null;
    }
  }

  /// Apply conflict resolution strategy based on entity type.
  Future<Map<String, dynamic>> _applyResolutionStrategy({
    required SyncOperation operation,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    switch (operation.type) {
      case SyncOperationType.syncAppointment:
      case SyncOperationType.updateAppointment:
        return await _resolveAppointmentConflict(localData, serverData);

      case SyncOperationType.syncAssessment:
        return await _resolveAssessmentConflict(
          operation,
          localData,
          serverData,
        );

      case SyncOperationType.cancelAppointment:
        // For cancellations, local action takes precedence
        return localData;

      default:
        debugPrint('⚠️ Unknown operation type, using server data');
        return serverData;
    }
  }

  /// Resolve appointment conflict using context-based strategy.
  Future<Map<String, dynamic>> _resolveAppointmentConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) async {
    try {
      final resolvedData = await ConflictResolver.instance
          .resolveAppointmentConflict(
        localData: localData,
        serverData: serverData,
      );

      debugPrint('✅ Appointment conflict resolved');
      return resolvedData;
    } catch (e) {
      debugPrint('❌ Error resolving appointment conflict: $e');
      return serverData; // Fallback to server data
    }
  }

  /// Resolve assessment conflict using merge strategy.
  Future<Map<String, dynamic>> _resolveAssessmentConflict(
    SyncOperation operation,
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) async {
    try {
      final resolution = await ConflictResolver.instance
          .resolveAssessmentConflict(
        localData: localData,
        serverData: serverData,
      );

      if (resolution.requiresManualReview) {
        // Queue for manual review
        await _queueForManualReview(
          operation: operation,
          resolution: resolution,
        );

        debugPrint('⚠️ Assessment conflict requires manual review');
        // Return server version for now
        return resolution.serverVersion;
      }

      debugPrint('✅ Assessment conflict auto-resolved');
      return resolution.serverVersion;
    } catch (e) {
      debugPrint('❌ Error resolving assessment conflict: $e');
      return serverData; // Fallback to server data
    }
  }

  /// Check if device is online.
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('⚠️ Error checking connectivity: $e');
      return false;
    }
  }

  /// Queue conflict for manual review.
  Future<void> _queueForManualReview({
    required SyncOperation operation,
    required AssessmentConflictResolution resolution,
  }) async {
    try {
      final conflictEntry = {
        'operationId': operation.id,
        'operationType': operation.type.toString(),
        'localVersion': resolution.localVersion,
        'serverVersion': resolution.serverVersion,
        'detectedAt': DateTime.now().toIso8601String(),
      };

      _manualReviewConflicts.add(conflictEntry);
      await _persistManualReviewQueue();

      debugPrint('📝 Conflict queued for manual review (ID: ${operation.id})');
    } catch (e) {
      debugPrint('❌ Error queueing conflict for manual review: $e');
    }
  }

  /// Set up connectivity listener.
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;

      if (isOnline && _queue.isNotEmpty && !_isProcessing) {
        debugPrint('🌐 Connection restored - resuming sync queue');
        _processQueue();
      }
    });
  }

  /// Persist queue to SharedPreferences.
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _queue.map((op) => op.toJson()).toList();
      await prefs.setString(_queueKey, jsonEncode(queueJson));
    } catch (e) {
      debugPrint('❌ Error persisting queue: $e');
    }
  }

  /// Persist failed operations to SharedPreferences.
  Future<void> _persistFailedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedJson = _failedOperations.map((op) => op.toJson()).toList();
      await prefs.setString(_failedQueueKey, jsonEncode(failedJson));
    } catch (e) {
      debugPrint('❌ Error persisting failed queue: $e');
    }
  }

  /// Persist manual review conflicts to SharedPreferences.
  Future<void> _persistManualReviewQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _manualReviewQueueKey,
        jsonEncode(_manualReviewConflicts),
      );
    } catch (e) {
      debugPrint('❌ Error persisting manual review queue: $e');
    }
  }

  /// Load persisted queue from SharedPreferences.
  Future<void> _loadPersistedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load pending operations
      final queueString = prefs.getString(_queueKey);
      if (queueString != null) {
        final List<dynamic> queueJson = jsonDecode(queueString);
        final loadedOperations = queueJson.map((json) => SyncOperation.fromJson(json)).toList();

        // 🔧 FIX: Deduplicate operations by ID before adding to queue
        final seenIds = <String>{};
        int duplicatesRemoved = 0;

        for (final operation in loadedOperations) {
          if (!seenIds.contains(operation.id)) {
            seenIds.add(operation.id);
            _queue.add(operation);
          } else {
            duplicatesRemoved++;
          }
        }

        if (duplicatesRemoved > 0) {
          debugPrint('🧹 Removed $duplicatesRemoved duplicate operations from queue');
          // Persist the cleaned queue
          await _persistQueue();
        }
      }

      // Load failed operations
      final failedString = prefs.getString(_failedQueueKey);
      if (failedString != null) {
        final List<dynamic> failedJson = jsonDecode(failedString);
        _failedOperations.addAll(
          failedJson.map((json) => SyncOperation.fromJson(json)),
        );
      }

      // Load manual review conflicts
      final manualReviewString = prefs.getString(_manualReviewQueueKey);
      if (manualReviewString != null) {
        final List<dynamic> manualReviewJson = jsonDecode(manualReviewString);
        _manualReviewConflicts.addAll(
          manualReviewJson.map((json) => json as Map<String, dynamic>),
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading persisted queue: $e');
    }
  }

  /// Get current queue status.
  Map<String, dynamic> getQueueStatus() {
    return {
      'pending': _queue.length,
      'failed': _failedOperations.length,
      'manualReview': _manualReviewConflicts.length,
      'isProcessing': _isProcessing,
      'operations': _queue.map((op) => {
        'id': op.id,
        'type': op.type.toString(),
        'retryCount': op.retryCount,
        'createdAt': op.createdAt.toIso8601String(),
      }).toList(),
    };
  }

  /// Get list of failed operations with details.
  List<SyncOperation> getFailedOperations() {
    return List.unmodifiable(_failedOperations);
  }

  /// Get number of failed operations.
  int getFailedCount() {
    return _failedOperations.length;
  }

  /// Stream of failed operations count for UI updates.
  Stream<int> watchFailedCount() async* {
    while (true) {
      yield _failedOperations.length;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Retry failed operations.
  Future<void> retryFailedOperations() async {
    if (_failedOperations.isEmpty) {
      debugPrint('ℹ️ No failed operations to retry');
      return;
    }

    debugPrint('🔄 Retrying ${_failedOperations.length} failed operations');

    // Track initial counts for success notification
    final initialAssessmentCount = _failedOperations
        .where((op) => op.type == SyncOperationType.syncAssessment)
        .length;
    final initialAppointmentCount = _failedOperations.length - initialAssessmentCount;

    // Move failed operations back to queue
    _queue.addAll(_failedOperations);
    _failedOperations.clear();

    // Reset retry counts
    for (var operation in _queue) {
      operation.retryCount = 0;
      operation.lastAttemptAt = null;
      operation.lastError = null;
    }

    await _persistQueue();
    await _persistFailedQueue();

    // Start processing and track success
    await _processQueue();

    // Send success notification if any operations were synced
    try {
      final notificationService = NotificationService.instance;

      // Count how many actually succeeded by checking remaining failed operations
      final currentAssessmentFailed = _failedOperations
          .where((op) => op.type == SyncOperationType.syncAssessment)
          .length;
      final currentAppointmentFailed = _failedOperations.length - currentAssessmentFailed;

      final syncedAssessments = initialAssessmentCount - currentAssessmentFailed;
      final syncedAppointments = initialAppointmentCount - currentAppointmentFailed;

      if (syncedAssessments > 0) {
        await notificationService.notifySyncSuccess(
          syncedCount: syncedAssessments,
          type: 'assessment',
        );
        debugPrint('📲 Sent sync success notification for $syncedAssessments assessment(s)');
      }

      if (syncedAppointments > 0) {
        await notificationService.notifySyncSuccess(
          syncedCount: syncedAppointments,
          type: 'appointment',
        );
        debugPrint('📲 Sent sync success notification for $syncedAppointments appointment(s)');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to send sync success notification: $e');
    }
  }

  /// Clear all queues.
  Future<void> clearAll() async {
    _queue.clear();
    _failedOperations.clear();
    await _persistQueue();
    await _persistFailedQueue();
    debugPrint('🗑️ Cleared all sync queues');
  }

  /// Process queue manually.
  ///
  /// Can be called from background sync or manual sync trigger.
  Future<void> processQueue() async {
    await _processQueue();
  }

  /// Get queue statistics.
  ///
  /// Returns counts of pending, failed, manual review, and total operations.
  Future<Map<String, int>> getQueueStatistics() async {
    return {
      'pending': _queue.length,
      'failed': _failedOperations.length,
      'manualReview': _manualReviewConflicts.length,
      'total': _queue.length +
               _failedOperations.length +
               _manualReviewConflicts.length,
    };
  }

  /// Get conflicts requiring manual review.
  ///
  /// Returns list of conflicts that need user intervention.
  List<Map<String, dynamic>> getManualReviewConflicts() {
    return List.unmodifiable(_manualReviewConflicts);
  }

  /// Get count of conflicts requiring manual review.
  int getManualReviewCount() {
    return _manualReviewConflicts.length;
  }

  /// Resolve a manual review conflict.
  ///
  /// [conflictId] - The operation ID of the conflict.
  /// [selectedVersion] - 'local' or 'server' to indicate which version to keep.
  Future<bool> resolveManualConflict({
    required String conflictId,
    required String selectedVersion,
  }) async {
    try {
      final index = _manualReviewConflicts.indexWhere(
        (conflict) => conflict['operationId'] == conflictId,
      );

      if (index == -1) {
        debugPrint('⚠️ Conflict not found: $conflictId');
        return false;
      }

      final conflict = _manualReviewConflicts[index];
      final chosenData = selectedVersion == 'local'
          ? conflict['localVersion']
          : conflict['serverVersion'];

      // Remove from manual review queue
      _manualReviewConflicts.removeAt(index);
      await _persistManualReviewQueue();

      debugPrint('✅ Manual conflict resolved: $conflictId ($selectedVersion)');

      // Re-queue for sync with chosen version
      final operation = SyncOperation(
        id: conflictId,
        type: SyncOperationType.values.firstWhere(
          (e) => e.toString() == conflict['operationType'],
        ),
        data: chosenData as Map<String, dynamic>,
      );

      await addOperation(operation);

      return true;
    } catch (e) {
      debugPrint('❌ Error resolving manual conflict: $e');
      return false;
    }
  }

  /// Clear all manual review conflicts.
  Future<void> clearManualReviewConflicts() async {
    try {
      _manualReviewConflicts.clear();
      await _persistManualReviewQueue();
      debugPrint('✅ Manual review conflicts cleared');
    } catch (e) {
      debugPrint('❌ Error clearing manual review conflicts: $e');
    }
  }

  /// Dispose the service.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
