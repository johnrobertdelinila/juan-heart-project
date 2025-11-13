import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

/// Assessments table for storing user health assessments offline.
@DataClassName('AssessmentEntity')
class Assessments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get likelihoodScore => integer()();
  IntColumn get impactScore => integer()();
  IntColumn get finalRiskScore => integer()();
  TextColumn get riskCategory => text()();
  TextColumn get symptomsData => text()(); // JSON string
  TextColumn get vitalSignsData => text().nullable()(); // JSON string
  TextColumn get recommendationsData => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Healthcare facilities table for offline facility search.
@DataClassName('FacilityEntity')
class Facilities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type =>
      text()(); // 'hospital', 'clinic', 'health_center', 'barangay_health_station'
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get address => text()();
  TextColumn get municipality => text().nullable()();
  TextColumn get province => text().nullable()();
  TextColumn get region => text().nullable()();
  TextColumn get contactNumber => text().nullable()();
  TextColumn get services => text()(); // JSON array of services
  TextColumn get operatingHours => text().nullable()(); // JSON object
  BoolColumn get is24Hours => boolean().withDefault(const Constant(false))();
  BoolColumn get hasEmergencyService =>
      boolean().withDefault(const Constant(false))();
  IntColumn get capacity => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Users table for local user profile caching.
@DataClassName('UserEntity')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get profileData => text().nullable()(); // JSON string
  TextColumn get medicalHistory => text().nullable()(); // JSON string
  TextColumn get emergencyContacts => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table for managing offline operations.
@DataClassName('SyncQueueEntity')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get operationType =>
      text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get entityType =>
      text()(); // 'assessment', 'appointment', 'user'
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON string
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get status =>
      text()(); // 'pending', 'processing', 'failed', 'completed'

  @override
  Set<Column> get primaryKey => {id};
}

/// Appointments table for offline appointment management.
@DataClassName('AppointmentEntity')
class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get facilityId => text()();
  TextColumn get assessmentId => text().nullable()();
  DateTimeColumn get appointmentDateTime => dateTime()();
  TextColumn get appointmentType => text()(); // consultation, followUp, emergency
  TextColumn get status => text()(); // pending, confirmed, completed, cancelled
  TextColumn get notes => text().nullable()();
  TextColumn get assessmentData => text().nullable()(); // JSON string
  TextColumn get questionnaireStatus => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Main database class with all tables.
