import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

class AssessmentDetailsScreen extends StatelessWidget {
  final AssessmentRecord record;

  const AssessmentDetailsScreen({super.key, required this.record});

  bool get _isFilipino => Get.locale?.languageCode == 'fil';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        title: Text(
          _isFilipino ? 'Detalye ng Pagsusuri' : 'Assessment Details',
          style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark),
        ),
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildRiskSummary(),
          const SizedBox(height: 16),
          _buildScoreGrid(),
          const SizedBox(height: 16),
          _buildVitalsCard(),
          const SizedBox(height: 16),
          _buildRecommendationCard(),
        ],
      ),
    );
  }

  Widget _buildRiskSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: record.getRiskColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: record.getRiskColor().withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: record.getRiskColor(),
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.riskCategory,
                      style: JHTextStyles.h4.copyWith(
                        color: record.getRiskColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • h:mm a').format(record.date),
                      style: JHTextStyles.caption.copyWith(
                        color: ColorConstant.bluedark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${record.finalRiskScore}/25',
            style: JHTextStyles.h3.copyWith(
              color: record.getRiskColor(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isFilipino
                ? 'Kabuuang Score (Likelihood × Impact)'
                : 'Total Score (Likelihood × Impact)',
            style: JHTextStyles.caption.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScoreTile(
              label: 'Likelihood',
              value: '${record.likelihoodScore}/5',
              description: record.likelihoodLevel,
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: ColorConstant.cardBorder,
          ),
          Expanded(
            child: _ScoreTile(
              label: 'Impact',
              value: '${record.impactScore}/5',
              description: record.impactLevel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    final vitals = <Widget>[];

    void addVital(String label, String value, IconData icon) {
      vitals.add(_VitalTile(label: label, value: value, icon: icon));
    }

    if (record.systolicBP != null && record.diastolicBP != null) {
      addVital(
        _isFilipino ? 'Presyon ng Dugo' : 'Blood Pressure',
        '${record.systolicBP}/${record.diastolicBP} mmHg',
        Icons.favorite_outline,
      );
    }

    if (record.heartRate != null) {
      addVital(
        _isFilipino ? 'Pulang Tibok' : 'Heart Rate',
        '${record.heartRate} bpm',
        Icons.monitor_heart,
      );
    }

    if (record.oxygenSaturation != null) {
      addVital(
        _isFilipino ? 'Oxygen' : 'Oxygen',
        '${record.oxygenSaturation}%',
        Icons.bloodtype,
      );
    }

    if (record.bmi != null) {
      addVital(
        'BMI',
        record.bmi!.toStringAsFixed(1),
        Icons.scale,
      );
    }

    if (vitals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstant.softWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isFilipino ? 'Mga Vital Signs' : 'Vital Signs',
            style: JHTextStyles.label.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: vitals,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isFilipino ? 'Rekomendasyon' : 'Recommendation',
            style: JHTextStyles.label.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            record.recommendedAction,
            style: JHTextStyles.bodyBase.copyWith(
              color: ColorConstant.bluedark,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (record.timeframe != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_isFilipino ? 'Panahon' : 'Timeframe'}: ${record.timeframe}',
              style: JHTextStyles.caption.copyWith(
                color: ColorConstant.gentleGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _ScoreTile({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JHTextStyles.caption.copyWith(
            color: ColorConstant.gentleGray,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: JHTextStyles.h4.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: JHTextStyles.bodySmall.copyWith(
            color: ColorConstant.trustBlue,
          ),
        ),
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _VitalTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorConstant.trustBlue, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: JHTextStyles.caption.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: JHTextStyles.bodyBase.copyWith(
              color: ColorConstant.bluedark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
