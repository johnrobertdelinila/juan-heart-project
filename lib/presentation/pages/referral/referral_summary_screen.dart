/// Referral Summary Screen - Enhanced UI/UX
/// 
/// Redesigned with:
/// - QR code for facility navigation
/// - Share to family feature
/// - Appointment preparation tips
/// - Enhanced visual design
/// - Bilingual support
/// 
/// Final step in the referral flow
/// Displays summary of assessment results and selected facility
/// Allows generating and sharing PDF referral document
/// 
/// Part of the Referral & Care Navigation System

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/services/referral_pdf_service.dart';
import 'package:juan_heart/themes/app_styles.dart';
import 'package:juan_heart/presentation/widgets/referral_widgets.dart';

class ReferralSummaryScreen extends StatefulWidget {
  const ReferralSummaryScreen({Key? key}) : super(key: key);
  
  @override
  State<ReferralSummaryScreen> createState() => _ReferralSummaryScreenState();
}

class _ReferralSummaryScreenState extends State<ReferralSummaryScreen> {
  CareRecommendation? _recommendation;
  HealthcareFacility? _selectedFacility;
  Map<String, dynamic>? _assessmentData;
  
  bool _isGenerating = false;
  
  @override
  void initState() {
    super.initState();
    _loadArguments();
  }
  
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _recommendation = args['recommendation'] as CareRecommendation?;
      _selectedFacility = args['selectedFacility'] as HealthcareFacility?;
      _assessmentData = args['assessmentData'] as Map<String, dynamic>?;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final String lang = Get.locale?.languageCode ?? 'en';
    
