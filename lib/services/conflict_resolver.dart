import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Conflict Resolution Service for Juan Heart Mobile
///
/// Handles data synchronization conflicts using configurable strategies:
/// - Last-Write-Wins: Most recent timestamp wins (user profiles)
/// - Server-Wins: Server data always takes precedence (facility data)
/// - Merge: Keep both versions, mark conflict (assessments)
/// - Manual: User decides resolution (configurable)
///
/// All conflict resolutions are logged for audit trail and debugging.
class ConflictResolver {
  static final ConflictResolver instance = ConflictResolver._internal();

  factory ConflictResolver() => instance;

  ConflictResolver._internal();

  static const String _prefsKey = 'conflict_resolution_preference';
  static const String _conflictLogKey = 'conflict_resolution_log';

  /// Get user's preferred conflict resolution strategy
  Future<ConflictResolutionStrategy> getUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strategyName = prefs.getString(_prefsKey);

      if (strategyName != null) {
        return ConflictResolutionStrategy.values.firstWhere(
          (e) => e.toString() == strategyName,
          orElse: () => ConflictResolutionStrategy.lastWriteWins,
        );
      }

      return ConflictResolutionStrategy.lastWriteWins;
    } catch (e) {
      debugPrint('❌ Error getting user preference: $e');
      return ConflictResolutionStrategy.lastWriteWins;
    }
  }

  /// Set user's preferred conflict resolution strategy
  Future<void> setUserPreference(ConflictResolutionStrategy strategy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, strategy.toString());
      debugPrint('✅ Conflict resolution preference set to: $strategy');
    } catch (e) {
      debugPrint('❌ Error setting user preference: $e');
    }
  }

  /// Resolve user profile conflict
  ///
  /// Strategy: Last-Write-Wins
  /// The version with the most recent timestamp is kept.
  Future<Map<String, dynamic>> resolveUserProfileConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    debugPrint('🔄 Resolving user profile conflict');

    try {
      final localTimestamp = _parseTimestamp(localData['updatedAt']);
      final serverTimestamp = _parseTimestamp(serverData['updatedAt']);

      Map<String, dynamic> winner;
      String resolution;

      if (localTimestamp.isAfter(serverTimestamp)) {
        winner = localData;
        resolution = 'local_wins';
        debugPrint('✅ Local data is newer, using local version');
      } else {
        winner = serverData;
        resolution = 'server_wins';
        debugPrint('✅ Server data is newer, using server version');
      }

      await _logConflict(
        entityType: 'user_profile',
        strategy: ConflictResolutionStrategy.lastWriteWins,
        localData: localData,
        serverData: serverData,
        resolution: resolution,
        winner: winner,
      );

      return winner;
    } catch (e) {
      debugPrint('❌ Error resolving user profile conflict: $e');
      // Default to server data on error
      await _logConflict(
        entityType: 'user_profile',
        strategy: ConflictResolutionStrategy.serverWins,
        localData: localData,
        serverData: serverData,
        resolution: 'error_fallback_server',
        winner: serverData,
      );
      return serverData;
    }
  }

  /// Resolve facility data conflict
  ///
  /// Strategy: Server-Wins
  /// Server data is always authoritative for facility information.
  Future<Map<String, dynamic>> resolveFacilityConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    debugPrint('🔄 Resolving facility data conflict');

    try {
      debugPrint('✅ Server data wins for facility data (authoritative source)');

      await _logConflict(
        entityType: 'facility',
        strategy: ConflictResolutionStrategy.serverWins,
        localData: localData,
        serverData: serverData,
        resolution: 'server_wins',
        winner: serverData,
      );

      return serverData;
    } catch (e) {
      debugPrint('❌ Error resolving facility conflict: $e');
      return serverData; // Always return server data for facilities
    }
  }

  /// Resolve assessment conflict
  ///
  /// Strategy: Merge (Keep Both)
  /// Both versions are preserved with conflict marker.
  /// Local version gets a conflict flag for manual review.
  Future<AssessmentConflictResolution> resolveAssessmentConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    debugPrint('🔄 Resolving assessment conflict');

    try {
      // Mark local assessment as conflicted
      final conflictedLocal = Map<String, dynamic>.from(localData);
      conflictedLocal['hasConflict'] = true;
      conflictedLocal['conflictDetectedAt'] = DateTime.now().toIso8601String();
      conflictedLocal['conflictReason'] = 'sync_conflict_merge_required';

      debugPrint('✅ Keeping both versions, local marked for review');

      await _logConflict(
        entityType: 'assessment',
        strategy: ConflictResolutionStrategy.merge,
        localData: localData,
        serverData: serverData,
        resolution: 'merge_both_kept',
        winner: null, // Both kept
      );

      return AssessmentConflictResolution(
        localVersion: conflictedLocal,
        serverVersion: serverData,
        requiresManualReview: true,
      );
    } catch (e) {
      debugPrint('❌ Error resolving assessment conflict: $e');
      // Default to server data on error
      await _logConflict(
        entityType: 'assessment',
        strategy: ConflictResolutionStrategy.serverWins,
        localData: localData,
        serverData: serverData,
        resolution: 'error_fallback_server',
        winner: serverData,
      );

      return AssessmentConflictResolution(
        localVersion: null,
        serverVersion: serverData,
        requiresManualReview: false,
      );
    }
  }

  /// Resolve appointment conflict
  ///
  /// Strategy: Context-based
  /// - If status differs: Server wins (authoritative)
  /// - If details differ: Last-write-wins
  Future<Map<String, dynamic>> resolveAppointmentConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    debugPrint('🔄 Resolving appointment conflict');

    try {
      final localStatus = localData['status'];
      final serverStatus = serverData['status'];

      Map<String, dynamic> winner;
      String resolution;

      // If status differs, server is authoritative
      if (localStatus != serverStatus) {
        winner = serverData;
        resolution = 'server_wins_status_conflict';
        debugPrint('✅ Status differs, server is authoritative: $serverStatus');
      } else {
        // Same status, use last-write-wins
        final localTimestamp = _parseTimestamp(localData['updatedAt']);
        final serverTimestamp = _parseTimestamp(serverData['updatedAt']);

        if (localTimestamp.isAfter(serverTimestamp)) {
          winner = localData;
          resolution = 'local_wins_newer';
          debugPrint('✅ Local appointment is newer');
        } else {
          winner = serverData;
          resolution = 'server_wins_newer';
          debugPrint('✅ Server appointment is newer');
        }
      }

      await _logConflict(
        entityType: 'appointment',
        strategy: ConflictResolutionStrategy.contextBased,
        localData: localData,
        serverData: serverData,
        resolution: resolution,
        winner: winner,
      );

      return winner;
    } catch (e) {
      debugPrint('❌ Error resolving appointment conflict: $e');
      // Default to server data on error
      await _logConflict(
        entityType: 'appointment',
        strategy: ConflictResolutionStrategy.serverWins,
        localData: localData,
        serverData: serverData,
        resolution: 'error_fallback_server',
        winner: serverData,
      );
      return serverData;
    }
  }

  /// Detect if conflict exists between local and server data
  bool detectConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    try {
      // Compare updatedAt timestamps
      final localTimestamp = _parseTimestamp(localData['updatedAt']);
      final serverTimestamp = _parseTimestamp(serverData['updatedAt']);

      // If timestamps are different, check if data differs
      if (localTimestamp != serverTimestamp) {
        // Compare key fields (excluding metadata)
        final localFiltered = _filterMetadata(localData);
        final serverFiltered = _filterMetadata(serverData);

        final localJson = jsonEncode(localFiltered);
        final serverJson = jsonEncode(serverFiltered);

        return localJson != serverJson;
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Error detecting conflict: $e');
      return false; // Assume no conflict on error
    }
  }

  /// Get conflict resolution statistics
  Future<Map<String, dynamic>> getConflictStatistics() async {
    try {
      final logs = await getConflictLog();

      final stats = {
        'totalConflicts': logs.length,
        'byEntityType': <String, int>{},
        'byStrategy': <String, int>{},
        'byResolution': <String, int>{},
        'lastConflictAt': logs.isNotEmpty ? logs.last['timestamp'] : null,
      };

      for (var log in logs) {
        // Count by entity type
        final entityType = log['entityType'] as String;
        stats['byEntityType'][entityType] =
            ((stats['byEntityType'] as Map)[entityType] ?? 0) + 1;

        // Count by strategy
        final strategy = log['strategy'] as String;
        stats['byStrategy'][strategy] =
            ((stats['byStrategy'] as Map)[strategy] ?? 0) + 1;

        // Count by resolution
        final resolution = log['resolution'] as String;
        stats['byResolution'][resolution] =
            ((stats['byResolution'] as Map)[resolution] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting conflict statistics: $e');
      return {
        'totalConflicts': 0,
        'byEntityType': {},
        'byStrategy': {},
        'byResolution': {},
        'lastConflictAt': null,
      };
    }
  }

  /// Get conflict resolution log
  Future<List<Map<String, dynamic>>> getConflictLog({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logString = prefs.getString(_conflictLogKey);

      if (logString != null) {
        final List<dynamic> logJson = jsonDecode(logString);
        final logs = logJson.map((e) => e as Map<String, dynamic>).toList();

        // Sort by timestamp descending (most recent first)
        logs.sort((a, b) {
          final aTime = DateTime.parse(a['timestamp'] as String);
          final bTime = DateTime.parse(b['timestamp'] as String);
          return bTime.compareTo(aTime);
        });

        if (limit != null && logs.length > limit) {
          return logs.sublist(0, limit);
        }

        return logs;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting conflict log: $e');
      return [];
    }
  }

  /// Clear conflict log
  Future<void> clearConflictLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conflictLogKey);
      debugPrint('✅ Conflict log cleared');
    } catch (e) {
      debugPrint('❌ Error clearing conflict log: $e');
    }
  }

  /// Get conflicts requiring manual review
  /// Returns list of conflicts flagged for manual resolution
  Future<List<ConflictItem>> getConflictsRequiringManualReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const manualReviewKey = 'conflicts_manual_review';
      final manualReviewString = prefs.getString(manualReviewKey);

      if (manualReviewString != null) {
        final List<dynamic> conflictsJson = jsonDecode(manualReviewString);
        final conflicts = conflictsJson
            .map((e) => ConflictItem.fromJson(e as Map<String, dynamic>))
            .toList();

        // Sort by timestamp descending (most recent first)
        conflicts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return conflicts;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting conflicts requiring manual review: $e');
      return [];
    }
  }

  /// Add conflict for manual review
  Future<void> addConflictForManualReview(ConflictItem conflict) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const manualReviewKey = 'conflicts_manual_review';
      final conflicts = await getConflictsRequiringManualReview();

      // Check if conflict already exists
      final existingIndex = conflicts.indexWhere((c) =>
          c.entityType == conflict.entityType &&
          c.localData['id'] == conflict.localData['id']);

      if (existingIndex >= 0) {
        // Update existing conflict
        conflicts[existingIndex] = conflict;
      } else {
        // Add new conflict
        conflicts.add(conflict);
      }

      // Keep only last 50 conflicts to prevent storage bloat
      final limitedConflicts =
          conflicts.length > 50 ? conflicts.sublist(0, 50) : conflicts;

      final conflictsJson = limitedConflicts.map((c) => c.toJson()).toList();
      await prefs.setString(manualReviewKey, jsonEncode(conflictsJson));

      debugPrint('📝 Conflict added for manual review: ${conflict.entityType}');
    } catch (e) {
      debugPrint('❌ Error adding conflict for manual review: $e');
    }
  }

  /// Apply manual resolution choice
  Future<Map<String, dynamic>> applyManualResolution({
    required String conflictId,
    required ManualResolutionChoice choice,
  }) async {
    try {
      final conflicts = await getConflictsRequiringManualReview();
      final conflict = conflicts.firstWhere(
        (c) => c.id == conflictId,
        orElse: () => throw Exception('Conflict not found'),
      );

      Map<String, dynamic> winner;
      String resolution;

      switch (choice) {
        case ManualResolutionChoice.keepLocal:
          winner = conflict.localData;
          resolution = 'manual_local_wins';
          break;
        case ManualResolutionChoice.keepServer:
          winner = conflict.serverData;
          resolution = 'manual_server_wins';
          break;
      }

      // Log the manual resolution
      await _logConflict(
        entityType: conflict.entityType,
        strategy: ConflictResolutionStrategy.manual,
        localData: conflict.localData,
        serverData: conflict.serverData,
        resolution: resolution,
        winner: winner,
      );

      // Remove from manual review queue
      await removeConflictFromManualReview(conflictId);

      debugPrint('✅ Manual resolution applied: $resolution');
      return winner;
    } catch (e) {
      debugPrint('❌ Error applying manual resolution: $e');
      rethrow;
    }
  }

  /// Remove conflict from manual review queue
  Future<void> removeConflictFromManualReview(String conflictId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const manualReviewKey = 'conflicts_manual_review';
      final conflicts = await getConflictsRequiringManualReview();

      final filteredConflicts =
          conflicts.where((c) => c.id != conflictId).toList();

      final conflictsJson = filteredConflicts.map((c) => c.toJson()).toList();
      await prefs.setString(manualReviewKey, jsonEncode(conflictsJson));

      debugPrint('✅ Conflict removed from manual review: $conflictId');
    } catch (e) {
      debugPrint('❌ Error removing conflict from manual review: $e');
    }
  }

  /// Get count of conflicts requiring manual review
  Future<int> getManualReviewCount() async {
    try {
      final conflicts = await getConflictsRequiringManualReview();
      return conflicts.length;
    } catch (e) {
      debugPrint('❌ Error getting manual review count: $e');
      return 0;
    }
  }

  /// Log conflict resolution
  Future<void> _logConflict({
    required String entityType,
    required ConflictResolutionStrategy strategy,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required String resolution,
    Map<String, dynamic>? winner,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logString = prefs.getString(_conflictLogKey);

      List<Map<String, dynamic>> logs = [];
      if (logString != null) {
        final List<dynamic> logJson = jsonDecode(logString);
        logs = logJson.map((e) => e as Map<String, dynamic>).toList();
      }

      // Add new log entry
      logs.add({
        'timestamp': DateTime.now().toIso8601String(),
        'entityType': entityType,
        'strategy': strategy.toString(),
        'resolution': resolution,
        'localTimestamp': localData['updatedAt'],
        'serverTimestamp': serverData['updatedAt'],
        'winnerId': winner?['id'],
        'details': {
          'localId': localData['id'],
          'serverId': serverData['id'],
        },
      });

      // Keep only last 100 entries to prevent storage bloat
      if (logs.length > 100) {
        logs = logs.sublist(logs.length - 100);
      }

      await prefs.setString(_conflictLogKey, jsonEncode(logs));
      debugPrint('📝 Conflict logged: $entityType - $resolution');
    } catch (e) {
      debugPrint('❌ Error logging conflict: $e');
    }
  }

  /// Parse timestamp from various formats
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        debugPrint('⚠️ Error parsing timestamp string: $e');
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    debugPrint('⚠️ Unknown timestamp format: ${timestamp.runtimeType}');
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Filter metadata fields for conflict detection
  Map<String, dynamic> _filterMetadata(Map<String, dynamic> data) {
    final filtered = Map<String, dynamic>.from(data);

    // Remove metadata fields that shouldn't affect conflict detection
    filtered.remove('updatedAt');
    filtered.remove('createdAt');
    filtered.remove('syncStatus');
    filtered.remove('lastSyncAt');

    return filtered;
  }
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Most recent timestamp wins
  lastWriteWins,

  /// Server data always wins
  serverWins,

  /// Keep both versions, mark for manual review
  merge,

  /// Context-based resolution (e.g., status changes)
  contextBased,

  /// User decides manually
  manual,
}

