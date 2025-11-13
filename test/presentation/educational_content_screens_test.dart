import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/presentation/pages/education/educational_content_list_screen.dart';
import 'package:juan_heart/presentation/pages/education/content_viewer_screen.dart';
import 'package:juan_heart/presentation/widgets/content_card.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

class _UITestPathProvider extends PathProviderPlatform {
  _UITestPathProvider(this.documentsPath);
  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// Mock Educational Content Service
class MockEducationalContentService extends Mock {
  Future<List<EducationalContent>> getAllCachedContent() async {
    return _generateMockContent();
  }

  Future<List<EducationalContent>> searchContent(String query) async {
    final allContent = await getAllCachedContent();
    return allContent
        .where((content) =>
            content.titleEn.toLowerCase().contains(query.toLowerCase()) ||
            content.titleFil.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<EducationalContent>> getByCategory(
    ContentCategory category,
  ) async {
    final allContent = await getAllCachedContent();
    return allContent
        .where((content) => content.category == category)
        .toList();
  }

  Future<bool> isWiFiAvailable() async => true;

  Stream<dynamic> get downloadProgressStream => Stream.value({
        'current': 5,
        'total': 10,
        'percentage': 50.0,
      });

  List<EducationalContent> _generateMockContent() {
    final now = DateTime.now();
    return [
      EducationalContent(
        id: 'test-001',
        titleEn: 'Understanding Heart Disease',
        titleFil: 'Pag-unawa sa Sakit sa Puso',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Learn about cardiovascular disease and prevention.',
        summaryFil: 'Alamin ang tungkol sa sakit sa puso at pag-iwas.',
        htmlContentEn: '<h2>Heart Disease</h2><p>Test content</p>',
        htmlContentFil: '<h2>Sakit sa Puso</h2><p>Test content</p>',
        imageUrls: const [],
        tags: const ['heart', 'prevention', 'puso'],
        version: 1,
        publishedAt: now.subtract(const Duration(days: 5)),
        readTimeMinutes: 5,
        cachedAt: now,
      ),
      EducationalContent(
        id: 'test-002',
        titleEn: 'Heart Attack Warning Signs',
        titleFil: 'Mga Babala ng Heart Attack',
        category: ContentCategory.symptomRecognition,
        summaryEn: 'Recognize warning signs of heart attack.',
        summaryFil: 'Kilalanin ang mga babala ng heart attack.',
        htmlContentEn: '<h2>Warning Signs</h2><p>Test content</p>',
        htmlContentFil: '<h2>Mga Babala</h2><p>Test content</p>',
        imageUrls: const [],
        tags: const ['heart attack', 'symptoms', 'sintomas'],
        version: 1,
        publishedAt: now.subtract(const Duration(days: 10)),
        readTimeMinutes: 4,
      ),
      EducationalContent(
        id: 'test-003',
        titleEn: 'Exercise for Heart Health',
        titleFil: 'Ehersisyo para sa Kalusugan ng Puso',
        category: ContentCategory.exercise,
        summaryEn: 'Physical activity strengthens your heart.',
        summaryFil: 'Ang ehersisyo ay nagpapalakas ng iyong puso.',
        htmlContentEn: '<h2>Exercise</h2><p>Test content</p>',
        htmlContentFil: '<h2>Ehersisyo</h2><p>Test content</p>',
        imageUrls: const [],
        tags: const ['exercise', 'fitness', 'ehersisyo'],
        version: 1,
        publishedAt: now.subtract(const Duration(days: 2)),
        readTimeMinutes: 6,
        cachedAt: now,
      ),
    ];
  }
}

void main() {
  late MockEducationalContentService mockService;
  late Directory testDir;
  late PathProviderPlatform previousPathProvider;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDir = Directory.systemTemp.createTempSync('educational_content_ui_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _UITestPathProvider(testDir.path);
    await Hive.initFlutter(testDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EducationalContentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ContentCategoryAdapter());
    }

    await EducationalContentService.instance.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    PathProviderPlatform.instance = previousPathProvider;
  });

  setUp(() {
    mockService = MockEducationalContentService();
  });

  group('ContentCard Widget Tests', () {
    testWidgets('displays article title and summary', (tester) async {
      // Given: A test article
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Test Article Title',
        titleFil: 'Titulo ng Test',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'This is a test summary for the article.',
        summaryFil: 'Ito ay test summary para sa artikulo.',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentCard is rendered
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
            ),
          ),
        ),
      );

