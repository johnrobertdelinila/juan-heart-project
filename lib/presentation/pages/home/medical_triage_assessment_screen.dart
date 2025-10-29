import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/services/medical_triage_assessment_service.dart';
import 'package:juan_heart/services/pdf_report_service.dart';
import 'package:juan_heart/services/referral_service.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/assessment_strategy.dart';
import 'package:juan_heart/services/feature_flag_service.dart';
import 'package:juan_heart/services/ai_consent_service.dart';
import 'package:juan_heart/models/medical_triage_assessment_data.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/presentation/widgets/ai_consent_dialog.dart';
import 'package:juan_heart/presentation/widgets/validation_comparison_view.dart';
import 'package:juan_heart/themes/app_styles.dart';
import 'package:juan_heart/routes/app_routes.dart';

class MedicalTriageAssessmentScreen extends StatefulWidget {
  const MedicalTriageAssessmentScreen({super.key});

  @override
  State<MedicalTriageAssessmentScreen> createState() => _MedicalTriageAssessmentScreenState();
}

class _MedicalTriageAssessmentScreenState extends State<MedicalTriageAssessmentScreen> {
  final MedicalTriageAssessmentService _assessmentService = MedicalTriageAssessmentService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _assessmentResult;
  
  // Collapsible sections state for results screen
  bool _isHeatmapExpanded = true;
  bool _isDetailsExpanded = false;
  bool _isRecommendationsExpanded = false;

  // AI assessment state
  AssessmentStrategy _selectedStrategy = RuleBasedAssessmentStrategy();
  bool _showAIOption = false;
  bool _isComparisonExpanded = true;

  // Form data
  Map<String, dynamic> _userInput = {
    'age': '',
    'sex': '',
    'chestPainType': '',
    'chestPainDuration': '',
    'chestPainRadiation': false,
    'chestPainExertional': false,
    'shortnessOfBreath': '',
    'palpitations': false,
    'palpitationType': '',
    'syncope': false,
    'fainting': false,
    'neurologicalSymptoms': false,
    'legSwelling': false,
    'sweating': false,
    'dizziness': false,
    'nausea': false,
    'systolicBP': '',
    'diastolicBP': '',
    'heartRate': '',
    'oxygenSaturation': '',
    'temperature': '',
    'hypertension': false,
    'diabetes': false,
    'ckd': false,
    'highCholesterol': false,
    'smoking': false,
    'obesity': false,
    'familyHistory': false,
    'previousHeartDisease': false,
  };

