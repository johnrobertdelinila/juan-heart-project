import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/services/privacy_service.dart';
import 'package:juan_heart/services/analytics_csv_service.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// Privacy & Data Preferences Screen
///
/// Allows users to manage their privacy settings including:
/// - Analytics opt-in/opt-out
/// - Data sharing preferences
/// - Personalized insights toggle
/// - Research contribution
/// - Data export (Philippine Data Privacy Act compliance)
/// - Data deletion requests
///
/// Implements granular consent management per DPA requirements

class PrivacyPreferencesScreen extends StatefulWidget {
  const PrivacyPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPreferencesScreen> createState() => _PrivacyPreferencesScreenState();
}

class _PrivacyPreferencesScreenState extends State<PrivacyPreferencesScreen> {
  bool _isLoading = true;
  bool _analyticsEnabled = true;
  bool _dataSharingEnabled = false;
  bool _personalizedInsightsEnabled = true;
  bool _researchContributionEnabled = false;
  DateTime? _consentDate;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final preferences = await PrivacyService.getPrivacyPreferences();

      setState(() {
        _analyticsEnabled = preferences.analyticsEnabled;
        _dataSharingEnabled = preferences.dataSharingEnabled;
        _personalizedInsightsEnabled = preferences.personalizedInsightsEnabled;
        _researchContributionEnabled = preferences.researchContributionEnabled;
        _consentDate = preferences.consentDate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load preferences: $e');
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      switch (key) {
        case 'analytics':
          await PrivacyService.setAnalyticsEnabled(value);
          setState(() => _analyticsEnabled = value);
          break;
        case 'data_sharing':
          await PrivacyService.setDataSharingEnabled(value);
          setState(() => _dataSharingEnabled = value);
          break;
        case 'personalized_insights':
          await PrivacyService.setPersonalizedInsightsEnabled(value);
          setState(() => _personalizedInsightsEnabled = value);
          break;
        case 'research':
          await PrivacyService.setResearchContributionEnabled(value);
          setState(() => _researchContributionEnabled = value);
          break;
      }

      _showSuccessSnackbar(
        Get.locale?.languageCode == 'fil'
            ? 'Naka-save na ang pagbabago'
            : 'Preference saved',
      );
    } catch (e) {
      _showErrorSnackbar('Failed to save preference: $e');
    }
  }

