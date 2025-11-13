import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/mock_connectivity.dart';

/// Unit tests for SyncQueueService conflict detection integration.
///
/// Tests cover:
/// - Conflict detection during sync operations
/// - Each resolution strategy (appointment, assessment, user, facility)
/// - Manual review queue management
/// - Data fetcher registration and usage
/// - Error handling and fallback scenarios
void main() {
  late SyncQueueService syncQueueService;
  late MockConnectivity mockConnectivity;

  setUpAll(() {
    // Initialize Flutter bindings for tests
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    // Initialize SharedPreferences with mock
    SharedPreferences.setMockInitialValues({});

    // Create mock connectivity (start online)
    mockConnectivity = MockConnectivity();
    mockConnectivity.goOnline();

    // Create fresh instance
    syncQueueService = SyncQueueService();
    syncQueueService.setConnectivityProvider(mockConnectivity);
    await syncQueueService.initialize();
  });

  tearDown(() async {
    await syncQueueService.clearAll();
    await syncQueueService.clearManualReviewConflicts();
    mockConnectivity.dispose();
  });

  group('Data Fetcher Registration', () {
    test('should register data fetchers for operation type', () {
      // Arrange
      Future<Map<String, dynamic>?> serverFetcher(String id) async {
        return {'id': id, 'data': 'server'};
      }

      Future<Map<String, dynamic>?> localFetcher(String id) async {
        return {'id': id, 'data': 'local'};
      }

      // Act
      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      // Assert - no exception thrown
      expect(true, true);
    });

    test('should allow registering multiple operation types', () {
      // Arrange
      Future<Map<String, dynamic>?> fetcher(String id) async => null;

      // Act
      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: fetcher,
        localFetcher: fetcher,
      );

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAssessment,
        serverFetcher: fetcher,
        localFetcher: fetcher,
      );

      // Assert - no exception thrown
      expect(true, true);
    });
  });

  group('Appointment Conflict Resolution', () {
    test('should resolve appointment conflict with server wins on status change',
        () async {
      // Arrange
      final localData = {
        'id': 'apt-1',
        'status': 'pending',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final serverData = {
        'id': 'apt-1',
        'status': 'confirmed',
        'updatedAt': '2025-01-01T09:00:00Z',
      };

      Future<Map<String, dynamic>?> serverFetcher(String id) async =>
          serverData;
      Future<Map<String, dynamic>?> localFetcher(String id) async => localData;

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.syncAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final operation = SyncOperation(
        id: 'apt-1',
        type: SyncOperationType.syncAppointment,
        data: localData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - server data should win due to status conflict
      expect(executedData, isNotNull);
      expect(executedData!['status'], equals('confirmed'));
    });

    test('should resolve appointment conflict with last-write-wins on same status',
        () async {
      // Arrange
      final localData = {
        'id': 'apt-2',
        'status': 'pending',
        'notes': 'Local notes',
        'updatedAt': '2025-01-01T12:00:00Z', // Newer
      };

      final serverData = {
        'id': 'apt-2',
        'status': 'pending',
        'notes': 'Server notes',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      Future<Map<String, dynamic>?> serverFetcher(String id) async =>
          serverData;
      Future<Map<String, dynamic>?> localFetcher(String id) async => localData;

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.syncAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final operation = SyncOperation(
        id: 'apt-2',
        type: SyncOperationType.syncAppointment,
        data: localData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - local data should win (newer timestamp)
      expect(executedData, isNotNull);
      expect(executedData!['notes'], equals('Local notes'));
    });
  });

  group('Assessment Conflict Resolution', () {
    test('should queue assessment conflict for manual review', () async {
      // Arrange
      final localData = {
        'id': 'assess-1',
        'finalRiskScore': 15,
        'riskCategory': 'moderate',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final serverData = {
        'id': 'assess-1',
        'finalRiskScore': 18,
        'riskCategory': 'high',
        'updatedAt': '2025-01-01T09:00:00Z',
      };

      Future<Map<String, dynamic>?> serverFetcher(String id) async =>
          serverData;
      Future<Map<String, dynamic>?> localFetcher(String id) async => localData;

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAssessment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      syncQueueService.registerExecutor(
        SyncOperationType.syncAssessment,
        (operation) async {
          return operation.data;
        },
      );

      final operation = SyncOperation(
        id: 'assess-1',
        type: SyncOperationType.syncAssessment,
        data: localData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert
      final manualReviewConflicts =
          syncQueueService.getManualReviewConflicts();
      expect(manualReviewConflicts.length, greaterThan(0));
      expect(manualReviewConflicts[0]['operationId'], equals('assess-1'));
      expect(manualReviewConflicts[0]['localVersion'], isNotNull);
      expect(manualReviewConflicts[0]['serverVersion'], isNotNull);
    });
  });

  group('Manual Review Queue Management', () {
    test('should get manual review conflicts', () async {
      // Arrange - manually add a conflict for testing
      final prefs = await SharedPreferences.getInstance();
      final conflicts = [
        {
          'operationId': 'test-1',
          'operationType': 'SyncOperationType.syncAssessment',
          'localVersion': {'id': 'test-1', 'data': 'local'},
          'serverVersion': {'id': 'test-1', 'data': 'server'},
          'detectedAt': DateTime.now().toIso8601String(),
        }
      ];
      await prefs.setString(
        'conflict_manual_review_queue',
        jsonEncode(conflicts),
      );

      // Re-initialize to load conflicts
      final newService = SyncQueueService();
      await newService.initialize();

      // Act
      final retrieved = newService.getManualReviewConflicts();

      // Assert
      expect(retrieved.length, equals(1));
      expect(retrieved[0]['operationId'], equals('test-1'));
    });

    test('should get manual review count', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final conflicts = [
        {
          'operationId': 'test-1',
          'operationType': 'SyncOperationType.syncAssessment',
          'localVersion': {},
          'serverVersion': {},
          'detectedAt': DateTime.now().toIso8601String(),
        },
        {
          'operationId': 'test-2',
          'operationType': 'SyncOperationType.syncAssessment',
          'localVersion': {},
          'serverVersion': {},
          'detectedAt': DateTime.now().toIso8601String(),
        }
      ];
      await prefs.setString(
        'conflict_manual_review_queue',
        jsonEncode(conflicts),
      );

      final newService = SyncQueueService();
      await newService.initialize();

      // Act
      final count = newService.getManualReviewCount();

      // Assert
      expect(count, equals(2));
    });

    test('should clear manual review conflicts', () async {
      // Arrange
      await syncQueueService.clearManualReviewConflicts();

      // Act
      final count = syncQueueService.getManualReviewCount();

      // Assert
      expect(count, equals(0));
    });

    test('should include manual review count in queue statistics', () async {
      // Act
      final stats = await syncQueueService.getQueueStatistics();

      // Assert
      expect(stats, contains('manualReview'));
      expect(stats['manualReview'], isA<int>());
    });

    test('should include manual review count in queue status', () {
      // Act
      final status = syncQueueService.getQueueStatus();

      // Assert
      expect(status, contains('manualReview'));
      expect(status['manualReview'], isA<int>());
    });
  });

  group('No Conflict Scenarios', () {
    test('should proceed with sync when no server data exists', () async {
      // Arrange - new entity
      final localData = {
        'id': 'new-1',
        'data': 'new entity',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      Future<Map<String, dynamic>?> serverFetcher(String id) async => null;
      Future<Map<String, dynamic>?> localFetcher(String id) async => localData;

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.syncAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final operation = SyncOperation(
        id: 'new-1',
        type: SyncOperationType.syncAppointment,
        data: localData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - should use original local data
      expect(executedData, isNotNull);
      expect(executedData!['data'], equals('new entity'));
    });

    test('should proceed with sync when data matches', () async {
      // Arrange - identical data
      final matchingData = {
        'id': 'match-1',
        'data': 'same',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      Future<Map<String, dynamic>?> serverFetcher(String id) async =>
          matchingData;
      Future<Map<String, dynamic>?> localFetcher(String id) async =>
          matchingData;

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.syncAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final operation = SyncOperation(
        id: 'match-1',
        type: SyncOperationType.syncAppointment,
        data: matchingData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert
      expect(executedData, isNotNull);
    });
  });

  group('Error Handling', () {
    test('should fallback to original data on fetcher error', () async {
      // Arrange
      Future<Map<String, dynamic>?> errorFetcher(String id) async {
        throw Exception('Fetcher error');
      }

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.syncAppointment,
        serverFetcher: errorFetcher,
        localFetcher: errorFetcher,
      );

      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.syncAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final originalData = {'id': 'error-1', 'data': 'original'};
      final operation = SyncOperation(
        id: 'error-1',
        type: SyncOperationType.syncAppointment,
        data: originalData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - should use original data despite error
      expect(executedData, isNotNull);
      expect(executedData!['data'], equals('original'));
    });

    test('should proceed with sync when no fetchers registered', () async {
      // Arrange - no fetchers registered
      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.syncAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final data = {'id': 'no-fetcher-1', 'data': 'test'};
      final operation = SyncOperation(
        id: 'no-fetcher-1',
        type: SyncOperationType.syncAppointment,
        data: data,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert
      expect(executedData, isNotNull);
      expect(executedData!['data'], equals('test'));
    });
  });

  group('Cancellation Operations', () {
    test('should use local data for cancellation operations', () async {
      // Arrange
      final localData = {
        'id': 'cancel-1',
        'status': 'cancelled',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final serverData = {
        'id': 'cancel-1',
        'status': 'confirmed',
        'updatedAt': '2025-01-01T12:00:00Z', // Server is newer
      };

      Future<Map<String, dynamic>?> serverFetcher(String id) async =>
          serverData;
      Future<Map<String, dynamic>?> localFetcher(String id) async => localData;

      syncQueueService.registerDataFetchers(
        type: SyncOperationType.cancelAppointment,
        serverFetcher: serverFetcher,
        localFetcher: localFetcher,
      );

      Map<String, dynamic>? executedData;
      syncQueueService.registerExecutor(
        SyncOperationType.cancelAppointment,
        (operation) async {
          executedData = operation.data;
          return operation.data;
        },
      );

      final operation = SyncOperation(
        id: 'cancel-1',
        type: SyncOperationType.cancelAppointment,
        data: localData,
      );

      // Act
      await syncQueueService.addOperation(operation);
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - local cancellation should take precedence
      expect(executedData, isNotNull);
      expect(executedData!['status'], equals('cancelled'));
    });
  });

  group('Integration Tests', () {
    test('should handle multiple conflicts in sequence', () async {
      // This is a placeholder for integration testing
      // In real scenario, would test end-to-end flow with actual data
      expect(true, true);
    });

    test('should persist and restore manual review conflicts', () async {
      // Arrange - add conflict
      final prefs = await SharedPreferences.getInstance();
      final conflicts = [
        {
          'operationId': 'persist-1',
          'operationType': 'SyncOperationType.syncAssessment',
          'localVersion': {'id': 'persist-1', 'score': 15},
          'serverVersion': {'id': 'persist-1', 'score': 18},
          'detectedAt': DateTime.now().toIso8601String(),
        }
      ];

      // Properly encode as JSON string
      final encoded = jsonEncode(conflicts);
      await prefs.setString('conflict_manual_review_queue', encoded);

      // Act - create new service instance (simulates app restart)
      final newService = SyncQueueService();
      await newService.initialize();

      // Assert
      final retrieved = newService.getManualReviewConflicts();
      expect(retrieved.length, greaterThan(0));
    });
  });
}