      // Then: Title and summary are displayed
      expect(find.text('Test Article Title'), findsOneWidget);
      expect(find.text('This is a test summary for the article.'), findsOneWidget);
    });

    testWidgets('displays category badge with correct icon', (tester) async {
      // Given: An article in CVD Prevention category
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'CVD Prevention Article',
        titleFil: 'Artikulo sa Pag-iwas',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentCard is rendered
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
            ),
          ),
        ),
      );

      // Then: Category badge is displayed
      expect(find.text('CVD Prevention'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('displays offline indicator when content is cached',
        (tester) async {
      // Given: A cached article
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Cached Article',
        titleFil: 'Naka-cache na Artikulo',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
        cachedAt: DateTime.now(),
      );

      // When: ContentCard is rendered
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
            ),
          ),
        ),
      );

      // Then: Offline indicator is displayed
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays download button when content is not cached',
        (tester) async {
      // Given: An uncached article
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Uncached Article',
        titleFil: 'Hindi Naka-cache',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentCard is rendered with download button
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
              onDownload: () {},
              showDownloadButton: true,
            ),
          ),
        ),
      );

      // Then: Download button is displayed
      expect(find.text('Download'), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('calls onTap callback when card is tapped', (tester) async {
      // Given: An article and tap callback
      bool wasTapped = false;
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Tappable Article',
        titleFil: 'Tappable na Artikulo',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentCard is rendered and tapped
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Article'));
      await tester.pumpAndSettle();

      // Then: Callback was called
      expect(wasTapped, isTrue);
    });

    testWidgets('displays read time estimate', (tester) async {
      // Given: An article with 8 minute read time
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Long Article',
        titleFil: 'Mahabang Artikulo',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 8,
      );

      // When: ContentCard is rendered
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
            ),
          ),
        ),
      );

      // Then: Read time is displayed
      expect(find.text('8 min read'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });

  group('EducationalContentListScreen Widget Tests', () {
    testWidgets('displays app bar with title', (tester) async {
      // When: Screen is rendered
      await tester.pumpWidget(
        const GetMaterialApp(
          home: EducationalContentListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: App bar with title is displayed
      expect(find.text('Health Education'), findsOneWidget);
    });

    testWidgets('displays category tabs', (tester) async {
      // When: Screen is rendered
      await tester.pumpWidget(
        const GetMaterialApp(
          home: EducationalContentListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: Category tabs are displayed
      expect(find.text('CVD Prevention'), findsWidgets);
      expect(find.text('Symptom Recognition'), findsWidgets);
      expect(find.text('Exercise'), findsWidgets);
    });

    testWidgets('displays search icon in app bar', (tester) async {
      // When: Screen is rendered
      await tester.pumpWidget(
        const GetMaterialApp(
          home: EducationalContentListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: Search icon is displayed
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays loading indicator initially', (tester) async {
      // When: Screen is rendered
      await tester.pumpWidget(
        const GetMaterialApp(
          home: EducationalContentListScreen(),
        ),
      );

      // Then: Loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides empty state when sample content is available',
        (tester) async {
      // When: Screen is rendered with seeded content
      await tester.pumpWidget(
        const GetMaterialApp(
          home: EducationalContentListScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Then: Empty state message should not appear because sample content exists
      expect(
        find.textContaining('No articles available'),
        findsNothing,
      );
    });
  });

  group('ContentViewerScreen Widget Tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    Future<void> _pumpViewer(
      WidgetTester tester,
      EducationalContent content,
    ) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: SizedBox.shrink(),
        ),
      );

      Get.to(
        () => const ContentViewerScreen(),
        arguments: {'content': content},
      );

      await tester.pumpAndSettle();
    }

    testWidgets('displays article title in app bar', (tester) async {
      // Given: An article to view
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Test Article for Viewer',
        titleFil: 'Test Artikulo para sa Viewer',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<h2>Heading</h2><p>Test content paragraph.</p>',
        htmlContentFil: '<h2>Pamagat</h2><p>Test na nilalaman.</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentViewerScreen is rendered
      await _pumpViewer(tester, content);

      // Then: Title is displayed in app bar
      expect(find.text('Test Article for Viewer'), findsOneWidget);
    });

    testWidgets('displays language toggle button', (tester) async {
      // Given: An article to view
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Bilingual Article',
        titleFil: 'Artikulo sa Dalawang Wika',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>English content</p>',
        htmlContentFil: '<p>Filipino content</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentViewerScreen is rendered
      await _pumpViewer(tester, content);

      // Then: Language toggle button is displayed
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays back button in app bar', (tester) async {
      // Given: An article to view
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Article with Back',
        titleFil: 'Artikulo na may Back',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Nilalaman</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentViewerScreen is rendered
      await _pumpViewer(tester, content);

      // Then: Back button is displayed
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('ContentCard has semantic labels', (tester) async {

      // Given: An article
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Accessible Article',
        titleFil: 'Accessible na Artikulo',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'This article has proper accessibility.',
        summaryFil: 'Ang artikulo na ito ay may tamang accessibility.',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Nilalaman</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentCard is rendered
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
            ),
          ),
        ),
      );

      // Then: Semantic labels are present
      final titleSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Article title: Accessible Article',
      );
      final categorySemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Category: CVD Prevention',
      );

      expect(titleSemantics, findsOneWidget);
      expect(categorySemantics, findsOneWidget);
    });

    testWidgets('Download button has semantic hint', (tester) async {
      // Given: An uncached article
      final content = EducationalContent(
        id: 'test-001',
        titleEn: 'Downloadable Article',
        titleFil: 'Ma-download na Artikulo',
        category: ContentCategory.cvdPrevention,
        summaryEn: 'Summary',
        summaryFil: 'Buod',
        htmlContentEn: '<p>Content</p>',
        htmlContentFil: '<p>Nilalaman</p>',
        imageUrls: const [],
        tags: const ['test'],
        version: 1,
        publishedAt: DateTime.now(),
        readTimeMinutes: 5,
      );

      // When: ContentCard with download button is rendered
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: content,
              onTap: () {},
              onDownload: () {},
              showDownloadButton: true,
            ),
          ),
        ),
      );

      // Then: Download button has proper semantics
      final downloadSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Download article: Downloadable Article',
      );
      expect(downloadSemantics, findsOneWidget);
    });
  });
}
