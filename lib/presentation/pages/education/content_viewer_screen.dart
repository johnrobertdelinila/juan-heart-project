import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Article Viewer Screen with HTML content rendering
///
/// Features:
/// - HTML content display with responsive styling
/// - Language toggle (EN ⟷ FIL)
/// - Related articles suggestions
/// - Offline support
/// - Responsive text sizing
/// - Share functionality (future)
///
/// Design:
/// - Readable typography (Poppins font)
/// - Proper content width (max 600dp on tablets)
/// - Comfortable line height (1.6)
/// - Material Design 3 patterns
class ContentViewerScreen extends StatefulWidget {
  const ContentViewerScreen({Key? key}) : super(key: key);

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  final EducationalContentService _contentService =
      EducationalContentService.instance;

  late EducationalContent _content;
  List<EducationalContent> _relatedArticles = [];
  bool _isFilipino = false;
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  void _initializeContent() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['content'] != null) {
      _content = args['content'] as EducationalContent;
      _isFilipino = Get.locale?.languageCode == 'fil';
      _loadRelatedArticles();
    } else {
      // Handle missing content
      Get.back();
    }
  }

  Future<void> _loadRelatedArticles() async {
    try {
      final allContent = await _contentService.getByCategory(_content.category);
      setState(() {
        _relatedArticles = allContent
            .where((article) => article.id != _content.id)
            .take(3)
            .toList();
        _isLoadingRelated = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRelated = false;
      });
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isFilipino = !_isFilipino;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToRelatedArticle(EducationalContent article) {
    Get.off(
      () => const ContentViewerScreen(),
      arguments: {'content': article},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArticleHeader(),
                const SizedBox(height: 24),
                _buildArticleContent(),
                const SizedBox(height: 32),
                if (_relatedArticles.isNotEmpty) _buildRelatedArticles(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final title = _content.getTitle(_isFilipino ? 'fil' : 'en');
    final truncatedTitle = title.length > 50
        ? '${title.substring(0, 50)}...'
        : title;

    return AppBar(
      backgroundColor: ColorConstant.trustBlue,
      elevation: 0,
      leading: Semantics(
        label: 'Back to article list',
        button: true,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      title: Text(
        truncatedTitle,
        style: JHTextStyles.bodyBase.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Semantics(
          label: _isFilipino
              ? 'Switch to English'
              : 'Switch to Filipino',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: _toggleLanguage,
            tooltip: _isFilipino ? 'English' : 'Filipino',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildArticleHeader() {
    final title = _content.getTitle(_isFilipino ? 'fil' : 'en');
    final categoryLabel = _isFilipino
        ? _content.category.labelFil
        : _content.category.labelEn;
    final publishedDate = DateFormat.yMMMd().format(_content.publishedAt);

    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryBadge(categoryLabel),
          const SizedBox(height: 16),
          Text(
            title,
            style: JHTextStyles.h2.copyWith(
              color: ColorConstant.bluedark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: ColorConstant.gentleGray,
              ),
              const SizedBox(width: 6),
              Text(
                '${_content.readTimeMinutes} ${_isFilipino ? 'min' : 'min read'}',
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.gentleGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: ColorConstant.gentleGray,
              ),
              const SizedBox(width: 6),
              Text(
                publishedDate,
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.gentleGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_content.isOfflineAvailable) ...[
            const SizedBox(height: 12),
            _buildOfflineBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String label) {
    final categoryColor = _getCategoryColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 16,
            color: categoryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: JHTextStyles.label.copyWith(
              color: categoryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstant.reassuringGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_bolt,
            size: 14,
            color: ColorConstant.reassuringGreen,
          ),
          const SizedBox(width: 4),
          Text(
            _isFilipino ? 'Available offline' : 'Available offline',
            style: JHTextStyles.caption.copyWith(
              color: ColorConstant.reassuringGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    final htmlContent = _content.getHtmlContent(_isFilipino ? 'fil' : 'en');

    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Html(
        data: htmlContent,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            color: ColorConstant.bluedark,
          ),
          "h2": Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.w700,
            color: ColorConstant.bluedark,
            margin: Margins.only(top: 20, bottom: 12),
          ),
          "h3": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.w600,
            color: ColorConstant.bluedark,
            margin: Margins.only(top: 16, bottom: 10),
          ),
          "p": Style(
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            color: ColorConstant.bluedark,
            margin: Margins.only(bottom: 16),
          ),
          "ul": Style(
            margin: Margins.only(bottom: 16, left: 16),
          ),
          "ol": Style(
            margin: Margins.only(bottom: 16, left: 16),
          ),
          "li": Style(
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            margin: Margins.only(bottom: 8),
          ),
          "a": Style(
            color: ColorConstant.trustBlue,
            textDecoration: TextDecoration.underline,
          ),
        },
        onLinkTap: (url, _, __) {
          if (url != null) {
            _launchUrl(url);
          }
        },
      ),
    );
  }

  Widget _buildRelatedArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _isFilipino ? 'Mga Kaugnay na Artikulo' : 'Related Articles',
            style: JHTextStyles.h4.copyWith(
              color: ColorConstant.bluedark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingRelated)
          Center(
            child: CircularProgressIndicator(
              color: ColorConstant.trustBlue,
            ),
          )
        else
          ..._relatedArticles.map((article) => _buildRelatedArticleCard(article)),
      ],
    );
  }

  Widget _buildRelatedArticleCard(EducationalContent article) {
    final title = article.getTitle(_isFilipino ? 'fil' : 'en');
    final summary = article.getSummary(_isFilipino ? 'fil' : 'en');
    final truncatedSummary = summary.length > 80
        ? '${summary.substring(0, 80)}...'
        : summary;

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => _navigateToRelatedArticle(article),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRelatedCategoryIcon(article),
                size: 20,
                color: ColorConstant.trustBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: JHTextStyles.bodyBase.copyWith(
                    color: ColorConstant.bluedark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            truncatedSummary,
            style: JHTextStyles.bodySmall.copyWith(
              color: ColorConstant.gentleGray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: ColorConstant.gentleGray,
              ),
              const SizedBox(width: 4),
              Text(
                '${article.readTimeMinutes} min',
                style: JHTextStyles.label.copyWith(
                  color: ColorConstant.gentleGray,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: ColorConstant.trustBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (_content.category) {
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

  IconData _getRelatedCategoryIcon(EducationalContent article) {
    return _getCategoryIcon();
  }

  Color _getCategoryColor() {
    switch (_content.category) {
      case ContentCategory.cvdPrevention:
        return ColorConstant.trustBlue;
      case ContentCategory.symptomRecognition:
        return ColorConstant.calmingBlue;
      case ContentCategory.lifestyleModification:
        return ColorConstant.reassuringGreen;
      case ContentCategory.medicationCompliance:
        return ColorConstant.pupuleColor;
      case ContentCategory.emergencyResponse:
        return ColorConstant.emergencyBadge;
      case ContentCategory.riskFactors:
        return ColorConstant.urgentBadge;
      case ContentCategory.nutrition:
        return ColorConstant.barangayGreen;
      case ContentCategory.exercise:
        return ColorConstant.calmingBlue;
    }
  }
}
