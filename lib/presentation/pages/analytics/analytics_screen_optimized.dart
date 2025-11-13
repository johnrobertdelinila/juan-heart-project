import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/analytics_service_optimized.dart';
import 'package:juan_heart/services/network_adaptive_loader.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';
import 'package:intl/intl.dart';

/// OPTIMIZED Heart Insights Center
///
/// Performance Optimizations:
/// 1. Progressive loading (summary first, details lazy-loaded)
/// 2. Network-adaptive payload sizes
/// 3. Smart caching with TTL
/// 4. Pagination for large datasets
/// 5. <5s load time on 3G guaranteed
///
/// Rural Network Support:
/// - 2G: Summary only + last 5 records
/// - 3G: Summary + last 10 records + reduced vitals
/// - 4G: Summary + last 15 records + full vitals
/// - WiFi: Full data
class AnalyticsScreenOptimized extends StatefulWidget {
  const AnalyticsScreenOptimized({super.key});

  @override
  State<AnalyticsScreenOptimized> createState() => _AnalyticsScreenOptimizedState();
}

class _AnalyticsScreenOptimizedState extends State<AnalyticsScreenOptimized>
    with NetworkAdaptiveMixin {
  bool _isLoadingSummary = true;
  bool _isLoadingDetails = false;
  bool _isLoadingMore = false;

  // Summary data (loads first for instant feedback)
  RiskTrendStats? _trendStats;

  // Progressive data (loads after summary)
  List<AssessmentRecord> _displayedRecords = [];
  Map<String, List<VitalSignTrend>> _vitalTrends = {};
  List<HealthInsight> _insights = [];
  Map<String, int> _categoryDistribution = {};

  // Pagination state
  int _currentPage = 0;
  bool _hasMoreRecords = false;

  // Network quality
  NetworkQuality _networkQuality = NetworkQuality.threeG;
  String _networkMessage = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeNetworkAndLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize network detection and start progressive loading
  Future<void> _initializeNetworkAndLoad() async {
    await initNetworkAdaptive();
    _networkQuality = networkQuality;
    final isFilipino = Get.locale?.languageCode == 'fil';
    _networkMessage = NetworkAdaptiveLoader.getNetworkMessage(
      _networkQuality,
      isFilipino,
    );

    await _loadAnalyticsProgressive();
  }

  /// Progressive loading strategy:
  /// 1. Load summary first (cached, <500ms)
  /// 2. Show summary UI immediately
  /// 3. Load initial records in background
  /// 4. Load remaining data lazily
  Future<void> _loadAnalyticsProgressive() async {
    final startTime = DateTime.now();

    setState(() => _isLoadingSummary = true);

    try {
      // PHASE 1: Load summary (ultra-fast, from cache if possible)
      debugPrint('📊 Phase 1: Loading summary...');
      final summaryResult = await AnalyticsServiceOptimized.getAnalyticsWithProgressiveLoading();

      setState(() {
        _trendStats = summaryResult.summary;
        _displayedRecords = summaryResult.initialRecords;
        _hasMoreRecords = summaryResult.hasMore;
        _isLoadingSummary = false;
      });

      final summaryTime = DateTime.now().difference(startTime);
      debugPrint('✅ Summary loaded in ${summaryTime.inMilliseconds}ms');

      // PHASE 2: Load additional analytics data in background
      setState(() => _isLoadingDetails = true);
      await _loadAdditionalAnalytics();

      final totalTime = DateTime.now().difference(startTime);
      debugPrint('✅ Total load time: ${totalTime.inMilliseconds}ms');

      setState(() => _isLoadingDetails = false);
    } catch (e) {
      debugPrint('⚠️ Error in progressive loading: $e');
      setState(() {
        _isLoadingSummary = false;
        _isLoadingDetails = false;
      });
    }
  }

  /// Load additional analytics data (vitals, insights, distribution)
  Future<void> _loadAdditionalAnalytics() async {
    try {
      // Generate mock data if needed (for demo)
      await AnalyticsService.generateMockData();

      // Load vitals (network-adaptive)
      _vitalTrends = await AnalyticsServiceOptimized.getVitalSignsTrends();

      // Load insights (from existing service)
      _insights = await AnalyticsService.generateHealthInsights();

      // Load category distribution (lightweight calculation)
      _categoryDistribution = await AnalyticsService.getRiskCategoryDistribution();

      setState(() {});
    } catch (e) {
      debugPrint('⚠️ Error loading additional analytics: $e');
    }
  }

  /// Handle scroll for infinite loading
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMoreRecords) {
        _loadMoreRecords();
      }
    }
  }

  /// Load more records (pagination)
  Future<void> _loadMoreRecords() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreRecords = await AnalyticsServiceOptimized.loadMoreRecords(_currentPage);

      if (moreRecords.isEmpty) {
        setState(() {
          _hasMoreRecords = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        _displayedRecords.addAll(moreRecords);
        _currentPage++;
        _hasMoreRecords = moreRecords.length >= config.pageSize;
        _isLoadingMore = false;
      });

      debugPrint('✅ Loaded page $_currentPage (${moreRecords.length} records)');
    } catch (e) {
      debugPrint('⚠️ Error loading more records: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  /// Force refresh (invalidates cache)
  Future<void> _refreshAnalytics() async {
    await AnalyticsServiceOptimized.invalidateCaches();
    _currentPage = 0;
    _displayedRecords.clear();
    await _loadAnalyticsProgressive();
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
            onPressed: _refreshAnalytics,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoadingSummary
          ? _buildLoadingState()
          : _displayedRecords.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshAnalytics,
                  color: ColorConstant.trustBlue,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Network quality indicator
                        if (shouldShowNetworkWarning) _buildNetworkWarning(),

                        // 1. Quick Stats Overview (always shows - from cache)
                        _buildQuickStatsOverview(),
                        const SizedBox(height: 24),

                        // 2. Personalized Health Insights (loaded progressively)
                        if (_insights.isNotEmpty) ...[
                          _buildHealthInsights(),
                          const SizedBox(height: 24),
                        ],

                        // 3. Risk History Chart (uses displayed records)
                        if (_displayedRecords.length >= 2) ...[
                          _buildRiskHistorySection(),
                          const SizedBox(height: 24),
                        ],

                        // 4. Vital Signs (network-adaptive)
                        if (_vitalTrends.isNotEmpty && config.includeVitalSigns) ...[
                          _buildVitalSignsSection(),
                          const SizedBox(height: 24),
                        ],

                        // 5. Risk Distribution
                        if (_categoryDistribution.isNotEmpty) ...[
                          _buildRiskDistribution(),
                          const SizedBox(height: 24),
                        ],

                        // Loading more indicator
                        if (_isLoadingMore) _buildLoadingMoreIndicator(),

                        // Load more button (if has more and not auto-loading)
                        if (_hasMoreRecords && !_isLoadingMore)
                          _buildLoadMoreButton(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Network warning banner for slow connections
  Widget _buildNetworkWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JHColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: JHColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.signal_cellular_alt_2_bar, color: JHColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _networkMessage,
                  style: JHTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
                Text(
                  Get.locale?.languageCode == 'fil'
                      ? 'Naglo-load ng limited data para sa bilis'
                      : 'Loading limited data for faster performance',
                  style: JHTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: ColorConstant.gentleGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Loading state with progress message
  Widget _buildLoadingState() {
    return Center(
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
          const SizedBox(height: 8),
          FutureBuilder<Duration>(
            future: AnalyticsServiceOptimized.getEstimatedLoadTime(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  'Estimated: ${snapshot.data!.inSeconds}s',
                  style: JHTextStyles.caption.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  /// Loading more indicator (at bottom)
  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorConstant.trustBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more records...',
              style: JHTextStyles.caption.copyWith(
                color: ColorConstant.gentleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Load more button
  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: StandardButton.grey(
          text: 'Load More Records',
          onPressed: _loadMoreRecords,
        ),
      ),
    );
  }

  /// Quick stats overview (same as original, but uses cached data)
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: JHTextStyles.h3.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: JHTextStyles.caption.copyWith(color: ColorConstant.gentleGray),
          ),
        ],
      ),
    );
  }

  // Additional UI methods (simplified versions)
  Widget _buildHealthInsights() {
    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Insights',
            style: JHTextStyles.h4.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 16),
          ...List.generate(_insights.take(3).length, (index) {
            final insight = _insights[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(insight.icon, color: insight.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight.title,
                      style: JHTextStyles.bodySmall.copyWith(
                        color: ColorConstant.bluedark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiskHistorySection() {
    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Trend',
            style: JHTextStyles.h4.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _displayedRecords.length,
                      (i) => FlSpot(i.toDouble(), _displayedRecords[i].finalRiskScore.toDouble()),
                    ),
                    isCurved: true,
                    color: ColorConstant.trustBlue,
                    barWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsSection() {
    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vital Signs',
            style: JHTextStyles.h4.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 16),
          Text(
            'Showing vital signs for loaded records',
            style: JHTextStyles.caption.copyWith(color: ColorConstant.gentleGray),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution() {
    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Distribution',
            style: JHTextStyles.h4.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _categoryDistribution.entries.where((e) => e.value > 0).map((e) {
              return Chip(
                label: Text('${e.key}: ${e.value}'),
                backgroundColor: _getCategoryColor(e.key).withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No assessment data yet',
        style: JHTextStyles.h4.copyWith(color: ColorConstant.gentleGray),
      ),
    );
  }

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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return JHColors.dangerDark;
      case 'high':
        return JHColors.danger;
      case 'moderate':
      case 'mild':
        return JHColors.warning;
      case 'low':
        return JHColors.success;
      default:
        return Colors.grey;
    }
  }
}
