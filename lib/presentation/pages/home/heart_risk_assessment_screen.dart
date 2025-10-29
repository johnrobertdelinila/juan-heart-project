import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/presentation/widgets/assessment_widgets.dart';
import 'package:juan_heart/presentation/pages/home/medical_triage_assessment_screen.dart';

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

  @override
  void initState() {
    super.initState();
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212529),
              ),
            ),

            const SizedBox(height: 20),

            _buildInfoItem(
              icon: Icons.favorite,
              color: const Color(0xFFE63946),
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
              color: const Color(0xFF4CAF50),
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
              color: const Color(0xFF2E5BBA),
              title: lang == 'fil'
                  ? 'Personalized na gabay'
                  : 'Personalized Guidance',
              description: lang == 'fil'
                  ? 'Makakakuha ng recommendations na swak sa iyong kalagayan'
                  : 'Get recommendations tailored to your specific condition',
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5BBA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  lang == 'fil' ? 'Naintindihan' : 'Got it',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
            color: color.withOpacity(0.12),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConstant.gentleGray,
                  height: 1.4,
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
                color: Color(0xFF2E5BBA),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'fil'
                    ? 'Sample na Resulta'
                    : 'Sample Results',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'fil'
                    ? 'Makikita mo ang:\n\n• Heart risk score mo (0-25)\n• Risk category (Low to Critical)\n• Visual na heatmap\n• Personalized recommendations\n• Next steps para sa healthcare'
                    : 'You will see:\n\n• Your heart risk score (0-25)\n• Risk category (Low to Critical)\n• Visual heatmap\n• Personalized recommendations\n• Next steps for healthcare',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 15,
                  color: ColorConstant.gentleGray,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5BBA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    lang == 'fil' ? 'Salamat' : 'Thanks',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
    final userName = ''; // Get.find<UserController>().currentUser?.name ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    color: Color(0xFFE63946),
                  ),
                ),

                const SizedBox(height: 32),

                // Main greeting
                Text(
                  lang == 'fil'
                      ? 'Hi${userName.isNotEmpty ? " $userName" : ""}! Tingnan natin ang kalusugan ng puso mo.'
                      : 'Hi${userName.isNotEmpty ? " $userName" : ""}! Let\'s check your heart health.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212529),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtext
                Text(
                  lang == 'fil'
                      ? 'Sagutan ang ilang mabilis na tanong para malaman ang iyong heart risk. Tatagal lang ng 2 minuto.'
                      : 'Answer a few quick questions to assess your heart risk. It\'ll take less than 2 minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: ColorConstant.gentleGray,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // Feature highlights
                _buildFeatureItem(
                  icon: Icons.timer_outlined,
                  text: lang == 'fil'
                      ? 'Mabilis lang - 2 minuto'
                      : 'Quick - 2 minutes',
                  color: const Color(0xFF2E5BBA),
                ),

                const SizedBox(height: 12),

                _buildFeatureItem(
                  icon: Icons.verified_user_outlined,
                  text: lang == 'fil'
                      ? 'Verified ng Philippine Heart Center'
                      : 'Verified by Philippine Heart Center',
                  color: const Color(0xFF4CAF50),
                ),

                const SizedBox(height: 12),

                _buildFeatureItem(
                  icon: Icons.insights_outlined,
                  text: lang == 'fil'
                      ? 'Makakakuha ng personalized na recommendations'
                      : 'Get personalized recommendations',
                  color: const Color(0xFFFFA726),
                ),

                const SizedBox(height: 40),

                // Start button
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BBA),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(0xFF2E5BBA).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          lang == 'fil'
                              ? 'Simulan ang Assessment'
                              : 'Start Assessment',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstant.trustBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: ColorConstant.gentleGray)),
                    TextButton(
                      onPressed: () => _showSampleResults(context),
                      child: Text(
                        lang == 'fil'
                            ? 'Tignan ang sample'
                            : 'View sample results',
                        style: TextStyle(
                          fontSize: 14,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorConstant.bluedark.withOpacity(0.8),
                            height: 1.4,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
        ],
      ),
    );
  }
}
