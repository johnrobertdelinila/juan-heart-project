import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/services/privacy_service.dart';

/// Privacy Consent Dialog
///
/// Shows on first app launch or when privacy consent is not yet given
/// Implements Philippine Data Privacy Act compliance requirements
/// Provides granular consent options for users

class PrivacyConsentDialog extends StatefulWidget {
  final VoidCallback onConsentGiven;

  const PrivacyConsentDialog({
    Key? key,
    required this.onConsentGiven,
  }) : super(key: key);

  @override
  State<PrivacyConsentDialog> createState() => _PrivacyConsentDialogState();

  /// Show the consent dialog
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onConsentGiven,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must give consent
      builder: (context) => PrivacyConsentDialog(
        onConsentGiven: onConsentGiven,
      ),
    );
  }
}

class _PrivacyConsentDialogState extends State<PrivacyConsentDialog> {
  bool _analyticsEnabled = true;
  bool _dataSharingEnabled = false;
  bool _personalizedInsightsEnabled = true;
  bool _researchContributionEnabled = false;
  bool _isProcessing = false;
  int _currentPage = 0;

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _giveConsent() async {
    setState(() => _isProcessing = true);

    try {
      await PrivacyService.giveConsent(
        analyticsEnabled: _analyticsEnabled,
        dataSharingEnabled: _dataSharingEnabled,
        personalizedInsightsEnabled: _personalizedInsightsEnabled,
        researchContributionEnabled: _researchContributionEnabled,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onConsentGiven();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      Get.snackbar(
        'Error',
        'Failed to save consent: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstant.emergencyBadge,
        colorText: Colors.white,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _giveConsent();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorConstant.trustBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Get.locale?.languageCode == 'fil'
                          ? 'Privacy at Data Protection'
                          : 'Privacy & Data Protection',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? ColorConstant.trustBlue
                            : ColorConstant.gentleGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildConsentOptionsPage(),
                  _buildConfirmationPage(),
                ],
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: ColorConstant.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _isProcessing ? null : _previousPage,
                      child: Text(
                        Get.locale?.languageCode == 'fil' ? 'Bumalik' : 'Back',
                        style: TextStyle(color: ColorConstant.gentleGray),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.trustBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentPage < 2
                                ? (Get.locale?.languageCode == 'fil'
                                    ? 'Susunod'
                                    : 'Next')
                                : (Get.locale?.languageCode == 'fil'
                                    ? 'Sumang-ayon'
                                    : 'I Agree'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety,
            color: ColorConstant.trustBlue,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Maligayang pagdating sa Juan Heart!'
                : 'Welcome to Juan Heart!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorConstant.trustBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Bago magsimula, kailangan nating pag-usapan kung paano namin poprotektahan ang iyong health data.'
                : 'Before we begin, let\'s talk about how we protect your health data.',
            style: TextStyle(
              fontSize: 15,
              color: ColorConstant.gentleGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            icon: Icons.lock_outline,
            title: Get.locale?.languageCode == 'fil'
                ? 'Secure Storage'
                : 'Secure Storage',
            description: Get.locale?.languageCode == 'fil'
                ? 'Lahat ng iyong health records ay naka-encrypt at ligtas sa iyong device'
                : 'All your health records are encrypted and stored securely on your device',
          ),
          _buildInfoCard(
            icon: Icons.verified_user_outlined,
            title: Get.locale?.languageCode == 'fil'
                ? 'Philippine Data Privacy Act'
                : 'Philippine Data Privacy Act',
            description: Get.locale?.languageCode == 'fil'
                ? 'Sumusunod kami sa DPA at NPC guidelines para sa medical data'
                : 'We comply with DPA and NPC guidelines for medical data',
          ),
          _buildInfoCard(
            icon: Icons.control_point_outlined,
            title: Get.locale?.languageCode == 'fil'
                ? 'You Have Control'
                : 'You Have Control',
            description: Get.locale?.languageCode == 'fil'
                ? 'Ikaw ang may kontrol - pwede mong i-export o i-delete ang iyong data anumang oras'
                : 'You\'re in control - export or delete your data anytime',
          ),
        ],
      ),
    );
  }

  Widget _buildConsentOptionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Pumili ng Mga Preference'
                : 'Choose Your Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstant.trustBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Pwede mong baguhin ito mamaya sa Settings'
                : 'You can change these later in Settings',
            style: TextStyle(
              fontSize: 14,
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 24),

          // Analytics
          _buildConsentOption(
            icon: Icons.analytics_outlined,
            title: Get.locale?.languageCode == 'fil'
                ? 'Analytics at Improvements'
                : 'Analytics & Improvements',
            description: Get.locale?.languageCode == 'fil'
                ? 'Tulungan kami na pahusayin ang app gamit ang anonymous usage data'
                : 'Help us improve the app using anonymous usage data',
            value: _analyticsEnabled,
            recommended: true,
            onChanged: (value) {
              setState(() => _analyticsEnabled = value);
            },
          ),

          // Personalized Insights
          _buildConsentOption(
            icon: Icons.psychology_outlined,
            title: Get.locale?.languageCode == 'fil'
                ? 'Personalized Health Insights'
                : 'Personalized Health Insights',
            description: Get.locale?.languageCode == 'fil'
                ? 'Makatanggap ng AI-driven health recommendations base sa iyong data'
                : 'Receive AI-driven health recommendations based on your data',
            value: _personalizedInsightsEnabled,
            recommended: true,
            onChanged: (value) {
              setState(() => _personalizedInsightsEnabled = value);
            },
          ),

          // Data Sharing
          _buildConsentOption(
            icon: Icons.share_outlined,
            title: Get.locale?.languageCode == 'fil'
                ? 'Data Sharing (Optional)'
                : 'Data Sharing (Optional)',
            description: Get.locale?.languageCode == 'fil'
                ? 'Ibahagi ang anonymized data sa Philippine Heart Center para sa research'
                : 'Share anonymized data with Philippine Heart Center for research',
            value: _dataSharingEnabled,
            recommended: false,
            onChanged: (value) {
              setState(() => _dataSharingEnabled = value);
            },
          ),

          // Research Contribution
          _buildConsentOption(
            icon: Icons.science_outlined,
            title: Get.locale?.languageCode == 'fil'
                ? 'Research Contribution (Optional)'
                : 'Research Contribution (Optional)',
            description: Get.locale?.languageCode == 'fil'
                ? 'Tumulong sa cardiovascular research sa Pilipinas'
                : 'Contribute to cardiovascular research in the Philippines',
            value: _researchContributionEnabled,
            recommended: false,
            onChanged: (value) {
              setState(() => _researchContributionEnabled = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: ColorConstant.reassuringGreen,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Handa na!'
                : 'All Set!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorConstant.trustBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Narito ang iyong mga pinili:'
                : 'Here\'s what you\'ve chosen:',
            style: TextStyle(
              fontSize: 15,
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 24),

          _buildSummaryItem(
            'Analytics',
            _analyticsEnabled,
          ),
          _buildSummaryItem(
            'Personalized Insights',
            _personalizedInsightsEnabled,
          ),
          _buildSummaryItem(
            'Data Sharing',
            _dataSharingEnabled,
          ),
          _buildSummaryItem(
            'Research Contribution',
            _researchContributionEnabled,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstant.lightBlueBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstant.trustBlue.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ColorConstant.trustBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Get.locale?.languageCode == 'fil'
                          ? 'Mahalagang Tandaan'
                          : 'Important Note',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.trustBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Get.locale?.languageCode == 'fil'
                      ? 'Pwede mong baguhin ang mga preference na ito anumang oras sa Settings > Privacy & Data. Mayroon ka ring karapatan na i-export o i-delete ang iyong lahat ng data.'
                      : 'You can change these preferences anytime in Settings > Privacy & Data. You also have the right to export or delete all your data.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstant.gentleGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.lightBlueBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstant.trustBlue.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorConstant.trustBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.trustBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstant.gentleGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentOption({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required bool recommended,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? ColorConstant.trustBlue.withOpacity(0.3)
              : ColorConstant.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.cardShadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorConstant.trustBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstant.reassuringGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    Get.locale?.languageCode == 'fil'
                        ? 'Inirerekomenda'
                        : 'Recommended',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ColorConstant.reassuringGreen,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: ColorConstant.trustBlue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: ColorConstant.gentleGray,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled
                ? ColorConstant.reassuringGreen
                : ColorConstant.gentleGray,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: enabled ? Colors.black87 : ColorConstant.gentleGray,
              fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
