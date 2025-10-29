import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/services/ai_consent_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog for obtaining user consent for AI assessment
///
/// This dialog:
/// - Explains what data is sent to Gemini API
/// - Provides privacy policy link
/// - Requires explicit opt-in
/// - Tracks consent status
class AIConsentDialog extends StatefulWidget {
  const AIConsentDialog({Key? key}) : super(key: key);

  @override
  State<AIConsentDialog> createState() => _AIConsentDialogState();
}

class _AIConsentDialogState extends State<AIConsentDialog> {
  bool _agreedToTerms = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: ColorConstant.lightRed,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isFilipino
                  ? 'Pahintulot para sa AI Assessment'
                  : 'AI Assessment Consent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFilipino
                          ? 'Kailangan ng inyong pahintulot bago gamitin ang AI'
                          : 'Your consent is required to use AI assessment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Consent text
            Text(
              AIConsentService.getConsentText(isFilipino: isFilipino),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ColorConstant.bluedark,
              ),
            ),

            const SizedBox(height: 16),

            // Privacy policy link
            InkWell(
              onTap: _openPrivacyPolicy,
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                  Text(
                    isFilipino
                        ? 'Basahin ang Privacy Policy'
                        : 'Read Privacy Policy',
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorConstant.lightRed,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Agreement checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _agreedToTerms = !_agreedToTerms;
                });
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    activeColor: ColorConstant.lightRed,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        isFilipino
                            ? 'Naiintindihan ko at sumasang-ayon ako sa mga kondisyon sa itaas'
                            : 'I understand and agree to the terms above',
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorConstant.bluedark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isProcessing
              ? null
              : () {
                  Get.back(result: false);
                },
          child: Text(
            isFilipino ? 'Kanselahin' : 'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Accept button
        ElevatedButton(
          onPressed: _agreedToTerms && !_isProcessing ? _acceptConsent : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstant.lightRed,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isFilipino ? 'Sumang-ayon' : 'Accept',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  /// Handle consent acceptance
  Future<void> _acceptConsent() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Grant consent
      final success = await AIConsentService.grantConsent();

      if (success) {
        // Show success message
        final isFilipino = Get.locale?.languageCode == 'fil';

        Get.snackbar(
          isFilipino ? 'Salamat!' : 'Thank you!',
          isFilipino
              ? 'Maaari na ninyong gamitin ang AI assessment'
              : 'You can now use AI assessment',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        // Return success
        Get.back(result: true);
      } else {
        throw Exception('Failed to save consent');
      }

    } catch (e) {
      // Show error
      final isFilipino = Get.locale?.languageCode == 'fil';

      Get.snackbar(
        'Error',
        isFilipino
            ? 'Hindi ma-save ang pahintulot. Subukan ulit.'
            : 'Failed to save consent. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Open privacy policy in browser
  Future<void> _openPrivacyPolicy() async {
    try {
      final url = Uri.parse(AIConsentService.getPrivacyPolicyUrl());

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch privacy policy URL');
      }

    } catch (e) {
      final isFilipino = Get.locale?.languageCode == 'fil';

      Get.snackbar(
        'Error',
        isFilipino
            ? 'Hindi mabuksan ang privacy policy'
            : 'Could not open privacy policy',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// Show AI consent dialog
///
/// Returns true if user consented, false otherwise.
Future<bool> showAIConsentDialog() async {
  final result = await Get.dialog<bool>(
    const AIConsentDialog(),
    barrierDismissible: false,
  );

  return result ?? false;
}
