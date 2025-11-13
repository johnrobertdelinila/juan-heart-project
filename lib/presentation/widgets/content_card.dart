import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Reusable card widget for displaying educational content articles.
///
/// Features:
/// - Bilingual title and summary display
/// - Category badge with icon
/// - Read time estimate
/// - Offline availability indicator
/// - Optional download button
/// - Responsive layout
///
/// Design follows Juan Heart Material Design 3 standards:
/// - StandardCard base with 15px border radius
/// - Consistent spacing and typography
/// - Semantic color coding
class ContentCard extends StatelessWidget {
  final EducationalContent content;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final bool showDownloadButton;

  const ContentCard({
    Key? key,
    required this.content,
    required this.onTap,
    this.onDownload,
    this.showDownloadButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Get.locale?.languageCode ?? 'en';
    final isFilipino = locale == 'fil';

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isFilipino),
          const SizedBox(height: 12),
          _buildTitle(isFilipino),
          const SizedBox(height: 8),
          _buildSummary(isFilipino),
          const SizedBox(height: 16),
          _buildFooter(isFilipino),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isFilipino) {
    return Row(
      children: [
        _buildCategoryBadge(isFilipino),
        const Spacer(),
        _buildReadTime(isFilipino),
      ],
    );
  }

  Widget _buildCategoryBadge(bool isFilipino) {
    final categoryIcon = _getCategoryIcon(content.category);
    final categoryColor = _getCategoryColor(content.category);
    final categoryLabel =
        isFilipino ? content.category.labelFil : content.category.labelEn;

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
            categoryIcon,
            size: 16,
            color: categoryColor,
            semanticLabel: 'Category: $categoryLabel',
          ),
          const SizedBox(width: 6),
          Text(
            categoryLabel,
            style: JHTextStyles.caption.copyWith(
              color: categoryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadTime(bool isFilipino) {
    final readTimeText = isFilipino
        ? '${content.readTimeMinutes} min'
        : '${content.readTimeMinutes} min read';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: ColorConstant.gentleGray,
          semanticLabel: 'Reading time',
        ),
        const SizedBox(width: 4),
        Text(
          readTimeText,
          style: JHTextStyles.caption.copyWith(
            color: ColorConstant.gentleGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isFilipino) {
    final title = content.getTitle(isFilipino ? 'fil' : 'en');

    return Text(
      title,
      style: JHTextStyles.h5.copyWith(
        color: ColorConstant.bluedark,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: 'Article title: $title',
    );
  }

  Widget _buildSummary(bool isFilipino) {
    final summary = content.getSummary(isFilipino ? 'fil' : 'en');
    final truncatedSummary =
        summary.length > 100 ? '${summary.substring(0, 100)}...' : summary;

    return Text(
      truncatedSummary,
      style: JHTextStyles.bodySmall.copyWith(
        color: ColorConstant.gentleGray,
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(bool isFilipino) {
    return Row(
      children: [
        if (content.isOfflineAvailable) _buildOfflineIndicator(isFilipino),
        if (content.isRecent && !content.isOfflineAvailable)
          _buildNewBadge(isFilipino),
        const Spacer(),
        if (showDownloadButton && !content.isOfflineAvailable)
          _buildDownloadButton(isFilipino),
      ],
    );
  }

  Widget _buildOfflineIndicator(bool isFilipino) {
    final offlineText = isFilipino ? 'Available offline' : 'Available offline';

    return Semantics(
      label: offlineText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ColorConstant.reassuringGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: ColorConstant.reassuringGreen,
            ),
            const SizedBox(width: 4),
            Text(
              isFilipino ? 'Offline' : 'Offline',
              style: JHTextStyles.label.copyWith(
                color: ColorConstant.reassuringGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewBadge(bool isFilipino) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstant.trustBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFilipino ? 'BAGO' : 'NEW',
        style: JHTextStyles.label.copyWith(
          color: ColorConstant.trustBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDownloadButton(bool isFilipino) {
    final downloadText = isFilipino ? 'I-download' : 'Download';

    return Semantics(
      label: 'Download article: ${content.getTitle(isFilipino ? 'fil' : 'en')}',
      hint: 'Double tap to download this article for offline reading',
      button: true,
      child: InkWell(
        onTap: onDownload,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ColorConstant.trustBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.download_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                downloadText,
                style: JHTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  Color _getCategoryColor(ContentCategory category) {
    switch (category) {
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