/// Assessment conflict resolution result
class AssessmentConflictResolution {
  final Map<String, dynamic>? localVersion;
  final Map<String, dynamic> serverVersion;
  final bool requiresManualReview;

  AssessmentConflictResolution({
    this.localVersion,
    required this.serverVersion,
    required this.requiresManualReview,
  });

  /// Get both versions if merge was used
  List<Map<String, dynamic>> getBothVersions() {
    if (localVersion != null) {
      return [localVersion!, serverVersion];
    }
    return [serverVersion];
  }

  /// Check if conflict was resolved automatically
  bool get wasAutoResolved => !requiresManualReview;
}

/// Conflict item for manual review
class ConflictItem {
  final String id;
  final String entityType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime timestamp;
  final String? reason;

  ConflictItem({
    required this.id,
    required this.entityType,
    required this.localData,
    required this.serverData,
    required this.timestamp,
    this.reason,
  });

  factory ConflictItem.fromJson(Map<String, dynamic> json) {
    return ConflictItem(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      localData: json['localData'] as Map<String, dynamic>,
      serverData: json['serverData'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'localData': localData,
      'serverData': serverData,
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
    };
  }

  /// Get entity icon based on type
  IconData getIcon() {
    switch (entityType) {
      case 'user_profile':
        return Icons.person;
      case 'facility':
        return Icons.local_hospital;
      case 'assessment':
        return Icons.monitor_heart;
      case 'appointment':
        return Icons.calendar_today;
      default:
        return Icons.sync_problem;
    }
  }

  /// Get key differences between local and server data
  List<ConflictDifference> getDifferences() {
    final differences = <ConflictDifference>[];

    // Compare all keys from both versions
    final allKeys = {...localData.keys, ...serverData.keys};

    for (final key in allKeys) {
      // Skip metadata fields
      if (['updatedAt', 'createdAt', 'syncStatus', 'lastSyncAt']
          .contains(key)) {
        continue;
      }

      final localValue = localData[key];
      final serverValue = serverData[key];

      if (localValue != serverValue) {
        differences.add(ConflictDifference(
          field: key,
          localValue: localValue?.toString() ?? 'null',
          serverValue: serverValue?.toString() ?? 'null',
        ));
      }
    }

    return differences;
  }
}

/// Represents a difference between local and server data
class ConflictDifference {
  final String field;
  final String localValue;
  final String serverValue;

  ConflictDifference({
    required this.field,
    required this.localValue,
    required this.serverValue,
  });
}

/// Manual resolution choice
enum ManualResolutionChoice {
  keepLocal,
  keepServer,
}
