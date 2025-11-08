import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/presentation/widgets/assessment_widgets.dart';
import 'package:juan_heart/presentation/pages/home/medical_triage_assessment_screen.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/services/performance_service.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';

/// Enhanced Heart Assessment Screen (Replaces old intro screen)
/// 
/// This is now the main entry point for Heart Risk Assessment
/// Features:
/// - Animated heart logo with pulse effect
/// - Conversational greeting with user personalization
/// - Clear value proposition (< 2 minutes)
/// - Bilingual support (English/Filipino)
/// - Privacy assurance badge
/// - Large, accessible start button
/// - Soft gradient background for emotional warmth
class HeartRiskAssessmentScreen extends StatefulWidget {
  const HeartRiskAssessmentScreen({super.key});

  @override
  State<HeartRiskAssessmentScreen> createState() =>
      _HeartRiskAssessmentScreenState();
}

class _HeartRiskAssessmentScreenState extends State<HeartRiskAssessmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Trace? _screenTrace;

  @override
  void initState() {
    super.initState();
    _startScreenTrace();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  /// Start screen load performance trace
  Future<void> _startScreenTrace() async {
    _screenTrace = await PerformanceService.instance.startScreenTrace('heart_risk_assessment_screen');

    // Stop trace after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceService.instance.stopScreenTrace(_screenTrace);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startAssessment() {
    // Navigate directly to the assessment form
    Get.to(
      () => const MedicalTriageAssessmentScreen(),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showLearnMore(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'en';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: ColorConstant.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              lang == 'fil'
                  ? 'Bakit mahalaga ang Heart Risk Assessment?'
                  : 'Why is Heart Risk Assessment Important?',
              style: JHTextStyles.h3.copyWith(
                color: const JHColors.slate900,
              ),
            ),

            const SizedBox(height: 20),

            _buildInfoItem(
              icon: Icons.favorite,
              color: const JHColors.danger,
              title: lang == 'fil'
                  ? 'Maaga na pagkilala'
                  : 'Early Detection',
              description: lang == 'fil'
                  ? 'Mas madaling gamutin ang heart disease kung maaga na itong natuklasan'
                  : 'Heart disease is easier to treat when detected early',
            ),

            const SizedBox(height: 16),

            _buildInfoItem(
              icon: Icons.shield_outlined,
              color: const JHColors.success,
              title: lang == 'fil'
                  ? 'Iwas sa komplikasyon'
                  : 'Prevent Complications',
              description: lang == 'fil'
                  ? 'Makakapag-prevent ng mas seryosong problema sa puso'
                  : 'Can prevent more serious heart problems from developing',
            ),

            const SizedBox(height: 16),

            _buildInfoItem(
              icon: Icons.insights,
              color: const JHColors.infoDark,
              title: lang == 'fil'
                  ? 'Personalized na gabay'
                  : 'Personalized Guidance',
              description: lang == 'fil'
                  ? 'Makakakuha ng recommendations na swak sa iyong kalagayan'
                  : 'Get recommendations tailored to your specific condition',
            ),

            const SizedBox(height: 24),

            StandardButton.primary(
              text: lang == 'fil' ? 'Naintindihan' : 'Got it',
              onPressed: () => Navigator.pop(context),
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: JHTextStyles.bodyBase.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const JHColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.gentleGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSampleResults(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'en';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 60,
                color: JHColors.infoDark,
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'fil'
                    ? 'Sample na Resulta'
                    : 'Sample Results',
                style: JHTextStyles.h3.copyWith(
                  color: const JHColors.slate900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'fil'
                    ? 'Makikita mo ang:\n\n• Heart risk score mo (0-25)\n• Risk category (Low to Critical)\n• Visual na heatmap\n• Personalized recommendations\n• Next steps para sa healthcare'
                    : 'You will see:\n\n• Your heart risk score (0-25)\n• Risk category (Low to Critical)\n• Visual heatmap\n• Personalized recommendations\n• Next steps for healthcare',
                textAlign: TextAlign.left,
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.gentleGray,
                ),
              ),
              const SizedBox(height: 24),
              StandardButton.primary(
                text: lang == 'fil' ? 'Salamat' : 'Thanks',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'en';
    // You could get user name from a user service/controller
    const userName = ''; // Get.find<UserController>().currentUser?.name ?? '';

    return Scaffold(
      backgroundColor: const JHColors.infoLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorConstant.bluedark,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.language,
              color: ColorConstant.bluedark,
            ),
            onPressed: () {
              // Toggle language
              Get.updateLocale(
                Get.locale?.languageCode == 'fil'
                    ? const Locale('en', 'US')
                    : const Locale('fil', 'PH'),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Animated heart icon
                const Center(
                  child: AnimatedHeartLogo(
                    size: 100,
                    color: JHColors.danger,
                  ),
                ),

                const SizedBox(height: 32),

                // Main greeting
                Text(
                  lang == 'fil'
                      ? 'Hi${userName.isNotEmpty ? " $userName" : ""}! Tingnan natin ang kalusugan ng puso mo.'
                      : 'Hi${userName.isNotEmpty ? " $userName" : ""}! Let\'s check your heart health.',
                  textAlign: TextAlign.center,
                  style: JHTextStyles.h2.copyWith(
                    color: const JHColors.slate900,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtext
                Text(
                  lang == 'fil'
                      ? 'Sagutan ang ilang mabilis na tanong para malaman ang iyong heart risk. Tatagal lang ng 2 minuto.'
                      : 'Answer a few quick questions to assess your heart risk. It\'ll take less than 2 minutes.',
                  textAlign: TextAlign.center,
                  style: JHTextStyles.bodyBase.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                ),

                const SizedBox(height: 32),

                // Feature highlights
                _buildFeatureItem(
                  icon: Icons.timer_outlined,
                  text: lang == 'fil'
                      ? 'Mabilis lang - 2 minuto'
                      : 'Quick - 2 minutes',
                  color: const JHColors.infoDark,
                ),

                const SizedBox(height: 12),

                _buildFeatureItem(
                  icon: Icons.verified_user_outlined,
                  text: lang == 'fil'
                      ? 'Verified ng Philippine Heart Center'
                      : 'Verified by Philippine Heart Center',
                  color: const JHColors.success,
                ),

                const SizedBox(height: 12),

                _buildFeatureItem(
                  icon: Icons.insights_outlined,
                  text: lang == 'fil'
                      ? 'Makakakuha ng personalized na recommendations'
                      : 'Get personalized recommendations',
                  color: const JHColors.warning,
                ),

                const SizedBox(height: 40),

                // Start button
                StandardButton.primary(
                  text: lang == 'fil'
                      ? 'Simulan ang Assessment'
                      : 'Start Assessment',
                  onPressed: _startAssessment,
                ),

                const SizedBox(height: 16),

                // Secondary links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showLearnMore(context),
                      child: Text(
                        lang == 'fil'
                            ? 'Bakit ito importante?'
                            : 'Learn why this is important',
                        style: JHTextStyles.bodySmall.copyWith(
                          color: ColorConstant.trustBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(' • ', style: JHTextStyles.bodySmall.copyWith(color: ColorConstant.gentleGray)),
                    TextButton(
                      onPressed: () => _showSampleResults(context),
                      child: Text(
                        lang == 'fil'
                            ? 'Tignan ang sample'
                            : 'View sample results',
                        style: JHTextStyles.bodySmall.copyWith(
                          color: ColorConstant.trustBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Privacy note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstant.warmBeige,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorConstant.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 20,
                        color: ColorConstant.trustBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang == 'fil'
                              ? 'Ang iyong data ay ligtas at private. Hindi ito ibabahagi sa ibang tao o kumpanya.'
                              : 'Your data is safe and private. We don\'t share your information with anyone.',
                          style: JHTextStyles.caption.copyWith(
                            color: ColorConstant.bluedark.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return StandardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: JHTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: const JHColors.slate900,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: JHColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}
