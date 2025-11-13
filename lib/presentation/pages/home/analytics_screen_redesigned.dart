import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/analytics_pdf_service.dart';
import 'package:juan_heart/services/analytics_csv_service.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
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
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Heart Insights Center",
          style: JHTextStyles.h4.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
        actions: [
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
                    style: JHTextStyles.bodyBase.copyWith(
                      color: ColorConstant.bluedark,
                      fontWeight: FontWeight.w600,
                    ),
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
                        
                        // 2. Personalized Health Insights
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
                        
                        // 6. Risk Category Distribution
                        _buildRiskDistribution(),
                        const SizedBox(height: 24),
                        
                        // 7. Risk Factor Insights
                        _buildRiskFactorInsights(),
                        const SizedBox(height: 24),
                        
                        // 8. Export & Share Section
                        _buildExportSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  // SECTION 1: Quick Stats Overview
  Widget _buildQuickStatsOverview() {
    if (_trendStats == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: JHTextStyles.h3.copyWith(
            fontSize: 22,
            color: ColorConstant.bluedark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Assessments',
                value: '${_trendStats!.totalAssessments}',
                icon: Icons.assignment,
                color: ColorConstant.trustBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Avg Risk Score',
                value: _trendStats!.avgRiskScore.toStringAsFixed(1),
                icon: Icons.analytics,
                color: _getTrendColor(_trendStats!.trendDirection),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Trend',
                value: _formatTrendDirection(_trendStats!.trendDirection),
                icon: _getTrendIcon(_trendStats!.trendDirection),
                color: _getTrendColor(_trendStats!.trendDirection),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Most Common',
                value: _trendStats!.mostCommonCategory,
                icon: Icons.favorite,
                color: _getCategoryColor(_trendStats!.mostCommonCategory),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AccentCard(
      accentColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: JHTextStyles.h3.copyWith(
              color: ColorConstant.bluedark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: JHTextStyles.caption.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 2: Personalized Health Insights
  Widget _buildHealthInsights() {
    if (_insights.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Insights',
          style: JHTextStyles.h3.copyWith(
            fontSize: 22,
            color: ColorConstant.bluedark,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_insights.length, (index) {
          final insight = _insights[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInsightCard(insight),
          );
        }),
      ],
    );
  }

  Widget _buildInsightCard(HealthInsight insight) {
    return AccentCard(
      accentColor: insight.color,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: JHTextStyles.button.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: JHTextStyles.bodySmall.copyWith(
                    color: ColorConstant.bluedark.withValues(alpha: 0.8),
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
                          style: JHTextStyles.caption.copyWith(
                            color: ColorConstant.gentleGray,
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
                            style: JHTextStyles.caption.copyWith(
                              color: ColorConstant.gentleGray,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          ColorConstant.trustBlue.withValues(alpha: 0.3),
                          ColorConstant.trustBlue.withValues(alpha: 0.05),
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
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            
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
        _buildLegendItem('Low', JHColors.success),
        _buildLegendItem('Mild', JHColors.warning),
        _buildLegendItem('Moderate', JHColors.warning),
        _buildLegendItem('High', JHColors.danger),
        _buildLegendItem('Critical', JHColors.dangerDark),
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
          style: JHTextStyles.caption.copyWith(
            color: ColorConstant.gentleGray,
          ),
        ),
      ],
    );
  }

  // SECTION 4: Vital Signs Trends
  Widget _buildVitalSignsSection() {
    return _buildSectionCard(
      title: '🩺 Vital Signs Trends',
      subtitle: 'Monitor your key health indicators',
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (_vitalTrends['systolicBP']!.isNotEmpty)
            _buildVitalTrendRow('Blood Pressure (Systolic)', _vitalTrends['systolicBP']!, 'mmHg', 90, 120),
          if (_vitalTrends['diastolicBP']!.isNotEmpty)
            _buildVitalTrendRow('Blood Pressure (Diastolic)', _vitalTrends['diastolicBP']!, 'mmHg', 60, 80),
          if (_vitalTrends['heartRate']!.isNotEmpty)
            _buildVitalTrendRow('Heart Rate', _vitalTrends['heartRate']!, 'bpm', 60, 100),
          if (_vitalTrends['oxygenSaturation']!.isNotEmpty)
            _buildVitalTrendRow('Oxygen Saturation', _vitalTrends['oxygenSaturation']!, '%', 95, 100),
          if (_vitalTrends['temperature']!.isNotEmpty)
            _buildVitalTrendRow('Temperature', _vitalTrends['temperature']!, '°C', 36.1, 37.2),
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
        color: isNormal ? JHColors.successLight : JHColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNormal ? JHColors.success : JHColors.danger,
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
                  style: JHTextStyles.button.copyWith(
                    color: ColorConstant.bluedark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isNormal ? JHColors.success : JHColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${latest.value.toStringAsFixed(name == 'Temperature' ? 1 : 0)} $unit',
                  style: JHTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Normal range: $minNormal-$maxNormal $unit',
            style: JHTextStyles.caption.copyWith(
              color: ColorConstant.gentleGray,
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
                            color: cellColor.withValues(alpha: 0.5),
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
                                    style: JHTextStyles.caption.copyWith(
                                      color: cellColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
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
            style: JHTextStyles.caption.copyWith(
              color: ColorConstant.gentleGray,
              fontStyle: FontStyle.italic,
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
                style: JHTextStyles.h3.copyWith(
                  color: _getHeatmapColor(score),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${records.length} assessment${records.length > 1 ? 's' : ''} at this level',
                style: JHTextStyles.h4.copyWith(
                  fontSize: 16,
                  color: ColorConstant.gentleGray,
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
                          color: record.getRiskColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: record.getRiskColor()),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(record.date),
                              style: JHTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.bluedark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.riskCategory,
                              style: JHTextStyles.caption.copyWith(
                                color: record.getRiskColor(),
                                fontWeight: FontWeight.w600,
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

  // SECTION 6: Risk Category Distribution
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
                    titleStyle: JHTextStyles.button.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                    style: JHTextStyles.bodySmall.copyWith(
                      color: ColorConstant.bluedark,
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
              style: JHTextStyles.h4.copyWith(
                fontSize: 16,
                color: ColorConstant.bluedark,
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
            const Text(
              '✓ Improvements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: JHColors.success,
                
              ),
            ),
            const SizedBox(height: 12),
            ...improved.map((factor) => _buildRiskFactorItem(
              factor,
              JHColors.success,
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                  style: JHTextStyles.button.copyWith(
                    color: ColorConstant.bluedark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  factor.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConstant.gentleGray,
                    
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
              style: JHTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 8: Export & Share
  Widget _buildExportSection() {
    return _buildSectionCard(
      title: 'Export & Share',
      subtitle: 'Generate and share your health reports',
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(
                    Get.locale?.languageCode == 'fil' ? 'I-download ang PDF' : 'Download PDF',
                  ),
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
                  onPressed: _shareReport,
                  icon: const Icon(Icons.share),
                  label: Text(
                    Get.locale?.languageCode == 'fil' ? 'Ibahagi' : 'Share',
                  ),
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
        ],
      ),
    );
  }

  // Helper: Build section card wrapper
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: JHTextStyles.h4.copyWith(
              color: ColorConstant.bluedark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: JHTextStyles.bodySmall.copyWith(
              color: ColorConstant.gentleGray,
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
              style: JHTextStyles.h3.copyWith(
                fontSize: 22,
                color: ColorConstant.bluedark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first heart risk assessment to start tracking your cardiovascular health journey.',
              style: JHTextStyles.bodyBase.copyWith(
                fontSize: 15,
                color: ColorConstant.gentleGray,
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
  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return JHColors.success;
      case 'worsening':
        return JHColors.danger;
      default:
        return ColorConstant.trustBlue;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_down;
      case 'worsening':
        return Icons.trending_up;
      default:
        return Icons.trending_flat;
    }
  }

  String _formatTrendDirection(String trend) {
    switch (trend) {
      case 'improving':
        return 'Improving ↓';
      case 'worsening':
        return 'Worsening ↑';
      default:
        return 'Stable →';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return JHColors.dangerDark;
      case 'high':
        return JHColors.danger;
      case 'moderate':
        return JHColors.warning;
      case 'mild':
        return JHColors.warning;
      case 'low':
        return JHColors.success;
      default:
        return Colors.grey;
    }
  }

  Color _getHeatmapColor(int score) {
    if (score <= 5) {
      return JHColors.success; // Green
    } else if (score <= 10) {
      return JHColors.warning; // Yellow
    } else if (score <= 15) {
      return JHColors.warning; // Orange
    } else if (score <= 20) {
      return JHColors.danger; // Red-Orange
    } else {
      return JHColors.dangerDark; // Red
    }
  }

  /// Export health report as PDF
  Future<void> _exportPDF() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.trustBlue),
              const SizedBox(height: 16),
              Text(
                isFilipino
                    ? 'Ginagawa ang PDF report...'
                    : 'Generating PDF report...',
                style: JHTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Validate required data
      if (_trendStats == null) {
        throw Exception(isFilipino ? 'Walang available na trend data' : 'No trend data available');
      }

      // Generate and share PDF
      await AnalyticsPDFService.generateAndShareHealthReport(
        history: _history,
        trendStats: _trendStats!,
        vitalTrends: _vitalTrends,
        insights: _insights,
        categoryDistribution: _categoryDistribution,
        language: isFilipino ? 'fil' : 'en',
      );

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        isFilipino ? 'Tagumpay!' : 'Success!',
        isFilipino
            ? 'Ang PDF report ay na-generate na. Tingnan ang inyong downloads folder.'
            : 'PDF report generated successfully. Check your downloads folder.',
        backgroundColor: JHColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error message
      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Hindi ma-generate ang PDF report: $e'
            : 'Failed to generate PDF report: $e',
        backgroundColor: JHColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Share health report (PDF or CSV)
  Future<void> _shareReport() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show action sheet to choose format
    await Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Piliin ang Format' : 'Choose Format',
              style: JHTextStyles.h4.copyWith(
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFilipino
                  ? 'Piliin kung paano mo gusto ibahagi ang iyong health report.'
                  : 'Choose how you want to share your health report.',
              style: JHTextStyles.bodySmall.copyWith(
                color: ColorConstant.gentleGray,
              ),
            ),
            const SizedBox(height: 24),
            // PDF Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: Text(
                'PDF Report',
                style: JHTextStyles.h5.copyWith(
                  color: ColorConstant.bluedark,
                ),
              ),
              subtitle: Text(
                isFilipino
                    ? 'Visual na report na may charts at insights'
                    : 'Visual report with charts and insights',
                style: JHTextStyles.caption.copyWith(
                  color: ColorConstant.gentleGray,
                ),
              ),
              onTap: () {
                Get.back();
                _shareAsPDF();
              },
            ),
            const SizedBox(height: 8),
            // CSV Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart, color: Colors.green),
              ),
              title: Text(
                'CSV Data',
                style: JHTextStyles.h5.copyWith(
                  color: ColorConstant.bluedark,
                ),
              ),
              subtitle: Text(
                isFilipino
                    ? 'Raw data para sa spreadsheet analysis'
                    : 'Raw data for spreadsheet analysis',
                style: JHTextStyles.caption.copyWith(
                  color: ColorConstant.gentleGray,
                ),
              ),
              onTap: () {
                Get.back();
                _shareAsCSV();
              },
            ),
            const SizedBox(height: 16),
            // Cancel button
            StandardButton.grey(
              text: isFilipino ? 'Kanselahin' : 'Cancel',
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Share report as PDF
  Future<void> _shareAsPDF() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.trustBlue),
              const SizedBox(height: 16),
              Text(
                isFilipino
                    ? 'Ginagawa ang PDF...'
                    : 'Generating PDF...',
                style: JHTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Validate required data
      if (_trendStats == null) {
        throw Exception(isFilipino ? 'Walang available na trend data' : 'No trend data available');
      }

      await AnalyticsPDFService.generateAndShareHealthReport(
        history: _history,
        trendStats: _trendStats!,
        vitalTrends: _vitalTrends,
        insights: _insights,
        categoryDistribution: _categoryDistribution,
        language: isFilipino ? 'fil' : 'en',
      );

      Get.back(); // Close loading dialog
    } catch (e) {
      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Hindi ma-share ang PDF: $e'
            : 'Failed to share PDF: $e',
        backgroundColor: JHColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Share report as CSV
  Future<void> _shareAsCSV() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.trustBlue),
              const SizedBox(height: 16),
              Text(
                isFilipino
                    ? 'Ginagawa ang CSV...'
                    : 'Generating CSV...',
                style: JHTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await AnalyticsCSVService.exportAndShareAssessmentHistory(
        history: _history,
        language: isFilipino ? 'fil' : 'en',
      );

      Get.back(); // Close loading dialog
    } catch (e) {
      Get.back(); // Close loading dialog

      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Hindi ma-share ang CSV: $e'
            : 'Failed to share CSV: $e',
        backgroundColor: JHColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

