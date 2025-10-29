import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int getBackoffDelay() {
    return pow(2, retryCount).toInt();
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

  final Queue<SyncOperation> _queue = Queue();
  final List<SyncOperation> _failedOperations = [];
  bool _isProcessing = false;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final Map<SyncOperationType, SyncExecutor> _executors = {};

  /// Initialize the sync queue service.
  ///
  /// Loads persisted queue and sets up connectivity listener.
  Future<void> initialize() async {
    await _loadPersistedQueue();
    _setupConnectivityListener();
    print('✅ SyncQueue initialized with ${_queue.length} pending operations');
  }

  /// Register a sync executor for a specific operation type.
  ///
  /// [type] - The type of sync operation.
  /// [executor] - Function that executes the sync operation.
  void registerExecutor(SyncOperationType type, SyncExecutor executor) {
    _executors[type] = executor;
  }

  /// Add operation to sync queue.
  ///
  /// [operation] - The sync operation to queue.
  Future<void> addOperation(SyncOperation operation) async {
    _queue.add(operation);
    await _persistQueue();
    print('📝 Added ${operation.type} to sync queue (ID: ${operation.id})');

    // Start processing if not already running
    _processQueue();
  }

  /// Remove operation from queue.
  Future<void> _removeOperation(SyncOperation operation) async {
    _queue.remove(operation);
    await _persistQueue();
  }

  /// Move operation to failed queue.
  Future<void> _moveToFailed(SyncOperation operation) async {
    _queue.remove(operation);
    _failedOperations.add(operation);
    await _persistQueue();
    await _persistFailedQueue();
    print('❌ Moved ${operation.type} to failed queue (ID: ${operation.id})');
  }

  /// Process sync queue.
  ///
  /// Executes queued operations sequentially with retry logic.
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    if (!await _isOnline()) {
      print('⚠️ Offline - waiting for connection to process queue');
      return;
    }

    _isProcessing = true;
    print('🔄 Processing sync queue (${_queue.length} operations)');

    while (_queue.isNotEmpty && await _isOnline()) {
      final operation = _queue.first;

      // Check if we need to wait for backoff delay
      if (operation.lastAttemptAt != null) {
        final backoffDelay = operation.getBackoffDelay();
        final timeSinceLastAttempt = DateTime.now().difference(operation.lastAttemptAt!).inSeconds;

        if (timeSinceLastAttempt < backoffDelay) {
          final waitTime = backoffDelay - timeSinceLastAttempt;
          print('⏳ Waiting ${waitTime}s before retry (attempt ${operation.retryCount + 1})');
          await Future.delayed(Duration(seconds: waitTime));
        }
      }

      try {
        await _executeOperation(operation);
        await _removeOperation(operation);
        print('✅ Successfully synced ${operation.type} (ID: ${operation.id})');
      } catch (e) {
        operation.incrementRetry(error: e.toString());
        print('⚠️ Sync failed for ${operation.type} (attempt ${operation.retryCount}/3): $e');

        if (operation.hasExceededMaxRetries()) {
          await _moveToFailed(operation);
        } else {
          await _persistQueue();
          // Continue to next operation and retry this one later
          break;
        }
      }
    }

    _isProcessing = false;

    if (_queue.isNotEmpty) {
      print('📊 Sync queue status: ${_queue.length} pending, ${_failedOperations.length} failed');
    } else {
      print('✅ Sync queue processed successfully');
    }
  }

  /// Execute a single sync operation.
  Future<Map<String, dynamic>> _executeOperation(SyncOperation operation) async {
    final executor = _executors[operation.type];

    if (executor == null) {
      throw Exception('No executor registered for ${operation.type}');
    }

    print('🔄 Executing ${operation.type} (ID: ${operation.id})');
    return await executor(operation);
  }

  /// Check if device is online.
  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('⚠️ Error checking connectivity: $e');
      return false;
    }
  }

  /// Set up connectivity listener.
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;

      if (isOnline && _queue.isNotEmpty && !_isProcessing) {
        print('🌐 Connection restored - resuming sync queue');
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
      print('❌ Error persisting queue: $e');
    }
  }

  /// Persist failed operations to SharedPreferences.
  Future<void> _persistFailedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedJson = _failedOperations.map((op) => op.toJson()).toList();
      await prefs.setString(_failedQueueKey, jsonEncode(failedJson));
    } catch (e) {
      print('❌ Error persisting failed queue: $e');
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
        _queue.addAll(queueJson.map((json) => SyncOperation.fromJson(json)));
      }

      // Load failed operations
      final failedString = prefs.getString(_failedQueueKey);
      if (failedString != null) {
        final List<dynamic> failedJson = jsonDecode(failedString);
        _failedOperations.addAll(failedJson.map((json) => SyncOperation.fromJson(json)));
      }
    } catch (e) {
      print('❌ Error loading persisted queue: $e');
    }
  }

  /// Get current queue status.
  Map<String, dynamic> getQueueStatus() {
    return {
      'pending': _queue.length,
      'failed': _failedOperations.length,
      'isProcessing': _isProcessing,
      'operations': _queue.map((op) => {
        'id': op.id,
        'type': op.type.toString(),
        'retryCount': op.retryCount,
        'createdAt': op.createdAt.toIso8601String(),
      }).toList(),
    };
  }

  /// Retry failed operations.
  Future<void> retryFailedOperations() async {
    if (_failedOperations.isEmpty) {
      print('ℹ️ No failed operations to retry');
      return;
    }

    print('🔄 Retrying ${_failedOperations.length} failed operations');

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

    // Start processing
    _processQueue();
  }

  /// Clear all queues.
  Future<void> clearAll() async {
    _queue.clear();
    _failedOperations.clear();
    await _persistQueue();
    await _persistFailedQueue();
    print('🗑️ Cleared all sync queues');
  }

  /// Dispose the service.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