  // Controllers for text fields
  Map<String, TextEditingController> _controllers = {};
  Map<String, FocusNode> _focusNodes = {};
  Map<String, bool> _fieldTouched = {}; // Track if field has been touched

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _assessmentService.initialize();
    _checkAIAvailability();
  }

  /// Check if AI assessment option should be shown
  Future<void> _checkAIAvailability() async {
    final isEnabled = await FeatureFlagService.isAIAssessmentEnabled();
    setState(() {
      _showAIOption = isEnabled;
    });
  }

  void _initializeControllers() {
    final textFields = ['age', 'chestPainDuration', 'systolicBP', 'diastolicBP', 
                       'heartRate', 'oxygenSaturation', 'temperature'];
    for (String field in textFields) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
      _fieldTouched[field] = false;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _pageController.dispose();
    _assessmentService.dispose();
    super.dispose();
  }

  void _updateInput(String key, dynamic value) {
    setState(() {
      _userInput[key] = value;
    });
  }

  Future<void> _runAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert text field values
      for (String field in _controllers.keys) {
        if (_controllers[field]!.text.isNotEmpty) {
          _userInput[field] = _controllers[field]!.text;
        }
      }

      // Use selected strategy (AI or Rule-Based)
      final assessmentContext = AssessmentContext(_selectedStrategy);
      final result = await assessmentContext.performAssessment(_userInput);

      // Check if AI fallback was used
      if (result['fallbackUsed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI unavailable. Using validated rule-based algorithm.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      // Save assessment to history for analytics
      await _saveAssessmentToHistory(result);

      setState(() {
        _assessmentResult = result;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  /// Save assessment results to history for analytics tracking
  Future<void> _saveAssessmentToHistory(Map<String, dynamic> result) async {
    try {
      final record = AssessmentRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        finalRiskScore: result['finalRiskScore'] ?? 0,
        likelihoodScore: result['likelihoodScore'] ?? 1,
        impactScore: result['impactScore'] ?? 1,
        riskCategory: result['riskCategory'] ?? 'Low',
        likelihoodLevel: result['likelihoodLevel'] ?? '',
        impactLevel: result['impactLevel'] ?? '',
        recommendedAction: result['recommendedAction'] ?? '',
        systolicBP: int.tryParse(_userInput['systolicBP']?.toString() ?? ''),
        diastolicBP: int.tryParse(_userInput['diastolicBP']?.toString() ?? ''),
        heartRate: int.tryParse(_userInput['heartRate']?.toString() ?? ''),
        oxygenSaturation: int.tryParse(_userInput['oxygenSaturation']?.toString() ?? ''),
        temperature: double.tryParse(_userInput['temperature']?.toString() ?? ''),
        symptoms: Map<String, dynamic>.from(_userInput)
          ..removeWhere((key, value) => !key.startsWith('symptom_') && key != 'chestPainType' && key != 'shortnessOfBreath'),
        riskFactors: Map<String, dynamic>.from(_userInput)
          ..removeWhere((key, value) => !(key.contains('hypertension') || key.contains('diabetes') || 
            key.contains('smoking') || key.contains('obesity') || key.contains('familyHistory') || 
            key.contains('ckd') || key.contains('highCholesterol'))),
        age: int.tryParse(_userInput['age']?.toString() ?? '') ?? 0,
        sex: _userInput['sex']?.toString() ?? 'Unknown',
      );
      
      await AnalyticsService.saveAssessment(record);
      print('✅ Assessment saved to history for analytics');
    } catch (e) {
      print('⚠️ Error saving assessment to history: $e');
      // Don't block the user flow if saving fails
    }
  }

  void _nextPage() {
    // Validate required fields before proceeding
    if (!_validateCurrentPage()) {
      return; // Stop if validation fails
    }

    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _runAssessment();
    }
  }
  
  void _navigateToNextSteps() {
    if (_assessmentResult == null) return;
    
    // Get risk score from assessment result (note: it's stored as 'finalRiskScore' in the assessment)
    int riskScore = _assessmentResult!['finalRiskScore'] ?? 0;
    String riskCategory = _assessmentResult!['riskCategory'] ?? 'Low Risk';
    
    // Generate care recommendation using ReferralService
    final recommendation = ReferralService.generateRecommendation(
      riskCategory: riskCategory,
      riskScore: riskScore,
      language: Get.locale?.languageCode ?? 'en',
    );
    
    // Navigate to Next Steps screen with recommendation and assessment data
    Get.toNamed(
      AppRoutes.nextStepsScreen,
      arguments: {
        'recommendation': recommendation,
        'assessmentData': _userInput,
      },
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Method Selection - No validation needed
        break;
      case 1: // Basic Information
        // Check age - try both _userInput and controller
        String ageValue = _userInput['age']?.toString() ?? _controllers['age']?.text ?? '';
        if (ageValue.isEmpty) {
          _showValidationError('Age is required to proceed.');
          return false;
        }
        if (_userInput['sex'] == null || _userInput['sex'].toString().isEmpty) {
          _showValidationError('Sex is required to proceed.');
          return false;
        }
        // Validate age range
        int age = int.tryParse(ageValue) ?? 0;
        if (age < 10 || age > 90) {
          _showValidationError('Please enter a valid age between 10 and 90.');
          return false;
        }
        break;
      case 2: // Symptoms - No required fields
        break;
      case 3: // Vital Signs - No required fields
        break;
      case 4: // Risk Factors - No required fields
        break;
      case 5: // Review - No validation needed
        break;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Heart Risk Assessment",
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorConstant.bluedark,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        backgroundColor: ColorConstant.whiteBackground,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _assessmentResult != null
              ? _buildResultsScreen()
              : _buildAssessmentForm(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorConstant.bluedark,
          ),
          const SizedBox(height: 20),
          Text(
            "Analyzing your assessment...",
            style: AppStyle.txtPoppinsSemiBold18Dark,
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentForm() {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 6,
                  backgroundColor: ColorConstant.bluedark.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.bluedark),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${_currentPage + 1}/6",
                style: AppStyle.txtPoppinsSemiBold16Dark,
              ),
            ],
          ),
        ),
        
        // Form pages
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              // Disable swipe gestures
              if (notification is ScrollUpdateNotification) {
                return true; // Consume the notification to prevent swiping
              }
              return false;
            },
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildMethodSelectionPage(),
                _buildBasicInfoPage(),
                _buildSymptomsPage(),
                _buildVitalSignsPage(),
                _buildRiskFactorsPage(),
                _buildReviewPage(),
              ],
            ),
          ),
        ),
        
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Required fields note (only show on basic info page)
              if (_currentPage == 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstant.lightBlueBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ColorConstant.bluedark.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Only age and sex are required. Vital signs are optional but help provide more accurate results.",
                          style: TextStyle(
                            color: ColorConstant.bluedark.withOpacity(0.8),
                            fontSize: 12,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_currentPage == 1) const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: ColorConstant.bluedark,
                      ),
                      child: Text("Previous"),
                    )
                  else
                    const SizedBox(width: 100),

                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.bluedark,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_currentPage == 5 ? "Complete Assessment" : "Next"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build method selection page (AI vs Rule-Based)
  Widget _buildMethodSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Assessment Method",
            style: AppStyle.txtPoppinsSemiBold24Dark,
          ),
          const SizedBox(height: 8),
          Text(
            "Choose how you want to assess your heart disease risk. Both methods are validated and safe.",
            style: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.7),
              fontSize: 14,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 24),

          // Rule-Based Card
          _buildMethodCard(
            title: "PHC Rule-Based Algorithm",
            badge: "VALIDATED",
            badgeColor: Colors.green,
            icon: Icons.calculate,
            description: "Clinically validated algorithm based on Philippine Heart Center guidelines. Works offline.",
            features: [
              "100% offline capability",
              "PHC-validated accuracy",
              "Instant results",
              "Privacy-first design",
            ],
            isSelected: _selectedStrategy is RuleBasedAssessmentStrategy,
            onTap: () {
              setState(() {
                _selectedStrategy = RuleBasedAssessmentStrategy();
              });
            },
          ),

          const SizedBox(height: 16),

          // AI Card (conditional)
          if (_showAIOption)
            _buildMethodCard(
              title: "Gemini AI Prediction",
              badge: "EXPERIMENTAL",
              badgeColor: Colors.orange,
              icon: Icons.auto_awesome,
              description: "AI-powered assessment using Google's Gemini Flash model. Requires internet connection.",
              features: [
                "Advanced AI analysis",
                "Contextual insights",
                "Validation against rule-based",
                "Shows both results if different",
              ],
              isSelected: _selectedStrategy is AIAssessmentStrategy,
              onTap: () async {
                // Check consent before selecting AI
                final hasConsent = await AIConsentService.hasConsent();
                if (!hasConsent) {
                  final consented = await showAIConsentDialog();
                  if (!consented) return; // User declined
                }

                setState(() {
                  _selectedStrategy = AIAssessmentStrategy();
                });
              },
            ),
        ],
      ),
    );
  }

  /// Build method selection card
  Widget _buildMethodCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String description,
    required List<String> features,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? badgeColor : ColorConstant.cardBorder,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? badgeColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: badgeColor, size: 28),
                ),
                const SizedBox(width: 12),

                // Title and badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: ColorConstant.bluedark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ColorConstant.gentleGray,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: ColorConstant.bluedark.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 12),

            // Features list
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstant.bluedark.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Basic Information",
            style: AppStyle.txtPoppinsSemiBold24Dark,
          ),
          const SizedBox(height: 8),
          Text(
            "Please provide your basic information to help us personalize your assessment.",
            style: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.7),
              fontSize: 14,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 20),
          
          // Age
          Row(
            children: [
              Text("Age", style: AppStyle.txtPoppinsSemiBold18Dark),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers['age'],
            keyboardType: TextInputType.number,
            onChanged: (value) => _updateInput('age', value),
            decoration: InputDecoration(
              hintText: "Enter your age",
              hintStyle: TextStyle(
                color: ColorConstant.bluedark.withOpacity(0.4),
                fontSize: 14,
              ),
              helperText: "Range: 10-90 years",
              helperStyle: TextStyle(
                color: ColorConstant.bluedark.withOpacity(0.6),
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ColorConstant.bluedark.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ColorConstant.bluedark,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Sex
          Row(
            children: [
              Text("Sex", style: AppStyle.txtPoppinsSemiBold18Dark),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _assessmentService.getSexOptions().map((option) {
              return Expanded(
                child: RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _userInput['sex'],
                  onChanged: (value) => _updateInput('sex', value),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Symptoms",
            style: AppStyle.txtPoppinsSemiBold24Dark,
          ),
          const SizedBox(height: 8),
          Text(
            "Please describe any symptoms you have experienced recently. This helps us assess your heart health more accurately.",
            style: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.7),
              fontSize: 14,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 20),
          
          // Chest pain type
          _buildFieldWithInfo(
            label: "Chest Pain Type",
            tooltipText: "Chest pain can feel different for everyone. It might feel like pressure, squeezing, burning, or sharp pain in your chest area.",
            child: DropdownButtonFormField<String>(
              value: _userInput['chestPainType'].isEmpty ? null : _userInput['chestPainType'],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _assessmentService.getChestPainTypes().map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) => _updateInput('chestPainType', value),
            ),
          ),
          const SizedBox(height: 20),
          
          // Chest pain duration
          Text("Chest Pain Duration (minutes)", style: AppStyle.txtPoppinsSemiBold18Dark),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers['chestPainDuration'],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter duration in minutes",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Shortness of breath
          _buildFieldWithInfo(
            label: "Shortness of Breath",
            tooltipText: "Shortness of breath means having trouble breathing or feeling like you can't get enough air. It can happen during activity or even at rest.",
            child: DropdownButtonFormField<String>(
              value: _userInput['shortnessOfBreath'].isEmpty ? null : _userInput['shortnessOfBreath'],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _assessmentService.getShortnessOfBreathLevels().map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) => _updateInput('shortnessOfBreath', value),
            ),
          ),
          const SizedBox(height: 20),
          
          // Other symptoms checkboxes
          Text("Other Symptoms", style: AppStyle.txtPoppinsSemiBold18Dark),
          const SizedBox(height: 4),
          Text(
            "Check all symptoms that you have felt recently.",
            style: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.7),
              fontSize: 12,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 8),
          _buildCheckboxListTile('syncope', 'Fainting/Syncope'),
          _buildCheckboxListTile('dizziness', 'Dizziness'),
          _buildCheckboxListTile('nausea', 'Nausea'),
          _buildCheckboxListTile('sweating', 'Sweating'),
        ],
      ),
    );
  }

  Widget _buildVitalSignsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vital Signs",
            style: AppStyle.txtPoppinsSemiBold24Dark,
          ),
          const SizedBox(height: 8),
          Text(
            "Please enter your current vital signs if you know them. If you don't have these measurements, you can skip them.",
            style: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.7),
              fontSize: 14,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildValidatedTextField(
                  label: "Systolic BP",
                  controllerKey: "systolicBP",
                  hintText: "120",
                  helperText: "Normal BP range: 90–140 mmHg",
                  unit: "mmHg",
                  minValue: 50,
                  maxValue: 300,
                  tooltipText: "Systolic blood pressure is the top number in a blood pressure reading. It measures the pressure in your arteries when your heart beats and pumps blood.",
                  isRequired: false,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildValidatedTextField(
                  label: "Diastolic BP",
                  controllerKey: "diastolicBP",
                  hintText: "80",
                  helperText: "Normal BP range: 60–90 mmHg",
                  unit: "mmHg",
                  minValue: 30,
                  maxValue: 200,
                  tooltipText: "Diastolic blood pressure is the bottom number in a blood pressure reading. It measures the pressure in your arteries when your heart rests between beats.",
                  isRequired: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildValidatedTextField(
                  label: "Heart Rate",
                  controllerKey: "heartRate",
                  hintText: "75",
                  helperText: "Normal range: 60–100 bpm",
                  unit: "bpm",
                  minValue: 30,
                  maxValue: 250,
                  tooltipText: "Heart rate is the number of times your heart beats per minute. You can measure this by feeling your pulse on your wrist or neck.",
                  isRequired: false,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildValidatedTextField(
                  label: "Oxygen Saturation",
                  controllerKey: "oxygenSaturation",
                  hintText: "98",
                  helperText: "Normal range: 95–100%",
                  unit: "%",
                  minValue: 70,
                  maxValue: 100,
                  tooltipText: "Oxygen saturation measures how much oxygen your blood is carrying. It's usually measured with a pulse oximeter on your finger.",
                  isRequired: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildValidatedTextField(
            label: "Temperature",
            controllerKey: "temperature",
            hintText: "36.5",
            helperText: "Normal range: 36–38°C",
            unit: "°C",
            minValue: 30,
            maxValue: 45,
            tooltipText: "Body temperature measures how hot or cold your body is. Normal body temperature is around 37°C (98.6°F).",
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Risk Factors",
            style: AppStyle.txtPoppinsSemiBold24Dark,
          ),
          const SizedBox(height: 8),
          Text(
            "Please check any medical conditions you have and describe your lifestyle habits. This information helps us provide more accurate recommendations.",
            style: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.7),
              fontSize: 14,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 20),
          
          Text("Medical History", style: AppStyle.txtPoppinsSemiBold18Dark),
          const SizedBox(height: 8),
          _buildCheckboxListTile('hypertension', 'Hypertension'),
          _buildCheckboxListTile('diabetes', 'Diabetes'),
          _buildCheckboxListTile('highCholesterol', 'High Cholesterol'),
          _buildCheckboxListTile('previousHeartDisease', 'Previous Heart Disease'),
          _buildCheckboxListTile('ckd', 'Chronic Kidney Disease'),
          
          const SizedBox(height: 20),
          Text("Lifestyle Factors", style: AppStyle.txtPoppinsSemiBold18Dark),
          const SizedBox(height: 8),
          _buildCheckboxListTile('smoking', 'Smoking'),
          _buildCheckboxListTile('obesity', 'Obesity'),
          _buildCheckboxListTile('familyHistory', 'Family History of Heart Disease'),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with icon
          Icon(
            Icons.check_circle_outline,
            size: 60,
            color: ColorConstant.reassuringGreen,
          ),
          const SizedBox(height: 16),
          
          Text(
            "Review Your Information",
            style: AppStyle.txtPoppinsSemiBold24Dark,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            "Please review your entries before submitting",
            style: TextStyle(
              color: ColorConstant.gentleGray,
              fontSize: 14,
              fontFamily: "Poppins",
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Basic Info Card
          _buildReviewCard(
            title: "Basic Information",
            icon: Icons.person_outline,
            iconColor: ColorConstant.trustBlue,
            items: [
              _buildReviewItem("Age", "${_userInput['age']} years"),
              _buildReviewItem("Sex", "${_userInput['sex']}"),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Symptoms Card
          _buildReviewCard(
            title: "Symptoms",
            icon: Icons.favorite_outline,
            iconColor: const Color(0xFFE63946),
            items: [
              if (_userInput['chestPainType'].toString().isNotEmpty && _userInput['chestPainType'] != '')
                _buildReviewItem("Chest Pain", "${_userInput['chestPainType']}"),
              if (_userInput['chestPainDuration'].toString().isNotEmpty && _userInput['chestPainDuration'] != '')
                _buildReviewItem("Duration", "${_userInput['chestPainDuration']} minutes"),
              if (_userInput['shortnessOfBreath'].toString().isNotEmpty && _userInput['shortnessOfBreath'] != '')
                _buildReviewItem("Shortness of Breath", "${_userInput['shortnessOfBreath']}"),
              if (_userInput['dizziness'] == true)
                _buildReviewItem("Other Symptoms", "Dizziness"),
              if (_userInput['nausea'] == true)
                _buildReviewItem("", "Nausea"),
              if (_userInput['sweating'] == true)
                _buildReviewItem("", "Sweating"),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Vital Signs Card
          _buildReviewCard(
            title: "Vital Signs",
            icon: Icons.monitor_heart_outlined,
            iconColor: ColorConstant.calmingBlue,
            items: [
              if (_userInput['systolicBP'].toString().isNotEmpty && _userInput['diastolicBP'].toString().isNotEmpty)
                _buildReviewItem("Blood Pressure", "${_userInput['systolicBP']}/${_userInput['diastolicBP']} mmHg"),
              if (_userInput['heartRate'].toString().isNotEmpty)
                _buildReviewItem("Heart Rate", "${_userInput['heartRate']} bpm"),
              if (_userInput['oxygenSaturation'].toString().isNotEmpty)
                _buildReviewItem("Oxygen Saturation", "${_userInput['oxygenSaturation']}%"),
              if (_userInput['temperature'].toString().isNotEmpty)
                _buildReviewItem("Temperature", "${_userInput['temperature']}°C"),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Risk Factors Card
          _buildReviewCard(
            title: "Risk Factors",
            icon: Icons.warning_amber_outlined,
            iconColor: const Color(0xFFFFB703),
            items: [
              if (_userInput['hypertension'] == true)
                _buildReviewItem("Medical", "Hypertension"),
              if (_userInput['diabetes'] == true)
                _buildReviewItem("", "Diabetes"),
              if (_userInput['highCholesterol'] == true)
                _buildReviewItem("", "High Cholesterol"),
              if (_userInput['ckd'] == true)
                _buildReviewItem("", "Chronic Kidney Disease"),
              if (_userInput['smoking'] == true)
                _buildReviewItem("Lifestyle", "Smoking"),
              if (_userInput['obesity'] == true)
                _buildReviewItem("", "Obesity"),
              if (_userInput['familyHistory'] == true)
                _buildReviewItem("Family History", "Heart Disease"),
            ],
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstant.cardBorder,
          width: 1,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstant.bluedark,
                  fontFamily: "Poppins",
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...items,
          ] else ...[
            const SizedBox(height: 12),
            Text(
              "No information provided",
              style: TextStyle(
                fontSize: 14,
                color: ColorConstant.gentleGray,
                fontStyle: FontStyle.italic,
                fontFamily: "Poppins",
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConstant.gentleGray,
                  fontFamily: "Poppins",
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.bluedark,
                  fontFamily: "Poppins",
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "• $value",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.bluedark,
                  fontFamily: "Poppins",
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckboxListTile(String key, String title) {
    return CheckboxListTile(
      title: Text(title),
      value: _userInput[key] == true,
      onChanged: (value) => _updateInput(key, value),
    );
  }

  Widget _buildValidatedTextField({
    required String label,
    required String controllerKey,
    required String hintText,
    required String helperText,
    required String unit,
    required int minValue,
    required int maxValue,
    required String tooltipText,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label, 
                    style: AppStyle.txtPoppinsSemiBold18Dark,
                    overflow: TextOverflow.visible,
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Tooltip(
                  message: tooltipText,
                  decoration: BoxDecoration(
                    color: ColorConstant.bluedark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "Poppins",
                  ),
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () {
                      // Show tooltip on tap as well
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tooltipText),
                          backgroundColor: ColorConstant.bluedark,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ColorConstant.bluedark.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConstant.bluedark.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: ColorConstant.bluedark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Tap for more information",
                  style: TextStyle(
                    color: ColorConstant.bluedark.withOpacity(0.6),
                    fontSize: 11,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[controllerKey],
          focusNode: _focusNodes[controllerKey],
          keyboardType: keyboardType,
          onChanged: (value) {
            _updateInput(controllerKey, value);
          },
          onTap: () {
            _fieldTouched[controllerKey] = true;
          },
          onSubmitted: (value) {
            _fieldTouched[controllerKey] = true;
            _validateInputOnSubmit(controllerKey, value, minValue, maxValue);
          },
          onEditingComplete: () {
            _fieldTouched[controllerKey] = true;
            _validateInputOnSubmit(controllerKey, _controllers[controllerKey]?.text ?? '', minValue, maxValue);
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.4),
              fontSize: 14,
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.6),
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _getValidationColor(controllerKey),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: ColorConstant.bluedark.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: ColorConstant.bluedark,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            suffixText: unit,
            suffixStyle: TextStyle(
              color: ColorConstant.bluedark.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
        if (_getValidationError(controllerKey) != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _getValidationError(controllerKey)!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  void _validateInputOnSubmit(String key, String value, int minValue, int maxValue) {
    if (value.isEmpty) {
      return; // Don't validate empty fields
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return; // Don't validate invalid numbers
    }

    // Only validate range for vital signs when user finishes input
    setState(() {
      // This will trigger a rebuild and show validation colors
    });
  }

  Color _getValidationColor(String key) {
    final value = _controllers[key]?.text ?? '';
    if (value.isEmpty) return ColorConstant.bluedark.withOpacity(0.3);
    
    // Only show validation colors if the field has been completed (not just touched)
    if (!(_fieldTouched[key] ?? false)) {
      return ColorConstant.bluedark.withOpacity(0.3);
    }
    
    // Check if the field is currently focused - don't show validation while typing
    if (_focusNodes[key]?.hasFocus == true) {
      return ColorConstant.bluedark.withOpacity(0.3);
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) return ColorConstant.bluedark.withOpacity(0.3);
    
    // Only show validation colors for vital signs when they have complete values
    switch (key) {
      case 'systolicBP':
        return (intValue >= 90 && intValue <= 140) ? Colors.green : Colors.orange;
      case 'diastolicBP':
        return (intValue >= 60 && intValue <= 90) ? Colors.green : Colors.orange;
      case 'heartRate':
        return (intValue >= 60 && intValue <= 100) ? Colors.green : Colors.orange;
      case 'oxygenSaturation':
        return (intValue >= 95 && intValue <= 100) ? Colors.green : Colors.orange;
      case 'temperature':
        return (intValue >= 36 && intValue <= 38) ? Colors.green : Colors.orange;
      default:
        return ColorConstant.bluedark.withOpacity(0.3);
    }
  }

  String? _getValidationError(String key) {
    final value = _controllers[key]?.text ?? '';
    if (value.isEmpty) return null; // No error for empty optional fields
    
    // Only show validation errors if the field has been completed (not just touched)
    if (!(_fieldTouched[key] ?? false)) {
      return null;
    }
    
    // Check if the field is currently focused - don't show validation while typing
    if (_focusNodes[key]?.hasFocus == true) {
      return null;
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) return null; // Don't show error for invalid numbers while typing
    
    // Only show warnings for vital signs when they have complete values
    // Vital signs are optional, so empty values should not trigger errors
    switch (key) {
      case 'systolicBP':
        if (intValue < 90 || intValue > 140) {
          return 'Outside normal range (90-140 mmHg)';
        }
        break;
      case 'diastolicBP':
        if (intValue < 60 || intValue > 90) {
          return 'Outside normal range (60-90 mmHg)';
        }
        break;
      case 'heartRate':
        if (intValue < 60 || intValue > 100) {
          return 'Outside normal range (60-100 bpm)';
        }
        break;
      case 'oxygenSaturation':
        if (intValue < 95 || intValue > 100) {
          return 'Outside normal range (95-100%)';
        }
        break;
      case 'temperature':
        if (intValue < 36 || intValue > 38) {
          return 'Outside normal range (36-38°C)';
        }
        break;
    }
    return null;
  }

  Widget _buildFieldWithInfo({
    required String label,
    required String tooltipText,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label, 
                    style: AppStyle.txtPoppinsSemiBold18Dark,
                    overflow: TextOverflow.visible,
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Tooltip(
                  message: tooltipText,
                  decoration: BoxDecoration(
                    color: ColorConstant.bluedark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "Poppins",
                  ),
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tooltipText),
                          backgroundColor: ColorConstant.bluedark,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ColorConstant.bluedark.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConstant.bluedark.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: ColorConstant.bluedark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Tap for more information",
                  style: TextStyle(
                    color: ColorConstant.bluedark.withOpacity(0.6),
                    fontSize: 11,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildResultsScreen() {
    final result = _assessmentResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Risk category header - Centered
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getRiskColor(result['riskCategory']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getRiskColor(result['riskCategory']),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getRiskIcon(result['riskCategory']),
                  size: 56,
                  color: _getRiskColor(result['riskCategory']),
                ),
                const SizedBox(height: 16),
                Text(
                  result['riskCategory'],
                  style: AppStyle.txtPoppinsSemiBold24Dark.copyWith(
                    color: _getRiskColor(result['riskCategory']),
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  result['recommendedAction'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.bluedark,
                    fontFamily: "Poppins",
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Risk Heatmap - Collapsible & Centered
          _buildCollapsibleSection(
            title: "Risk Heatmap",
            icon: Icons.grid_on,
            isExpanded: _isHeatmapExpanded,
            onTap: () => setState(() => _isHeatmapExpanded = !_isHeatmapExpanded),
            child: _buildRiskHeatmap(result),
          ),
          
          const SizedBox(height: 16),

          // Comparison View - Show when AI and rule-based scores differ
          if (result['hasDiscrepancy'] == true)
            _buildCollapsibleSection(
              title: "Assessment Comparison",
              icon: Icons.compare_arrows,
              isExpanded: _isComparisonExpanded,
              onTap: () => setState(() => _isComparisonExpanded = !_isComparisonExpanded),
              child: ValidationComparisonView(
                aiResult: result,
                isFilipino: Get.locale?.languageCode == 'fil',
              ),
            ),

          if (result['hasDiscrepancy'] == true) const SizedBox(height: 16),

          // Assessment Details - Collapsible (collapsed by default)
          _buildCollapsibleSection(
            title: "Assessment Details",
            icon: Icons.analytics_outlined,
            isExpanded: _isDetailsExpanded,
            onTap: () => setState(() => _isDetailsExpanded = !_isDetailsExpanded),
            child: _buildDetailedResults(result),
          ),
          
          const SizedBox(height: 16),
          
          // Recommendations - Collapsible (collapsed by default)
          _buildCollapsibleSection(
            title: "Personalized Recommendations",
            icon: Icons.lightbulb_outline,
            isExpanded: _isRecommendationsExpanded,
            onTap: () => setState(() => _isRecommendationsExpanded = !_isRecommendationsExpanded),
            child: _buildRecommendationsSection(result),
          ),
          
          const SizedBox(height: 24),
          
          // Medical Disclaimer - Concise version
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstant.warmBeige,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstant.cardBorder,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: ColorConstant.trustBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Medical Disclaimer",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.bluedark,
                          fontFamily: "Poppins",
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This assessment provides guidance only. Always consult healthcare professionals for proper diagnosis and treatment.",
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstant.bluedark.withOpacity(0.8),
                          fontFamily: "Poppins",
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons - Redesigned layout
          Column(
            children: [
              // PDF Actions Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PDFReportService.generateAndShareReport(
                          _assessmentResult!,
                          _userInput,
                          context,
                        );
                      },
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ColorConstant.trustBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        side: BorderSide(
                          color: ColorConstant.trustBlue,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PDFReportService.generateAndDownloadReport(
                          _assessmentResult!,
                          _userInput,
                          context,
                        );
                      },
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text("Download"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ColorConstant.trustBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        side: BorderSide(
                          color: ColorConstant.trustBlue,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Done Button (replaced New Assessment)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check_circle, size: 22),
                  label: const Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.trustBlue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: ColorConstant.trustBlue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Next Steps Button - Moved to bottom with emphasis
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _navigateToNextSteps,
                  icon: const Icon(Icons.arrow_forward, size: 24),
                  label: const Text(
                    "Continue to Next Steps",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRiskColor(result['riskCategory']),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: _getRiskColor(result['riskCategory']).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstant.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstant.trustBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: ColorConstant.trustBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.bluedark,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: ColorConstant.gentleGray,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: ColorConstant.cardBorder,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
  
  IconData _getRiskIcon(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return Icons.emergency;
      case 'high':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'mild':
        return Icons.check_circle;
      case 'low':
        return Icons.verified;
      default:
        return Icons.favorite;
    }
  }
  
  void _showHeatmapTooltip(int score, int x, int y) {
    String riskLevel;
    if (score <= 5) {
      riskLevel = "Low Risk";
    } else if (score <= 10) {
      riskLevel = "Mild Risk";
    } else if (score <= 15) {
      riskLevel = "Moderate Risk";
    } else if (score <= 20) {
      riskLevel = "High Risk";
    } else {
      riskLevel = "Critical Risk";
    }
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: _getHeatmapColor(score),
              ),
              const SizedBox(height: 16),
              Text(
                "Score: $score",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getHeatmapColor(score),
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 8),
              Text(
                riskLevel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.bluedark,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Position: Row ${y + 1}, Column ${x + 1}",
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConstant.gentleGray,
                  fontFamily: "Poppins",
                ),
                textAlign: TextAlign.center,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Got it"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskHeatmap(Map<String, dynamic> result) {
    return Column(
      children: [
        // 5x5 heatmap grid - Centered
        Center(
          child: Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorConstant.softWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstant.cardBorder,
                width: 1,
              ),
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
                int x = index % 5;
                int y = index ~/ 5;
                int score = (x + 1) * (y + 1);
                
                Color cellColor = _getHeatmapColor(score);
                bool isCurrentPosition = x == result['heatmapPosition']['x'] && 
                                       y == result['heatmapPosition']['y'];
                
                return GestureDetector(
                  onTap: () {
                    // Interactive: show tooltip
                    _showHeatmapTooltip(score, x, y);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: isCurrentPosition 
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isCurrentPosition ? [
                        BoxShadow(
                          color: cellColor.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCurrentPosition) 
                            Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 16,
                            ),
                          Text(
                            score.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isCurrentPosition ? FontWeight.w900 : FontWeight.bold,
                              fontSize: isCurrentPosition ? 14 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          "Your Position: ${result['finalRiskScore']} (${result['likelihoodLevel']} × ${result['impactLevel']})",
          style: AppStyle.txtPoppinsSemiBold14Dark,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailedResults(Map<String, dynamic> result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Assessment Details",
            style: AppStyle.txtPoppinsSemiBold18Dark,
          ),
          const SizedBox(height: 15),
          
          _buildResultRow("Likelihood Score", "${result['likelihoodScore']} (${result['likelihoodLevel']})"),
          _buildResultRow("Impact Score", "${result['impactScore']} (${result['impactLevel']})"),
          _buildResultRow("Final Risk Score", result['finalRiskScore'].toString()),
          _buildResultRow("Risk Category", result['riskCategory']),
          
          const SizedBox(height: 15),
          Text(
            "Explanation",
            style: AppStyle.txtPoppinsSemiBold16Dark,
          ),
          const SizedBox(height: 8),
          Text(
            result['explanation'],
            style: AppStyle.txtPoppinsSemiBold14Dark.copyWith(
              color: ColorConstant.bluedark.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(Map<String, dynamic> result) {
    // Generate recommendations based on the assessment data
    final data = MedicalTriageAssessmentData.fromMap(_userInput);
    final recommendations = _assessmentService.generateRecommendations(
      data, 
      result['finalRiskScore'], 
      result['riskCategory']
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display recommendations as clean bullet list
        ...recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final recommendation = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorConstant.trustBlue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.trustBlue,
                      fontFamily: "Poppins",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorConstant.bluedark.withOpacity(0.85),
                      fontFamily: "Poppins",
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }


  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyle.txtPoppinsSemiBold14Dark),
          Text(value, style: AppStyle.txtPoppinsSemiBold14Dark),
        ],
      ),
    );
  }

  Color _getRiskColor(String category) {
    switch (category.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow[700]!;
      case 'mild':
        return Colors.lightGreen;
      case 'low':
        return Colors.green;
      default:
        return ColorConstant.bluedark;
    }
  }

  Color _getHeatmapColor(int score) {
    if (score >= 20) return Colors.red[900]!;
    if (score >= 15) return Colors.red[700]!;
    if (score >= 10) return Colors.orange[700]!;
    if (score >= 5) return Colors.yellow[600]!;
    return Colors.green[600]!;
  }
}