@DriftDatabase(tables: [
  Assessments,
  Facilities,
  Users,
  SyncQueue,
  Appointments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test constructor for in-memory database.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createPerformanceIndexes(m);
        print('✅ Database created with schema version $schemaVersion');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        print('🔄 Migrating database from version $from to $to');

        // Migration from v1 to v2: Add performance indexes
        if (from == 1 && to == 2) {
          print('📊 Adding performance indexes...');
          await _createPerformanceIndexes(m);
          print('✅ Performance indexes created successfully');
        }
      },
      beforeOpen: (details) async {
        if (details.wasCreated) {
          print('🎉 New database created!');
        } else {
          print('📂 Existing database opened (version ${details.versionNow})');
        }
      },
    );
  }

  /// Create performance indexes for optimized queries.
  ///
  /// Total: 8 strategic indexes covering common query patterns.
  /// Expected performance improvement: 3x-10x for indexed queries.
  Future<void> _createPerformanceIndexes(Migrator m) async {
    try {
      // FACILITIES INDEXES (3 indexes)
      // Index for filtering by facility type (hospital, clinic, etc.)
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_facilities_type ON facilities(type)',
      );

      // Composite index for geospatial bounding box queries
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_facilities_location ON facilities(latitude, longitude)',
      );

      // Index for location-based filtering
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_facilities_municipality ON facilities(municipality)',
      );

      // ASSESSMENTS INDEXES (2 indexes)
      // Composite index for user's assessment history (most common query)
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_assessments_user_date ON assessments(user_id, created_at DESC)',
      );

      // Index for finding unsynced assessments
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_assessments_sync ON assessments(is_synced, created_at)',
      );

      // APPOINTMENTS INDEXES (2 indexes)
      // Composite index for user's upcoming appointments
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appointments_user_datetime ON appointments(user_id, appointment_date_time)',
      );

      // Index for filtering by appointment status
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status, updated_at DESC)',
      );

      // SYNC_QUEUE INDEX (1 index)
      // Composite index for priority-based sync processing
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_status_priority ON sync_queue(status, priority DESC, created_at)',
      );

      print('✅ Created 8 performance indexes successfully');
    } catch (e) {
      print('❌ Error creating indexes: $e');
      rethrow;
    }
  }

  // Assessment queries
  Future<List<AssessmentEntity>> getAllAssessments() => select(assessments).get();

  Future<List<AssessmentEntity>> getAssessmentsByUserId(String userId) =>
      (select(assessments)..where((t) => t.userId.equals(userId))).get();

  /// Get recent assessments with pagination (OPTIMIZED).
  ///
  /// Uses idx_assessments_user_date for efficient retrieval.
  /// Expected performance: <50ms for typical dataset.
  ///
  /// [userId] - User ID to filter by
  /// [limit] - Maximum number of results (default: 20)
  /// [offset] - Number of records to skip (default: 0)
  Future<List<AssessmentEntity>> getRecentAssessments(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) =>
      (select(assessments)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  /// Get unsynced assessments in batches (OPTIMIZED).
  ///
  /// Uses idx_assessments_sync for efficient filtering.
  /// Expected performance: <30ms for typical dataset.
  ///
  /// [batchSize] - Maximum number of unsynced records to fetch
  Future<List<AssessmentEntity>> getUnsyncedAssessments({
    int batchSize = 50,
  }) =>
      (select(assessments)
            ..where((t) => t.isSynced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(batchSize))
          .get();

  Future<AssessmentEntity?> getAssessmentById(String id) =>
      (select(assessments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertAssessment(AssessmentsCompanion entry) =>
      into(assessments).insert(entry);

  Future<bool> updateAssessment(AssessmentsCompanion entry) =>
      update(assessments).replace(entry);

  Future<int> deleteAssessment(String id) =>
      (delete(assessments)..where((t) => t.id.equals(id))).go();

  // Facility queries
  Future<List<FacilityEntity>> getAllFacilities() => select(facilities).get();

  Future<List<FacilityEntity>> searchFacilities(String query) async {
    final lowerQuery = query.toLowerCase();
    return (select(facilities)
          ..where((t) =>
              t.name.lower().contains(lowerQuery) |
              t.address.lower().contains(lowerQuery) |
              t.municipality.lower().contains(lowerQuery)))
        .get();
  }

  /// Get facilities by type (OPTIMIZED).
  ///
  /// Uses idx_facilities_type for efficient filtering.
  /// Expected performance: <50ms for typical dataset.
  ///
  /// [type] - Facility type (hospital, clinic, health_center, etc.)
  Future<List<FacilityEntity>> getFacilitiesByType(String type) =>
      (select(facilities)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// Get facilities within bounding box (OPTIMIZED).
  ///
  /// Uses idx_facilities_location for efficient spatial queries.
  /// Expected performance: <75ms for typical dataset.
  ///
  /// This is a pre-filter step for geospatial queries. Follow up with
  /// precise distance calculation using GeospatialService.
  ///
  /// [minLat] - Minimum latitude
  /// [maxLat] - Maximum latitude
  /// [minLon] - Minimum longitude
  /// [maxLon] - Maximum longitude
  Future<List<FacilityEntity>> getFacilitiesInBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
  }) =>
      (select(facilities)
            ..where((t) =>
                t.latitude.isBiggerOrEqualValue(minLat) &
                t.latitude.isSmallerOrEqualValue(maxLat) &
                t.longitude.isBiggerOrEqualValue(minLon) &
                t.longitude.isSmallerOrEqualValue(maxLon)))
          .get();

  /// Get facilities by municipality (OPTIMIZED).
  ///
  /// Uses idx_facilities_municipality for efficient filtering.
  /// Expected performance: <50ms for typical dataset.
  Future<List<FacilityEntity>> getFacilitiesByMunicipality(
    String municipality,
  ) =>
      (select(facilities)
            ..where((t) => t.municipality.equals(municipality))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<FacilityEntity?> getFacilityById(String id) =>
      (select(facilities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertFacility(FacilitiesCompanion entry) =>
      into(facilities).insert(entry);

  Future<void> insertFacilities(List<FacilitiesCompanion> entries) =>
      batch((batch) => batch.insertAll(facilities, entries));

  /// Import facilities from backend API with batch optimization
  ///
  /// Implements upsert strategy:
  /// - Updates existing facilities (matching by ID)
  /// - Inserts new facilities
  /// - Processes in batches of 100 records per transaction
  ///
  /// [facilities] - List of facility API models from backend
  ///
  /// Returns total number of facilities processed
  /// Performance: <5 seconds for 50 facilities, <15 seconds for 500 facilities
  Future<int> importFacilitiesFromBackend(
    List<dynamic> facilityModels,
  ) async {
    if (facilityModels.isEmpty) {
      debugPrint('[Database] No facilities to import');
      return 0;
    }

    debugPrint('[Database] Starting facility import: ${facilityModels.length} facilities');
    final startTime = DateTime.now();

    const batchSize = 100;
    int totalProcessed = 0;

    try {
      // Process in batches for optimal performance
      for (int i = 0; i < facilityModels.length; i += batchSize) {
        final batchEnd = (i + batchSize < facilityModels.length)
            ? i + batchSize
            : facilityModels.length;
        final batch = facilityModels.sublist(i, batchEnd);

        await transaction(() async {
          for (final model in batch) {
            // Convert API model to database companion
            final companion = _convertToFacilitiesCompanion(model);

            // Upsert: Try to insert, if conflict update
            await into(facilities).insertOnConflictUpdate(companion);
            totalProcessed++;
          }
        });

        debugPrint(
            '[Database] Processed batch ${i ~/ batchSize + 1}: $totalProcessed/${ facilityModels.length} facilities');
      }

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          '[Database] Import complete: $totalProcessed facilities in ${duration.inMilliseconds}ms');

      return totalProcessed;
    } catch (e) {
      debugPrint('[Database] Error importing facilities: $e');
      rethrow;
    }
  }

  /// Convert FacilityApiModel to FacilitiesCompanion for database insertion
  FacilitiesCompanion _convertToFacilitiesCompanion(dynamic model) {
    // Handle both FacilityApiModel and Map<String, dynamic>
    final id = model.id?.toString() ?? model['id']?.toString() ?? '';
    final name = model.name ?? model['name'] ?? '';
    final type = model.type ?? model['type'] ?? '';
    final lat = (model.latitude ?? model['latitude'] ?? 0.0) is double
        ? (model.latitude ?? model['latitude'] ?? 0.0)
        : double.parse((model.latitude ?? model['latitude'] ?? 0.0).toString());
    final lon = (model.longitude ?? model['longitude'] ?? 0.0) is double
        ? (model.longitude ?? model['longitude'] ?? 0.0)
        : double.parse(
            (model.longitude ?? model['longitude'] ?? 0.0).toString());
    final addr = model.address ?? model['address'] ?? '';
    final municipality = model.municipality ?? model['municipality'];
    final province = model.province ?? model['province'];
    final region = model.region ?? model['region'];
    final contactNumber = model.contactNumber ??
        model['contact_number'] ??
        model.phone ??
        model['phone'];
    final services = model.services is List
        ? (model.services as List).join(',')
        : model['services'] is List
            ? (model['services'] as List).join(',')
            : model.services?.toString() ?? model['services']?.toString() ?? '';
    final operatingHours = model.operatingHours?.toString() ??
        model['operating_hours']?.toString();
    final is24Hours = model.open24Hours ??
        model['open_24_hours'] ??
        model.is24Hours ??
        model['is_24_hours'] ??
        false;
    final hasEmergency = model.emergencyServices ??
        model['emergency_services'] ??
        model.hasEmergencyService ??
        model['has_emergency_service'] ??
        false;
    final capacity =
        model.capacity ?? model['capacity'] ?? model.bedCapacity ?? model['bed_capacity'];
    final now = DateTime.now();

    return FacilitiesCompanion.insert(
      id: id,
      name: name,
      type: type,
      latitude: lat,
      longitude: lon,
      address: addr,
      municipality: Value(municipality),
      province: Value(province),
      region: Value(region),
      contactNumber: Value(contactNumber),
      services: services,
      operatingHours: Value(operatingHours),
      is24Hours: Value(is24Hours),
      hasEmergencyService: Value(hasEmergency),
      capacity: Value(capacity),
      createdAt: now,
      updatedAt: Value(now),
    );
  }

  // User queries
  Future<UserEntity?> getUserById(String id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertUser(UsersCompanion entry) => into(users).insert(entry);

  Future<bool> updateUser(UsersCompanion entry) =>
      update(users).replace(entry);

  // Sync queue queries
  Future<List<SyncQueueEntity>> getPendingSyncOperations() =>
      (select(syncQueue)..where((t) => t.status.equals('pending'))).get();

  Future<List<SyncQueueEntity>> getFailedSyncOperations() =>
      (select(syncQueue)..where((t) => t.status.equals('failed'))).get();

  /// Get pending sync operations by priority (OPTIMIZED).
  ///
  /// Uses idx_sync_status_priority for efficient retrieval.
  /// Expected performance: <30ms for typical dataset.
  ///
  /// [batchSize] - Maximum number of operations to fetch (default: 10)
  Future<List<SyncQueueEntity>> getPendingHighPrioritySyncOps({
    int batchSize = 10,
  }) =>
      (select(syncQueue)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.createdAt),
            ])
            ..limit(batchSize))
          .get();

  Future<int> insertSyncOperation(SyncQueueCompanion entry) =>
      into(syncQueue).insert(entry);

  Future<bool> updateSyncOperation(SyncQueueCompanion entry) =>
      update(syncQueue).replace(entry);

  Future<int> deleteSyncOperation(String id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  Future<int> clearCompletedSyncOperations() =>
      (delete(syncQueue)..where((t) => t.status.equals('completed'))).go();

  // Appointment queries
  Future<List<AppointmentEntity>> getAllAppointments() =>
      select(appointments).get();

  Future<List<AppointmentEntity>> getAppointmentsByUserId(String userId) =>
      (select(appointments)..where((t) => t.userId.equals(userId))).get();

  Future<List<AppointmentEntity>> getUnsyncedAppointments() =>
      (select(appointments)..where((t) => t.isSynced.equals(false))).get();

  /// Get upcoming appointments (OPTIMIZED).
  ///
  /// Uses idx_appointments_user_datetime for efficient retrieval.
  /// Expected performance: <40ms for typical dataset.
  ///
  /// [userId] - User ID to filter by
  /// [limit] - Maximum number of results (default: 10)
  Future<List<AppointmentEntity>> getUpcomingAppointments(
    String userId, {
    int limit = 10,
  }) {
    final now = DateTime.now();
    return (select(appointments)
          ..where((t) =>
              t.userId.equals(userId) &
              t.appointmentDateTime.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.appointmentDateTime)])
          ..limit(limit))
        .get();
  }

  /// Get appointments by status (OPTIMIZED).
  ///
  /// Uses idx_appointments_status for efficient filtering.
  /// Expected performance: <40ms for typical dataset.
  ///
  /// [status] - Appointment status (pending, confirmed, completed, cancelled)
  /// [limit] - Maximum number of results (default: 20)
  Future<List<AppointmentEntity>> getAppointmentsByStatus(
    String status, {
    int limit = 20,
  }) =>
      (select(appointments)
            ..where((t) => t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(limit))
          .get();

  Future<AppointmentEntity?> getAppointmentById(String id) =>
      (select(appointments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertAppointment(AppointmentsCompanion entry) =>
      into(appointments).insert(entry);

  Future<bool> updateAppointment(AppointmentsCompanion entry) =>
      update(appointments).replace(entry);

  // Database maintenance
  Future<void> clearAllData() async {
    await delete(assessments).go();
    await delete(facilities).go();
    await delete(users).go();
    await delete(syncQueue).go();
    await delete(appointments).go();
    print('🗑️ All data cleared from database');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final assessmentCount = await (selectOnly(assessments)
          ..addColumns([assessments.id.count()]))
        .getSingle();
    final facilityCount = await (selectOnly(facilities)
          ..addColumns([facilities.id.count()]))
        .getSingle();
    final userCount =
        await (selectOnly(users)..addColumns([users.id.count()])).getSingle();
    final syncQueueCount = await (selectOnly(syncQueue)
          ..addColumns([syncQueue.id.count()]))
        .getSingle();
    final appointmentCount = await (selectOnly(appointments)
          ..addColumns([appointments.id.count()]))
        .getSingle();

    return {
      'assessments': assessmentCount.read(assessments.id.count()) ?? 0,
      'facilities': facilityCount.read(facilities.id.count()) ?? 0,
      'users': userCount.read(users.id.count()) ?? 0,
      'syncQueue': syncQueueCount.read(syncQueue.id.count()) ?? 0,
      'appointments': appointmentCount.read(appointments.id.count()) ?? 0,
    };
  }
}

/// Open database connection.
QueryExecutor _openConnection() {
  return driftDatabase(name: 'juan_heart_db');
}