  Future<void> _exportPersonalData() async {
    try {
      // Show loading dialog
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  Get.locale?.languageCode == 'fil'
                      ? 'Ine-export ang iyong data...'
                      : 'Exporting your data...',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Export personal data as JSON
      final personalData = await PrivacyService.exportPersonalData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(personalData);

      // Also get assessment history and vital trends for complete export
      final history = await AnalyticsService.getAssessmentHistory();
      final vitalTrends = await AnalyticsService.getVitalSignsTrends();

      // Close loading dialog
      Get.back();

      // Show export options dialog
      Get.dialog(
        AlertDialog(
          title: Text(
            Get.locale?.languageCode == 'fil'
                ? 'I-export ang Personal Data'
                : 'Export Personal Data',
            style: TextStyle(
              color: ColorConstant.trustBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Get.locale?.languageCode == 'fil'
                    ? 'Pumili ng format para sa pag-export:'
                    : 'Choose export format:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.description, color: ColorConstant.trustBlue),
                title: const Text('JSON (Complete)'),
                subtitle: Text(
                  Get.locale?.languageCode == 'fil'
                      ? 'Lahat ng data kasama ang privacy settings'
                      : 'All data including privacy settings',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Get.back();
                  await _shareJsonData(jsonString);
                },
              ),
              ListTile(
                leading: Icon(Icons.table_chart, color: ColorConstant.reassuringGreen),
                title: const Text('CSV (Health Records)'),
                subtitle: Text(
                  Get.locale?.languageCode == 'fil'
                      ? 'Assessment history at vital signs'
                      : 'Assessment history and vital signs',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Get.back();
                  await _exportCsvData(history, vitalTrends);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                Get.locale?.languageCode == 'fil' ? 'Kanselahin' : 'Cancel',
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showErrorSnackbar('Failed to export data: $e');
    }
  }

  Future<void> _shareJsonData(String jsonString) async {
    try {
      // For now, show the JSON in a dialog (in production, use share_plus)
      Get.dialog(
        AlertDialog(
          title: const Text('Personal Data (JSON)'),
          content: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to share JSON: $e');
    }
  }

  Future<void> _exportCsvData(List<AssessmentRecord> history, Map<String, List<VitalSignTrend>> vitalTrends) async {
    try {
      final language = Get.locale?.languageCode ?? 'en';

      final result = await AnalyticsCSVService.exportAndShareCompleteAnalytics(
        history: history,
        vitalTrends: vitalTrends,
        language: language,
      );

      _showSuccessSnackbar(result);
    } catch (e) {
      _showErrorSnackbar('Failed to export CSV: $e');
    }
  }

  Future<void> _requestDataDeletion() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ColorConstant.emergencyBadge, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                Get.locale?.languageCode == 'fil'
                    ? 'Tanggalin ang Lahat ng Data'
                    : 'Delete All Data',
                style: TextStyle(
                  color: ColorConstant.emergencyBadge,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Sigurado ka ba?'
                  : 'Are you sure?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Ang aksyon na ito ay HINDI MABABALIK. Lahat ng iyong:'
                  : 'This action is IRREVERSIBLE. All your:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Assessment history'),
            _buildBulletPoint('Vital signs records'),
            _buildBulletPoint('Health insights'),
            _buildBulletPoint('Privacy preferences'),
            const SizedBox(height: 8),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'ay permanenteng mabubura.'
                  : 'will be permanently deleted.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.redLightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorConstant.emergencyBadge.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ColorConstant.emergencyBadge, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Get.locale?.languageCode == 'fil'
                          ? 'I-export muna ang iyong data bago burahin.'
                          : 'Consider exporting your data first.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstant.emergencyBadge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              Get.locale?.languageCode == 'fil' ? 'Kanselahin' : 'Cancel',
              style: TextStyle(color: ColorConstant.gentleGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.emergencyBadge,
            ),
            child: Text(
              Get.locale?.languageCode == 'fil' ? 'Oo, Tanggalin' : 'Yes, Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final result = await PrivacyService.deleteAllUserData();
        Get.back(); // Close loading

        if (result.success) {
          _showSuccessSnackbar(
            Get.locale?.languageCode == 'fil'
                ? '${result.recordsDeleted} na records ang natanggal'
                : '${result.recordsDeleted} records deleted successfully',
          );

          // Reload preferences
          await _loadPreferences();
        } else {
          _showErrorSnackbar(result.message);
        }
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back();
        _showErrorSnackbar('Failed to delete data: $e');
      }
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ColorConstant.emergencyBadge,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      Get.locale?.languageCode == 'fil' ? 'Tagumpay!' : 'Success!',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorConstant.reassuringGreen,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorConstant.emergencyBadge,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Privacy at Data'
              : 'Privacy & Data',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorConstant.trustBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with consent info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorConstant.trustBlue,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.privacy_tip, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                Get.locale?.languageCode == 'fil'
                                    ? 'Ang iyong privacy ay mahalaga sa amin'
                                    : 'Your privacy matters to us',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_consentDate != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            Get.locale?.languageCode == 'fil'
                                ? 'Consent ibinigay: ${DateFormat.yMMMd().format(_consentDate!)}'
                                : 'Consent given: ${DateFormat.yMMMd().format(_consentDate!)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Privacy Preferences Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Mga Privacy Preference'
                              : 'Privacy Preferences',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.trustBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Kontrolin kung paano ginagamit ang iyong data'
                              : 'Control how your data is used',
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstant.gentleGray,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Analytics Toggle
                        _buildPreferenceCard(
                          icon: Icons.analytics_outlined,
                          title: Get.locale?.languageCode == 'fil'
                              ? 'Analytics'
                              : 'Analytics',
                          description: Get.locale?.languageCode == 'fil'
                              ? 'Pahintulutan ang pag-track ng app usage para sa pagpapabuti'
                              : 'Allow app usage tracking for improvements',
                          value: _analyticsEnabled,
                          onChanged: (value) => _savePreference('analytics', value),
                        ),

                        // Data Sharing Toggle
                        _buildPreferenceCard(
                          icon: Icons.share_outlined,
                          title: Get.locale?.languageCode == 'fil'
                              ? 'Pagbabahagi ng Data'
                              : 'Data Sharing',
                          description: Get.locale?.languageCode == 'fil'
                              ? 'Ibahagi ang anonymous data sa healthcare partners'
                              : 'Share anonymized data with healthcare partners',
                          value: _dataSharingEnabled,
                          onChanged: (value) => _savePreference('data_sharing', value),
                        ),

                        // Personalized Insights Toggle
                        _buildPreferenceCard(
                          icon: Icons.psychology_outlined,
                          title: Get.locale?.languageCode == 'fil'
                              ? 'Personalized Insights'
                              : 'Personalized Insights',
                          description: Get.locale?.languageCode == 'fil'
                              ? 'Makakuha ng health recommendations base sa iyong data'
                              : 'Receive health recommendations based on your data',
                          value: _personalizedInsightsEnabled,
                          onChanged: (value) => _savePreference('personalized_insights', value),
                        ),

                        // Research Contribution Toggle
                        _buildPreferenceCard(
                          icon: Icons.science_outlined,
                          title: Get.locale?.languageCode == 'fil'
                              ? 'Kontribusyon sa Research'
                              : 'Research Contribution',
                          description: Get.locale?.languageCode == 'fil'
                              ? 'Tumulong sa cardiovascular research sa Pilipinas'
                              : 'Help cardiovascular research in the Philippines',
                          value: _researchContributionEnabled,
                          onChanged: (value) => _savePreference('research', value),
                        ),

                        const SizedBox(height: 32),

                        // Data Rights Section
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Mga Karapatan sa Data'
                              : 'Your Data Rights',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.trustBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Alinsunod sa Philippine Data Privacy Act'
                              : 'Per Philippine Data Privacy Act',
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstant.gentleGray,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Export Data Button
                        _buildActionCard(
                          icon: Icons.download_outlined,
                          iconColor: ColorConstant.trustBlue,
                          title: Get.locale?.languageCode == 'fil'
                              ? 'I-download ang Aking Data'
                              : 'Download My Data',
                          description: Get.locale?.languageCode == 'fil'
                              ? 'Kunin ang kopya ng lahat ng iyong personal data'
                              : 'Get a copy of all your personal data',
                          buttonText: Get.locale?.languageCode == 'fil'
                              ? 'I-export'
                              : 'Export',
                          onTap: _exportPersonalData,
                        ),

                        // Delete Data Button
                        _buildActionCard(
                          icon: Icons.delete_outline,
                          iconColor: ColorConstant.emergencyBadge,
                          title: Get.locale?.languageCode == 'fil'
                              ? 'Tanggalin ang Aking Data'
                              : 'Delete My Data',
                          description: Get.locale?.languageCode == 'fil'
                              ? 'Permanenteng tanggalin ang lahat ng health records'
                              : 'Permanently delete all your health records',
                          buttonText: Get.locale?.languageCode == 'fil'
                              ? 'Tanggalin'
                              : 'Delete',
                          onTap: _requestDataDeletion,
                          isDangerous: true,
                        ),

                        const SizedBox(height: 32),

                        // Privacy Policy Link
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorConstant.lightBlueBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorConstant.trustBlue.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: ColorConstant.trustBlue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Get.locale?.languageCode == 'fil'
                                          ? 'Para sa higit pang impormasyon'
                                          : 'For more information',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ColorConstant.trustBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Get.locale?.languageCode == 'fil'
                                          ? 'Basahin ang aming Privacy Policy at Terms of Service'
                                          : 'Read our Privacy Policy and Terms of Service',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorConstant.gentleGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: ColorConstant.trustBlue, size: 16),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstant.cardBorder),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.cardShadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstant.trustBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ColorConstant.trustBlue, size: 24),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstant.gentleGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ColorConstant.trustBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDangerous
              ? ColorConstant.emergencyBadge.withOpacity(0.3)
              : ColorConstant.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.cardShadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDangerous ? ColorConstant.emergencyBadge : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorConstant.gentleGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDangerous ? ColorConstant.emergencyBadge : ColorConstant.trustBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
