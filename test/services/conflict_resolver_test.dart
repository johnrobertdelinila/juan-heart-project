import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/services/conflict_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Comprehensive unit tests for ConflictResolver service.
///
/// Tests cover all resolution strategies:
/// - Last-Write-Wins (user profiles)
/// - Server-Wins (facility data)
/// - Merge/Both-Kept (assessments)
/// - Context-Based (appointments)
/// - Manual resolution queue
/// - Conflict detection logic
/// - Audit trail and statistics
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('Conflict Detection', () {
    test('detects conflict when timestamps differ and data differs', () {
      final localData = {
        'id': 'test-1',
        'name': 'Local Name',
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'test-1',
        'name': 'Server Name',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final hasConflict = ConflictResolver.instance.detectConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(hasConflict, isTrue);
    });

    test('no conflict when timestamps same', () {
      const timestamp = '2025-01-01T12:00:00Z';
      final localData = {
        'id': 'test-1',
        'name': 'Same Name',
        'updatedAt': timestamp,
      };

      final serverData = {
        'id': 'test-1',
        'name': 'Same Name',
        'updatedAt': timestamp,
      };

      final hasConflict = ConflictResolver.instance.detectConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(hasConflict, isFalse);
    });

    test('no conflict when data identical despite metadata differences', () {
      final localData = {
        'id': 'test-1',
        'name': 'Same Name',
        'value': 123,
        'updatedAt': '2025-01-01T12:00:00Z',
        'createdAt': '2025-01-01T10:00:00Z',
      };

      final serverData = {
        'id': 'test-1',
        'name': 'Same Name',
        'value': 123,
        'updatedAt': '2025-01-01T12:00:00Z',
        'createdAt': '2025-01-01T11:00:00Z', // Different createdAt
      };

      final hasConflict = ConflictResolver.instance.detectConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(hasConflict, isFalse);
    });

    test('handles null timestamps gracefully', () {
      final localData = {
        'id': 'test-1',
        'name': 'Local Name',
        'updatedAt': null,
      };

      final serverData = {
        'id': 'test-1',
        'name': 'Server Name',
        'updatedAt': null,
      };

      expect(
        () => ConflictResolver.instance.detectConflict(
          localData: localData,
          serverData: serverData,
        ),
        returnsNormally,
      );
    });
  });

  group('User Profile Conflict Resolution (Last-Write-Wins)', () {
    test('selects local when local newer', () async {
      final localData = {
        'id': 'user-1',
        'name': 'Local Name',
        'email': 'local@test.com',
        'updatedAt': '2025-01-01T12:00:00Z', // Newer
      };

      final serverData = {
        'id': 'user-1',
        'name': 'Server Name',
        'email': 'server@test.com',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final winner = await ConflictResolver.instance.resolveUserProfileConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['name'], equals('Local Name'));
      expect(winner['email'], equals('local@test.com'));
    });

    test('selects server when server newer', () async {
      final localData = {
        'id': 'user-1',
        'name': 'Local Name',
        'email': 'local@test.com',
        'updatedAt': '2025-01-01T08:00:00Z',
      };

      final serverData = {
        'id': 'user-1',
        'name': 'Server Name',
        'email': 'server@test.com',
        'updatedAt': '2025-01-01T12:00:00Z', // Newer
      };

      final winner = await ConflictResolver.instance.resolveUserProfileConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['name'], equals('Server Name'));
      expect(winner['email'], equals('server@test.com'));
    });

    test('handles null timestamps by falling back to server', () async {
      final localData = {
        'id': 'user-1',
        'name': 'Local Name',
        'updatedAt': null,
      };

      final serverData = {
        'id': 'user-1',
        'name': 'Server Name',
        'updatedAt': null,
      };

      final winner = await ConflictResolver.instance.resolveUserProfileConflict(
        localData: localData,
        serverData: serverData,
      );

      // Both have epoch timestamps, server should win (same timestamp)
      expect(winner['name'], equals('Server Name'));
    });

    test('logs resolution to audit trail', () async {
      final localData = {
        'id': 'user-1',
        'name': 'Local Name',
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'user-1',
        'name': 'Server Name',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      await ConflictResolver.instance.resolveUserProfileConflict(
        localData: localData,
        serverData: serverData,
      );

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs, isNotEmpty);
      expect(logs.first['entityType'], equals('user_profile'));
      expect(logs.first['resolution'], equals('local_wins'));
    });
  });

  group('Facility Conflict Resolution (Server-Wins)', () {
    test('always selects server version', () async {
      final localData = {
        'id': 'facility-1',
        'name': 'Local Hospital',
        'address': '123 Local St',
        'updatedAt': '2025-01-01T12:00:00Z', // Even if local is newer
      };

      final serverData = {
        'id': 'facility-1',
        'name': 'Server Hospital',
        'address': '456 Server St',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final winner = await ConflictResolver.instance.resolveFacilityConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['name'], equals('Server Hospital'));
      expect(winner['address'], equals('456 Server St'));
    });

    test('logs resolution with server_wins strategy', () async {
      final localData = {
        'id': 'facility-1',
        'name': 'Local Hospital',
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'facility-1',
        'name': 'Server Hospital',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      await ConflictResolver.instance.resolveFacilityConflict(
        localData: localData,
        serverData: serverData,
      );

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs, isNotEmpty);
      expect(logs.first['entityType'], equals('facility'));
      expect(logs.first['resolution'], equals('server_wins'));
    });

    test('handles errors by returning server data', () async {
      final localData = {
        'id': 'facility-1',
        'name': 'Local Hospital',
        'updatedAt': 'invalid-date', // Invalid timestamp
      };

      final serverData = {
        'id': 'facility-1',
        'name': 'Server Hospital',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final winner = await ConflictResolver.instance.resolveFacilityConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['name'], equals('Server Hospital'));
    });
  });

  group('Assessment Conflict Resolution (Merge)', () {
    test('keeps both versions and marks local for review', () async {
      final localData = {
        'id': 'assess-1',
        'finalRiskScore': 15,
        'riskCategory': 'moderate',
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'assess-1',
        'finalRiskScore': 18,
        'riskCategory': 'high',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final resolution =
          await ConflictResolver.instance.resolveAssessmentConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(resolution.requiresManualReview, isTrue);
      expect(resolution.localVersion, isNotNull);
      expect(resolution.localVersion!['hasConflict'], isTrue);
      expect(resolution.localVersion!['conflictDetectedAt'], isNotNull);
      expect(resolution.serverVersion['finalRiskScore'], equals(18));
    });

    test('returns both versions via getBothVersions', () async {
      final localData = {
        'id': 'assess-1',
        'finalRiskScore': 15,
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'assess-1',
        'finalRiskScore': 18,
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final resolution =
          await ConflictResolver.instance.resolveAssessmentConflict(
        localData: localData,
        serverData: serverData,
      );

      final bothVersions = resolution.getBothVersions();
      expect(bothVersions.length, equals(2));
      expect(bothVersions[0]['hasConflict'], isTrue); // Local version
      expect(bothVersions[1]['finalRiskScore'], equals(18)); // Server version
    });

    test('logs merge resolution', () async {
      final localData = {
        'id': 'assess-1',
        'finalRiskScore': 15,
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'assess-1',
        'finalRiskScore': 18,
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      await ConflictResolver.instance.resolveAssessmentConflict(
        localData: localData,
        serverData: serverData,
      );

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs, isNotEmpty);
      expect(logs.first['entityType'], equals('assessment'));
      expect(logs.first['resolution'], equals('merge_both_kept'));
    });

    test('handles invalid timestamps gracefully', () async {
      final localData = {
        'id': 'assess-1',
        'finalRiskScore': 15,
        'updatedAt': 'invalid-date',
      };

      final serverData = {
        'id': 'assess-1',
        'finalRiskScore': 18,
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      // Should still work even with invalid timestamp
      final resolution =
          await ConflictResolver.instance.resolveAssessmentConflict(
        localData: localData,
        serverData: serverData,
      );

      // Assessment conflicts always keep both versions
      expect(resolution.localVersion, isNotNull);
      expect(resolution.serverVersion['finalRiskScore'], equals(18));
      expect(resolution.requiresManualReview, isTrue);
    });
  });

  group('Appointment Conflict Resolution (Context-Based)', () {
    test('server wins when status differs', () async {
      final localData = {
        'id': 'apt-1',
        'status': 'pending',
        'notes': 'Local notes',
        'updatedAt': '2025-01-01T12:00:00Z', // Even if newer
      };

      final serverData = {
        'id': 'apt-1',
        'status': 'confirmed',
        'notes': 'Server notes',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final winner = await ConflictResolver.instance.resolveAppointmentConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['status'], equals('confirmed'));
      expect(winner['notes'], equals('Server notes'));
    });

    test('last-write-wins when status same and local newer', () async {
      final localData = {
        'id': 'apt-1',
        'status': 'pending',
        'notes': 'Local notes',
        'updatedAt': '2025-01-01T12:00:00Z', // Newer
      };

      final serverData = {
        'id': 'apt-1',
        'status': 'pending',
        'notes': 'Server notes',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      final winner = await ConflictResolver.instance.resolveAppointmentConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['notes'], equals('Local notes'));
    });

    test('last-write-wins when status same and server newer', () async {
      final localData = {
        'id': 'apt-1',
        'status': 'pending',
        'notes': 'Local notes',
        'updatedAt': '2025-01-01T08:00:00Z',
      };

      final serverData = {
        'id': 'apt-1',
        'status': 'pending',
        'notes': 'Server notes',
        'updatedAt': '2025-01-01T12:00:00Z', // Newer
      };

      final winner = await ConflictResolver.instance.resolveAppointmentConflict(
        localData: localData,
        serverData: serverData,
      );

      expect(winner['notes'], equals('Server notes'));
    });

    test('logs context-based resolution', () async {
      final localData = {
        'id': 'apt-1',
        'status': 'pending',
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'apt-1',
        'status': 'confirmed',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      await ConflictResolver.instance.resolveAppointmentConflict(
        localData: localData,
        serverData: serverData,
      );

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs, isNotEmpty);
      expect(logs.first['entityType'], equals('appointment'));
      expect(logs.first['resolution'], equals('server_wins_status_conflict'));
    });
  });

  group('Manual Review Queue', () {
    test('adds conflict to manual review queue', () async {
      final conflict = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1', 'score': 15},
        serverData: {'id': 'assess-1', 'score': 18},
        timestamp: DateTime.now(),
        reason: 'Risk score differs',
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict);

      final conflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(conflicts.length, equals(1));
      expect(conflicts.first.id, equals('conflict-1'));
      expect(conflicts.first.entityType, equals('assessment'));
    });

    test('retrieves manual review conflicts', () async {
      final conflict1 = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1'},
        serverData: {'id': 'assess-1'},
        timestamp: DateTime.now(),
      );

      final conflict2 = ConflictItem(
        id: 'conflict-2',
        entityType: 'appointment',
        localData: {'id': 'apt-1'},
        serverData: {'id': 'apt-1'},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict1);
      await ConflictResolver.instance.addConflictForManualReview(conflict2);

      final conflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(conflicts.length, equals(2));
    });

    test('applies manual resolution - keep local', () async {
      final conflict = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1', 'score': 15},
        serverData: {'id': 'assess-1', 'score': 18},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict);

      final winner = await ConflictResolver.instance.applyManualResolution(
        conflictId: 'conflict-1',
        choice: ManualResolutionChoice.keepLocal,
      );

      expect(winner['score'], equals(15));

      // Should be removed from queue
      final remainingConflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(remainingConflicts.length, equals(0));
    });

    test('applies manual resolution - keep server', () async {
      final conflict = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1', 'score': 15},
        serverData: {'id': 'assess-1', 'score': 18},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict);

      final winner = await ConflictResolver.instance.applyManualResolution(
        conflictId: 'conflict-1',
        choice: ManualResolutionChoice.keepServer,
      );

      expect(winner['score'], equals(18));
    });

    test('removes conflict from manual review', () async {
      final conflict = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1'},
        serverData: {'id': 'assess-1'},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict);

      await ConflictResolver.instance
          .removeConflictFromManualReview('conflict-1');

      final conflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(conflicts.length, equals(0));
    });

    test('gets manual review count', () async {
      final conflict1 = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1'},
        serverData: {'id': 'assess-1'},
        timestamp: DateTime.now(),
      );

      final conflict2 = ConflictItem(
        id: 'conflict-2',
        entityType: 'appointment',
        localData: {'id': 'apt-1'},
        serverData: {'id': 'apt-1'},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict1);
      await ConflictResolver.instance.addConflictForManualReview(conflict2);

      final count = await ConflictResolver.instance.getManualReviewCount();
      expect(count, equals(2));
    });

    test('limits manual review queue to 50 items', () async {
      // Add 60 conflicts
      for (int i = 0; i < 60; i++) {
        final conflict = ConflictItem(
          id: 'conflict-$i',
          entityType: 'assessment',
          localData: {'id': 'assess-$i'},
          serverData: {'id': 'assess-$i'},
          timestamp: DateTime.now(),
        );
        await ConflictResolver.instance.addConflictForManualReview(conflict);
      }

      final conflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(conflicts.length, equals(50)); // Should be limited to 50
    });

    test('updates existing conflict in manual review queue', () async {
      final conflict1 = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1', 'score': 15},
        serverData: {'id': 'assess-1', 'score': 18},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict1);

      // Add again with updated data
      final conflict2 = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1', 'score': 20},
        serverData: {'id': 'assess-1', 'score': 22},
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(conflict2);

      final conflicts =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(conflicts.length, equals(1)); // Should not duplicate
      expect(conflicts.first.localData['score'], equals(20)); // Updated
    });
  });

  group('Audit Trail and Statistics', () {
    test('logs all resolutions to audit trail', () async {
      final localData = {
        'id': 'user-1',
        'name': 'Local Name',
        'updatedAt': '2025-01-01T12:00:00Z',
      };

      final serverData = {
        'id': 'user-1',
        'name': 'Server Name',
        'updatedAt': '2025-01-01T10:00:00Z',
      };

      await ConflictResolver.instance.resolveUserProfileConflict(
        localData: localData,
        serverData: serverData,
      );

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs.length, equals(1));
      expect(logs.first, containsPair('entityType', 'user_profile'));
      expect(logs.first, containsPair('resolution', 'local_wins'));
      expect(logs.first.keys, contains('timestamp'));
    });

    test('limits audit log to 100 entries', () async {
      // Add 120 conflict resolutions
      for (int i = 0; i < 120; i++) {
        await ConflictResolver.instance.resolveUserProfileConflict(
          localData: {
            'id': 'user-$i',
            'name': 'Local $i',
            'updatedAt': '2025-01-01T12:00:00Z',
          },
          serverData: {
            'id': 'user-$i',
            'name': 'Server $i',
            'updatedAt': '2025-01-01T10:00:00Z',
          },
        );
      }

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs.length, equals(100)); // Should be limited
    });

    test('clears audit log', () async {
      await ConflictResolver.instance.resolveUserProfileConflict(
        localData: {
          'id': 'user-1',
          'name': 'Local',
          'updatedAt': '2025-01-01T12:00:00Z',
        },
        serverData: {
          'id': 'user-1',
          'name': 'Server',
          'updatedAt': '2025-01-01T10:00:00Z',
        },
      );

      await ConflictResolver.instance.clearConflictLog();

      final logs = await ConflictResolver.instance.getConflictLog();
      expect(logs.length, equals(0));
    });

    test('gets conflict statistics', () async {
      // Resolve various conflicts
      await ConflictResolver.instance.resolveUserProfileConflict(
        localData: {
          'id': 'user-1',
          'updatedAt': '2025-01-01T12:00:00Z',
        },
        serverData: {
          'id': 'user-1',
          'updatedAt': '2025-01-01T10:00:00Z',
        },
      );

      await ConflictResolver.instance.resolveFacilityConflict(
        localData: {
          'id': 'facility-1',
          'updatedAt': '2025-01-01T12:00:00Z',
        },
        serverData: {
          'id': 'facility-1',
          'updatedAt': '2025-01-01T10:00:00Z',
        },
      );

      await ConflictResolver.instance.resolveAppointmentConflict(
        localData: {
          'id': 'apt-1',
          'status': 'pending',
          'updatedAt': '2025-01-01T12:00:00Z',
        },
        serverData: {
          'id': 'apt-1',
          'status': 'confirmed',
          'updatedAt': '2025-01-01T10:00:00Z',
        },
      );

      final stats = await ConflictResolver.instance.getConflictStatistics();

      expect(stats['totalConflicts'], equals(3));
      expect(stats['byEntityType']['user_profile'], equals(1));
      expect(stats['byEntityType']['facility'], equals(1));
      expect(stats['byEntityType']['appointment'], equals(1));
      expect(stats['lastConflictAt'], isNotNull);
    });

    test('returns empty statistics when no conflicts', () async {
      await ConflictResolver.instance.clearConflictLog();

      final stats = await ConflictResolver.instance.getConflictStatistics();

      expect(stats['totalConflicts'], equals(0));
      expect(stats['byEntityType'], isEmpty);
      expect(stats['lastConflictAt'], isNull);
    });

    test('gets limited conflict log', () async {
      // Add 10 conflicts
      for (int i = 0; i < 10; i++) {
        await ConflictResolver.instance.resolveUserProfileConflict(
          localData: {
            'id': 'user-$i',
            'updatedAt': '2025-01-01T12:00:00Z',
          },
          serverData: {
            'id': 'user-$i',
            'updatedAt': '2025-01-01T10:00:00Z',
          },
        );
      }

      final logs = await ConflictResolver.instance.getConflictLog(limit: 5);
      expect(logs.length, equals(5)); // Should be limited
    });
  });

  group('User Preferences', () {
    test('gets user preference for conflict resolution', () async {
      final preference =
          await ConflictResolver.instance.getUserPreference();
      expect(preference, equals(ConflictResolutionStrategy.lastWriteWins));
    });

    test('sets user preference for conflict resolution', () async {
      await ConflictResolver.instance
          .setUserPreference(ConflictResolutionStrategy.manual);

      final preference =
          await ConflictResolver.instance.getUserPreference();
      expect(preference, equals(ConflictResolutionStrategy.manual));
    });

    test('defaults to lastWriteWins on invalid preference', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conflict_resolution_preference', 'invalid_strategy');

      final preference =
          await ConflictResolver.instance.getUserPreference();
      expect(preference, equals(ConflictResolutionStrategy.lastWriteWins));
    });
  });

  group('ConflictItem Model', () {
    test('serializes and deserializes ConflictItem', () {
      final original = ConflictItem(
        id: 'conflict-1',
        entityType: 'assessment',
        localData: {'id': 'assess-1', 'score': 15},
        serverData: {'id': 'assess-1', 'score': 18},
        timestamp: DateTime.parse('2025-01-01T12:00:00Z'),
        reason: 'Score differs',
      );

      final json = original.toJson();
      final deserialized = ConflictItem.fromJson(json);

      expect(deserialized.id, equals(original.id));
      expect(deserialized.entityType, equals(original.entityType));
      expect(deserialized.localData['score'], equals(15));
      expect(deserialized.serverData['score'], equals(18));
      expect(deserialized.reason, equals('Score differs'));
    });

    test('gets correct icon for entity type', () {
      final userConflict = ConflictItem(
        id: 'c1',
        entityType: 'user_profile',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );

      final facilityConflict = ConflictItem(
        id: 'c2',
        entityType: 'facility',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );

      final assessmentConflict = ConflictItem(
        id: 'c3',
        entityType: 'assessment',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );

      final appointmentConflict = ConflictItem(
        id: 'c4',
        entityType: 'appointment',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );

      expect(userConflict.getIcon(), equals(Icons.person));
      expect(facilityConflict.getIcon(), equals(Icons.local_hospital));
      expect(assessmentConflict.getIcon(), equals(Icons.monitor_heart));
      expect(appointmentConflict.getIcon(), equals(Icons.calendar_today));
    });

    test('gets differences between local and server data', () {
      final conflict = ConflictItem(
        id: 'c1',
        entityType: 'assessment',
        localData: {
          'id': 'assess-1',
          'score': 15,
          'category': 'moderate',
          'updatedAt': '2025-01-01T12:00:00Z',
        },
        serverData: {
          'id': 'assess-1',
          'score': 18,
          'category': 'high',
          'updatedAt': '2025-01-01T10:00:00Z',
        },
        timestamp: DateTime.now(),
      );

      final differences = conflict.getDifferences();

      expect(differences.length, equals(2)); // score and category differ
      expect(differences.any((d) => d.field == 'score'), isTrue);
      expect(differences.any((d) => d.field == 'category'), isTrue);
      expect(
          differences.any((d) => d.field == 'updatedAt'), isFalse); // Metadata filtered
    });
  });
}
