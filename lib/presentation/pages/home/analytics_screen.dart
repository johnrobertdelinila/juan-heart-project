import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/analytics_pdf_service.dart';
import 'package:juan_heart/services/analytics_csv_service.dart';
import 'package:juan_heart/presentation/widgets/date_range_selector.dart';
import 'package:juan_heart/themes/app_styles.dart';
import 'package:intl/intl.dart';

/// Heart Insights Center - Redesigned Analytics Screen
/// 
/// This screen provides users with comprehensive cardiovascular health analytics including:
/// 1. Risk History Overview (trend visualization)
/// 2. Vital Signs Trends (BP, HR, SpO2, Temp)
/// 3. Risk Heatmap History (5x5 grid with historical placements)
/// 4. Lifestyle & Risk Factor Insights
/// 5. Personalized Health Insights
/// 6. Risk Category Distribution
/// 7. Report Export and Sharing
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;

  // Data
  List<AssessmentRecord> _history = [];
  RiskTrendStats? _trendStats;
  Map<String, List<VitalSignTrend>> _vitalTrends = {};
  Map<String, List<RiskFactorContribution>> _riskFactorAnalysis = {};
  List<HealthInsight> _insights = [];
  Map<String, int> _categoryDistribution = {};

  // Filter & Search State
  String _selectedRiskFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Date Range Filter State
  DateRangeOption _selectedDateRange = DateRangeOption.last30Days;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AssessmentRecord> get _filteredHistory {
    var filtered = _history;

    // Apply date range filter
    final dateFilter = DateRangeFilter(
      option: _selectedDateRange,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
    );
    filtered = filtered.where((record) => dateFilter.isDateInRange(record.date)).toList();

    // Apply risk filter
    if (_selectedRiskFilter != 'All') {
      filtered = filtered.where((record) => record.riskCategory == _selectedRiskFilter).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final query = _searchQuery.toLowerCase();
        return record.riskCategory.toLowerCase().contains(query) ||
               record.date.toString().contains(query) ||
               record.finalRiskScore.toString().contains(query);
      }).toList();
    }

    return filtered.reversed.toList(); // Show newest first
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Generate mock data if no history exists (for demo purposes)
      await AnalyticsService.generateMockData();
      
      // Load all analytics data
      _history = await AnalyticsService.getAssessmentHistory();
      _trendStats = await AnalyticsService.getRiskTrendStats();
      _vitalTrends = await AnalyticsService.getVitalSignsTrends();
      _riskFactorAnalysis = await AnalyticsService.getRiskFactorAnalysis();
      _insights = await AnalyticsService.generateHealthInsights();
      _categoryDistribution = await AnalyticsService.getRiskCategoryDistribution();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Heart Insights Center",
              style: TextStyle(
                fontFamily: "Poppins",
                color: ColorConstant.bluedark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Your Cardiovascular Health Journey",
              style: TextStyle(
                fontFamily: "Poppins",
                color: ColorConstant.gentleGray,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: ColorConstant.trustBlue),
            onPressed: () {
              // Toggle between English and Filipino
              final currentLocale = Get.locale?.languageCode ?? 'en';
              final newLocale = currentLocale == 'en' ? 'fil' : 'en';
              Get.updateLocale(Locale(newLocale));
            },
            tooltip: Get.locale?.languageCode == 'fil' ? 'Switch to English' : 'Lumipat sa Filipino',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: ColorConstant.trustBlue),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorConstant.trustBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your health insights...',
                    style: AppStyle.txtPoppinsSemiBold16Dark,
                  ),
                ],
              ),
            )
          : _history.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAnalyticsData,
                  color: ColorConstant.trustBlue,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Quick Stats Overview
                        _buildQuickStatsOverview(),
                        const SizedBox(height: 24),
                        
        // 2. Assessment Streak & Reminders
        _buildAssessmentStreak(),
        const SizedBox(height: 24),
        
        // 3. Personalized Health Insights
        _buildHealthInsights(),
        const SizedBox(height: 24),
                        
                        // 3. Risk History Overview
                        _buildRiskHistorySection(),
                        const SizedBox(height: 24),
                        
                        // 4. Vital Signs Trends
                        _buildVitalSignsSection(),
                        const SizedBox(height: 24),
                        
                        // 5. Risk Heatmap History
                        _buildRiskHeatmapHistory(),
                        const SizedBox(height: 24),

                        // 6. Assessment History Timeline with Filter & Search
                        _buildAssessmentHistoryTimeline(),
                        const SizedBox(height: 24),

                        // 7. Risk Category Distribution
                        _buildRiskDistribution(),
                        const SizedBox(height: 24),
                        
                        // 7. Risk Factor Insights
                        _buildRiskFactorInsights(),
                        const SizedBox(height: 24),
                        
        // 8. Data Contribution for Research
        _buildDataContributionSection(),
        const SizedBox(height: 24),
        
        // 9. Export & Share Section
        _buildExportSection(),
        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  // SECTION 1: Heart Health Progress - Simplified & Encouraging
  Widget _buildQuickStatsOverview() {
    if (_trendStats == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Get.locale?.languageCode == 'fil' ? 'Kalusugan ng Puso' : 'Heart Health',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorConstant.bluedark,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Get.locale?.languageCode == 'fil' 
            ? 'Tingnan ang inyong pag-unlad sa kalusugan'
            : 'See how your health is progressing',
          style: TextStyle(
            fontSize: 14,
            color: ColorConstant.gentleGray,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 20),
        
        // Main Progress Card - Clean & Focused
        _buildProgressCard(),
        
        const SizedBox(height: 16),
        
        // Simple Stats Row
        Row(
          children: [
            Expanded(
              child: _buildSimpleStatCard(
                title: Get.locale?.languageCode == 'fil' ? 'Mga Pagsusuri' : 'Assessments',
                value: '${_trendStats!.totalAssessments}',
                icon: Icons.favorite,
                color: ColorConstant.trustBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleStatCard(
                title: Get.locale?.languageCode == 'fil' ? 'Kategorya' : 'Category',
                value: _trendStats!.mostCommonCategory,
                icon: Icons.analytics,
                color: _getCategoryColor(_trendStats!.mostCommonCategory),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildProgressCard() {
    final trend = _trendStats!.trendDirection;
    final isImproving = trend == 'improving';
    final isWorsening = trend == 'worsening';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isImproving 
            ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
            : isWorsening
            ? [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)]
            : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isImproving 
            ? const Color(0xFF4CAF50)
            : isWorsening
            ? const Color(0xFFF44336)
            : ColorConstant.trustBlue,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Progress Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isImproving 
                ? Icons.trending_up
                : isWorsening
                ? Icons.trending_down
                : Icons.trending_flat,
              size: 32,
              color: isImproving 
                ? const Color(0xFF4CAF50)
                : isWorsening
                ? const Color(0xFFF44336)
                : ColorConstant.trustBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress Message
          Text(
            _getProgressMessage(trend),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Encouraging Subtitle
          Text(
            _getProgressSubtitle(trend),
            style: TextStyle(
              fontSize: 14,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  String _getProgressMessage(String trend) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    switch (trend) {
      case 'improving':
        return isFilipino ? 'Gumaganda ang Kalusugan!' : 'Health Improving!';
      case 'worsening':
        return isFilipino ? '⚠️ Kailangan ng Atensyon' : '⚠️ Needs Attention';
      default:
        return isFilipino ? 'Patuloy na Subaybayan' : 'Keep Monitoring';
    }
  }
  
  String _getProgressSubtitle(String trend) {
    final isFilipino = Get.locale?.languageCode == 'fil';
    
    switch (trend) {
      case 'improving':
        return isFilipino 
          ? 'Magaling! Patuloy na gumaganda ang inyong puso.'
          : 'Great! Your heart health is getting better.';
      case 'worsening':
        return isFilipino 
          ? 'Konsultahin ang inyong doktor para sa payo.'
          : 'Consider consulting your doctor for guidance.';
      default:
        return isFilipino 
          ? 'Patuloy na subaybayan ang inyong kalusugan.'
          : 'Continue monitoring your health regularly.';
    }
  }

  Widget _buildSimpleStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstant.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 2: Assessment Streak & Reminders
  Widget _buildAssessmentStreak() {
    final streak = _calculateAssessmentStreak();
    final daysSinceLastAssessment = _getDaysSinceLastAssessment();
    final needsReminder = daysSinceLastAssessment >= 7; // Remind after 1 week
    
    return _buildSectionCard(
      title: Get.locale?.languageCode == 'fil' ? 'Patuloy na Pagsusuri' : 'Assessment Streak',
      subtitle: Get.locale?.languageCode == 'fil'
        ? 'Subaybayan ang inyong consistency sa pagsusuri'
        : 'Track your assessment consistency',
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Streak Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorConstant.trustBlue.withOpacity(0.1), ColorConstant.trustBlue.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColorConstant.trustBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstant.trustBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
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
                          ? '${streak} buwan na sunod-sunod!'
                          : '${streak} months in a row!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.bluedark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Get.locale?.languageCode == 'fil'
                          ? 'Magaling! Patuloy na subaybayan ang inyong kalusugan.'
                          : 'Great! Keep monitoring your health regularly.',
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorConstant.gentleGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reminder Section
          if (needsReminder) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: const Color(0xFFFF9800),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Get.locale?.languageCode == 'fil'
                            ? 'Oras na para sa bagong pagsusuri!'
                            : 'Time for a new assessment!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.bluedark,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Get.locale?.languageCode == 'fil'
                            ? 'Huling pagsusuri: $daysSinceLastAssessment araw na ang nakalipas'
                            : 'Last assessment: $daysSinceLastAssessment days ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorConstant.gentleGray,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to assessment
                      Get.back(); // Go to home where FAB is available
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      Get.locale?.languageCode == 'fil' ? 'Magsimula' : 'Start',
                      style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  int _calculateAssessmentStreak() {
    if (_history.isEmpty) return 0;
    
    // Group assessments by month
    final Map<String, List<AssessmentRecord>> monthlyAssessments = {};
    for (final record in _history) {
      final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      monthlyAssessments[monthKey] = monthlyAssessments[monthKey] ?? [];
      monthlyAssessments[monthKey]!.add(record);
    }
    
    // Calculate consecutive months with assessments
    final sortedMonths = monthlyAssessments.keys.toList()..sort();
    int streak = 0;
    final now = DateTime.now();
    
    for (int i = sortedMonths.length - 1; i >= 0; i--) {
      final monthKey = sortedMonths[i];
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      // Check if this month is consecutive
      final expectedYear = now.year;
      final expectedMonth = now.month - streak;
      
      if (year == expectedYear && month == expectedMonth) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  int _getDaysSinceLastAssessment() {
    if (_history.isEmpty) return 999; // Large number if no assessments
    
    final lastAssessment = _history.last;
    return DateTime.now().difference(lastAssessment.date).inDays;
  }

  // SECTION 3: Personalized Health Insights - Refined & Cultural
  Widget _buildHealthInsights() {
    if (_insights.isEmpty) return const SizedBox();
    
    return _buildSectionCard(
      title: Get.locale?.languageCode == 'fil' ? 'Mga Payo para sa Inyo' : 'Personalized Insights',
      subtitle: Get.locale?.languageCode == 'fil'
        ? 'Mga simpleng payo batay sa inyong kalusugan'
        : 'Simple advice based on your health data',
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Show only the most relevant insights (max 3)
          ...List.generate(
            _insights.length > 3 ? 3 : _insights.length, 
            (index) {
              final insight = _insights[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRefinedInsightCard(insight),
              );
            }
          ),
          
          // Show more insights button if there are more than 3
          if (_insights.length > 3) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Show all insights in a modal
                Get.snackbar(
                  Get.locale?.languageCode == 'fil' ? 'Paparating na Tampok' : 'Coming Soon',
                  Get.locale?.languageCode == 'fil' 
                    ? 'Makikita ninyo ang lahat ng insights sa susunod na update!'
                    : 'View all insights in the next update!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstant.trustBlue,
                  colorText: Colors.white,
                );
              },
              child: Text(
                Get.locale?.languageCode == 'fil' 
                  ? 'Tingnan ang lahat ng insights'
                  : 'View all insights',
                style: TextStyle(
                  color: ColorConstant.trustBlue,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefinedInsightCard(HealthInsight insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstant.gentleGray,
                    fontFamily: 'Poppins',
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

  // SECTION 3: Risk History Overview (Line Chart)
  Widget _buildRiskHistorySection() {
    if (_history.length < 2) return const SizedBox();
    
    return _buildSectionCard(
      title: 'Risk Trend Over Time',
      subtitle: 'Track how your cardiovascular risk has changed',
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: ColorConstant.cardBorder,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _history.length) return const SizedBox();
                        final date = _history[value.toInt()].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: TextStyle(
                              color: ColorConstant.gentleGray,
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_history.length - 1).toDouble(),
                minY: 0,
                maxY: 25,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _history.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        _history[index].finalRiskScore.toDouble(),
                      ),
                    ),
                    isCurved: true,
                    color: ColorConstant.trustBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final record = _history[index];
                        return FlDotCirclePainter(
                          radius: 5,
                          color: record.getRiskColor(),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          ColorConstant.trustBlue.withOpacity(0.3),
                          ColorConstant.trustBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final record = _history[spot.x.toInt()];
                        return LineTooltipItem(
                          '${record.riskCategory}\nScore: ${record.finalRiskScore}\n${DateFormat('MMM d').format(record.date)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRiskLegend(),
        ],
      ),
    );
  }

  Widget _buildRiskLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem('Low', const Color(0xFF32CD32)),
        _buildLegendItem('Mild', const Color(0xFFFFD700)),
        _buildLegendItem('Moderate', const Color(0xFFFFA500)),
        _buildLegendItem('High', const Color(0xFFFF6347)),
        _buildLegendItem('Critical', const Color(0xFFDC143C)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ColorConstant.gentleGray,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  // SECTION 4: Vital Signs Trends - Enhanced with Interactive Charts
  Widget _buildVitalSignsSection() {
    return _buildSectionCard(
      title: Get.locale?.languageCode == 'fil' ? '🩺 Mga Vital Signs' : '🩺 Vital Signs Trends',
      subtitle: Get.locale?.languageCode == 'fil'
        ? 'Subaybayan ang inyong mga pangunahing health indicators'
        : 'Monitor your key health indicators over time',
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Blood Pressure Combined Chart
          if (_vitalTrends['systolicBP']!.isNotEmpty && _vitalTrends['diastolicBP']!.isNotEmpty)
            _buildBloodPressureChart(),

          const SizedBox(height: 20),

          // Heart Rate Variability Chart
          if (_vitalTrends['heartRate']!.isNotEmpty)
            _buildHeartRateChart(),

          const SizedBox(height: 20),

          // Oxygen Saturation Chart
          if (_vitalTrends['oxygenSaturation']!.isNotEmpty)
            _buildOxygenSaturationChart(),

          const SizedBox(height: 20),

          // Temperature Chart
          if (_vitalTrends['temperature']!.isNotEmpty)
            _buildTemperatureChart(),

          const SizedBox(height: 20),

          // Weight Tracking Timeline
          if (_vitalTrends['weight']!.isNotEmpty)
            _buildWeightChart(),

          const SizedBox(height: 20),

          // BMI Trend Chart
          if (_vitalTrends['bmi']!.isNotEmpty)
            _buildBMIChart(),
        ],
      ),
    );
  }

  // Blood Pressure Combined Chart (Systolic + Diastolic)
  Widget _buildBloodPressureChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Get.locale?.languageCode == 'fil' ? 'Presyon ng Dugo' : 'Blood Pressure',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorConstant.bluedark,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstant.softWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstant.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  // Highlight normal range
                  if (value == 120 || value == 90) {
                    return FlLine(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  }
                  return FlLine(
                    color: ColorConstant.cardBorder,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: ColorConstant.gentleGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _vitalTrends['systolicBP']!.length) {
                        return const SizedBox();
                      }
                      final date = _vitalTrends['systolicBP']![value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 50,
              maxY: 160,
              lineBarsData: [
                // Systolic BP Line
                LineChartBarData(
                  spots: List.generate(
                    _vitalTrends['systolicBP']!.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      _vitalTrends['systolicBP']![index].value,
                    ),
                  ),
                  isCurved: true,
                  color: const Color(0xFFFF6347),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFFF6347),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                // Diastolic BP Line
                LineChartBarData(
                  spots: List.generate(
                    _vitalTrends['diastolicBP']!.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      _vitalTrends['diastolicBP']![index].value,
                    ),
                  ),
                  isCurved: true,
                  color: const Color(0xFF4A90E2),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF4A90E2),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = _vitalTrends['systolicBP']![spot.x.toInt()].date;
                      final isSystolic = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isSystolic ? "Systolic" : "Diastolic"}\n${spot.y.toInt()} mmHg\n${DateFormat('MMM d').format(date)}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChartLegendItem('Systolic', const Color(0xFFFF6347)),
            const SizedBox(width: 16),
            _buildChartLegendItem('Diastolic', const Color(0xFF4A90E2)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Normal: 90-120 (Systolic), 60-80 (Diastolic) mmHg'
                    : 'Normal Range: 90-120 (Systolic), 60-80 (Diastolic) mmHg',
                  style: TextStyle(
                    fontSize: 11,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Heart Rate Variability Chart
  Widget _buildHeartRateChart() {
    final trends = _vitalTrends['heartRate']!;
    final latest = trends.last.value;
    final avg = trends.map((t) => t.value).reduce((a, b) => a + b) / trends.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Get.locale?.languageCode == 'fil' ? 'Tibok ng Puso' : 'Heart Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorConstant.bluedark,
                fontFamily: 'Poppins',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: latest >= 60 && latest <= 100
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${latest.toInt()} bpm',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstant.softWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstant.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  // Highlight normal range (60-100)
                  if (value == 60 || value == 100) {
                    return FlLine(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  }
                  return FlLine(
                    color: ColorConstant.cardBorder,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: ColorConstant.gentleGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trends.length) return const SizedBox();
                      final date = trends[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 40,
              maxY: 140,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (index) => FlSpot(index.toDouble(), trends[index].value),
                  ),
                  isCurved: true,
                  color: const Color(0xFFE91E63),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isNormal = trends[index].isNormal;
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isNormal ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE91E63).withOpacity(0.2),
                        const Color(0xFFE91E63).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVitalStatCard(
                label: Get.locale?.languageCode == 'fil' ? 'Average' : 'Average',
                value: '${avg.toInt()} bpm',
                color: const Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalStatCard(
                label: Get.locale?.languageCode == 'fil' ? 'Kasalukuyan' : 'Current',
                value: '${latest.toInt()} bpm',
                color: latest >= 60 && latest <= 100
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Oxygen Saturation Chart
  Widget _buildOxygenSaturationChart() {
    final trends = _vitalTrends['oxygenSaturation']!;
    final latest = trends.last.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Get.locale?.languageCode == 'fil' ? 'Oxygen Saturation' : 'Oxygen Saturation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorConstant.bluedark,
                fontFamily: 'Poppins',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: latest >= 95
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6347),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${latest.toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstant.softWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstant.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: ColorConstant.gentleGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trends.length) return const SizedBox();
                      final date = trends[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 85,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (index) => FlSpot(index.toDouble(), trends[index].value),
                  ),
                  isCurved: true,
                  color: const Color(0xFF00BCD4),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isNormal = trends[index].isNormal;
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isNormal ? const Color(0xFF4CAF50) : const Color(0xFFFF6347),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00BCD4).withOpacity(0.2),
                        const Color(0xFF00BCD4).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Normal: 95-100%'
                    : 'Normal Range: 95-100%',
                  style: TextStyle(
                    fontSize: 11,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Temperature Chart
  Widget _buildTemperatureChart() {
    final trends = _vitalTrends['temperature']!;
    final latest = trends.last.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Get.locale?.languageCode == 'fil' ? 'Temperatura' : 'Temperature',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorConstant.bluedark,
                fontFamily: 'Poppins',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: latest >= 36.1 && latest <= 37.2
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${latest.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstant.softWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstant.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.5,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(1)}°',
                        style: TextStyle(
                          color: ColorConstant.gentleGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trends.length) return const SizedBox();
                      final date = trends[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 35,
              maxY: 39,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (index) => FlSpot(index.toDouble(), trends[index].value),
                  ),
                  isCurved: true,
                  color: const Color(0xFFFF9800),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isNormal = trends[index].isNormal;
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isNormal ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF9800).withOpacity(0.2),
                        const Color(0xFFFF9800).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Normal: 36.1-37.2°C'
                    : 'Normal Range: 36.1-37.2°C',
                  style: TextStyle(
                    fontSize: 11,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Weight Tracking Timeline
  Widget _buildWeightChart() {
    final trends = _vitalTrends['weight']!;
    final latest = trends.last.value;
    final first = trends.first.value;
    final change = latest - first;
    final changePercent = (change / first) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Get.locale?.languageCode == 'fil' ? 'Timbang' : 'Weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      change < 0 ? Icons.trending_down : Icons.trending_up,
                      size: 16,
                      color: change < 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)} kg ${change < 0 ? Get.locale?.languageCode == 'fil' ? 'nabawasan' : 'lost' : Get.locale?.languageCode == 'fil' ? 'nadagdag' : 'gained'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: ColorConstant.gentleGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConstant.trustBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${latest.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstant.softWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstant.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()} kg',
                        style: TextStyle(
                          color: ColorConstant.gentleGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trends.length) return const SizedBox();
                      final date = trends[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (index) => FlSpot(index.toDouble(), trends[index].value),
                  ),
                  isCurved: true,
                  color: change < 0 ? const Color(0xFF4CAF50) : ColorConstant.trustBlue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: change < 0 ? const Color(0xFF4CAF50) : ColorConstant.trustBlue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        (change < 0 ? const Color(0xFF4CAF50) : ColorConstant.trustBlue).withOpacity(0.2),
                        (change < 0 ? const Color(0xFF4CAF50) : ColorConstant.trustBlue).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: change < 0 ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                change < 0 ? Icons.check_circle_outline : Icons.info_outline,
                size: 16,
                color: change < 0 ? const Color(0xFF4CAF50) : ColorConstant.trustBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  change < 0
                      ? (Get.locale?.languageCode == 'fil'
                          ? 'Magandang progreso! Patuloy lang!'
                          : 'Great progress! Keep it up!')
                      : (Get.locale?.languageCode == 'fil'
                          ? 'Subaybayan ang inyong timbang'
                          : 'Monitor your weight regularly'),
                  style: TextStyle(
                    fontSize: 11,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // BMI Trend Chart
  Widget _buildBMIChart() {
    final trends = _vitalTrends['bmi']!;
    final latest = trends.last.value;
    final first = trends.first.value;
    final change = latest - first;

    String getBMICategory(double bmi) {
      if (bmi < 18.5) return Get.locale?.languageCode == 'fil' ? 'Kulang sa timbang' : 'Underweight';
      if (bmi < 25) return Get.locale?.languageCode == 'fil' ? 'Normal' : 'Normal';
      if (bmi < 30) return Get.locale?.languageCode == 'fil' ? 'Sobra sa timbang' : 'Overweight';
      return Get.locale?.languageCode == 'fil' ? 'Obese' : 'Obese';
    }

    Color getBMIColor(double bmi) {
      if (bmi >= 18.5 && bmi < 25) return const Color(0xFF4CAF50);
      if (bmi < 18.5 || (bmi >= 25 && bmi < 30)) return const Color(0xFFFF9800);
      return const Color(0xFFFF5722);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Get.locale?.languageCode == 'fil' ? 'BMI (Body Mass Index)' : 'BMI (Body Mass Index)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  getBMICategory(latest),
                  style: TextStyle(
                    fontSize: 12,
                    color: getBMIColor(latest),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: getBMIColor(latest),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                latest.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstant.softWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstant.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) {
                  // Highlight normal BMI range (18.5-24.9)
                  if (value == 18.5 || value == 24.9) {
                    return FlLine(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  }
                  return FlLine(
                    color: ColorConstant.cardBorder,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: ColorConstant.gentleGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trends.length) return const SizedBox();
                      final date = trends[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            color: ColorConstant.gentleGray,
                            fontSize: 9,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (index) => FlSpot(index.toDouble(), trends[index].value),
                  ),
                  isCurved: true,
                  color: getBMIColor(latest),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final bmi = trends[index].value;
                      return FlDotCirclePainter(
                        radius: 5,
                        color: getBMIColor(bmi),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        getBMIColor(latest).withOpacity(0.2),
                        getBMIColor(latest).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Get.locale?.languageCode == 'fil'
                        ? 'Normal BMI: 18.5 - 24.9'
                        : 'Normal BMI Range: 18.5 - 24.9',
                      style: TextStyle(
                        fontSize: 11,
                        color: ColorConstant.bluedark,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  Get.locale?.languageCode == 'fil'
                    ? '<18.5: Kulang • 25-29.9: Sobra • ≥30: Obese'
                    : '<18.5: Underweight • 25-29.9: Overweight • ≥30: Obese',
                  style: TextStyle(
                    fontSize: 9,
                    color: ColorConstant.gentleGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ColorConstant.gentleGray,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildVitalStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTrendRow(String name, List<VitalSignTrend> trends, String unit, double minNormal, double maxNormal) {
    if (trends.isEmpty) return const SizedBox();
    
    final latest = trends.last;
    final isNormal = latest.isNormal;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNormal ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNormal ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isNormal ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${latest.value.toStringAsFixed(name == 'Temperature' ? 1 : 0)} $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Normal range: $minNormal-$maxNormal $unit',
            style: TextStyle(
              fontSize: 11,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 5: Risk Heatmap History
  Widget _buildRiskHeatmapHistory() {
    return _buildSectionCard(
      title: 'Risk Heatmap Journey',
      subtitle: 'Your assessment placements on the 5×5 risk matrix',
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConstant.softWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorConstant.cardBorder),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  final x = index % 5;
                  final y = 4 - (index ~/ 5); // Reverse Y for proper orientation
                  final score = (y + 1) * (x + 1);
                  
                  // Find if any assessment landed on this cell
                  final assessmentsHere = _history.where((r) => 
                    r.likelihoodScore == (x + 1) && r.impactScore == (y + 1)
                  ).toList();
                  
                  final cellColor = _getHeatmapColor(score);
                  final hasData = assessmentsHere.isNotEmpty;
                  
                  return GestureDetector(
                    onTap: hasData ? () => _showHeatmapDetailsDialog(assessmentsHere, score) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(6),
                        border: hasData ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: hasData ? [
                          BoxShadow(
                            color: cellColor.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              score.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: hasData ? FontWeight.w900 : FontWeight.bold,
                                fontSize: hasData ? 13 : 10,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (hasData)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${assessmentsHere.length}',
                                    style: TextStyle(
                                      color: cellColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap on highlighted cells to view assessment details',
            style: TextStyle(
              fontSize: 12,
              color: ColorConstant.gentleGray,
              fontStyle: FontStyle.italic,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showHeatmapDetailsDialog(List<AssessmentRecord> records, int score) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_on,
                size: 48,
                color: _getHeatmapColor(score),
              ),
              const SizedBox(height: 16),
              Text(
                'Score: $score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getHeatmapColor(score),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${records.length} assessment${records.length > 1 ? 's' : ''} at this level',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstant.gentleGray,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: record.getRiskColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: record.getRiskColor()),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(record.date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.bluedark,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.riskCategory,
                              style: TextStyle(
                                fontSize: 12,
                                color: record.getRiskColor(),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getHeatmapColor(score),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION 6: Assessment History Timeline with Filter & Search
  Widget _buildAssessmentHistoryTimeline() {
    return _buildSectionCard(
      title: Get.locale?.languageCode == 'fil' ? '📋 Kasaysayan ng Pagsusuri' : '📋 Assessment History',
      subtitle: Get.locale?.languageCode == 'fil'
        ? 'Tingnan ang lahat ng inyong mga pagsusuri'
        : 'View all your assessment records',
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: Get.locale?.languageCode == 'fil'
                  ? 'Maghanap ng pagsusuri...'
                  : 'Search assessments...',
              prefixIcon: Icon(Icons.search, color: ColorConstant.trustBlue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: ColorConstant.gentleGray),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: ColorConstant.softWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstant.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstant.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorConstant.trustBlue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          // Risk Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', Get.locale?.languageCode == 'fil' ? 'Lahat' : 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('Low', Get.locale?.languageCode == 'fil' ? 'Mababa' : 'Low'),
                const SizedBox(width: 8),
                _buildFilterChip('Mild', Get.locale?.languageCode == 'fil' ? 'Bahagya' : 'Mild'),
                const SizedBox(width: 8),
                _buildFilterChip('Moderate', Get.locale?.languageCode == 'fil' ? 'Katamtaman' : 'Moderate'),
                const SizedBox(width: 8),
                _buildFilterChip('High', Get.locale?.languageCode == 'fil' ? 'Mataas' : 'High'),
                const SizedBox(width: 8),
                _buildFilterChip('Critical', Get.locale?.languageCode == 'fil' ? 'Kritikal' : 'Critical'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Date Range Selector
          DateRangeSelector(
            selectedRange: _selectedDateRange,
            onRangeSelected: (option) async {
              if (option == DateRangeOption.custom) {
                // Show custom date picker
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  currentDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: ColorConstant.trustBlue,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (range != null) {
                  setState(() {
                    _selectedDateRange = option;
                    _customStartDate = range.start;
                    _customEndDate = range.end;
                  });
                }
              } else {
                setState(() {
                  _selectedDateRange = option;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              }
            },
            customStartDate: _customStartDate,
            customEndDate: _customEndDate,
          ),

          const SizedBox(height: 20),

          // Results Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Get.locale?.languageCode == 'fil'
                    ? '${_filteredHistory.length} mga resulta'
                    : '${_filteredHistory.length} results',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConstant.gentleGray,
                  fontFamily: 'Poppins',
                ),
              ),
              if (_filteredHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedRiskFilter = 'All';
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(Icons.refresh, size: 16, color: ColorConstant.trustBlue),
                  label: Text(
                    Get.locale?.languageCode == 'fil' ? 'I-reset' : 'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstant.trustBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Timeline List
          _filteredHistory.isEmpty
              ? _buildNoResultsState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredHistory.length > 10 ? 10 : _filteredHistory.length,
                  itemBuilder: (context, index) {
                    final record = _filteredHistory[index];
                    final isFirst = index == 0;
                    final isLast = index == _filteredHistory.length - 1 || index == 9;

                    return _buildAssessmentTimelineCard(record, isFirst, isLast);
                  },
                ),

          // Show More Button
          if (_filteredHistory.length > 10) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to full history view
                Get.snackbar(
                  Get.locale?.languageCode == 'fil' ? 'Paparating na Tampok' : 'Coming Soon',
                  Get.locale?.languageCode == 'fil'
                      ? 'Ang buong kasaysayan ay makikita sa susunod na update!'
                      : 'Full history view coming in next update!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstant.trustBlue,
                  colorText: Colors.white,
                );
              },
              icon: Icon(Icons.history, color: ColorConstant.trustBlue),
              label: Text(
                Get.locale?.languageCode == 'fil'
                    ? 'Tingnan ang lahat (${_filteredHistory.length})'
                    : 'View all (${_filteredHistory.length})',
                style: TextStyle(
                  color: ColorConstant.trustBlue,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedRiskFilter == category;
    final color = _getCategoryColor(category);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Poppins',
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRiskFilter = category;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildAssessmentTimelineCard(AssessmentRecord record, bool isFirst, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: record.getRiskColor(),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: record.getRiskColor().withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${record.finalRiskScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: ColorConstant.cardBorder,
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Card Content
          Expanded(
            child: GestureDetector(
              onTap: () => _showAssessmentDetailsDialog(record),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: record.getRiskColor().withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: record.getRiskColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            record.riskCategory,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: ColorConstant.gentleGray,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: ColorConstant.gentleGray),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(record.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConstant.bluedark,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(record.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: ColorConstant.gentleGray,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Score Details
                    Row(
                      children: [
                        Expanded(
                          child: _buildScorePill(
                            'L: ${record.likelihoodScore}',
                            const Color(0xFF4A90E2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScorePill(
                            'I: ${record.impactScore}',
                            const Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Vital Signs Preview
                    if (record.systolicBP != null && record.heartRate != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildVitalChip(
                            Icons.favorite,
                            '${record.heartRate} bpm',
                            const Color(0xFFE91E63),
                          ),
                          _buildVitalChip(
                            Icons.monitor_heart,
                            '${record.systolicBP}/${record.diastolicBP}',
                            const Color(0xFFFF6347),
                          ),
                          if (record.oxygenSaturation != null)
                            _buildVitalChip(
                              Icons.air,
                              '${record.oxygenSaturation}%',
                              const Color(0xFF00BCD4),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Poppins',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVitalChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: ColorConstant.gentleGray,
          ),
          const SizedBox(height: 16),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Walang nakitang resulta'
                : 'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Subukang baguhin ang inyong filter o search query'
                : 'Try changing your filter or search query',
            style: TextStyle(
              fontSize: 13,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAssessmentDetailsDialog(AssessmentRecord record) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: record.getRiskColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
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
                                  ? 'Detalye ng Pagsusuri'
                                  : 'Assessment Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.bluedark,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy h:mm a').format(record.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: ColorConstant.gentleGray,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ColorConstant.gentleGray),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Risk Score
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          record.getRiskColor().withOpacity(0.1),
                          record.getRiskColor().withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: record.getRiskColor()),
                    ),
                    child: Column(
                      children: [
                        Text(
                          record.riskCategory,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: record.getRiskColor(),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Kabuuang Score: ${record.finalRiskScore}/25'
                              : 'Total Score: ${record.finalRiskScore}/25',
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorConstant.bluedark,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Likelihood',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ColorConstant.gentleGray,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${record.likelihoodScore}/5',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4A90E2),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: ColorConstant.cardBorder,
                            ),
                            Column(
                              children: [
                                Text(
                                  'Impact',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ColorConstant.gentleGray,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${record.impactScore}/5',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE91E63),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Vital Signs
                  Text(
                    Get.locale?.languageCode == 'fil'
                        ? 'Vital Signs'
                        : 'Vital Signs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.bluedark,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstant.softWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (record.systolicBP != null)
                          _buildDetailRow('Blood Pressure', '${record.systolicBP}/${record.diastolicBP} mmHg'),
                        if (record.heartRate != null)
                          _buildDetailRow('Heart Rate', '${record.heartRate} bpm'),
                        if (record.oxygenSaturation != null)
                          _buildDetailRow('Oxygen Saturation', '${record.oxygenSaturation}%'),
                        if (record.temperature != null)
                          _buildDetailRow('Temperature', '${record.temperature!.toStringAsFixed(1)}°C'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: record.getRiskColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Get.locale?.languageCode == 'fil' ? 'Isara' : 'Close',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorConstant.bluedark,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 7: Risk Category Distribution
  Widget _buildRiskDistribution() {
    final total = _categoryDistribution.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox();
    
    return _buildSectionCard(
      title: 'Risk Distribution',
      subtitle: 'Breakdown of your assessment categories',
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _categoryDistribution.entries.where((e) => e.value > 0).map((entry) {
                  final percentage = (entry.value / total * 100);
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    color: _getCategoryColor(entry.key),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _categoryDistribution.entries.where((e) => e.value > 0).map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key} (${entry.value})',
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorConstant.bluedark,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // SECTION 7: Risk Factor Insights
  Widget _buildRiskFactorInsights() {
    final contributors = _riskFactorAnalysis['contributors'] ?? [];
    final improved = _riskFactorAnalysis['improved'] ?? [];
    
    return _buildSectionCard(
      title: '⚡ Risk Factor Analysis',
      subtitle: 'What\'s influencing your heart health',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contributors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Top Contributors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorConstant.bluedark,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            ...contributors.map((factor) => _buildRiskFactorItem(
              factor,
              Colors.orange,
              Icons.warning_amber,
            )),
          ],
          if (improved.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '✓ Improvements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            ...improved.map((factor) => _buildRiskFactorItem(
              factor,
              const Color(0xFF4CAF50),
              Icons.check_circle,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskFactorItem(RiskFactorContribution factor, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.factorName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  factor.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConstant.gentleGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${factor.occurrences}x',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 8: Data Contribution for Research
  Widget _buildDataContributionSection() {
    return _buildSectionCard(
      title: Get.locale?.languageCode == 'fil' ? '🔬 Tulong sa Pananaliksik' : '🔬 Help Research',
      subtitle: Get.locale?.languageCode == 'fil' 
        ? 'Tulungan ang PHC sa pagpapabuti ng kalusugan ng puso'
        : 'Help PHC improve heart health research',
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.science,
                  size: 48,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 16),
                Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Tulungan ang Pananaliksik'
                    : 'Help Research',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  Get.locale?.languageCode == 'fil'
                    ? 'Pahintulutan ang inyong anonymized data na makatulong sa pagpapabuti ng heart disease research ng PHC.'
                    : 'Allow your anonymized data to help improve PHC\'s heart disease research.',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorConstant.gentleGray,
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement data contribution toggle
                          Get.snackbar(
                            Get.locale?.languageCode == 'fil' ? 'Paparating na Tampok' : 'Coming Soon',
                            Get.locale?.languageCode == 'fil' 
                              ? 'Ang tampok na ito ay paparating na!'
                              : 'This feature is coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF4CAF50),
                            colorText: Colors.white,
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        label: Text(Get.locale?.languageCode == 'fil' ? 'Matuto Pa' : 'Learn More'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          side: BorderSide(color: const Color(0xFF4CAF50), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement data contribution toggle
                          Get.snackbar(
                            Get.locale?.languageCode == 'fil' ? 'Paparating na Tampok' : 'Coming Soon',
                            Get.locale?.languageCode == 'fil' 
                              ? 'Ang tampok na ito ay paparating na!'
                              : 'This feature is coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF4CAF50),
                            colorText: Colors.white,
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: Text(Get.locale?.languageCode == 'fil' ? 'Pumayag' : 'Contribute'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 9: Export & Share - Enhanced
  Widget _buildExportSection() {
    return _buildSectionCard(
      title: Get.locale?.languageCode == 'fil' ? 'I-export at Ibahagi' : 'Export & Share',
      subtitle: Get.locale?.languageCode == 'fil'
        ? 'Gumawa ng professional na health report'
        : 'Generate professional health reports',
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // PHC Branded Report Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstant.softWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstant.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstant.trustBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description,
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
                          ? 'Juan Heart Health Report'
                          : 'Juan Heart Health Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.bluedark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Get.locale?.languageCode == 'fil' 
                          ? 'Kasama ang PHC branding at QR code'
                          : 'Includes PHC branding and QR code',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstant.gentleGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final language = Get.locale?.languageCode ?? 'en';

                      // Show loading dialog
                      Get.dialog(
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: ColorConstant.trustBlue),
                                const SizedBox(height: 16),
                                Text(
                                  language == 'fil'
                                    ? 'Ginagawa ang PDF report...'
                                    : 'Generating PDF report...',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: ColorConstant.bluedark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      final result = await AnalyticsPDFService.generateAndDownloadHealthReport(
                        history: _history,
                        trendStats: _trendStats!,
                        vitalTrends: _vitalTrends,
                        insights: _insights,
                        categoryDistribution: _categoryDistribution,
                        language: language,
                      );

                      // Close loading dialog
                      Get.back();

                      // Show success message
                      Get.snackbar(
                        language == 'fil' ? 'Tagumpay!' : 'Success!',
                        result,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF4CAF50),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    } catch (e) {
                      // Close loading dialog if open
                      if (Get.isDialogOpen ?? false) Get.back();

                      // Show error message
                      Get.snackbar(
                        Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
                        Get.locale?.languageCode == 'fil'
                          ? 'Hindi ma-generate ang PDF report'
                          : 'Failed to generate PDF report',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(Get.locale?.languageCode == 'fil' ? 'I-download PDF' : 'Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.trustBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final language = Get.locale?.languageCode ?? 'en';

                      // Show loading dialog
                      Get.dialog(
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: ColorConstant.trustBlue),
                                const SizedBox(height: 16),
                                Text(
                                  language == 'fil'
                                    ? 'Inihahanda ang PDF para ibahagi...'
                                    : 'Preparing PDF to share...',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: ColorConstant.bluedark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      final result = await AnalyticsPDFService.generateAndShareHealthReport(
                        history: _history,
                        trendStats: _trendStats!,
                        vitalTrends: _vitalTrends,
                        insights: _insights,
                        categoryDistribution: _categoryDistribution,
                        language: language,
                      );

                      // Close loading dialog
                      Get.back();

                      // Show success message
                      Get.snackbar(
                        language == 'fil' ? 'Tagumpay!' : 'Success!',
                        result,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF4CAF50),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    } catch (e) {
                      // Close loading dialog if open
                      if (Get.isDialogOpen ?? false) Get.back();

                      // Show error message
                      Get.snackbar(
                        Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
                        Get.locale?.languageCode == 'fil'
                          ? 'Hindi ma-share ang PDF report'
                          : 'Failed to share PDF report',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: Text(Get.locale?.languageCode == 'fil' ? 'Ibahagi' : 'Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstant.trustBlue,
                    side: BorderSide(color: ColorConstant.trustBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CSV Export Section
          Text(
            Get.locale?.languageCode == 'fil'
              ? 'I-export bilang CSV (Excel/Google Sheets)'
              : 'Export as CSV (Excel/Google Sheets)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Download CSV Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final language = Get.locale?.languageCode ?? 'en';

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
                                  language == 'fil'
                                    ? 'Ginagawa ang CSV file...'
                                    : 'Generating CSV file...',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      // Generate and download complete analytics CSV
                      final result = await AnalyticsCSVService.exportAndShareCompleteAnalytics(
                        history: _history,
                        vitalTrends: _vitalTrends,
                        language: language,
                      );

                      // Close loading dialog
                      Get.back();

                      // Show success message
                      Get.snackbar(
                        language == 'fil' ? 'Tagumpay!' : 'Success!',
                        result,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF4CAF50),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    } catch (e) {
                      // Close loading dialog if open
                      if (Get.isDialogOpen ?? false) Get.back();

                      // Show error message
                      Get.snackbar(
                        Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
                        Get.locale?.languageCode == 'fil'
                          ? 'Hindi ma-export ang CSV files'
                          : 'Failed to export CSV files',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.table_chart),
                  label: Text(Get.locale?.languageCode == 'fil' ? 'I-download ang CSV' : 'Download CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Share CSV Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final language = Get.locale?.languageCode ?? 'en';

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
                                  language == 'fil'
                                    ? 'Ginagawa ang CSV file...'
                                    : 'Generating CSV file...',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      // Generate and share complete analytics CSV
                      final result = await AnalyticsCSVService.exportAndShareCompleteAnalytics(
                        history: _history,
                        vitalTrends: _vitalTrends,
                        language: language,
                      );

                      // Close loading dialog
                      Get.back();

                      // Show success message
                      Get.snackbar(
                        language == 'fil' ? 'Tagumpay!' : 'Success!',
                        result,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF4CAF50),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    } catch (e) {
                      // Close loading dialog if open
                      if (Get.isDialogOpen ?? false) Get.back();

                      // Show error message
                      Get.snackbar(
                        Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
                        Get.locale?.languageCode == 'fil'
                          ? 'Hindi ma-share ang CSV files'
                          : 'Failed to share CSV files',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: Text(Get.locale?.languageCode == 'fil' ? 'Ibahagi ang CSV' : 'Share CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF28A745),
                    side: const BorderSide(color: Color(0xFF28A745), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Get color for risk category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return ColorConstant.trustBlue;
      case 'low':
        return const Color(0xFF32CD32);
      case 'mild':
        return const Color(0xFFFFD700);
      case 'moderate':
        return const Color(0xFFFFA500);
      case 'high':
        return const Color(0xFFFF6347);
      case 'critical':
        return const Color(0xFFDC143C);
      default:
        return ColorConstant.gentleGray;
    }
  }

  // Helper: Build section card wrapper
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstant.cardBorder),
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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: ColorConstant.gentleGray,
              fontFamily: 'Poppins',
            ),
          ),
          child,
        ],
      ),
    );
  }

  // Empty state when no assessments exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 100,
              color: ColorConstant.gentleGray,
            ),
            const SizedBox(height: 24),
            Text(
              'No Assessment Data Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ColorConstant.bluedark,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first heart risk assessment to start tracking your cardiovascular health journey.',
              style: TextStyle(
                fontSize: 15,
                color: ColorConstant.gentleGray,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to assessment
                Get.back(); // Go to dashboard where user can start assessment
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Start Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.trustBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  Color _getHeatmapColor(int score) {
    if (score <= 5) {
      return const Color(0xFF32CD32); // Green
    } else if (score <= 10) {
      return const Color(0xFFFFD700); // Yellow
    } else if (score <= 15) {
      return const Color(0xFFFFA500); // Orange
    } else if (score <= 20) {
      return const Color(0xFFFF6347); // Red-Orange
    } else {
      return const Color(0xFFDC143C); // Red
    }
  }
}

