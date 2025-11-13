import 'package:flutter/material.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Widget for displaying validation comparison when AI and rule-based scores differ
///
/// This widget shows:
/// - Warning banner about discrepancy
/// - Side-by-side comparison of AI vs Rule-Based results
/// - Explanation of why scores might differ
/// - Option to view detailed breakdown
class ValidationComparisonView extends StatelessWidget {
  final Map<String, dynamic> aiResult;
  final bool isFilipino;

  const ValidationComparisonView({
    Key? key,
    required this.aiResult,
    required this.isFilipino,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract data
    // Always show comparison when AI is used for transparency
    // Parent screen controls visibility
    final hasDiscrepancy = aiResult['hasDiscrepancy'] as bool? ?? false;
    final scoreDifference = aiResult['scoreDifference'] as int? ?? 0;
    final aiScore = aiResult['finalRiskScore'] as int? ?? 0;
    final ruleBasedScore = aiResult['ruleBasedScore'] as int? ?? 0;
    final aiCategory = aiResult['riskCategory'] as String? ?? 'Unknown';
    final ruleBasedCategory =
        aiResult['ruleBasedCategory'] as String? ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info/Warning Banner - Show different styling based on discrepancy size
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasDiscrepancy ? Colors.orange[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDiscrepancy ? Colors.orange[300]! : Colors.blue[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasDiscrepancy
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: hasDiscrepancy ? Colors.orange[700] : Colors.blue[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFilipino
                          ? (hasDiscrepancy
                              ? 'May Pagkakaiba sa mga Resulta'
                              : 'Dual Assessment')
                          : (hasDiscrepancy
                              ? 'Results Differ'
                              : 'Dual Assessment'),
                      style: JHTextStyles.bodyBase.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasDiscrepancy
                            ? Colors.orange[900]
                            : Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFilipino
                          ? 'Ang AI at rule-based assessment ay nagkaiba ng $scoreDifference points. Tingnan ang parehong resulta sa ibaba.'
                          : 'AI and rule-based assessments differ by $scoreDifference points. Both results shown below for your review.',
                      style: JHTextStyles.caption.copyWith(
                        color: hasDiscrepancy
                            ? Colors.orange[800]
                            : Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Comparison Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Result Card
            Expanded(
              child: _buildResultCard(
                title: isFilipino ? 'AI Prediction' : 'AI Prediction',
                badge: isFilipino ? 'EXPERIMENTAL' : 'EXPERIMENTAL',
                badgeColor: Colors.orange,
                score: aiScore,
                category: aiCategory,
                recommendation: aiResult['recommendedAction'] as String? ?? '',
                explanation: aiResult['explanation'] as String? ?? '',
                confidence: aiResult['confidence'] as double? ?? 0.0,
                isAI: true,
              ),
            ),

            const SizedBox(width: 12),

            // Rule-Based Result Card
            Expanded(
              child: _buildResultCard(
                title: isFilipino ? 'PHC Algorithm' : 'PHC Algorithm',
                badge: isFilipino ? 'VALIDATED' : 'VALIDATED',
                badgeColor: Colors.green,
                score: ruleBasedScore,
                category: ruleBasedCategory,
                recommendation:
                    aiResult['ruleBasedRecommendation'] as String? ?? '',
                explanation: null,
                confidence: null,
                isAI: false,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Explanation Section
        _buildExplanationSection(),
      ],
    );
  }

  /// Build individual result card
  Widget _buildResultCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required int score,
    required String category,
    required String recommendation,
    String? explanation,
    double? confidence,
    required bool isAI,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isAI ? Colors.orange[200]! : Colors.green[200]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: StandardCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: JHTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: JHTextStyles.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Score
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    score.toString(),
                    style: JHTextStyles.h2.copyWith(
                      color: _getCategoryColor(category),
                    ),
                  ),
                  Text(
                    category,
                    style: JHTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Recommendation
            Text(
              recommendation,
              style: JHTextStyles.caption.copyWith(
                fontSize: 11,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // AI-specific fields
            if (isAI && explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                explanation,
                style: JHTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (isAI && confidence != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.analytics, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% confidence',
                    style: JHTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build explanation section
  Widget _buildExplanationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                isFilipino ? 'Bakit may pagkakaiba?' : 'Why do they differ?',
                style: JHTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isFilipino
                ? '• Ang AI ay gumagamit ng mas malawak na context analysis\n'
                    '• Ang rule-based algorithm ay sumusunod sa mahigpit na clinical guidelines\n'
                    '• Ang parehong resulta ay valid para sa inyong consideration\n'
                    '• Kung may tanong, kumonsulta sa doktor'
                : '• AI uses broader context analysis\n'
                    '• Rule-based algorithm follows strict clinical guidelines\n'
                    '• Both results are valid for your consideration\n'
                    '• Consult with a doctor if you have questions',
            style: JHTextStyles.caption.copyWith(
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for risk category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return ColorConstant.reassuringGreen;
      case 'mild':
        return Colors.yellow[700]!;
      case 'moderate':
        return Colors.orange[600]!;
      case 'high':
        return Colors.deepOrange[600]!;
      case 'critical':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }
}