    if (_recommendation == null || _selectedFacility == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(lang == 'fil' ? 'Error' : 'Error'),
        ),
        body: Center(
          child: Text(
            lang == 'fil'
                ? 'Walang data na nakita'
                : 'No data found',
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'fil' ? 'Referral Summary' : 'Referral Summary',
              style: AppStyle.txtPoppinsSemiBold20Dark,
            ),
            Text(
              lang == 'fil' ? 'Handa na para i-share' : 'Ready to share',
              style: TextStyle(
                fontSize: 12,
                color: ColorConstant.gentleGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              ColorConstant.softWhite,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success banner
              _buildSuccessBanner(lang),
              
              const SizedBox(height: 20),
              
              // Risk assessment summary
              _buildRiskSummary(lang),
              
              const SizedBox(height: 16),
              
              // Selected facility card
              _buildFacilityCard(lang),
              
              const SizedBox(height: 16),
              
              // QR Code section
              _buildQRCodeSection(lang),
              
              const SizedBox(height: 16),
              
              // Appointment prep tips
              _buildAppointmentPrep(lang),
              
              const SizedBox(height: 16),
              
              // Recommendation summary
              _buildRecommendationSummary(lang),
              
              const SizedBox(height: 30),
              
              // Action buttons
              _buildActionButtons(lang),
              
              const SizedBox(height: 16),
              
              // Share to family
              _buildShareToFamily(lang),
              
              const SizedBox(height: 20),
              
              // Disclaimer
              _buildDisclaimer(lang),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Success banner
  Widget _buildSuccessBanner(String lang) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstant.reassuringGreen.withOpacity(0.12),
            ColorConstant.reassuringGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstant.reassuringGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstant.reassuringGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: ColorConstant.reassuringGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'fil' ? '✓ Referral Completed' : '✓ Referral Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.reassuringGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang == 'fil'
                      ? 'Handa na ang iyong referral document'
                      : 'Your referral document is ready',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstant.bluedark.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskSummary(String lang) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _recommendation!.indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _recommendation!.indicatorColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'fil' ? 'Resulta ng Assessment' : 'Assessment Result',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorConstant.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _recommendation!.urgencyIcon,
                size: 40,
                color: _recommendation!.indicatorColor,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recommendation!.riskCategory,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _recommendation!.indicatorColor,
                    ),
                  ),
                  Text(
                    '${lang == "fil" ? "Puntos" : "Score"}: ${_recommendation!.riskScore}/25',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorConstant.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _recommendation!.indicatorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _recommendation!.timeframe,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _recommendation!.indicatorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFacilityCard(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstant.lightBlueBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstant.bluelight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'fil' ? 'Napiling Pasilidad' : 'Selected Facility',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorConstant.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstant.bluelight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedFacility!.typeIcon,
                  color: ColorConstant.bluelight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFacility!.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.bluedark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFacility!.typeName,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstant.bluelight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, _selectedFacility!.address),
          if (_selectedFacility!.primaryContact != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, _selectedFacility!.primaryContact!),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(Icons.directions, _selectedFacility!.distanceText),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ColorConstant.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: ColorConstant.grey,
            ),
          ),
        ),
      ],
    );
  }
  
  /// QR Code section for facility navigation
  Widget _buildQRCodeSection(String lang) {
    final String facilityData = '${_selectedFacility!.name}|${_selectedFacility!.mapsUrl}|${_selectedFacility!.primaryContact ?? ""}';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.cardShadowMedium,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: ColorConstant.calmingBlue,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == 'fil' ? 'I-scan ang QR Code' : 'Scan QR Code',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstant.cardBorder,
                width: 2,
              ),
            ),
            child: QrImageView(
              data: facilityData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              errorStateBuilder: (ctx, err) {
                return Container(
                  width: 180,
                  height: 180,
                  alignment: Alignment.center,
                  child: Text(
                    'QR Code Error',
                    style: TextStyle(color: ColorConstant.gentleGray),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            lang == 'fil'
                ? 'Ipakita sa facility para mabilis na makuha ang directions at contact info'
                : 'Show at facility for quick access to directions and contact info',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: ColorConstant.gentleGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Appointment preparation tips
  Widget _buildAppointmentPrep(String lang) {
    List<String> tips = _getAppointmentTips(lang);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstant.calmingBlue.withOpacity(0.08),
            ColorConstant.calmingBlue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstant.calmingBlue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstant.calmingBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: ColorConstant.calmingBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == 'fil' ? 'Paghanda sa Appointment' : 'Appointment Preparation',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.trustBlue,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ColorConstant.calmingBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstant.bluedark.withOpacity(0.95),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
  
  /// Get appointment tips based on risk level
  List<String> _getAppointmentTips(String lang) {
    if (lang == 'fil') {
      if (_recommendation!.isEmergency) {
        return [
          'Dalhin ang valid ID at PhilHealth card kung meron',
          'Magdala ng kasama o family member',
          'Ipaalam sa facility na galing ka sa Juan Heart referral',
          'Huwag mag-alangan na magtanong sa healthcare provider',
        ];
      } else if (_recommendation!.isUrgent) {
        return [
          'Magdala ng ID, PhilHealth card, at medical records',
          'Magtanong about appointment availability',
          'Ilista ang lahat ng sintomas at kailan nagsimula',
          'Magdala ng listahan ng current medications',
          'Maghanda ng mga tanong para sa doktor',
        ];
      } else {
        return [
          'Mag-set ng appointment in advance',
          'Magdala ng health records at previous test results',
          'Gumawa ng list ng health concerns',
          'Magtanong about lifestyle recommendations',
          'I-track ang blood pressure at heart rate bago pumunta',
        ];
      }
    } else {
      if (_recommendation!.isEmergency) {
        return [
          'Bring valid ID and PhilHealth card if available',
          'Bring a companion or family member',
          'Inform facility you have a Juan Heart referral',
          'Don\'t hesitate to ask healthcare provider questions',
        ];
      } else if (_recommendation!.isUrgent) {
        return [
          'Bring ID, PhilHealth card, and medical records',
          'Ask about appointment availability',
          'List all symptoms and when they started',
          'Bring list of current medications',
          'Prepare questions for your doctor',
        ];
      } else {
        return [
          'Schedule appointment in advance',
          'Bring health records and previous test results',
          'Make a list of health concerns',
          'Ask about lifestyle recommendations',
          'Track blood pressure and heart rate before visit',
        ];
      }
    }
  }
  
  Widget _buildRecommendationSummary(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstant.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'fil' ? 'Rekomendasyon' : 'Recommendation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorConstant.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _recommendation!.actionTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _recommendation!.actionMessage,
            style: TextStyle(
              fontSize: 14,
              color: ColorConstant.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Download PDF button
          LargeAccessibleButton(
            label: lang == 'fil' ? 'I-download ang PDF' : 'Download PDF',
            icon: Icons.download,
            backgroundColor: ColorConstant.calmingBlue,
            onPressed: () => _generatePDF(download: true),
            isLoading: _isGenerating,
          ),
          
          const SizedBox(height: 14),
          
          // Share PDF button
          LargeAccessibleButton(
            label: lang == 'fil' ? 'I-share ang PDF' : 'Share PDF',
            icon: Icons.share,
            backgroundColor: ColorConstant.reassuringGreen,
            onPressed: () => _generatePDF(download: false),
            isLoading: _isGenerating,
            isOutlined: false,
          ),
        ],
      ),
    );
  }
  
  /// Share to family feature
  Widget _buildShareToFamily(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstant.warmBeige.withOpacity(0.5),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstant.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: ColorConstant.trustBlue,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == 'fil' ? 'I-share sa Pamilya' : 'Share with Family',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            lang == 'fil'
                ? 'Ipaalam sa iyong pamilya ang resulta ng assessment at kung saan ka pupunta.'
                : 'Let your family know your assessment results and where you\'re going.',
            style: TextStyle(
              fontSize: 14,
              color: ColorConstant.gentleGray,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _shareToFamily,
              icon: const Icon(Icons.send, size: 20),
              label: Text(
                lang == 'fil' ? 'I-send ang Message' : 'Send Message',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstant.trustBlue,
                side: BorderSide(color: ColorConstant.trustBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Share to family via SMS/messaging apps
  Future<void> _shareToFamily() async {
    final String lang = Get.locale?.languageCode ?? 'en';
    
    String message;
    if (lang == 'fil') {
      message = '''Hi! Kakatapos ko lang ng heart checkup assessment gamit ang Juan Heart app.

Resulta: ${_recommendation!.riskCategory}
Pupuntahan ko: ${_selectedFacility!.name}
Address: ${_selectedFacility!.address}
${_selectedFacility!.primaryContact != null ? 'Contact: ${_selectedFacility!.primaryContact}' : ''}

${_recommendation!.isUrgent ? '⚠️ Kailangan kong pumunta ${_recommendation!.timeframe}.' : ''}

Powered by Juan Heart × Philippine Heart Center''';
    } else {
      message = '''Hi! I just completed my heart checkup assessment using the Juan Heart app.

Result: ${_recommendation!.riskCategory}
Going to: ${_selectedFacility!.name}
Address: ${_selectedFacility!.address}
${_selectedFacility!.primaryContact != null ? 'Contact: ${_selectedFacility!.primaryContact}' : ''}

${_recommendation!.isUrgent ? '⚠️ I need to go ${_recommendation!.timeframe}.' : ''}

Powered by Juan Heart × Philippine Heart Center''';
    }
    
    try {
      await Share.share(
        message,
        subject: lang == 'fil' 
            ? 'Juan Heart Assessment Results'
            : 'Juan Heart Assessment Results',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        lang == 'fil'
            ? 'Hindi ma-share ang message: $e'
            : 'Could not share message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstant.redlight,
        colorText: ColorConstant.white,
      );
    }
  }
  
  Widget _buildDisclaimer(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: ColorConstant.grey,
              ),
              const SizedBox(width: 8),
              Text(
                lang == 'fil' ? 'Paalala' : 'Important Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstant.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lang == 'fil'
                ? 'Ang PDF na ito ay maaaring ipakita sa doktor o healthcare provider. Ito ay naglalaman ng iyong risk assessment results at recommended action.'
                : 'This PDF can be shown to your doctor or healthcare provider. It contains your risk assessment results and recommended action.',
            style: TextStyle(
              fontSize: 12,
              color: ColorConstant.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  // Generate PDF
  Future<void> _generatePDF({required bool download}) async {
    if (_recommendation == null || _selectedFacility == null) return;
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final String lang = Get.locale?.languageCode ?? 'en';
      
      // Create referral summary
      final referralSummary = ReferralSummary(
        recommendation: _recommendation!,
        selectedFacility: _selectedFacility,
        assessmentDate: DateTime.now(),
        patientName: _assessmentData?['name'] ?? 'User',
        patientAge: int.tryParse(_assessmentData?['age']?.toString() ?? '0') ?? 0,
        patientSex: _assessmentData?['sex'] ?? 'N/A',
      );
      
      String message;
      if (download) {
        message = await ReferralPDFService.generateAndDownloadReferral(
          referralSummary,
          language: lang,
        );
      } else {
        message = await ReferralPDFService.generateAndShareReferral(
          referralSummary,
          language: lang,
        );
      }
      
      Get.snackbar(
        lang == 'fil' ? 'Tagumpay' : 'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstant.greenlight,
        colorText: ColorConstant.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      final lang = Get.locale?.languageCode ?? 'en';
      Get.snackbar(
        'Error',
        lang == 'fil'
            ? 'May error sa pag-generate ng PDF: $e'
            : 'Error generating PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstant.redlight,
        colorText: ColorConstant.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}

