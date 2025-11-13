import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/presentation/widgets/content_card.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Educational Content Library Screen
///
/// Features:
/// - Category-based content browsing with 8 tabs
/// - Full-text search across titles and summaries
/// - Download management (WiFi-only)
/// - Offline availability indicators
/// - Bilingual support (EN/FIL)
/// - Material Design 3 patterns
///
/// Follows Juan Heart UI/UX standards:
/// - Poppins typography
/// - Semantic color coding
/// - Accessibility compliant (44dp touch targets)
/// - Responsive layout (4.7" to 10" screens)
class EducationalContentListScreen extends StatefulWidget {
  const EducationalContentListScreen({Key? key}) : super(key: key);

  @override
  State<EducationalContentListScreen> createState() =>
      _EducationalContentListScreenState();
}

class _EducationalContentListScreenState
    extends State<EducationalContentListScreen>
    with SingleTickerProviderStateMixin {
  final EducationalContentService _contentService =
      EducationalContentService.instance;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<EducationalContent> _allContent = [];
  List<EducationalContent> _filteredContent = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ContentCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _loadContent();
    _listenToDownloadProgress();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _filterContentByCategory();
      });
    }
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final content = await _contentService.getAllCachedContent();

      setState(() {
        _allContent = content;
        _filterContentByCategory();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load content: $e');
    }
  }

  void _filterContentByCategory() {
    if (_searchQuery.isNotEmpty) {
      _performSearch();
      return;
    }

    final currentCategory = ContentCategory.values[_tabController.index];
    _filteredContent = _allContent
        .where((content) => content.category == currentCategory)
        .toList();
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      _filterContentByCategory();
      return;
    }

    try {
      final results = await _contentService.searchContent(_searchQuery);
      final currentCategory = ContentCategory.values[_tabController.index];

      setState(() {
        _filteredContent = results
            .where((content) => content.category == currentCategory)
            .toList();
      });
    } catch (e) {
      _showErrorSnackBar('Search failed: $e');
    }
  }

  void _listenToDownloadProgress() {
    _contentService.downloadProgressStream.listen((progress) {
      setState(() {
        _downloadProgress = progress.percentage;
        _isDownloading = !progress.isComplete;
      });

      if (progress.isComplete) {
        _showSuccessSnackBar('Download complete!');
        _loadContent();
      }
    });
  }

  Future<void> _downloadAllContent() async {
    final locale = Get.locale?.languageCode ?? 'en';
    final isFilipino = locale == 'fil';

    try {
      // Check WiFi
      final hasWiFi = await _contentService.isWiFiAvailable();
      if (!hasWiFi) {
        _showWiFiWarningDialog(isFilipino);
        return;
      }

      // Get all content IDs that are not cached
      final uncachedContent = _allContent
          .where((content) => !content.isOfflineAvailable)
          .map((content) => content.id)
          .toList();

      if (uncachedContent.isEmpty) {
        _showInfoSnackBar(
          isFilipino
              ? 'Lahat ng content ay available na offline'
              : 'All content is already available offline',
        );
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      await _contentService.downloadContent(uncachedContent);
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showErrorSnackBar('Download failed: $e');
    }
  }

  Future<void> _downloadSingleArticle(String contentId) async {
    try {
      final hasWiFi = await _contentService.isWiFiAvailable();
      if (!hasWiFi) {
        final locale = Get.locale?.languageCode ?? 'en';
        _showWiFiWarningDialog(locale == 'fil');
        return;
      }

      await _contentService.downloadContent([contentId]);
      _showSuccessSnackBar('Article downloaded');
      _loadContent();
    } catch (e) {
      _showErrorSnackBar('Download failed: $e');
    }
  }

  void _showWiFiWarningDialog(bool isFilipino) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isFilipino ? 'Kailangan ng WiFi' : 'WiFi Required',
          style: JHTextStyles.h5.copyWith(
            color: ColorConstant.bluedark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          isFilipino
              ? 'Para sa mabilis at libre na pag-download, kumonekta sa WiFi.'
              : 'For fast and free download, please connect to WiFi.',
          style: const TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isFilipino ? 'OK' : 'OK',
              style: TextStyle(
                color: ColorConstant.trustBlue,
                
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToArticle(EducationalContent content) {
    Get.toNamed(
      '/educational-content-viewer',
      arguments: {'content': content},
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Get.locale?.languageCode ?? 'en';
    final isFilipino = locale == 'fil';

    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: _buildAppBar(isFilipino),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(isFilipino),
          _buildCategoryTabs(isFilipino),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildContentList(),
          ),
          if (_isDownloading) _buildDownloadProgress(),
        ],
      ),
      floatingActionButton: _buildDownloadFAB(isFilipino),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isFilipino) {
    return AppBar(
      backgroundColor: ColorConstant.trustBlue,
      elevation: 0,
      title: Text(
        isFilipino ? 'Edukasyon sa Kalusugan' : 'Health Education',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          
        ),
      ),
      actions: [
        Semantics(
          label: 'Search articles',
          button: true,
          child: IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterContentByCategory();
                }
              });
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(bool isFilipino) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ColorConstant.trustBlue,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.white,
          
        ),
        decoration: InputDecoration(
          hintText: isFilipino ? 'Maghanap ng artikulo...' : 'Search articles...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterContentByCategory();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.2),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _performSearch();
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs(bool isFilipino) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: ColorConstant.trustBlue,
        unselectedLabelColor: ColorConstant.gentleGray,
        indicatorColor: ColorConstant.trustBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          
        ),
        tabs: ContentCategory.values.map((category) {
          return Tab(
            icon: Icon(_getCategoryIcon(category), size: 20),
            text: isFilipino ? category.labelFil : category.labelEn,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentList() {
    if (_filteredContent.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredContent.length,
      itemBuilder: (context, index) {
        final content = _filteredContent[index];
        return ContentCard(
          content: content,
          onTap: () => _navigateToArticle(content),
          onDownload: () => _downloadSingleArticle(content.id),
          showDownloadButton: !content.isOfflineAvailable,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final locale = Get.locale?.languageCode ?? 'en';
    final isFilipino = locale == 'fil';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.article_outlined,
              size: 80,
              color: ColorConstant.gentleGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? (isFilipino
                      ? 'Walang resulta para sa "$_searchQuery"'
                      : 'No results found for "$_searchQuery"')
                  : (isFilipino
                      ? 'Walang available na artikulo'
                      : 'No articles available'),
              style: TextStyle(
                color: ColorConstant.gentleGray,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: ColorConstant.trustBlue,
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ColorConstant.trustBlue.withValues(alpha: 0.1),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: _downloadProgress / 100,
              strokeWidth: 3,
              color: ColorConstant.trustBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Downloading... ${_downloadProgress.toStringAsFixed(0)}%',
              style: TextStyle(
                color: ColorConstant.trustBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildDownloadFAB(bool isFilipino) {
    if (_isDownloading) return null;

    final uncachedCount = _allContent
        .where((content) => !content.isOfflineAvailable)
        .length;

    if (uncachedCount == 0) return null;

    return Semantics(
      label: 'Download all articles',
      hint: 'Download $uncachedCount articles for offline reading',
      button: true,
      child: FloatingActionButton.extended(
        onPressed: _downloadAllContent,
        backgroundColor: ColorConstant.trustBlue,
        icon: const Icon(Icons.download, color: Colors.white),
        label: Text(
          isFilipino ? 'I-download Lahat' : 'Download All',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ContentCategory category) {
    switch (category) {
      case ContentCategory.cvdPrevention:
        return Icons.favorite;
      case ContentCategory.symptomRecognition:
        return Icons.health_and_safety;
      case ContentCategory.lifestyleModification:
        return Icons.self_improvement;
      case ContentCategory.medicationCompliance:
        return Icons.medication;
      case ContentCategory.emergencyResponse:
        return Icons.emergency;
      case ContentCategory.riskFactors:
        return Icons.warning_amber;
      case ContentCategory.nutrition:
        return Icons.restaurant;
      case ContentCategory.exercise:
        return Icons.fitness_center;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(),
        ),
        backgroundColor: ColorConstant.reassuringGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(),
        ),
        backgroundColor: ColorConstant.emergencyBadge,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(),
        ),
        backgroundColor: ColorConstant.calmingBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
