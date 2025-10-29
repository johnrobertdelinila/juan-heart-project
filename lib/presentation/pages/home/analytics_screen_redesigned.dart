import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/analytics_service.dart';
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorConstant.bluedark,
            fontFamily: 'Poppins',
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
                color: ColorConstant.trust Blue,
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
              fontSize: 24,
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

  // SECTION 2: Personalized Health Insights
  Widget _buildHealthInsights() {
    if (_insights.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Insights',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorConstant.bluedark,
            fontFamily: 'Poppins',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withOpacity(0.3), width: 1.5),
      ),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorConstant.bluedark.withOpacity(0.8),
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
                  onPressed: () {
                    // TODO: Implement PDF export
                    Get.snackbar(
                      'Coming Soon',
                      'PDF report generation will be available soon!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: ColorConstant.trustBlue,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
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
                  onPressed: () {
                    // TODO: Implement share functionality
                    Get.snackbar(
                      'Coming Soon',
                      'Share feature will be available soon!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: ColorConstant.trustBlue,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
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
  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return const Color(0xFF4CAF50);
      case 'worsening':
        return const Color(0xFFF44336);
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
        return const Color(0xFFDC143C);
      case 'high':
        return const Color(0xFFFF6347);
      case 'moderate':
        return const Color(0xFFFFA500);
      case 'mild':
        return const Color(0xFFFFD700);
      case 'low':
        return const Color(0xFF32CD32);
      default:
        return Colors.grey;
    }
  }

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

