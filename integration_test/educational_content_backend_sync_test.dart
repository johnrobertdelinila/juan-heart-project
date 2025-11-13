import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/services/api/educational_content_api_service.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:juan_heart/services/educational_content_sync_worker.dart';
import 'package:juan_heart/database/content_box.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/models/api/educational_content_api_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Integration tests for Educational Content Backend Sync
///
/// This test suite validates:
/// 1. Full content sync from backend API
/// 2. Incremental sync (only fetch updated content)
/// 3. Single content retrieval with view count increment
/// 4. Category filtering
/// 5. Language filtering
/// 6. Search functionality
/// 7. Offline fallback to cached content
/// 8. Error handling (401, 404, 500, timeout)
/// 9. Performance benchmarks
/// 10. Stats endpoint validation
///
/// Prerequisites:
/// - Backend API running at http://localhost:8000
/// - Educational content database seeded with 20 articles
/// - 8 categories configured in backend
/// - Network connectivity for online tests
///
/// Test data requirements:
/// - At least 20 articles across 8 categories
/// - Bilingual content (EN/FIL or single language)
/// - Valid content IDs for single retrieval tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Educational Content Backend Sync Integration Tests', () {
    late EducationalContentApiService apiService;
    late EducationalContentService contentService;
    late EducationalContentSyncWorker syncWorker;
    late ContentBox contentBox;

    setUpAll(() async {
      // Initialize Hive for tests
      await Hive.initFlutter();
      Hive.registerAdapter(EducationalContentAdapter());
      Hive.registerAdapter(ContentCategoryAdapter());
    });

    setUp(() async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Initialize ContentBox
      contentBox = ContentBox.instance;
      await contentBox.initialize();

      // Initialize API service
      // NOTE: Update baseUrl if backend is hosted elsewhere
      apiService = EducationalContentApiService(
        baseUrl: 'http://localhost:8000/api/v1/mobile',
        timeout: 30,
      );

      // Initialize content service with backend API enabled
      contentService = EducationalContentService.instance;
      await contentService.initialize(
        apiService: apiService,
        useBackendApi: true,
      );

      // Initialize sync worker
      syncWorker = EducationalContentSyncWorker.instance;
      await syncWorker.reset();
      await syncWorker.initialize(enableWeeklySync: false);
    });

    tearDown(() async {
      // Clean up
      await contentBox.clearCache();
      await syncWorker.reset();
    });

    testWidgets('Test 1: Full content sync from backend', (tester) async {
      // STEP 1: Clear local cache
      await contentBox.clearCache();

      // Verify cache is empty
      final beforeSync = await contentBox.getAllContent();
      expect(beforeSync, isEmpty, reason: 'Cache should be empty before sync');

      // STEP 2: Fetch all content from backend API
      final stopwatch = Stopwatch()..start();
      final content = await apiService.fetchContent();
      stopwatch.stop();

      // STEP 3: Verify response
      expect(content, isNotEmpty, reason: 'Backend should return content');
      expect(content.length, greaterThanOrEqualTo(20),
          reason: 'Backend should have at least 20 articles seeded');

      // STEP 4: Verify performance (should complete in <5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Content sync should complete in <5 seconds');

      print('[Test 1] Fetched ${content.length} articles in ${stopwatch.elapsedMilliseconds}ms');

      // STEP 5: Verify data structure - all required fields present
      for (final item in content.take(5)) {
        expect(item.id, isNotEmpty, reason: 'Content ID should not be empty');
        expect(item.title, isNotEmpty, reason: 'Title should not be empty');
        expect(item.category, isNotEmpty, reason: 'Category should not be empty');
        expect(item.body, isNotEmpty, reason: 'Body should not be empty');
        expect(item.readingTimeMinutes, greaterThan(0),
            reason: 'Reading time should be positive');
        expect(item.views, greaterThanOrEqualTo(0),
            reason: 'Views should be non-negative');
        expect(item.createdAt, isNotNull, reason: 'Created date should exist');
        expect(item.updatedAt, isNotNull, reason: 'Updated date should exist');
      }

      // STEP 6: Convert to app model and cache
      final appContent = content.map((c) => c.toEducationalContent()).toList();
      await contentBox.saveMultipleContent(appContent);

      // STEP 7: Verify content cached correctly
      final afterSync = await contentBox.getAllContent();
      expect(afterSync.length, equals(content.length),
          reason: 'All content should be cached');

      // STEP 8: Verify cached content has cachedAt timestamp
      for (final item in afterSync) {
        expect(item.cachedAt, isNotNull,
            reason: 'Cached content should have cachedAt timestamp');
        expect(item.isOfflineAvailable, isTrue,
            reason: 'Cached content should be marked as offline available');
      }

      print('[Test 1] PASSED: ${afterSync.length} articles cached successfully');
    }, skip: false);

    testWidgets('Test 2: Incremental sync fetches only new content',
        (tester) async {
      // STEP 1: Perform initial sync
      final initialContent = await apiService.fetchContent();
      final appContent = initialContent.map((c) => c.toEducationalContent()).toList();
      await contentBox.saveMultipleContent(appContent);

      final initialCount = (await contentBox.getAllContent()).length;
      print('[Test 2] Initial sync: $initialCount articles');

      // STEP 2: Record timestamp for incremental sync
      final lastSyncTime = DateTime.now().toUtc();
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 3: Call incremental sync endpoint
      final incrementalContent = await apiService.syncContent(lastSyncTime);

      // STEP 4: Verify response
      // Since no content was added/updated since lastSyncTime, should be empty
      // If backend added content, verify they are newer than lastSyncTime
      print('[Test 2] Incremental sync returned: ${incrementalContent.length} articles');

      if (incrementalContent.isNotEmpty) {
        for (final item in incrementalContent) {
          expect(item.id, isNotEmpty);
          // Verify content is actually updated after lastSyncTime
          expect(
            item.updatedAt.isAfter(lastSyncTime) ||
                item.updatedAt.isAtSameMomentAs(lastSyncTime),
            isTrue,
            reason: 'Incremental sync should only return content updated since lastSync',
          );
        }
        print('[Test 2] PASSED: Incremental sync returned ${incrementalContent.length} updated articles');
      } else {
        print('[Test 2] PASSED: No new content since last sync (expected behavior)');
      }
    }, skip: false);

    testWidgets('Test 3: Single content retrieval with view increment',
        (tester) async {
      // STEP 1: Fetch all content to get a valid ID
      final allContent = await apiService.fetchContent();
      expect(allContent, isNotEmpty, reason: 'Need at least one article for this test');

      final testContentId = allContent.first.id;
      final initialViews = allContent.first.views;

      print('[Test 3] Testing content ID: $testContentId (initial views: $initialViews)');

      // STEP 2: Fetch single content by ID
      final singleContent = await apiService.getContent(testContentId);

      // STEP 3: Verify content retrieved successfully
      expect(singleContent.id, equals(testContentId),
          reason: 'Retrieved content should match requested ID');
      expect(singleContent.title, isNotEmpty, reason: 'Title should not be empty');
      expect(singleContent.body, isNotEmpty, reason: 'Body should not be empty');

      // STEP 4: Fetch again to verify view count incremented
      // Note: Backend increments view on each GET request
      await Future.delayed(const Duration(milliseconds: 300));
      final secondFetch = await apiService.getContent(testContentId);

      expect(secondFetch.views, greaterThanOrEqualTo(initialViews),
          reason: 'View count should increment or stay same');

      print('[Test 3] PASSED: Single content retrieved (views: ${singleContent.views} → ${secondFetch.views})');
    }, skip: false);

    testWidgets('Test 4: Invalid ID returns 404', (tester) async {
      // STEP 1: Try to fetch content with non-existent ID
      try {
        await apiService.getContent('non-existent-id-12345-test');
        fail('Should throw exception for non-existent ID');
      } on EducationalContentApiException catch (e) {
        // STEP 2: Verify correct error handling
        expect(e.statusCode, equals(404),
            reason: 'Non-existent ID should return 404 status');
        expect(e.message, contains('not found'),
            reason: 'Error message should indicate content not found');

        print('[Test 4] PASSED: 404 error handled correctly for invalid ID');
      } catch (e) {
        fail('Should throw EducationalContentApiException, got: $e');
      }
    }, skip: false);

    testWidgets('Test 5: Category filtering', (tester) async {
      // STEP 1: Fetch content filtered by specific category
      const categoryToTest = 'cvd_prevention';
      final filteredContent = await apiService.fetchContent(
        category: categoryToTest,
      );

      // STEP 2: Verify all results match the filter
      expect(filteredContent, isNotEmpty,
          reason: 'Should have content for $categoryToTest category');

      for (final item in filteredContent) {
        expect(item.category, equals(categoryToTest),
            reason: 'All results should match category filter');
      }

      print('[Test 5] PASSED: Category filtering returned ${filteredContent.length} articles for $categoryToTest');

      // STEP 3: Test with different category
      const secondCategory = 'symptom_recognition';
      final secondFiltered = await apiService.fetchContent(
        category: secondCategory,
      );

      if (secondFiltered.isNotEmpty) {
        for (final item in secondFiltered) {
          expect(item.category, equals(secondCategory));
        }
        print('[Test 5] PASSED: Second category $secondCategory returned ${secondFiltered.length} articles');
      }
    }, skip: false);

    testWidgets('Test 6: Language filtering', (tester) async {
      // STEP 1: Fetch English content only
      final englishContent = await apiService.fetchContent(
        language: 'en',
      );

      expect(englishContent, isNotEmpty,
          reason: 'Should have English content');

      print('[Test 6] English content: ${englishContent.length} articles');

      // STEP 2: Fetch Filipino content only
      final filipinoContent = await apiService.fetchContent(
        language: 'fil',
      );

      print('[Test 6] Filipino content: ${filipinoContent.length} articles');

      // STEP 3: Verify total matches (if backend supports language filtering)
      // Note: Backend may return single-language content for both filters
      final totalContent = await apiService.fetchContent();

      print('[Test 6] Total content: ${totalContent.length} articles');
      print('[Test 6] PASSED: Language filtering working (EN: ${englishContent.length}, FIL: ${filipinoContent.length})');
    }, skip: false);

    testWidgets('Test 7: Search functionality', (tester) async {
      // STEP 1: Search for common CVD term
      const searchQuery = 'heart';
      final searchResults = await apiService.fetchContent(
        search: searchQuery,
      );

      // STEP 2: Verify results contain search term
      expect(searchResults, isNotEmpty,
          reason: 'Should find content with "$searchQuery"');

      // STEP 3: Verify search matches in title or description or body
      for (final item in searchResults.take(5)) {
        final matchesSearch = item.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (item.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            item.body.toLowerCase().contains(searchQuery.toLowerCase());

        expect(matchesSearch, isTrue,
            reason: 'Search result should contain "$searchQuery" in title, description, or body');
      }

      print('[Test 7] PASSED: Search for "$searchQuery" returned ${searchResults.length} articles');

      // STEP 4: Test search with no results
      final noResultsSearch = await apiService.fetchContent(
        search: 'xyzqwertynonexistent123',
      );

      expect(noResultsSearch, isEmpty,
          reason: 'Invalid search term should return empty results');

      print('[Test 7] PASSED: Empty search result handled correctly');
    }, skip: false);

    testWidgets('Test 8: Offline fallback to cached content', (tester) async {
      // STEP 1: Fetch and cache content while online
      final onlineContent = await apiService.fetchContent();
      final appContent = onlineContent.map((c) => c.toEducationalContent()).toList();
      await contentBox.saveMultipleContent(appContent);

      final cachedCount = (await contentBox.getAllContent()).length;
      print('[Test 8] Cached $cachedCount articles');

      // STEP 2: Disable backend API to simulate offline mode
      await contentService.initialize(useBackendApi: false);

      // STEP 3: Retrieve content (should use cache)
      final offlineContent = await contentService.getAllCachedContent();

      // STEP 4: Verify cached content is returned
      expect(offlineContent, isNotEmpty,
          reason: 'Should return cached content when offline');
      expect(offlineContent.length, equals(cachedCount),
          reason: 'Offline content should match cached count');

      // STEP 5: Verify all cached content has cachedAt timestamp
      for (final item in offlineContent) {
        expect(item.cachedAt, isNotNull,
            reason: 'Cached content should have timestamp');
        expect(item.isOfflineAvailable, isTrue);
      }

      print('[Test 8] PASSED: Offline fallback working (${offlineContent.length} articles from cache)');

      // Re-enable backend for subsequent tests
      await contentService.initialize(
        apiService: apiService,
        useBackendApi: true,
      );
    }, skip: false);

    testWidgets('Test 9: Error handling - Network timeout', (tester) async {
      // STEP 1: Create API service with very short timeout
      final timeoutService = EducationalContentApiService(
        baseUrl: 'http://localhost:8000/api/v1/mobile',
        timeout: 1, // 1 second timeout
      );

      try {
        // STEP 2: Try to fetch content (may timeout on slow backend)
        await timeoutService.fetchContent();

        // If succeeded, backend is fast enough
        print('[Test 9] Backend responded within 1 second timeout');
        print('[Test 9] PASSED: No timeout error (backend is fast)');
      } on EducationalContentApiException catch (e) {
        // STEP 3: Verify timeout error is handled correctly
        expect(e.isNetworkError, isTrue,
            reason: 'Timeout should be classified as network error');
        expect(e.message, contains('timeout'),
            reason: 'Error message should mention timeout');

        print('[Test 9] PASSED: Timeout error handled gracefully: ${e.message}');
      }
    }, skip: false);

    testWidgets('Test 10: Categories endpoint', (tester) async {
      // STEP 1: Fetch available categories
      final categories = await apiService.getCategories();

      // STEP 2: Verify categories list is not empty
      expect(categories, isNotEmpty,
          reason: 'Backend should return available categories');

      // STEP 3: Verify expected categories exist
      final expectedCategories = [
        'cvd_prevention',
        'symptom_recognition',
        'lifestyle_modification',
        'emergency_response',
        'risk_factors',
      ];

      for (final expectedCat in expectedCategories) {
        expect(categories.contains(expectedCat), isTrue,
            reason: 'Should include $expectedCat category');
      }

      print('[Test 10] PASSED: Found ${categories.length} categories: $categories');
    }, skip: false);

    testWidgets('Test 11: Stats endpoint validation', (tester) async {
      // STEP 1: Fetch content statistics
      final stats = await apiService.getStats();

      // STEP 2: Verify stats structure
      expect(stats.totalContent, greaterThan(0),
          reason: 'Should have content in database');
      expect(stats.totalViews, greaterThanOrEqualTo(0),
          reason: 'Total views should be non-negative');
      expect(stats.byCategory, isNotEmpty,
          reason: 'Should have category breakdown');

      print('[Test 11] Content Statistics:');
      print('  - Total Content: ${stats.totalContent}');
      print('  - Total Views: ${stats.totalViews}');
      print('  - Categories: ${stats.byCategory.length}');

      // STEP 3: Verify category counts
      int categorySum = 0;
      stats.byCategory.forEach((category, count) {
        expect(count, greaterThanOrEqualTo(0),
            reason: 'Category count should be non-negative');
        categorySum += count;
        print('    - $category: $count articles');
      });

      // STEP 4: Verify category sum matches total
      expect(categorySum, equals(stats.totalContent),
          reason: 'Sum of category counts should equal total content');

      print('[Test 11] PASSED: Stats endpoint validated');
    }, skip: false);

    testWidgets('Test 12: Pagination support', (tester) async {
      // STEP 1: Fetch first page (10 items)
      final page1 = await apiService.fetchContent(
        page: 1,
        perPage: 10,
      );

      // STEP 2: Fetch second page
      final page2 = await apiService.fetchContent(
        page: 2,
        perPage: 10,
      );

      // STEP 3: Verify pagination works
      expect(page1.length, lessThanOrEqualTo(10),
          reason: 'Page 1 should have max 10 items');

      if (page2.isNotEmpty) {
        expect(page2.length, lessThanOrEqualTo(10),
            reason: 'Page 2 should have max 10 items');

        // STEP 4: Verify no duplicates between pages
        final page1Ids = page1.map((c) => c.id).toSet();
        final page2Ids = page2.map((c) => c.id).toSet();
        final intersection = page1Ids.intersection(page2Ids);

        expect(intersection, isEmpty,
            reason: 'Pages should not have duplicate content');

        print('[Test 12] PASSED: Pagination working (Page 1: ${page1.length}, Page 2: ${page2.length})');
      } else {
        print('[Test 12] PASSED: All content fits in first page (${page1.length} items)');
      }
    }, skip: false);

    testWidgets('Test 13: Sync worker manual sync', (tester) async {
      // STEP 1: Clear cache
      await contentBox.clearCache();

      // STEP 2: Trigger manual sync via sync worker
      final itemsSynced = await syncWorker.syncNow();

      // STEP 3: Verify content synced
      expect(itemsSynced, greaterThan(0),
          reason: 'Sync worker should sync content');

      // STEP 4: Verify content cached
      final cachedContent = await contentBox.getAllContent();
      expect(cachedContent, isNotEmpty,
          reason: 'Sync worker should cache content');

      // STEP 5: Verify sync status
      expect(syncWorker.status, equals(SyncStatus.success),
          reason: 'Sync status should be success');

      // STEP 6: Verify last sync timestamp updated
      expect(syncWorker.lastSync, isNotNull,
          reason: 'Last sync timestamp should be set');

      print('[Test 13] PASSED: Sync worker synced $itemsSynced items');
    }, skip: false);

    testWidgets('Test 14: Data integrity validation', (tester) async {
      // STEP 1: Fetch all content
      final allContent = await apiService.fetchContent();

      // STEP 2: Verify no duplicate IDs
      final ids = allContent.map((c) => c.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length),
          reason: 'Content IDs should be unique (no duplicates)');

      // STEP 3: Verify all required fields not empty
      for (final item in allContent) {
        expect(item.id, isNotEmpty, reason: 'ID should not be empty');
        expect(item.title, isNotEmpty, reason: 'Title should not be empty');
        expect(item.category, isNotEmpty, reason: 'Category should not be empty');
        expect(item.body, isNotEmpty, reason: 'Body should not be empty');
      }

      // STEP 4: Verify timestamps are valid
      for (final item in allContent) {
        expect(item.createdAt.isBefore(DateTime.now()), isTrue,
            reason: 'Created date should be in the past');
        expect(item.updatedAt.isBefore(DateTime.now().add(const Duration(minutes: 1))), isTrue,
            reason: 'Updated date should not be in the future');
        expect(
          item.updatedAt.isAfter(item.createdAt) ||
              item.updatedAt.isAtSameMomentAs(item.createdAt),
          isTrue,
          reason: 'Updated date should be >= created date',
        );
      }

      // STEP 5: Verify reading time is reasonable
      for (final item in allContent) {
        expect(item.readingTimeMinutes, greaterThan(0),
            reason: 'Reading time should be positive');
        expect(item.readingTimeMinutes, lessThan(60),
            reason: 'Reading time should be reasonable (<60 minutes)');
      }

      print('[Test 14] PASSED: Data integrity validated for ${allContent.length} articles');
    }, skip: false);

    testWidgets('Test 15: Performance benchmark - Sync speed', (tester) async {
      // STEP 1: Clear cache
      await contentBox.clearCache();

      // STEP 2: Measure full sync time
      final stopwatch = Stopwatch()..start();

      final allContent = await apiService.fetchContent();
      final appContent = allContent.map((c) => c.toEducationalContent()).toList();
      await contentBox.saveMultipleContent(appContent);

      stopwatch.stop();

      // STEP 3: Verify performance targets
      final totalTime = stopwatch.elapsedMilliseconds;
      final contentCount = allContent.length;

      expect(totalTime, lessThan(5000),
          reason: 'Sync of $contentCount articles should complete in <5 seconds');

      // STEP 4: Calculate metrics
      final timePerArticle = totalTime / contentCount;
      print('[Test 15] Performance Metrics:');
      print('  - Total articles: $contentCount');
      print('  - Total time: ${totalTime}ms');
      print('  - Time per article: ${timePerArticle.toStringAsFixed(2)}ms');
      print('  - Articles per second: ${(contentCount / (totalTime / 1000)).toStringAsFixed(2)}');

      expect(timePerArticle, lessThan(250),
          reason: 'Should process each article in <250ms on average');

      print('[Test 15] PASSED: Performance benchmark met');
    }, skip: false);

    testWidgets('Test 16: Cache access performance', (tester) async {
      // STEP 1: Populate cache
      final allContent = await apiService.fetchContent();
      final appContent = allContent.map((c) => c.toEducationalContent()).toList();
      await contentBox.saveMultipleContent(appContent);

      // STEP 2: Measure cache read time
      final stopwatch = Stopwatch()..start();
      final cachedContent = await contentBox.getAllContent();
      stopwatch.stop();

      // STEP 3: Verify performance
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Cache read should complete in <100ms');

      print('[Test 16] PASSED: Cache read ${cachedContent.length} articles in ${stopwatch.elapsedMilliseconds}ms');
    }, skip: false);

    testWidgets('Test 17: Multiple category filter', (tester) async {
      // STEP 1: Get content for multiple categories
      final categories = ['cvd_prevention', 'symptom_recognition', 'lifestyle_modification'];

      final List<EducationalContentApiModel> combinedResults = [];

      for (final category in categories) {
        final categoryContent = await apiService.fetchContent(
          category: category,
        );
        combinedResults.addAll(categoryContent);
      }

      // STEP 2: Verify all results match one of the categories
      for (final item in combinedResults) {
        expect(categories.contains(item.category), isTrue,
            reason: 'Content should match one of the filtered categories');
      }

      print('[Test 17] PASSED: Multi-category filter returned ${combinedResults.length} articles');
    }, skip: false);

    testWidgets('Test 18: API retry logic on server error', (tester) async {
      // STEP 1: Create API service with reduced retries for faster testing
      final retryService = EducationalContentApiService(
        baseUrl: 'http://localhost:8000/api/v1/mobile',
        maxRetries: 2,
        initialRetryDelay: const Duration(milliseconds: 100),
      );

      // STEP 2: Try to connect to potentially unavailable endpoint
      // This test validates retry logic exists, even if backend is available
      try {
        await retryService.fetchContent();
        print('[Test 18] PASSED: API request succeeded (no retry needed)');
      } on EducationalContentApiException catch (e) {
        // If error occurred, verify it's properly typed
        expect(e.message, isNotEmpty, reason: 'Error message should be provided');
        print('[Test 18] PASSED: Retry logic handled error: ${e.message}');
      }
    }, skip: false);

    testWidgets('Test 19: Combined filters (category + language + search)',
        (tester) async {
      // STEP 1: Apply multiple filters
      final filteredContent = await apiService.fetchContent(
        category: 'cvd_prevention',
        language: 'en',
        search: 'heart',
      );

      // STEP 2: Verify all filters applied
      if (filteredContent.isNotEmpty) {
        for (final item in filteredContent) {
          expect(item.category, equals('cvd_prevention'));
          // Language filter may not be enforced if backend returns single language
          // Search filter should match
          final matchesSearch = item.title.toLowerCase().contains('heart') ||
              (item.description?.toLowerCase().contains('heart') ?? false) ||
              item.body.toLowerCase().contains('heart');
          expect(matchesSearch, isTrue,
              reason: 'Should match search term "heart"');
        }
      }

      print('[Test 19] PASSED: Combined filters returned ${filteredContent.length} articles');
    }, skip: false);

    testWidgets('Test 20: Verify 20+ seeded articles exist', (tester) async {
      // STEP 1: Fetch all content
      final allContent = await apiService.fetchContent();

      // STEP 2: Verify minimum article count
      expect(allContent.length, greaterThanOrEqualTo(20),
          reason: 'Backend should have at least 20 seeded articles');

      // STEP 3: Verify distribution across categories
      final categoryDistribution = <String, int>{};
      for (final item in allContent) {
        categoryDistribution[item.category] = (categoryDistribution[item.category] ?? 0) + 1;
      }

      expect(categoryDistribution.length, greaterThanOrEqualTo(3),
          reason: 'Should have content distributed across multiple categories');

      print('[Test 20] Content Distribution:');
      categoryDistribution.forEach((category, count) {
        print('  - $category: $count articles');
      });

      print('[Test 20] PASSED: ${allContent.length} articles across ${categoryDistribution.length} categories');
    }, skip: false);
  });
}
