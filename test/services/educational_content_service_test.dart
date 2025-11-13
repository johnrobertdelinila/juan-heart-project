import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/database/content_box.dart';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.documentsPath);
  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  late EducationalContentService service;
  late Directory testDir;
  late PathProviderPlatform previousPathProvider;

  setUpAll(() async {
    // Initialize Hive for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    testDir = Directory.systemTemp.createTempSync('educational_content_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPathProvider(testDir.path);
    await Hive.initFlutter(testDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EducationalContentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ContentCategoryAdapter());
    }
  });

  setUp(() async {
    service = EducationalContentService.instance;
    await service.initialize();
  });

  tearDown(() async {
    // Clear cache after each test
    await ContentBox.instance.clearCache();
  });

  tearDownAll(() async {
    // Clean up Hive
    await Hive.close();
    testDir.deleteSync(recursive: true);
    PathProviderPlatform.instance = previousPathProvider;
  });

  group('EducationalContentService - Initialization', () {
    test('initialize loads sample content when cache is empty', () async {
      final cachedCount = await ContentBox.instance.getCachedCount();

      // Should have loaded sample content (10 articles)
      expect(cachedCount, greaterThan(0));
      expect(cachedCount, equals(10));
    });

    test('initialize does not reload content if cache has data', () async {
      // Get initial count
      final initialCount = await ContentBox.instance.getCachedCount();

      // Re-initialize
      await service.initialize();

      // Count should remain the same
      final finalCount = await ContentBox.instance.getCachedCount();
      expect(finalCount, equals(initialCount));
    });
  });

  group('EducationalContentService - Content Retrieval', () {
    test('getAllCachedContent returns all content', () async {
      final allContent = await service.getAllCachedContent();

      expect(allContent, isNotEmpty);
      expect(allContent.length, greaterThanOrEqualTo(10));
    });

    test('getContent returns specific article by ID', () async {
      final allContent = await service.getAllCachedContent();
      final firstArticle = allContent.first;

      final retrievedArticle = await service.getContent(firstArticle.id);

      expect(retrievedArticle, isNotNull);
      expect(retrievedArticle!.id, equals(firstArticle.id));
      expect(retrievedArticle.titleEn, equals(firstArticle.titleEn));
    });

    test('getContent returns null for non-existent ID', () async {
      final nonExistent = await service.getContent('non-existent-id-999');

      expect(nonExistent, isNull);
    });

    test('getByCategory filters content correctly', () async {
      final cvdContent = await service.getByCategory(ContentCategory.cvdPrevention);

      expect(cvdContent, isNotEmpty);

      // All results should be CVD Prevention category
      for (final content in cvdContent) {
        expect(content.category, equals(ContentCategory.cvdPrevention));
      }
    });

    test('getByCategory returns different results for different categories', () async {
      final cvdContent = await service.getByCategory(ContentCategory.cvdPrevention);
      final symptomContent = await service.getByCategory(ContentCategory.symptomRecognition);

      // Should have content in both categories
      expect(cvdContent, isNotEmpty);
      expect(symptomContent, isNotEmpty);

      // Should be different lists
      expect(cvdContent.length, isNot(equals(symptomContent.length)));
    });
  });

  group('EducationalContentService - Search Functionality', () {
    test('searchContent returns all content for empty query', () async {
      final allContent = await service.getAllCachedContent();
      final searchResults = await service.searchContent('');

      expect(searchResults.length, equals(allContent.length));
    });

    test('searchContent finds content by title (English)', () async {
      final results = await service.searchContent('heart');

      expect(results, isNotEmpty);

      // At least one result should have "heart" in title
      final hasHeartInTitle = results.any((content) =>
          content.titleEn.toLowerCase().contains('heart'));
      expect(hasHeartInTitle, isTrue);
    });

    test('searchContent finds content by title (Filipino)', () async {
      final results = await service.searchContent('puso');

      expect(results, isNotEmpty);

      // At least one result should have "puso" in Filipino title
      final hasPusoInTitle = results.any((content) =>
          content.titleFil.toLowerCase().contains('puso'));
      expect(hasPusoInTitle, isTrue);
    });

    test('searchContent finds content by summary', () async {
      final results = await service.searchContent('activity');

      expect(results, isNotEmpty);

      // At least one result should mention the keyword in summary
      final hasInSummary = results.any((content) =>
          content.summaryEn.toLowerCase().contains('activity') ||
          content.summaryFil.toLowerCase().contains('activity'));
      expect(hasInSummary, isTrue);
    });

    test('searchContent finds content by tags', () async {
      final results = await service.searchContent('cvd');

      expect(results, isNotEmpty);

      // At least one result should have "cvd" in tags
      final hasInTags = results.any((content) =>
          content.tags.any((tag) => tag.toLowerCase().contains('cvd')));
      expect(hasInTags, isTrue);
    });

    test('searchContent is case-insensitive', () async {
      final resultsLower = await service.searchContent('heart');
      final resultsUpper = await service.searchContent('HEART');
      final resultsMixed = await service.searchContent('HeArT');

      expect(resultsLower.length, equals(resultsUpper.length));
      expect(resultsLower.length, equals(resultsMixed.length));
    });

    test('searchContent returns empty for nonsense query', () async {
      final results = await service.searchContent('xyzqwerty123456');

      // Likely no matches
      expect(results, isEmpty);
    });

    test('searchContent trims whitespace from query', () async {
      final results1 = await service.searchContent('heart');
      final results2 = await service.searchContent('  heart  ');

      expect(results1.length, equals(results2.length));
    });
  });

  group('EducationalContentService - Cache Management', () {
    test('getCacheStats returns valid statistics', () async {
      final stats = await service.getCacheStats();

      expect(stats['count'], greaterThan(0));
      expect(stats['maxCount'], equals(50));
      expect(stats['sizeBytes'], greaterThan(0));
      expect(stats['sizeMB'], isNotNull);
      expect(stats['maxSizeMB'], equals(100));
      expect(stats['utilizationPercent'], isNotNull);
    });

    test('getCacheSizeBytes returns positive value', () async {
      final size = await service.getCacheSizeBytes();

      expect(size, greaterThan(0));
    });

    test('clearCache removes all content', () async {
      // Ensure cache has content
      final initialCount = await ContentBox.instance.getCachedCount();
      expect(initialCount, greaterThan(0));

      // Clear cache
      await service.clearCache();

      // Cache should be empty
      final finalCount = await ContentBox.instance.getCachedCount();
      expect(finalCount, equals(0));
    });

    test('cache repopulates after clearing and reinitializing', () async {
      // Clear cache
      await service.clearCache();
      expect(await ContentBox.instance.getCachedCount(), equals(0));

      // Re-initialize (should reload sample content)
      await service.initialize();

      // Cache should have content again
      final count = await ContentBox.instance.getCachedCount();
      expect(count, greaterThan(0));
    });
  });

  group('EducationalContentService - Cache Limits', () {
    test('enforceCacheLimits completes successfully', () async {
      final result = await service.enforceCacheLimits();

      expect(result, isTrue);
    });

    test('cache respects maximum article count', () async {
      // Cache has max 50 articles
      final count = await ContentBox.instance.getCachedCount();

      expect(count, lessThanOrEqualTo(50));
    });

    test('cache respects maximum total size', () async {
      final sizeBytes = await service.getCacheSizeBytes();
      const maxSizeBytes = 100 * 1024 * 1024; // 100 MB

      expect(sizeBytes, lessThanOrEqualTo(maxSizeBytes));
    });
  });

  group('EducationalContentService - Content Categories', () {
    test('all content categories are represented', () async {
      // Get content for each category
      final cvdContent = await service.getByCategory(ContentCategory.cvdPrevention);
      final symptomContent = await service.getByCategory(ContentCategory.symptomRecognition);
      final lifestyleContent = await service.getByCategory(ContentCategory.lifestyleModification);
      final emergencyContent = await service.getByCategory(ContentCategory.emergencyResponse);
      final riskContent = await service.getByCategory(ContentCategory.riskFactors);

      // Should have content in each category
      expect(cvdContent, isNotEmpty, reason: 'CVD Prevention should have content');
      expect(symptomContent, isNotEmpty, reason: 'Symptom Recognition should have content');
      expect(lifestyleContent, isNotEmpty, reason: 'Lifestyle Modification should have content');
      expect(emergencyContent, isNotEmpty, reason: 'Emergency Response should have content');
      expect(riskContent, isNotEmpty, reason: 'Risk Factors should have content');
    });

    test('content count matches across retrieval methods', () async {
      final allContent = await service.getAllCachedContent();

      // Get content by each category
      final categories = [
        ContentCategory.cvdPrevention,
        ContentCategory.symptomRecognition,
        ContentCategory.lifestyleModification,
        ContentCategory.emergencyResponse,
        ContentCategory.riskFactors,
        ContentCategory.medicationCompliance,
      ];

      int totalByCategoryCount = 0;
      for (final category in categories) {
        final categoryContent = await service.getByCategory(category);
        totalByCategoryCount += categoryContent.length;
      }

      // Total by category should equal total content
      expect(totalByCategoryCount, equals(allContent.length));
    });
  });

  group('EducationalContentService - Content Quality', () {
    test('all content has required fields', () async {
      final allContent = await service.getAllCachedContent();

      for (final content in allContent) {
        // Required fields
        expect(content.id, isNotEmpty, reason: 'Content should have ID');
        expect(content.titleEn, isNotEmpty, reason: 'Content should have English title');
        expect(content.titleFil, isNotEmpty, reason: 'Content should have Filipino title');
        expect(content.summaryEn, isNotEmpty, reason: 'Content should have English summary');
        expect(content.summaryFil, isNotEmpty, reason: 'Content should have Filipino summary');
        expect(content.htmlContentEn, isNotEmpty, reason: 'Content should have English HTML');
        expect(content.htmlContentFil, isNotEmpty, reason: 'Content should have Filipino HTML');
        expect(content.category, isNotNull, reason: 'Content should have category');
        expect(content.version, greaterThan(0), reason: 'Content should have positive version');
        expect(content.readTimeMinutes, greaterThan(0), reason: 'Content should have read time');
        expect(content.publishedAt, isNotNull, reason: 'Content should have published date');
      }
    });

    test('all content has valid tags', () async {
      final allContent = await service.getAllCachedContent();

      for (final content in allContent) {
        expect(content.tags, isA<List<String>>());
        expect(content.tags, isNotEmpty, reason: 'Content should have at least one tag');

        // Tags should not be empty strings
        for (final tag in content.tags) {
          expect(tag.trim(), isNotEmpty, reason: 'Tags should not be empty');
        }
      }
    });

    test('content read times are reasonable', () async {
      final allContent = await service.getAllCachedContent();

      for (final content in allContent) {
        // Read time should be between 1 and 60 minutes
        expect(
          content.readTimeMinutes,
          greaterThanOrEqualTo(1),
          reason: 'Read time should be at least 1 minute',
        );
        expect(
          content.readTimeMinutes,
          lessThanOrEqualTo(60),
          reason: 'Read time should not exceed 60 minutes',
        );
      }
    });

    test('content IDs are unique', () async {
      final allContent = await service.getAllCachedContent();
      final ids = allContent.map((c) => c.id).toSet();

      // Set should have same size as list (all unique)
      expect(ids.length, equals(allContent.length));
    });
  });

  group('EducationalContentService - Bilingual Support', () {
    test('all content has both English and Filipino text', () async {
      final allContent = await service.getAllCachedContent();

      for (final content in allContent) {
        // English content
        expect(content.titleEn, isNotEmpty);
        expect(content.summaryEn, isNotEmpty);
        expect(content.htmlContentEn, isNotEmpty);

        // Filipino content
        expect(content.titleFil, isNotEmpty);
        expect(content.summaryFil, isNotEmpty);
        expect(content.htmlContentFil, isNotEmpty);
      }
    });

    test('search works in both languages', () async {
      // English search
      final englishResults = await service.searchContent('heart');
      expect(englishResults, isNotEmpty);

      // Filipino search
      final filipinoResults = await service.searchContent('puso');
      expect(filipinoResults, isNotEmpty);
    });
  });

  group('EducationalContentService - Performance', () {
    test('getAllCachedContent completes quickly', () async {
      final stopwatch = Stopwatch()..start();

      await service.getAllCachedContent();

      stopwatch.stop();

      // Performance target: <50ms
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('searchContent completes quickly', () async {
      final stopwatch = Stopwatch()..start();

      await service.searchContent('cardiovascular');

      stopwatch.stop();

      // Performance target: <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('getByCategory completes quickly', () async {
      final stopwatch = Stopwatch()..start();

      await service.getByCategory(ContentCategory.cvdPrevention);

      stopwatch.stop();

      // Performance target: <50ms
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('multiple concurrent searches perform well', () async {
      final stopwatch = Stopwatch()..start();

      await Future.wait([
        service.searchContent('heart'),
        service.searchContent('stroke'),
        service.searchContent('exercise'),
      ]);

      stopwatch.stop();

      // Performance target: <200ms for 3 concurrent searches
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });

  group('EducationalContentService - Edge Cases', () {
    test('handles special characters in search', () async {
      final results = await service.searchContent('heart & health');

      // Should complete without error
      expect(results, isA<List<EducationalContent>>());
    });

    test('handles very long search query', () async {
      final longQuery = 'cardiovascular disease prevention ' * 10;
      final results = await service.searchContent(longQuery);

      // Should complete without error
      expect(results, isA<List<EducationalContent>>());
    });

    test('handles unicode characters in search', () async {
      final results = await service.searchContent('💓 puso');

      // Should complete without error
      expect(results, isA<List<EducationalContent>>());
    });

    test('handles null-safe operations', () async {
      // Get content with non-existent ID
      final content = await service.getContent('null-test-id');

      expect(content, isNull);

      // Should not throw error when accessing
      expect(() => content?.id, returnsNormally);
    });
  });

  group('EducationalContentService - Sample Content Validation', () {
    test('sample content includes CVD prevention articles', () async {
      final cvdContent = await service.getByCategory(ContentCategory.cvdPrevention);

      expect(cvdContent.length, greaterThanOrEqualTo(3));

      // Check for specific expected articles
      final titles = cvdContent.map((c) => c.titleEn).toList();
      expect(
        titles.any((t) => t.contains('Understanding Cardiovascular Disease')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Diet') || t.contains('Exercise')),
        isTrue,
      );
    });

    test('sample content includes symptom recognition articles', () async {
      final symptomContent = await service.getByCategory(ContentCategory.symptomRecognition);

      expect(symptomContent.length, greaterThanOrEqualTo(2));

      // Check for heart attack and stroke content
      final titles = symptomContent.map((c) => c.titleEn).toList();
      expect(
        titles.any((t) => t.contains('Heart Attack')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Stroke')),
        isTrue,
      );
    });

    test('sample content includes lifestyle modification articles', () async {
      final lifestyleContent = await service.getByCategory(ContentCategory.lifestyleModification);

      expect(lifestyleContent.length, greaterThanOrEqualTo(2));

      // Check for stress and smoking cessation content
      final titles = lifestyleContent.map((c) => c.titleEn).toList();
      expect(
        titles.any((t) => t.contains('Stress')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Smoking')),
        isTrue,
      );
    });

    test('sample content includes emergency response articles', () async {
      final emergencyContent = await service.getByCategory(ContentCategory.emergencyResponse);

      expect(emergencyContent.length, greaterThanOrEqualTo(1));

      // Check for CPR/AED content
      final titles = emergencyContent.map((c) => c.titleEn).toList();
      expect(
        titles.any((t) => t.contains('Emergency') || t.contains('CPR') || t.contains('AED')),
        isTrue,
      );
    });

    test('sample content includes risk factor articles', () async {
      final riskContent = await service.getByCategory(ContentCategory.riskFactors);

      expect(riskContent.length, greaterThanOrEqualTo(2));

      // Check for blood pressure and cholesterol content
      final titles = riskContent.map((c) => c.titleEn).toList();
      expect(
        titles.any((t) => t.contains('Blood Pressure') || t.contains('Hypertension')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Cholesterol')),
        isTrue,
      );
    });
  });

  group('EducationalContentService - Offline Functionality', () {
    test('content remains accessible after initialization', () async {
      // Get content
      final initialContent = await service.getAllCachedContent();
      expect(initialContent, isNotEmpty);

      // Simulate app restart by getting content again
      final afterRestart = await service.getAllCachedContent();
      expect(afterRestart.length, equals(initialContent.length));
    });

    test('search works without network connectivity', () async {
      // This test implicitly validates offline search since no network calls are made
      final results = await service.searchContent('heart disease');

      expect(results, isNotEmpty);
    });

    test('category filtering works without network connectivity', () async {
      // This test implicitly validates offline filtering since no network calls are made
      final cvdContent = await service.getByCategory(ContentCategory.cvdPrevention);

      expect(cvdContent, isNotEmpty);
    });
  });
}
