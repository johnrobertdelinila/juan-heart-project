import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/services/medical_triage_assessment_service.dart';
import 'package:juan_heart/services/pdf_report_service.dart';
import 'package:juan_heart/models/medical_triage_assessment_data.dart';
import 'package:juan_heart/themes/app_styles.dart';

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

      final result = _assessmentService.assessHeartDiseaseRisk(_userInput);
      
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

  void _nextPage() {
    // Validate required fields before proceeding
    if (!_validateCurrentPage()) {
      return; // Stop if validation fails
    }

    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _runAssessment();
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Basic Information
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
        if (age < 0 || age > 120) {
          _showValidationError('Please enter a valid age between 0 and 120.');
          return false;
        }
        break;
      case 1: // Symptoms - No required fields
        break;
      case 2: // Vital Signs - No required fields
        break;
      case 3: // Risk Factors - No required fields
        break;
      case 4: // Review - No validation needed
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
                  value: (_currentPage + 1) / 5,
                  backgroundColor: ColorConstant.bluedark.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.bluedark),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${_currentPage + 1}/5",
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
              // Required fields note (only show on first step)
              if (_currentPage == 0)
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
              if (_currentPage == 0) const SizedBox(height: 16),
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
                    child: Text(_currentPage == 4 ? "Complete Assessment" : "Next"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
              helperText: "Range: 0-120 years",
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Review Your Information",
            style: AppStyle.txtPoppinsSemiBold24Dark,
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: ColorConstant.bluedark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Basic Info:", style: AppStyle.txtPoppinsSemiBold16Dark),
                Text("Age: ${_userInput['age']}", style: AppStyle.txtPoppinsSemiBold14Dark),
                Text("Sex: ${_userInput['sex']}", style: AppStyle.txtPoppinsSemiBold14Dark),
                
                const SizedBox(height: 10),
                Text("Symptoms:", style: AppStyle.txtPoppinsSemiBold16Dark),
                Text("Chest Pain: ${_userInput['chestPainType']}", style: AppStyle.txtPoppinsSemiBold14Dark),
                Text("Duration: ${_userInput['chestPainDuration']} minutes", style: AppStyle.txtPoppinsSemiBold14Dark),
                Text("Shortness of Breath: ${_userInput['shortnessOfBreath']}", style: AppStyle.txtPoppinsSemiBold14Dark),
                
                const SizedBox(height: 10),
                Text("Vital Signs:", style: AppStyle.txtPoppinsSemiBold16Dark),
                Text("BP: ${_userInput['systolicBP']}/${_userInput['diastolicBP']}", style: AppStyle.txtPoppinsSemiBold14Dark),
                Text("HR: ${_userInput['heartRate']} bpm", style: AppStyle.txtPoppinsSemiBold14Dark),
                Text("SpO₂: ${_userInput['oxygenSaturation']}%", style: AppStyle.txtPoppinsSemiBold14Dark),
              ],
            ),
          ),
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

  void _validateAndUpdateInput(String key, String value, int minValue, int maxValue) {
    if (value.isEmpty) {
      _updateInput(key, '');
      return;
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      _updateInput(key, value);
      return;
    }

    // Always update the value, validation is only for display purposes
    _updateInput(key, value);
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk category header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getRiskColor(result['riskCategory']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _getRiskColor(result['riskCategory']),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  result['riskCategory'],
                  style: AppStyle.txtPoppinsSemiBold24Dark.copyWith(
                    color: _getRiskColor(result['riskCategory']),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result['recommendedAction'],
                  style: AppStyle.txtPoppinsSemiBold16Dark,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Risk heatmap visualization
          _buildRiskHeatmap(result),
          
          const SizedBox(height: 20),
          
          // Detailed results
          _buildDetailedResults(result),
          
          // Recommendations section
          _buildRecommendationsSection(result),
          
          // Medical disclaimer
          _buildMedicalDisclaimer(),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Column(
            children: [
              // PDF Generation Row
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
                      icon: Icon(Icons.share, size: 18),
                      label: Text("Share Report"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.greenColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PDFReportService.generateAndDownloadReport(
                          _assessmentResult!,
                          _userInput,
                          context,
                        );
                      },
                      icon: Icon(Icons.download, size: 18),
                      label: Text("Download PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.blueColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Navigation Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _assessmentResult = null;
                          _currentPage = 0;
                          _pageController.animateToPage(0, 
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: ColorConstant.bluedark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("New Assessment"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.bluedark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("Done"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskHeatmap(Map<String, dynamic> result) {
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
        children: [
          Text(
            "Risk Assessment Heatmap",
            style: AppStyle.txtPoppinsSemiBold18Dark,
          ),
          const SizedBox(height: 20),
          
          // 5x5 heatmap grid
          SizedBox(
            width: 200,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                int x = index % 5;
                int y = index ~/ 5;
                int score = (x + 1) * (y + 1);
                
                Color cellColor = _getHeatmapColor(score);
                bool isCurrentPosition = x == result['heatmapPosition']['x'] && 
                                       y == result['heatmapPosition']['y'];
                
                return Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: isCurrentPosition 
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      score.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 10),
          Text(
            "Your Position: ${result['finalRiskScore']} (${result['likelihoodLevel']} × ${result['impactLevel']})",
            style: AppStyle.txtPoppinsSemiBold14Dark,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
    
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstant.lightBlueBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ColorConstant.bluedark.withOpacity(0.2)),
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
            "Personalized Recommendations",
            style: AppStyle.txtPoppinsSemiBold18Dark,
          ),
          const SizedBox(height: 12),
          Text(
            "Based on your assessment results, here are some recommendations to help improve your heart health:",
            style: AppStyle.txtPoppinsSemiBold14Dark,
          ),
          const SizedBox(height: 16),
          
          // Display recommendations
          ...recommendations.map((recommendation) => 
            _buildRecommendationItem(recommendation)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        recommendation,
        style: AppStyle.txtPoppinsSemiBold14Dark.copyWith(
          color: ColorConstant.bluedark.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildMedicalDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.redLightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstant.redAccent.withOpacity(0.3)),
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
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: ColorConstant.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Important Medical Disclaimer",
                style: AppStyle.txtPoppinsSemiBold16Dark.copyWith(
                  color: ColorConstant.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "This app is designed to provide general health guidance and triage recommendations only. It does not:",
            style: AppStyle.txtPoppinsSemiBold14Dark,
          ),
          const SizedBox(height: 8),
          Text(
            "• Make medical diagnoses\n"
            "• Replace professional medical advice\n"
            "• Provide emergency medical care\n"
            "• Guarantee the accuracy of assessments",
            style: AppStyle.txtPoppinsSemiBold14Dark,
          ),
          const SizedBox(height: 12),
          Text(
            "Always consult with qualified healthcare professionals for proper medical evaluation, diagnosis, and treatment. In case of emergency, call your local emergency number immediately.",
            style: AppStyle.txtPoppinsSemiBold14Dark.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
