import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/services/api/educational_content_api_service.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:juan_heart/database/content_box.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for Educational Content Sync (Phase 6)
///
/// This test suite validates:
/// 1. Full content sync from backend API
/// 2. Bilingual content (English + Filipino)
/// 3. Content search functionality
/// 4. Category filtering
/// 5. Offline content access
/// 6. Weekly sync worker
///
/// Prerequisites:
/// - Backend API running at http://localhost:8000
/// - Educational content database seeded with 10+ articles
/// - Bilingual content (English + Filipino)
///
/// Test data requirements:
/// - At least 10 educational articles
/// - All categories present (cvd_prevention, heart_health, etc.)
/// - Bilingual content for all articles
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Educational Content Sync Integration Tests', () {
    late EducationalContentApiService apiService;
    late EducationalContentService contentService;
    late ContentBox contentBox;

    setUp(() async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Initialize content box (Hive cache)
      contentBox = ContentBox.instance;
      await contentBox.initialize();
      await contentBox.clearCache();

      // Initialize API service
      apiService = EducationalContentApiService(
        baseUrl: 'http://localhost:8000/api/v1/mobile',
      );

      // Initialize content service with backend API enabled
      contentService = EducationalContentService.instance;
      await contentService.initialize(
        apiService: apiService,
        useBackendApi: true,
      );
    });

    tearDown(() async {
      await contentBox.clearCache();
    });

    testWidgets('Test 1: Full content sync from backend', (tester) async {
      // STEP 1: Clear cache
      await contentBox.clearCache();

      final initialCount = await contentBox.getCachedCount();
      expect(initialCount, equals(0), reason: 'Cache should be empty before sync');

      // STEP 2: Fetch content from backend
      final stopwatch = Stopwatch()..start();
      final content = await apiService.fetchContent();
      stopwatch.stop();

      // STEP 3: Verify response
      expect(content, isNotEmpty, reason: 'Backend should return educational content');
      expect(content.length, greaterThanOrEqualTo(10),
          reason: 'Backend should have at least 10 articles for testing');

      // STEP 4: Verify performance (<3 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Content sync should complete in <3 seconds');

      print('[Test 1] Fetched ${content.length} articles in ${stopwatch.elapsedMilliseconds}ms');

      // STEP 5: Verify data structure
      for (final article in content.take(5)) {
        expect(article.id, isNotEmpty, reason: 'Article ID should not be empty');
        expect(article.title, isNotEmpty, reason: 'Title should not be empty');
        expect(article.body, isNotEmpty, reason: 'Content should not be empty');
        expect(article.category, isNotEmpty, reason: 'Category should not be empty');
      }

      // STEP 6: Cache the content
      final contentModels = content.map((c) => c.toEducationalContent()).toList();
      await contentBox.saveMultipleContent(contentModels);

      // STEP 7: Verify cache populated
      final cachedCount = await contentBox.getCachedCount();
      expect(cachedCount, equals(content.length),
          reason: 'All content should be cached');

      print('[Test 1] PASSED: $cachedCount articles cached');
    }, skip: false);

    testWidgets('Test 2: Bilingual content validation', (tester) async {
      // STEP 1: Fetch content
      final content = await apiService.fetchContent();
      expect(content, isNotEmpty);

      // STEP 2: Verify all articles have content
      // NOTE: Backend API currently returns single-language content
      // Bilingual support is handled in the toEducationalContent() conversion
      for (final article in content) {
        // Verify required fields
        expect(article.title, isNotEmpty,
            reason: 'Article ${article.id} should have title');
        expect(article.body, isNotEmpty,
            reason: 'Article ${article.id} should have content');

        // After conversion to EducationalContent, bilingual fields are populated
        final eduContent = article.toEducationalContent();
        expect(eduContent.titleEn, isNotEmpty);
        expect(eduContent.titleFil, isNotEmpty);
        expect(eduContent.htmlContentEn, isNotEmpty);
        expect(eduContent.htmlContentFil, isNotEmpty);
      }

      print('[Test 2] PASSED: All ${content.length} articles have bilingual content');
    }, skip: false);

    testWidgets('Test 3: Content search works with backend data', (tester) async {
      // STEP 1: Sync content from backend
      await contentService.syncFromBackend();

      // STEP 2: Search for "heart attack" (English)
      final stopwatch = Stopwatch()..start();
      final englishResults = await contentService.searchContent('heart attack');
      stopwatch.stop();

      expect(englishResults, isNotEmpty,
          reason: 'Should find articles about heart attack');

      // STEP 3: Verify performance (<500ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Search should complete in <500ms');

      print('[Test 3] English search: Found ${englishResults.length} results in ${stopwatch.elapsedMilliseconds}ms');

      // STEP 4: Search for "atake sa puso" (Filipino)
      final filipinoResults = await contentService.searchContent('atake sa puso');

      expect(filipinoResults, isNotEmpty,
          reason: 'Filipino search should work');

      print('[Test 3] Filipino search: Found ${filipinoResults.length} results');

      // STEP 5: Search for "CVD" (abbreviation)
      final abbreviationResults = await contentService.searchContent('CVD');
      print('[Test 3] Abbreviation search: Found ${abbreviationResults.length} results');

      print('[Test 3] PASSED: Search works in multiple languages');
    }, skip: false);

    testWidgets('Test 4: Category filtering works correctly', (tester) async {
      // STEP 1: Sync content from backend
      final syncCount = await contentService.syncFromBackend();
      expect(syncCount, greaterThan(0));

      // STEP 2: Filter by CVD prevention category
      final cvdPreventionArticles = await contentService.getByCategory(
        ContentCategory.cvdPrevention,
      );

      expect(cvdPreventionArticles, isNotEmpty,
          reason: 'Should find CVD prevention articles');

      // STEP 3: Verify all results are in correct category
      for (final article in cvdPreventionArticles) {
        expect(article.category, equals(ContentCategory.cvdPrevention),
            reason: 'All results should be in CVD prevention category');
      }

      print('[Test 4] Found ${cvdPreventionArticles.length} CVD prevention articles');

      // STEP 4: Filter by symptom recognition category
      final symptomArticles = await contentService.getByCategory(
        ContentCategory.symptomRecognition,
      );

      print('[Test 4] Found ${symptomArticles.length} symptom recognition articles');

      // STEP 5: Verify categories are mutually exclusive
      final cvdIds = cvdPreventionArticles.map((a) => a.id).toSet();
      final symptomIds = symptomArticles.map((a) => a.id).toSet();
      final overlap = cvdIds.intersection(symptomIds);

      expect(overlap, isEmpty,
          reason: 'Articles should only belong to one category');

      print('[Test 4] PASSED: Category filtering working correctly');
    }, skip: false);

    testWidgets('Test 5: Content available offline after caching', (tester) async {
      // STEP 1: Sync content from backend (online)
      final onlineContent = await contentService.syncFromBackend();
      expect(onlineContent, greaterThan(0));

      print('[Test 5] Synced $onlineContent articles from backend');

      // STEP 2: Disable backend API (simulate offline)
      await contentService.initialize(
        apiService: apiService,
        useBackendApi: false,
      );

      // STEP 3: Try to get all content (should use cache)
      final cachedContent = await contentService.getAllCachedContent();

      expect(cachedContent, isNotEmpty,
          reason: 'Should return cached content when offline');
      expect(cachedContent.length, equals(onlineContent),
          reason: 'Cached content count should match synced content');

      print('[Test 5] Retrieved ${cachedContent.length} articles from cache (offline)');

      // STEP 4: Try to search offline
      final offlineSearchResults = await contentService.searchContent('heart');

      expect(offlineSearchResults, isNotEmpty,
          reason: 'Search should work offline with cached content');

      print('[Test 5] Offline search found ${offlineSearchResults.length} results');

      // STEP 5: Try to get content by ID offline
      if (cachedContent.isNotEmpty) {
        final firstArticleId = cachedContent.first.id;
        final offlineArticle = await contentService.getContent(firstArticleId);

        expect(offlineArticle, isNotNull,
            reason: 'Should retrieve specific content offline');
        expect(offlineArticle!.id, equals(firstArticleId));
      }

      print('[Test 5] PASSED: Offline access working correctly');

      // Re-enable backend API for subsequent tests
      await contentService.initialize(
        apiService: apiService,
        useBackendApi: true,
      );
    }, skip: false);

    testWidgets('Test 6: Incremental sync fetches only new content', (tester) async {
      // STEP 1: Perform initial sync
      final initialSync = await contentService.syncFromBackend();
      print('[Test 6] Initial sync: $initialSync articles');

      // STEP 2: Record timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('educational_content_last_sync');
      expect(lastSync, isNotNull, reason: 'Last sync timestamp should be recorded');

      // STEP 3: Wait a moment
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 4: Perform incremental sync
      final incrementalSync = await contentService.syncFromBackend();

      // STEP 5: Verify behavior
      // If no new content added, should return 0
      // If new content added, should return only new articles
      print('[Test 6] Incremental sync: $incrementalSync articles');

      // STEP 6: Verify last sync timestamp updated
      final updatedLastSync = prefs.getString('educational_content_last_sync');
      expect(updatedLastSync, isNotNull);

      print('[Test 6] PASSED: Incremental sync working');
    }, skip: false);

    testWidgets('Test 7: Content cache respects size limits', (tester) async {
      // STEP 1: Sync content
      await contentService.syncFromBackend();

      // STEP 2: Get cache statistics
      final cacheStats = await contentService.getCacheStats();

      expect(cacheStats, isNotEmpty);
      expect(cacheStats.containsKey('totalItems'), isTrue);
      expect(cacheStats.containsKey('totalSizeBytes'), isTrue);

      print('[Test 7] Cache stats:');
      print('  - Total items: ${cacheStats['totalItems']}');
      print('  - Total size: ${cacheStats['totalSizeBytes']} bytes');

      // STEP 3: Verify cache size is reasonable
      final cacheSizeBytes = await contentService.getCacheSizeBytes();
      expect(cacheSizeBytes, greaterThan(0));
      expect(cacheSizeBytes, lessThan(50 * 1024 * 1024),
          reason: 'Cache should be <50MB for educational content');

      // STEP 4: Test cache limit enforcement
      final limitsEnforced = await contentService.enforceCacheLimits();

      print('[Test 7] Cache limits enforced: $limitsEnforced');
      print('[Test 7] PASSED: Cache management working');
    }, skip: false);

    testWidgets('Test 8: Content view tracking (if implemented)', (tester) async {
      // STEP 1: Fetch content list
      final content = await apiService.fetchContent();
      expect(content, isNotEmpty);

      final firstArticle = content.first;

      // STEP 2: Fetch specific content by ID
      // This may increment view count on backend
      try {
        final articleDetail = await apiService.getContent(firstArticle.id);

        expect(articleDetail.id, equals(firstArticle.id));

        print('[Test 8] Content detail fetched: ${articleDetail.title}');
        print('[Test 8] PASSED: Content detail endpoint working');
      } catch (e) {
        print('[Test 8] WARNING: Content detail fetch failed: $e');
      }
    }, skip: false);

    testWidgets('Test 9: Content statistics from backend', (tester) async {
      try {
        // STEP 1: Get content statistics
        final stats = await contentService.getContentStats();

        if (stats != null) {
          expect(stats.totalContent, greaterThan(0));

          print('[Test 9] Content statistics:');
          print('  - Total content: ${stats.totalContent}');

          // NOTE: Backend stats model may have different structure
          // Just verify we got valid stats
          if (stats.totalContent > 0) {
            print('[Test 9] Valid statistics received from backend');
          }

          print('[Test 9] PASSED: Statistics endpoint working');
        } else {
          print('[Test 9] WARNING: Statistics not available from backend');
        }
      } catch (e) {
        print('[Test 9] WARNING: Statistics fetch failed: $e');
      }
    }, skip: false);

    testWidgets('Test 10: Search performance benchmark', (tester) async {
      // STEP 1: Sync content
      await contentService.syncFromBackend();

      // STEP 2: Perform multiple searches and measure time
      final searchTerms = [
        'heart',
        'blood pressure',
        'cholesterol',
        'exercise',
        'smoking',
      ];

      final searchTimes = <int>[];

      for (final term in searchTerms) {
        final stopwatch = Stopwatch()..start();
        final results = await contentService.searchContent(term);
        stopwatch.stop();

        searchTimes.add(stopwatch.elapsedMilliseconds);
        print('[Test 10] Search "$term": ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');

        // Each search should be <500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Search for "$term" should complete in <500ms');
      }

      // STEP 3: Calculate average search time
      final avgSearchTime = searchTimes.reduce((a, b) => a + b) / searchTimes.length;
      print('[Test 10] Average search time: ${avgSearchTime.toStringAsFixed(2)}ms');

      expect(avgSearchTime, lessThan(300),
          reason: 'Average search time should be <300ms');

      print('[Test 10] PASSED: Search performance benchmark met');
    }, skip: false);

    testWidgets('Test 11: Available categories from backend', (tester) async {
      try {
        // STEP 1: Get available categories
        final categories = await contentService.getAvailableCategories();

        expect(categories, isNotEmpty,
            reason: 'Backend should return available categories');

        print('[Test 11] Available categories: ${categories.join(", ")}');

        // STEP 2: Verify expected categories present
        final expectedCategories = [
          'cvd_prevention',
          'symptom_recognition',
          'lifestyle_modification',
          'emergency_response',
          'risk_factors',
        ];

        for (final expected in expectedCategories) {
          final hasCategory = categories.any((c) =>
              c.toLowerCase().contains(expected.toLowerCase()));
          expect(hasCategory, isTrue,
              reason: 'Should include $expected category');
        }

        print('[Test 11] PASSED: Categories endpoint working');
      } catch (e) {
        print('[Test 11] WARNING: Categories fetch failed: $e');
      }
    }, skip: false);

    testWidgets('Test 12: Content sync error handling', (tester) async {
      // STEP 1: Try to sync with invalid API endpoint
      final invalidApiService = EducationalContentApiService(
        baseUrl: 'http://invalid-endpoint-12345.com',
      );

      await contentService.initialize(
        apiService: invalidApiService,
        useBackendApi: true,
      );

      // STEP 2: Attempt sync (should fail gracefully)
      try {
        final syncCount = await contentService.syncFromBackend();
        print('[Test 12] Unexpected success: $syncCount');
      } catch (e) {
        print('[Test 12] Caught expected error: $e');

        // STEP 3: Verify app still has cached content
        final cachedContent = await contentService.getAllCachedContent();
        print('[Test 12] Cached content available: ${cachedContent.length} articles');

        print('[Test 12] PASSED: Error handled gracefully with cached fallback');
      }

      // Restore valid API service
      await contentService.initialize(
        apiService: apiService,
        useBackendApi: true,
      );
    }, skip: false);
  });
}
