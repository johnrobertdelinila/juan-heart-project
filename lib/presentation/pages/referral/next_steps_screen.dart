/// Next Steps Screen - Enhanced UI/UX
/// 
/// Redesigned with:
/// - Emotional reassurance and warm tone
/// - Guided experience with breadcrumb trail
/// - Contextual messaging based on risk level
/// - Bilingual Taglish support
/// - Calming gradient backgrounds
/// - Trust-building visual cues
/// 
/// Part of the Referral & Care Navigation System

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/services/referral_service.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/presentation/widgets/referral_widgets.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';

class NextStepsScreen extends StatelessWidget {
  final CareRecommendation recommendation;
  final Map<String, dynamic> assessmentData;
  
  const NextStepsScreen({
    Key? key,
    required this.recommendation,
    required this.assessmentData,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final String lang = Get.locale?.languageCode ?? 'en';
    
    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          lang == 'fil' ? 'Iyong Susunod na Hakbang' : 'Your Next Steps',
          style: JHTextStyles.h3.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              ColorConstant.gradientBlueStart,
              ColorConstant.softWhite,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Breadcrumb trail
              CarePathBreadcrumb(
                steps: [
                  lang == 'fil' ? 'Assessment' : 'Assessment',
                  lang == 'fil' ? 'Rekomendasyon' : 'Recommendations',
                  lang == 'fil' ? 'Facility' : 'Find Care',
                ],
                currentStep: 1,
                language: lang,
              ),
              
              const SizedBox(height: 20),
              
              // Emergency Disclaimer Banner (conditional)
              _buildEmergencyDisclaimer(lang),
              
              // Reassurance message
              _buildReassuranceMessage(lang),
              
              const SizedBox(height: 20),
              
              // Risk Summary Card (enhanced)
              _buildRiskSummary(lang),
              
              const SizedBox(height: 16),
              
              // PHC Trust Badge
              Center(
                child: PHCTrustBadge(language: lang),
              ),
              
              const SizedBox(height: 20),
              
              // Recommendation Details (enhanced)
              _buildRecommendationDetails(lang),
              
              const SizedBox(height: 16),
              
              // Detailed Guidance (enhanced)
              _buildGuidanceSection(lang),
              
              const SizedBox(height: 30),
              
              // Action Buttons (enhanced)
              _buildActionButtons(lang),
              
              const SizedBox(height: 20),
              
              // Medical Disclaimer
              _buildMedicalDisclaimer(lang),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Emergency disclaimer banner - Only show for urgent cases
  Widget _buildEmergencyDisclaimer(String lang) {
    // Only show for emergency situations
    if (!recommendation.isEmergency) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstant.emergencyBadge.withValues(alpha: 0.15),
            ColorConstant.emergencyBadge.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstant.emergencyBadge,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          AnimatedHeartPulse(
            color: ColorConstant.emergencyBadge,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'fil' ? '⚠️ EMERGENCY' : '⚠️ EMERGENCY',
                  style: JHTextStyles.bodyBase.copyWith(
                    color: ColorConstant.emergencyBadge,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ReferralService.getEmergencyDisclaimer(lang),
                  style: JHTextStyles.caption.copyWith(
                    color: ColorConstant.bluedark,
                    fontWeight: FontWeight.w500,
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
  
  /// Reassurance message - Contextual based on risk level
  Widget _buildReassuranceMessage(String lang) {
    String message;
    IconData icon;
    
    if (recommendation.isEmergency) {
      message = lang == 'fil'
          ? 'Nandito kami para tulungan ka. Ipapakita namin ang pinakamalapit na emergency facility.'
          : 'We\'re here to help you. We\'ll guide you to the nearest emergency facility.';
      icon = Icons.emergency;
    } else if (recommendation.isUrgent) {
      message = lang == 'fil'
          ? 'Kalusugan mo ang aming priority. Gabayan ka namin sa tamang healthcare facility.'
          : 'Your health is our priority. We\'ll guide you to the right healthcare facility.';
      icon = Icons.support_agent;
    } else if (recommendation.urgency == CareUrgency.routine) {
      message = lang == 'fil'
          ? 'Mabuti na mag-check up para maiwasan ang mas malaking problema. Tutulungan ka namin.'
          : 'It\'s good to get checked. Early care prevents bigger problems. We\'re here to help.';
      icon = Icons.health_and_safety;
    } else if (recommendation.urgency == CareUrgency.monitor) {
      message = lang == 'fil'
          ? 'Magaling! Regular monitoring ay mahalaga. Nandito kami kung kailangan mo ng tulong.'
          : 'Good job! Regular monitoring is important. We\'re here if you need support.';
      icon = Icons.favorite_border;
    } else {
      message = lang == 'fil'
          ? 'Tuloy-tuloy lang ang healthy lifestyle! Nandito kami para sa iyo.'
          : 'Keep up the healthy lifestyle! We\'re always here for you.';
      icon = Icons.celebration;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ReassuranceMessage(
        message: message,
        icon: icon,
        backgroundColor: recommendation.isEmergency
            ? ColorConstant.gradientWarmStart
            : ColorConstant.gradientBlueStart,
      ),
    );
  }
  
  /// Risk summary card with score and category - Minimalist monochrome version
  Widget _buildRiskSummary(String lang) {
    return StandardCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header with status indicator dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: recommendation.indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                lang == 'fil' ? 'Resulta ng Assessment' : 'Assessment Result',
                style: JHTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const JHColors.midnightBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Risk icon and score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ColorConstant.gentleGray.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  recommendation.urgencyIcon,
                  size: 52,
                  color: ColorConstant.bluedark,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.riskCategory,
                    style: JHTextStyles.h3.copyWith(
                      color: const JHColors.midnightBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstant.gentleGray.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${lang == "fil" ? "Puntos" : "Score"}: ${recommendation.riskScore}/25',
                      style: JHTextStyles.bodySmall.copyWith(
                        color: ColorConstant.bluedark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Urgency timeframe - Monochrome version
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstant.softWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ColorConstant.gentleGray.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: ColorConstant.bluedark,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == 'fil' ? 'Kaagaran ng Aksyon' : 'Action Timeframe',
                        style: JHTextStyles.label.copyWith(
                          color: ColorConstant.gentleGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.timeframe,
                        style: JHTextStyles.bodyBase.copyWith(
                          color: const JHColors.midnightBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Recommendation details section - Enhanced with better visual hierarchy
  Widget _buildRecommendationDetails(String lang) {
    return StandardCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstant.calmingBlue.withValues(alpha: 0.15),
                      ColorConstant.calmingBlue.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medical_information,
                  color: ColorConstant.calmingBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang == 'fil' ? 'Ano ang dapat gawin?' : 'What Should You Do?',
                  style: JHTextStyles.bodyBase.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 18),
          
          // Action title
          Text(
            recommendation.actionTitle,
            style: JHTextStyles.h4.copyWith(
              color: ColorConstant.bluedark,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action message
          Text(
            recommendation.actionMessage,
            style: JHTextStyles.bodySmall.copyWith(
              color: ColorConstant.gentleGray,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Detailed guidance section - Enhanced with better formatting
  Widget _buildGuidanceSection(String lang) {
    // Parse guidance into bullet points if it contains line breaks
    final guidancePoints = recommendation.detailedGuidance
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    
    return StandardCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstant.calmingBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: ColorConstant.calmingBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                lang == 'fil' ? 'Mga Rekomendasyon' : 'Detailed Recommendations',
                style: JHTextStyles.h5.copyWith(
                  color: ColorConstant.trustBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // If we have multiple points, show as list
          if (guidancePoints.length > 1)
            ...guidancePoints.map((point) => Padding(
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
                          point.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
                          style: JHTextStyles.bodySmall.copyWith(
                            color: ColorConstant.bluedark.withValues(alpha: 0.95),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          else
            Text(
              recommendation.detailedGuidance,
              style: JHTextStyles.bodySmall.copyWith(
                color: ColorConstant.bluedark.withValues(alpha: 0.95),
                height: 1.7,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Action buttons section - Enhanced with better accessibility
  Widget _buildActionButtons(String lang) {
    // Check if appointment booking should be offered (moderate risk and above)
    final bool shouldOfferBooking = recommendation.riskScore >= 10; // Moderate, High, Critical

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Emergency button (for critical risk)
          if (recommendation.isEmergency)
            LargeAccessibleButton(
              label: ReferralService.getActionButtonText(
                recommendation.urgency,
                lang,
              ),
              icon: Icons.local_hospital,
              backgroundColor: ColorConstant.emergencyBadge,
              onPressed: () {
                Get.toNamed(
                  AppRoutes.facilityListScreen,
                  arguments: {
                    'recommendation': recommendation,
                    'assessmentData': assessmentData,
                    'bookingIntent': true, // Signal that user wants to book
                  },
                );
              },
            ),

          // Book Appointment button (for moderate/high risk, not emergency)
          if (shouldOfferBooking && !recommendation.isEmergency) ...[
            LargeAccessibleButton(
              label: lang == 'fil'
                  ? 'Mag-book ng Appointment'
                  : 'Book Doctor Appointment',
              icon: Icons.calendar_month,
              backgroundColor: ColorConstant.trustBlue,
              onPressed: () {
                Get.toNamed(
                  AppRoutes.facilityListScreen,
                  arguments: {
                    'recommendation': recommendation,
                    'assessmentData': assessmentData,
                    'bookingIntent': true, // Signal that user wants to book
                  },
                );
              },
            ),

            const SizedBox(height: 14),
          ],

          // Find facilities button (for non-emergency or as secondary option)
          if (recommendation.urgency != CareUrgency.none && !recommendation.isEmergency)
            LargeAccessibleButton(
              label: lang == 'fil'
                  ? 'Maghanap ng Facility'
                  : 'Find Healthcare Facility',
              icon: Icons.search,
              backgroundColor: shouldOfferBooking
                  ? ColorConstant.gentleGray
                  : ColorConstant.calmingBlue,
              onPressed: () {
                Get.toNamed(
                  AppRoutes.facilityListScreen,
                  arguments: {
                    'recommendation': recommendation,
                    'assessmentData': assessmentData,
                    'bookingIntent': false, // Just browsing facilities
                  },
                );
              },
              isOutlined: shouldOfferBooking, // Make it secondary if booking is offered
            ),

          const SizedBox(height: 14),

          // Back to results button
          LargeAccessibleButton(
            label: lang == 'fil' ? 'Bumalik sa Mga Resulta' : 'Back to Results',
            icon: Icons.arrow_back,
            backgroundColor: ColorConstant.gentleGray,
            onPressed: () => Get.back(),
            isOutlined: true,
          ),
        ],
      ),
    );
  }
  
  /// Medical disclaimer - Enhanced with better readability
  Widget _buildMedicalDisclaimer(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorConstant.warmBeige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstant.gentleGray.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorConstant.gentleGray.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: ColorConstant.trustBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'fil' ? 'Mahalagang Paalala' : 'Important Note',
                  style: JHTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.trustBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ReferralService.getMedicalDisclaimer(lang),
                  style: JHTextStyles.label.copyWith(
                    color: ColorConstant.bluedark.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

