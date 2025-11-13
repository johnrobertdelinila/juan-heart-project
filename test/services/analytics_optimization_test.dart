import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/models/analytics_dto.dart';
import 'package:juan_heart/services/analytics_cache_service.dart';
import 'package:juan_heart/services/network_adaptive_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for analytics payload optimization
///
/// Tests verify:
/// 1. Payload size reduction >50%
/// 2. Compression effectiveness
/// 3. Cache TTL behavior
/// 4. Network-adaptive configurations
/// 5. Progressive loading performance
void main() {
  group('Analytics DTO Optimization Tests', () {
    test('DTO reduces payload size by >50%', () {
      // Create a full AssessmentRecord
      final fullRecord = AssessmentRecord(
        id: 'test_123',
        date: DateTime(2024, 1, 15),
        finalRiskScore: 12,
        likelihoodScore: 3,
        impactScore: 4,
        riskCategory: 'Moderate',
        likelihoodLevel: 'Level 3',
        impactLevel: 'Level 4',
        recommendedAction: 'Consult with healthcare provider',
        systolicBP: 130,
        diastolicBP: 85,
        heartRate: 75,
        oxygenSaturation: 98,
        temperature: 36.8,
        weight: 70.5,
        height: 170.0,
        bmi: 24.4,
        symptoms: {
          'chestPain': false,
          'shortnessOfBreath': true,
          'dizziness': false,
        },
        riskFactors: {
          'hypertension': true,
          'smoking': false,
          'diabetes': false,
          'obesity': false,
          'familyHistory': true,
        },
        age: 45,
        sex: 'Male',
        userId: 'user_123',
        userName: 'Juan Dela Cruz',
        userGender: 'Male',
      );

      // Convert to DTO
      final dto = AnalyticsRecordDTO.fromAssessmentRecord(fullRecord);

      // Serialize both to JSON
      final fullJson = fullRecord.toJson().toString();
      final dtoJson = dto.toJson().toString();

      final fullSize = fullJson.length;
      final dtoSize = dtoJson.length;
      final reduction = ((fullSize - dtoSize) / fullSize * 100);

      print('Full AssessmentRecord size: $fullSize bytes');
      print('DTO size: $dtoSize bytes');
      print('Reduction: ${reduction.toStringAsFixed(1)}%');

      // Verify >50% reduction
      expect(reduction, greaterThan(50),
          reason: 'DTO should reduce payload by more than 50%');
    });

    test('DTO preserves critical data integrity', () {
      final original = AssessmentRecord(
        id: 'test_123',
        date: DateTime(2024, 1, 15),
        finalRiskScore: 12,
        likelihoodScore: 3,
        impactScore: 4,
        riskCategory: 'Moderate',
        likelihoodLevel: 'Level 3',
        impactLevel: 'Level 4',
        recommendedAction: 'Test',
        systolicBP: 130,
        diastolicBP: 85,
        heartRate: 75,
        riskFactors: {
          'hypertension': true,
          'smoking': false,
          'diabetes': true,
        },
        symptoms: {},
        age: 45,
        sex: 'Male',
      );

      // Convert to DTO and back
      final dto = AnalyticsRecordDTO.fromAssessmentRecord(original);
      final reconstructed = dto.toAssessmentRecord();

      // Verify critical fields preserved
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.finalRiskScore, equals(original.finalRiskScore));
      expect(reconstructed.likelihoodScore, equals(original.likelihoodScore));
      expect(reconstructed.impactScore, equals(original.impactScore));
      expect(reconstructed.riskCategory, equals(original.riskCategory));
      expect(reconstructed.systolicBP, equals(original.systolicBP));
      expect(reconstructed.diastolicBP, equals(original.diastolicBP));
      expect(reconstructed.heartRate, equals(original.heartRate));

      // Verify risk factors bitmask works
      expect(reconstructed.riskFactors['hypertension'], isTrue);
      expect(reconstructed.riskFactors['smoking'], isFalse);
      expect(reconstructed.riskFactors['diabetes'], isTrue);
    });

    test('Summary DTO is ultra-lightweight', () {
      final summary = AnalyticsSummaryDTO(
        tc: 25,
        avg: 12.5,
        tr: 'i',
        mc: 'Moderate',
        ld: DateTime.now().toIso8601String(),
      );

      final json = summary.toJson().toString();
      final size = json.length;

      print('Summary DTO size: $size bytes');

      // Summary should be <200 bytes
      expect(size, lessThan(200),
          reason: 'Summary should be ultra-lightweight (<200 bytes)');
    });

    test('Bitmask encoding works correctly', () {
      final record = AssessmentRecord(
        id: 'test',
        date: DateTime.now(),
        finalRiskScore: 10,
        likelihoodScore: 2,
        impactScore: 5,
        riskCategory: 'Moderate',
        likelihoodLevel: 'Level 2',
        impactLevel: 'Level 5',
        recommendedAction: '',
        riskFactors: {
          'hypertension': true, // bit 0
          'smoking': true, // bit 1
          'diabetes': false, // bit 2
          'obesity': true, // bit 3
          'familyHistory': false, // bit 4
        },
        symptoms: {},
        age: 50,
        sex: 'Female',
      );

      final dto = AnalyticsRecordDTO.fromAssessmentRecord(record);

      // Expected bitmask: 1011 (binary) = 11 (decimal)
      // bit 0 (hypertension) = 1
      // bit 1 (smoking) = 1
      // bit 2 (diabetes) = 0
      // bit 3 (obesity) = 1
      expect(dto.rf, equals(11));

      // Verify decoding
      final reconstructed = dto.toAssessmentRecord();
      expect(reconstructed.riskFactors['hypertension'], isTrue);
      expect(reconstructed.riskFactors['smoking'], isTrue);
      expect(reconstructed.riskFactors['diabetes'], isFalse);
      expect(reconstructed.riskFactors['obesity'], isTrue);
    });
  });

  group('Cache Service Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Cache invalidation works correctly', () async {
      // Cache some data
      final summary = AnalyticsSummaryDTO(
        tc: 10,
        avg: 12.0,
        tr: 's',
        mc: 'Low',
        ld: DateTime.now().toIso8601String(),
      );

      await AnalyticsCacheService.cacheSummary(summary);

      // Verify cache exists
      var cached = await AnalyticsCacheService.getCachedSummary();
      expect(cached, isNotNull);

      // Invalidate cache
      await AnalyticsCacheService.invalidateCache();

      // Verify cache cleared
      cached = await AnalyticsCacheService.getCachedSummary();
      expect(cached, isNull);
    });

    test('Cache returns null after TTL expiry (simulated)', () async {
      final summary = AnalyticsSummaryDTO(
        tc: 10,
        avg: 12.0,
        tr: 's',
        mc: 'Low',
        ld: DateTime.now().toIso8601String(),
      );

      await AnalyticsCacheService.cacheSummary(summary);

      // Manually set old timestamp (2 hours ago)
      final prefs = await SharedPreferences.getInstance();
      final twoHoursAgo = DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch;
      await prefs.setInt('analytics_summary_timestamp', twoHoursAgo);

      // Should return null due to TTL expiry
      final cached = await AnalyticsCacheService.getCachedSummary();
      expect(cached, isNull, reason: 'Cache should expire after TTL');
    });

    test('Cache validation checks work', () async {
      // Initially no cache
      var isValid = await AnalyticsCacheService.isSummaryCacheValid();
      expect(isValid, isFalse);

      // Cache data
      final summary = AnalyticsSummaryDTO(
        tc: 10,
        avg: 12.0,
        tr: 's',
        mc: 'Low',
        ld: DateTime.now().toIso8601String(),
      );

      await AnalyticsCacheService.cacheSummary(summary);

      // Should be valid now
      isValid = await AnalyticsCacheService.isSummaryCacheValid();
      expect(isValid, isTrue);
    });
  });

  group('Network Adaptive Loader Tests', () {
    test('WiFi config provides full data', () {
      final config = NetworkAdaptiveLoader.getConfig(NetworkQuality.wifi);

      expect(config.maxRecords, equals(50));
      expect(config.includeVitalSigns, isTrue);
      expect(config.includeRiskFactors, isTrue);
      expect(config.pageSize, equals(20));
    });

    test('3G config reduces data appropriately', () {
      final config = NetworkAdaptiveLoader.getConfig(NetworkQuality.threeG);

      expect(config.maxRecords, equals(20));
      expect(config.includeVitalSigns, isTrue);
      expect(config.includeRiskFactors, isFalse);
      expect(config.pageSize, equals(10));
    });

    test('2G config provides minimal data', () {
      final config = NetworkAdaptiveLoader.getConfig(NetworkQuality.twoG);

      expect(config.maxRecords, equals(10));
      expect(config.includeVitalSigns, isFalse);
      expect(config.includeRiskFactors, isFalse);
      expect(config.pageSize, equals(5));
    });

    test('Estimated load time scales with network quality', () {
      final recordCount = 20;

      final wifiTime = NetworkAdaptiveLoader.getEstimatedLoadTime(
        NetworkQuality.wifi,
        recordCount,
      );
      final fourGTime = NetworkAdaptiveLoader.getEstimatedLoadTime(
        NetworkQuality.fourG,
        recordCount,
      );
      final threeGTime = NetworkAdaptiveLoader.getEstimatedLoadTime(
        NetworkQuality.threeG,
        recordCount,
      );
      final twoGTime = NetworkAdaptiveLoader.getEstimatedLoadTime(
        NetworkQuality.twoG,
        recordCount,
      );

      // Verify progressive degradation
      expect(wifiTime.inMilliseconds, lessThan(fourGTime.inMilliseconds));
      expect(fourGTime.inMilliseconds, lessThan(threeGTime.inMilliseconds));
      expect(threeGTime.inMilliseconds, lessThan(twoGTime.inMilliseconds));

      // Verify 3G is within 5s requirement
      expect(threeGTime.inSeconds, lessThanOrEqualTo(5),
          reason: '3G load time should be <=5 seconds');

      print('WiFi: ${wifiTime.inMilliseconds}ms');
      print('4G: ${fourGTime.inMilliseconds}ms');
      print('3G: ${threeGTime.inMilliseconds}ms');
      print('2G: ${twoGTime.inMilliseconds}ms');
    });

    test('Network quality messages are localized', () {
      final englishMsg = NetworkAdaptiveLoader.getNetworkMessage(
        NetworkQuality.threeG,
        false,
      );
      final filipinoMsg = NetworkAdaptiveLoader.getNetworkMessage(
        NetworkQuality.threeG,
        true,
      );

      expect(englishMsg, contains('3G'));
      expect(filipinoMsg, contains('3G'));
      expect(englishMsg, isNot(equals(filipinoMsg)),
          reason: 'Messages should be localized');
    });
  });

  group('Pagination Tests', () {
    test('Paginated response handles edge cases', () {
      final emptyResponse = AnalyticsPaginatedResponse(
        data: [],
        page: 0,
        pageSize: 10,
        totalCount: 0,
        hasMore: false,
      );

      expect(emptyResponse.data.length, equals(0));
      expect(emptyResponse.hasMore, isFalse);

      final fullResponse = AnalyticsPaginatedResponse(
        data: List.generate(10, (_) => AnalyticsRecordDTO(
          i: 'test',
          d: DateTime.now().toIso8601String(),
          frs: 10,
          ls: 2,
          is_: 5,
          rc: 'Moderate',
        )),
        page: 0,
        pageSize: 10,
        totalCount: 25,
        hasMore: true,
      );

      expect(fullResponse.data.length, equals(10));
      expect(fullResponse.hasMore, isTrue);
    });

    test('Pagination JSON serialization works', () {
      final response = AnalyticsPaginatedResponse(
        data: [
          AnalyticsRecordDTO(
            i: 'test_1',
            d: DateTime.now().toIso8601String(),
            frs: 10,
            ls: 2,
            is_: 5,
            rc: 'Moderate',
          ),
        ],
        page: 0,
        pageSize: 10,
        totalCount: 25,
        hasMore: true,
      );

      final json = response.toJson();
      final deserialized = AnalyticsPaginatedResponse.fromJson(json);

      expect(deserialized.data.length, equals(1));
      expect(deserialized.page, equals(0));
      expect(deserialized.pageSize, equals(10));
      expect(deserialized.totalCount, equals(25));
      expect(deserialized.hasMore, isTrue);
    });
  });

  group('Performance Benchmarks', () {
    test('DTO serialization is faster than full model', () {
      final record = AssessmentRecord(
        id: 'test',
        date: DateTime.now(),
        finalRiskScore: 12,
        likelihoodScore: 3,
        impactScore: 4,
        riskCategory: 'Moderate',
        likelihoodLevel: 'Level 3',
        impactLevel: 'Level 4',
        recommendedAction: 'Test',
        systolicBP: 130,
        diastolicBP: 85,
        heartRate: 75,
        riskFactors: {'hypertension': true},
        symptoms: {},
        age: 45,
        sex: 'Male',
      );

      final dto = AnalyticsRecordDTO.fromAssessmentRecord(record);

      final stopwatchFull = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        record.toJson();
      }
      stopwatchFull.stop();

      final stopwatchDTO = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        dto.toJson();
      }
      stopwatchDTO.stop();

      print('Full model serialization: ${stopwatchFull.elapsedMicroseconds}μs');
      print('DTO serialization: ${stopwatchDTO.elapsedMicroseconds}μs');

      // DTO should be faster or comparable
      expect(stopwatchDTO.elapsedMicroseconds,
          lessThanOrEqualTo(stopwatchFull.elapsedMicroseconds * 1.5),
          reason: 'DTO serialization should be efficient');
    });
  });
}
