import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_event.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_state.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/user_model.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/service/ApiService.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';
import 'package:juan_heart/themes/jh_spacing.dart';
import 'package:juan_heart/themes/jh_grid.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/privacy_service.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/presentation/pages/settings/privacy_consent_dialog.dart';
import 'package:juan_heart/presentation/widgets/sync_status_badge.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/services/performance_service.dart';
import 'package:firebase_performance/firebase_performance.dart';

class HomeScreen extends StatefulWidget {
  final apiService = ApiService();
  final userModel = UserModel();

  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FetchUserDataBloc fetchUserDataBloc;
  AssessmentRecord? _latestAssessment;
  RiskTrendStats? _trendStats;
  Trace? _screenTrace;

  @override
  void initState() {
    super.initState();
    _startScreenTrace();
    fetchUserDataBloc = FetchUserDataBloc();
    fetchUserDataBloc.add(const GetUserData());
    _loadDashboardData();
    _checkPrivacyConsent();
  }

  /// Start screen load performance trace
  Future<void> _startScreenTrace() async {
    _screenTrace = await PerformanceService.instance.startScreenTrace('home_screen');

    // Stop trace after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceService.instance.stopScreenTrace(_screenTrace);
    });
  }

  /// Check if user has given privacy consent and show dialog if not
  Future<void> _checkPrivacyConsent() async {
    // Wait a bit for the screen to load
    await Future.delayed(const Duration(milliseconds: 500));

    final hasConsent = await PrivacyService.hasGivenConsent();
    if (!hasConsent && mounted) {
      await PrivacyConsentDialog.show(
        context: context,
        onConsentGiven: () {
          // Refresh dashboard after consent
          _loadDashboardData();
        },
      );
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final history = await AnalyticsService.getAssessmentHistory();
      final stats = await AnalyticsService.getRiskTrendStats();
      
      setState(() {
        _latestAssessment = history.isNotEmpty ? history.last : null;
        _trendStats = stats;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: ColorConstant.whiteBackground,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: CircularProgressIndicator(
          color: ColorConstant.bluedark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      body: _homeScreen(),
    );
  }

  Widget _homeScreen() {
    return BlocProvider(
      create: (_) => fetchUserDataBloc,
      child: BlocBuilder<FetchUserDataBloc, FetchUserDataBlocState>(
        builder: (context, state) {
          if (state is FetchingDataLoading) {
            return _buildLoadingScreen();
          } else if (state is FetchingDataSuccess) {
            return _homeScreenContent(state.user);
          } else if (state is FetchingDataFailure) {
            return Container(
              color: ColorConstant.bluedark,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Text(
                  state.errorMessage,
                  style: JHTextStyles.bodyBase.copyWith(
                    color: ColorConstant.whiteText,
                  ),
                ),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget _homeScreenContent(UserModel user) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header with greeting
            _buildHeader(user),
            
            // 1. Your Heart Today Section
            _buildHeartTodaySection(),

            const SizedBox(height: JHSpacing.lg),

            // 2. Vitals Summary
            _buildVitalsSummary(),

            const SizedBox(height: JHSpacing.lg),

            // 3. Progress Snapshot
            _buildProgressSnapshot(),

            const SizedBox(height: JHSpacing.lg),

            // 4. Next Recommended Step
            _buildNextRecommendedStep(),

            const SizedBox(height: JHSpacing.lg),

            // 5. Health Corner Preview
            _buildHealthCornerPreview(),

            const SizedBox(height: JHSpacing.lg),

            // 6. Assessment Streak/Reward Section
            _buildAssessmentStreak(),

            const SizedBox(height: JHSpacing.lg),

            // 7. Community & Events (Future Placeholder)
            _buildCommunityEvents(),

            const SizedBox(height: JHSpacing.xl5), // Extra padding at bottom for better scrolling
          ],
        ),
      ),
    );
  }

  // 1. Header with greeting
  Widget _buildHeader(UserModel user) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsivePadding.left,
        JHSpacing.xl3,
        context.responsivePadding.right,
        JHSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Get.locale?.languageCode == 'fil' ? 'Kumusta' : 'Hello',
                      style: JHTextStyles.h3.copyWith(
                        color: ColorConstant.bluedark,
                      ),
                    ),
                    Text(
                      user.fullName ?? 'User',
                      style: JHTextStyles.h3.copyWith(
                        color: ColorConstant.bluedark,
                      ),
                    ),
                  ],
                ),
              ),
              // Sync status badge
              SyncStatusBadge(
                onTap: () {
                  // Navigate to Appointments screen (index 2 in bottom nav)
                  Get.offAllNamed(
                    AppRoutes.home,
                    arguments: {'initialTab': 2},
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Get.locale?.languageCode == 'fil'
              ? 'Alagaan natin ang inyong puso ngayon'
              : "Let's take care of your heart today",
            style: JHTextStyles.bodyBase.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Your Heart Today Section
  Widget _buildHeartTodaySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getHeartTodayGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getHeartTodayColor().withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getHeartTodayIcon(),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Get.locale?.languageCode == 'fil' ? 'Inyong Puso Ngayon' : 'Your Heart Today',
                      style: JHTextStyles.h5.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHeartTodayMessage(),
                      style: JHTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_latestAssessment != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Get.locale?.languageCode == 'fil' ? 'Risk Level' : 'Risk Level',
                        style: JHTextStyles.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _latestAssessment!.riskCategory,
                        style: JHTextStyles.medicalData.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Get.locale?.languageCode == 'fil' ? 'Score' : 'Score',
                        style: JHTextStyles.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_latestAssessment!.finalRiskScore} / 25',
                        style: JHTextStyles.medicalData.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              Get.locale?.languageCode == 'fil'
                ? 'Huling pagsusuri: ${DateFormat('MMM dd, yyyy').format(_latestAssessment!.date)}'
                : 'Last checked: ${DateFormat('MMM dd, yyyy').format(_latestAssessment!.date)}',
              style: JHTextStyles.label.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              Get.locale?.languageCode == 'fil'
                ? 'Wala pa kayong pagsusuri. Magsimula na tayo!'
                : 'No assessments yet. Let\'s get started!',
              style: JHTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          StandardButton.secondary(
            text: Get.locale?.languageCode == 'fil' ? 'Suriin ang Aking Puso' : 'Check My Heart',
            onPressed: () {
              showCustomDialog(
                context,
                targetRoute: AppRoutes.medicalTriageAssessmentScreen,
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Vitals Summary
  Widget _buildVitalsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, size: 24, color: JHColors.midnightBlue),
              const SizedBox(width: 8),
              Text(
                Get.locale?.languageCode == 'fil' ? 'Vital Signs' : 'Vital Signs',
                style: JHTextStyles.h4.copyWith(
                  color: JHColors.midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_latestAssessment != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    'BP',
                    _latestAssessment!.systolicBP != null && _latestAssessment!.diastolicBP != null
                        ? '${_latestAssessment!.systolicBP}/${_latestAssessment!.diastolicBP}'
                        : 'N/A',
                    _getBPStatus(),
                    Icons.monitor_heart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalCard(
                    'HR',
                    _latestAssessment!.heartRate?.toString() ?? 'N/A',
                    _getHRStatus(),
                    Icons.favorite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    'SpO₂',
                    _latestAssessment!.oxygenSaturation?.toString() ?? 'N/A',
                    _getSpO2Status(),
                    Icons.air,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalCard(
                    'Temp',
                    _latestAssessment!.temperature?.toStringAsFixed(1) ?? 'N/A',
                    _getTempStatus(),
                    Icons.thermostat,
                  ),
                ),
              ],
            ),
          ] else ...[
            StandardCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_information,
                      size: 48,
                      color: ColorConstant.gentleGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Get.locale?.languageCode == 'fil'
                        ? 'Kumpletuhin ang pagsusuri para makita ang vital signs'
                        : 'Complete an assessment to see your vital signs',
                      style: JHTextStyles.bodySmall.copyWith(
                        color: ColorConstant.gentleGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Progress Snapshot
  Widget _buildProgressSnapshot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 24, color: JHColors.midnightBlue),
              const SizedBox(width: 8),
              Text(
                Get.locale?.languageCode == 'fil' ? 'Pag-unlad' : 'Progress',
                style: JHTextStyles.h4.copyWith(
                  color: JHColors.midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_trendStats != null && _trendStats!.totalAssessments > 1) ...[
            StandardCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getTrendIcon(),
                        color: _getTrendColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getProgressMessage(),
                          style: JHTextStyles.bodyBase.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.bluedark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mini trend visualization
                  _buildMiniTrendChart(),
                ],
              ),
            ),
          ] else ...[
            StandardCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 48,
                      color: ColorConstant.gentleGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Get.locale?.languageCode == 'fil'
                        ? 'Kumpletuhin ang maraming pagsusuri para makita ang inyong pag-unlad'
                        : 'Complete more assessments to see your progress',
                      style: JHTextStyles.bodySmall.copyWith(
                        color: ColorConstant.gentleGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 5. Next Recommended Step
  Widget _buildNextRecommendedStep() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 24, color: JHColors.midnightBlue),
              const SizedBox(width: 8),
              Text(
                Get.locale?.languageCode == 'fil' ? 'Susunod na Hakbang' : 'Next Step',
                style: JHTextStyles.h4.copyWith(
                  color: JHColors.midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getRecommendationIcon(),
                      color: _getRecommendationColor(),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getRecommendationTitle(),
                        style: JHTextStyles.bodyBase.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.bluedark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getRecommendationMessage(),
                  style: JHTextStyles.bodySmall.copyWith(
                    color: ColorConstant.gentleGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                StandardButton.primary(
                  text: Get.locale?.languageCode == 'fil' ? 'Hanapin ang Klinika' : 'Find a Clinic',
                  onPressed: () {
                    if (_latestAssessment != null) {
                      Get.toNamed(AppRoutes.nextStepsScreen, arguments: {
                        'riskScore': _latestAssessment!.finalRiskScore,
                        'riskCategory': _latestAssessment!.riskCategory,
                      });
                    } else {
                      Get.toNamed(AppRoutes.medicalTriageAssessmentScreen);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Health Corner Preview
  Widget _buildHealthCornerPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, size: 24, color: JHColors.midnightBlue),
                  const SizedBox(width: 8),
                  Text(
                    Get.locale?.languageCode == 'fil' ? 'Edukasyon sa Kalusugan' : 'Health Education',
                    style: JHTextStyles.h4.copyWith(
                      color: JHColors.midnightBlue,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.educationalContentListScreen);
                },
                child: Text(
                  Get.locale?.languageCode == 'fil' ? 'Tingnan Lahat' : 'View All',
                  style: JHTextStyles.button.copyWith(
                    color: ColorConstant.trustBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHealthTipCard(
                  Get.locale?.languageCode == 'fil'
                    ? 'Ano ang ibig sabihin ng BP numbers'
                    : 'What your BP numbers mean',
                  Icons.monitor_heart,
                  ColorConstant.trustBlue,
                ),
                _buildHealthTipCard(
                  Get.locale?.languageCode == 'fil'
                    ? 'Madaling ehersisyo para sa malusog na puso'
                    : 'Easy exercises for a healthy heart',
                  Icons.directions_run,
                  ColorConstant.greenlight,
                ),
                _buildHealthTipCard(
                  Get.locale?.languageCode == 'fil'
                    ? 'Malusog na pagkain para sa mga Pinoy'
                    : 'Healthy Pinoy meals to lower cholesterol',
                  Icons.restaurant,
                  ColorConstant.orangelight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Assessment Streak/Reward Section
  Widget _buildAssessmentStreak() {
    final streak = _calculateAssessmentStreak();
    final daysSinceLastAssessment = _getDaysSinceLastAssessment();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.whatshot, size: 24, color: JHColors.midnightBlue),
              const SizedBox(width: 8),
              Text(
                Get.locale?.languageCode == 'fil' ? 'Patuloy na Pagsusuri' : 'Assessment Streak',
                style: JHTextStyles.h4.copyWith(
                  color: JHColors.midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorConstant.trustBlue.withValues(alpha: 0.1), ColorConstant.trustBlue.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColorConstant.trustBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstant.trustBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Get.locale?.languageCode == 'fil'
                          ? '$streak buwan na sunod-sunod!'
                          : '$streak months in a row!',
                        style: JHTextStyles.h5.copyWith(
                          color: ColorConstant.bluedark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Get.locale?.languageCode == 'fil'
                          ? 'Magaling! Patuloy na subaybayan ang inyong kalusugan.'
                          : 'Great! Keep monitoring your health regularly.',
                        style: JHTextStyles.caption.copyWith(
                          color: ColorConstant.gentleGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (daysSinceLastAssessment >= 7) ...[
                  SizedBox(
                    width: 120,
                    child: StandardButton.compact(
                      text: Get.locale?.languageCode == 'fil' ? 'Magsimula' : 'Start',
                      onPressed: () {
                        Get.toNamed(AppRoutes.medicalTriageAssessmentScreen);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Community & Events (Future Placeholder)
  Widget _buildCommunityEvents() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, size: 24, color: JHColors.midnightBlue),
              const SizedBox(width: 8),
              Text(
                Get.locale?.languageCode == 'fil' ? 'Komunidad at Events' : 'Community & Events',
                style: JHTextStyles.h4.copyWith(
                  color: JHColors.midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorConstant.softWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColorConstant.cardBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event,
                  size: 48,
                  color: ColorConstant.gentleGray,
                ),
                const SizedBox(height: 12),
                Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Sumali sa PHC Free Heart Screening Day sa Pebrero!'
                    : 'Join PHC\'s Free Heart Screening Day this February!',
                  style: JHTextStyles.bodyBase.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Paparating na ang mga tampok na event at announcement!'
                    : 'More events and announcements coming soon!',
                  style: JHTextStyles.bodySmall.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for dashboard functionality
  
  // Heart Today Section Helpers
  List<Color> _getHeartTodayGradient() {
    if (_latestAssessment == null) {
      return [ColorConstant.trustBlue, ColorConstant.bluelight];
    }
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return [JHColors.success, JHColors.success];
      case 'mild':
        return [JHColors.warning, JHColors.warning];
      case 'moderate':
        return [JHColors.danger, JHColors.warning];
      case 'high':
        return [JHColors.danger, JHColors.danger];
      case 'critical':
        return [JHColors.heartRed, JHColors.heartRed];
      default:
        return [ColorConstant.trustBlue, ColorConstant.bluelight];
    }
  }

  Color _getHeartTodayColor() {
    if (_latestAssessment == null) return ColorConstant.trustBlue;
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return JHColors.success;
      case 'mild':
        return JHColors.warning;
      case 'moderate':
        return JHColors.danger;
      case 'high':
        return JHColors.danger;
      case 'critical':
        return JHColors.heartRed;
      default:
        return ColorConstant.trustBlue;
    }
  }

  IconData _getHeartTodayIcon() {
    if (_latestAssessment == null) return Icons.favorite;
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return Icons.favorite;
      case 'mild':
        return Icons.favorite_border;
      case 'moderate':
        return Icons.warning;
      case 'high':
        return Icons.warning_amber;
      case 'critical':
        return Icons.error;
      default:
        return Icons.favorite;
    }
  }

  String _getHeartTodayMessage() {
    if (_latestAssessment == null) {
      return Get.locale?.languageCode == 'fil' 
        ? 'Magsimula na tayo sa inyong heart health journey!'
        : 'Let\'s start your heart health journey!';
    }
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return Get.locale?.languageCode == 'fil' 
          ? 'Malusog ang inyong puso! Patuloy lang!'
          : 'Your heart is healthy! Keep it up!';
      case 'mild':
        return Get.locale?.languageCode == 'fil' 
          ? 'Magandang simula! Subaybayan natin ang inyong puso.'
          : 'Good start! Let\'s monitor your heart.';
      case 'moderate':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kailangan ng atensyon. Kumonsulta sa doktor.'
          : 'Needs attention. Consult your doctor.';
      case 'high':
        return Get.locale?.languageCode == 'fil' 
          ? 'Mataas na panganib. Kumonsulta agad sa doktor.'
          : 'High risk. Consult your doctor immediately.';
      case 'critical':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kritikal na panganib. Pumunta sa ER agad!'
          : 'Critical risk. Go to ER immediately!';
      default:
        return Get.locale?.languageCode == 'fil' 
          ? 'Subaybayan natin ang inyong puso.'
          : 'Let\'s monitor your heart.';
    }
  }

  // Vitals Summary Helpers
  Widget _buildVitalCard(String title, String value, String status, IconData icon) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'normal':
        statusColor = JHColors.success;
        break;
      case 'elevated':
        statusColor = JHColors.warning;
        break;
      case 'critical':
        statusColor = JHColors.danger;
        break;
      default:
        statusColor = ColorConstant.gentleGray;
    }

    return AccentCard(
      accentColor: statusColor,
      onTap: () {
        // Navigate to detailed analytics
        Get.toNamed(AppRoutes.analyticsScreen);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: JHTextStyles.label.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: JHTextStyles.medicalDataSmall.copyWith(
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: JHTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
      ),
    );
  }

  String _getBPStatus() {
    if (_latestAssessment?.systolicBP == null || _latestAssessment?.diastolicBP == null) {
      return 'N/A';
    }
    
    final systolic = _latestAssessment!.systolicBP!;
    final diastolic = _latestAssessment!.diastolicBP!;
    
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'High Stage 1';
    return 'Critical';
  }

  String _getHRStatus() {
    if (_latestAssessment?.heartRate == null) return 'N/A';
    
    final hr = _latestAssessment!.heartRate!;
    if (hr >= 60 && hr <= 100) return 'Normal';
    if (hr < 60 || hr > 100) return 'Elevated';
    return 'Critical';
  }

  String _getSpO2Status() {
    if (_latestAssessment?.oxygenSaturation == null) return 'N/A';
    
    final spo2 = _latestAssessment!.oxygenSaturation!;
    if (spo2 >= 95) return 'Normal';
    if (spo2 >= 90) return 'Elevated';
    return 'Critical';
  }

  String _getTempStatus() {
    if (_latestAssessment?.temperature == null) return 'N/A';
    
    final temp = _latestAssessment!.temperature!;
    if (temp >= 36.1 && temp <= 37.2) return 'Normal';
    if (temp >= 37.3 && temp <= 38.0) return 'Elevated';
    return 'Critical';
  }

  // Progress Snapshot Helpers
  IconData _getTrendIcon() {
    if (_trendStats == null) return Icons.trending_flat;
    
    switch (_trendStats!.trendDirection) {
      case 'improving':
        return Icons.trending_down;
      case 'worsening':
        return Icons.trending_up;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor() {
    if (_trendStats == null) return ColorConstant.gentleGray;
    
    switch (_trendStats!.trendDirection) {
      case 'improving':
        return JHColors.success;
      case 'worsening':
        return JHColors.danger;
      default:
        return ColorConstant.trustBlue;
    }
  }

  String _getProgressMessage() {
    if (_trendStats == null) return 'No data available';
    
    switch (_trendStats!.trendDirection) {
      case 'improving':
        return Get.locale?.languageCode == 'fil' 
          ? 'Gumaganda ang inyong puso! Patuloy lang!'
          : 'Your heart health is improving! Keep it up!';
      case 'worsening':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kailangan ng atensyon. Kumonsulta sa doktor.'
          : 'Needs attention. Consult your doctor.';
      default:
        return Get.locale?.languageCode == 'fil' 
          ? 'Patuloy na subaybayan ang inyong kalusugan.'
          : 'Keep monitoring your health consistently.';
    }
  }

  Widget _buildMiniTrendChart() {
    // Simple mini trend visualization
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          double height = 20 + (index * 8) + (index % 2 == 0 ? 10 : 0);
          return Container(
            width: 8,
            height: height,
            decoration: BoxDecoration(
              color: _getTrendColor().withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  // Next Recommended Step Helpers
  Color _getRecommendationColor() {
    if (_latestAssessment == null) return ColorConstant.trustBlue;
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return JHColors.success;
      case 'mild':
        return JHColors.warning;
      case 'moderate':
        return JHColors.danger;
      case 'high':
        return JHColors.danger;
      case 'critical':
        return JHColors.heartRed;
      default:
        return ColorConstant.trustBlue;
    }
  }

  IconData _getRecommendationIcon() {
    if (_latestAssessment == null) return Icons.info;
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'mild':
        return Icons.info;
      case 'moderate':
        return Icons.warning;
      case 'high':
        return Icons.warning_amber;
      case 'critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getRecommendationTitle() {
    if (_latestAssessment == null) {
      return Get.locale?.languageCode == 'fil' 
        ? 'Magsimula sa Pagsusuri'
        : 'Start with Assessment';
    }
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return Get.locale?.languageCode == 'fil' 
          ? 'Panatilihin ang Malusog na Gawi'
          : 'Maintain Healthy Habits';
      case 'mild':
        return Get.locale?.languageCode == 'fil' 
          ? 'Subaybayan ang Kalusugan'
          : 'Monitor Your Health';
      case 'moderate':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kumonsulta sa Doktor'
          : 'Consult Your Doctor';
      case 'high':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kailangan ng Medikal na Atensyon'
          : 'Medical Attention Needed';
      case 'critical':
        return Get.locale?.languageCode == 'fil' 
          ? 'Pumunta sa ER Agad!'
          : 'Go to ER Immediately!';
      default:
        return Get.locale?.languageCode == 'fil' 
          ? 'Kumonsulta sa Doktor'
          : 'Consult Your Doctor';
    }
  }

  String _getRecommendationMessage() {
    if (_latestAssessment == null) {
      return Get.locale?.languageCode == 'fil' 
        ? 'Kumpletuhin ang inyong unang pagsusuri para makakuha ng personalized na payo.'
        : 'Complete your first assessment to get personalized advice.';
    }
    
    switch (_latestAssessment!.riskCategory.toLowerCase()) {
      case 'low':
        return Get.locale?.languageCode == 'fil' 
          ? 'Magaling! Patuloy na subaybayan ang inyong kalusugan at panatilihin ang malusog na gawi.'
          : 'Great! Continue monitoring your health and maintain healthy habits.';
      case 'mild':
        return Get.locale?.languageCode == 'fil' 
          ? 'Subaybayan ang inyong kalusugan at kumonsulta sa doktor kung kinakailangan.'
          : 'Monitor your health and consult your doctor if needed.';
      case 'moderate':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kumonsulta sa doktor sa loob ng 48 oras para sa mas detalyadong pagsusuri.'
          : 'Consult your doctor within 48 hours for detailed assessment.';
      case 'high':
        return Get.locale?.languageCode == 'fil' 
          ? 'Kailangan ng medikal na atensyon sa loob ng 6-24 oras. Pumunta sa klinika o ospital.'
          : 'Medical attention needed within 6-24 hours. Visit a clinic or hospital.';
      case 'critical':
        return Get.locale?.languageCode == 'fil' 
          ? 'Pumunta sa pinakamalapit na emergency room agad! Huwag mag-antay.'
          : 'Go to the nearest emergency room immediately! Don\'t wait.';
      default:
        return Get.locale?.languageCode == 'fil' 
          ? 'Kumonsulta sa doktor para sa payo.'
          : 'Consult your doctor for advice.';
    }
  }

  // Health Corner Preview Helpers
  Widget _buildHealthTipCard(String title, IconData icon, Color color) {
    return AccentCard(
      width: 180,
      accentColor: color,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: JHTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Get.locale?.languageCode == 'fil'
              ? 'Matuto pa tungkol sa kalusugan ng puso'
              : 'Learn more about heart health',
            style: JHTextStyles.label.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
        ],
      ),
    );
  }

  // Assessment Streak Helpers
  int _calculateAssessmentStreak() {
    if (_trendStats == null) return 0;
    return (_trendStats!.totalAssessments / 4).floor(); // Approximate months
  }

  int _getDaysSinceLastAssessment() {
    if (_latestAssessment == null) return 999;
    return DateTime.now().difference(_latestAssessment!.date).inDays;
  }
}

