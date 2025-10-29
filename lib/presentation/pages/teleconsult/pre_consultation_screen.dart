import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/questionnaire_model.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/services/questionnaire_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PreConsultationScreen extends StatefulWidget {
  final Appointment appointment;

  const PreConsultationScreen({Key? key, required this.appointment})
      : super(key: key);

  @override
  State<PreConsultationScreen> createState() => _PreConsultationScreenState();
}

class _PreConsultationScreenState extends State<PreConsultationScreen> {
  PreConsultationQuestionnaire? _questionnaire;
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _answers = {};
  Map<String, List<String>> _uploadedFiles = {}; // questionId -> file paths
  Set<String> _prefilledFields = {}; // Track which fields were pre-filled from assessment

  @override
  void initState() {
    super.initState();
    _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
    setState(() => _isLoading = true);

    try {
      // Get questions
      _questions = QuestionnaireTemplates.getGeneralQuestions();

      // Load existing questionnaire or create new one
      PreConsultationQuestionnaire? existing =
          await QuestionnaireService.getQuestionnaireForAppointment(
        widget.appointment.id,
      );

      if (existing == null) {
        existing = await QuestionnaireService.createQuestionnaire(
          widget.appointment.id,
        );
      }

      // Load existing answers into map
      for (final answer in existing.answers) {
        _answers[answer.questionId] = answer.answer;
      }

      setState(() {
        _questionnaire = existing;
        _isLoading = false;
      });

      // Pre-fill from assessment data if answers are empty
      if (_answers.isEmpty) {
        await _prefillFromAssessment();
      }
    } catch (e) {
      print('Error loading questionnaire: $e');
      setState(() => _isLoading = false);
    }
  }

  // Helper: Convert boolean to Yes/No string
  String? _boolToYesNo(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 'Yes' : 'No';
    return null;
  }

  // Helper: Map assessment medical conditions to questionnaire options
  List<String> _mapMedicalConditions(Map<String, dynamic>? medicalHistory) {
    if (medicalHistory == null) return [];

    final List<String> conditions = [];
    if (medicalHistory['diabetes'] == true) conditions.add('Diabetes');
    if (medicalHistory['hypertension'] == true) conditions.add('High blood pressure');
    if (medicalHistory['highCholesterol'] == true) conditions.add('High cholesterol');
    if (medicalHistory['previousHeartDisease'] == true) conditions.add('Previous heart disease');
    if (medicalHistory['ckd'] == true) conditions.add('Kidney disease');
    if (medicalHistory['asthma'] == true) conditions.add('Asthma/COPD');

    return conditions;
  }

  // Helper: Map smoking status to questionnaire option
  String? _mapSmokingStatus(Map<String, dynamic>? lifestyleFactors) {
    if (lifestyleFactors == null) return null;

    final smokingStatus = lifestyleFactors['smokingStatus'];
    if (smokingStatus == null) return null;

    switch (smokingStatus) {
      case 'current_smoker':
        return 'Current smoker (1+ pack/day)';
      case 'former_smoker':
        return 'Former smoker';
      case 'non_smoker':
      case 'never':
        return 'Never smoked';
      default:
        return null;
    }
  }

  // Helper: Map alcohol frequency to questionnaire option
  String? _mapAlcoholFrequency(Map<String, dynamic>? lifestyleFactors) {
    if (lifestyleFactors == null) return null;

    final alcohol = lifestyleFactors['alcohol'];
    if (alcohol == null) return null;

    switch (alcohol) {
      case 'never':
        return 'Never';
      case 'occasionally':
      case 'rarely':
        return 'Occasionally (1-2 times/month)';
      case 'regularly':
      case 'frequently':
        return 'Regularly (3+ times/week)';
      default:
        return null;
    }
  }

  // Helper: Map exercise frequency to questionnaire option
  String? _mapExerciseFrequency(Map<String, dynamic>? lifestyleFactors) {
    if (lifestyleFactors == null) return null;

    final exercise = lifestyleFactors['exercise'];
    if (exercise == null) return null;

    switch (exercise) {
      case 'never':
      case 'rarely':
        return 'Rarely (less than once/week)';
      case 'sometimes':
      case 'occasionally':
        return 'Sometimes (1-2 times/week)';
      case 'regularly':
      case 'frequently':
        return 'Regularly (3+ times/week)';
      default:
        return null;
    }
  }

  // Helper: Calculate symptom duration from assessment date
  String? _calculateSymptomDuration(String? assessmentDate) {
    if (assessmentDate == null) return null;

    try {
      final assessmentDateTime = DateTime.parse(assessmentDate);
      final now = DateTime.now();
      final difference = now.difference(assessmentDateTime);

      if (difference.inDays < 1) {
        return 'Less than 24 hours';
      } else if (difference.inDays <= 7) {
        return '1-7 days';
      } else if (difference.inDays <= 30) {
        return '1-4 weeks';
      } else {
        return 'More than 1 month';
      }
    } catch (e) {
      return null;
    }
  }

  // Pre-fill questionnaire from assessment data
  Future<void> _prefillFromAssessment() async {
    if (widget.appointment.assessmentData == null) return;

    try {
      final assessment = widget.appointment.assessmentData!;
      final symptoms = assessment['symptoms'] as Map<String, dynamic>?;
      final medicalHistory = assessment['medicalHistory'] as Map<String, dynamic>?;
      final lifestyleFactors = assessment['lifestyleFactors'] as Map<String, dynamic>?;
      final medications = assessment['medications'] as List<dynamic>?;

      // Clear prefilled fields tracker
      _prefilledFields.clear();

      // Section 1: Chief Complaint
      if (assessment['riskCategory'] != null && assessment['date'] != null) {
        final riskCategory = assessment['riskCategory'];
        final date = assessment['date'];
        _answers['chief_complaint'] = '$riskCategory cardiovascular risk detected during assessment on $date. Seeking consultation for comprehensive evaluation.';
        _prefilledFields.add('chief_complaint');
      }

      if (assessment['date'] != null) {
        final duration = _calculateSymptomDuration(assessment['date']);
        if (duration != null) {
          _answers['symptom_duration'] = duration;
          _prefilledFields.add('symptom_duration');
        }
      }

      // Section 2: Current Symptoms
      if (symptoms != null) {
        // Chest pain
        final hasChestPain = symptoms['chestPainType'] != null &&
                             symptoms['chestPainType'].toString().isNotEmpty;
        _answers['chest_pain'] = hasChestPain ? 'Yes' : 'No';
        _prefilledFields.add('chest_pain');

        // Chest pain severity (from duration as proxy)
        if (hasChestPain && symptoms['chestPainDuration'] != null) {
          final duration = symptoms['chestPainDuration'] as int?;
          if (duration != null) {
            // Map duration to severity: >20 min = 8-10, 10-20 = 5-7, <10 = 3-5
            final severity = duration > 20 ? 8 : (duration > 10 ? 6 : 4);
            _answers['chest_pain_severity'] = severity.toString();
            _prefilledFields.add('chest_pain_severity');
          }
        }

        // Shortness of breath
        final hasShortness = symptoms['shortnessOfBreath'] != null &&
                            symptoms['shortnessOfBreath'].toString().isNotEmpty;
        _answers['shortness_breath'] = hasShortness ? 'Yes' : 'No';
        _prefilledFields.add('shortness_breath');

        // Palpitations
        _answers['palpitations'] = _boolToYesNo(symptoms['palpitations']) ?? 'No';
        _prefilledFields.add('palpitations');

        // Dizziness (from syncope or neurological symptoms)
        final hasDizziness = symptoms['syncope'] == true ||
                            symptoms['neurologicalSymptoms'] == true;
        _answers['dizziness'] = hasDizziness ? 'Yes' : 'No';
        _prefilledFields.add('dizziness');
      }

      // Section 3: Medical History
      if (medicalHistory != null) {
        final conditions = _mapMedicalConditions(medicalHistory);
        if (conditions.isNotEmpty) {
          _answers['existing_conditions'] = conditions;
          _prefilledFields.add('existing_conditions');
        }

        _answers['previous_heart_issues'] = _boolToYesNo(medicalHistory['previousHeartDisease']) ?? 'No';
        _prefilledFields.add('previous_heart_issues');

        // Heart issues details (if applicable)
        if (medicalHistory['previousHeartDisease'] == true) {
          _answers['heart_issues_details'] = 'Patient reported previous heart disease during assessment. Details to be reviewed during consultation.';
          _prefilledFields.add('heart_issues_details');
        }
      }

      // Section 4: Current Medications
      if (medications != null && medications.isNotEmpty) {
        _answers['taking_medications'] = 'Yes';
        _prefilledFields.add('taking_medications');

        // Convert medications list to string
        final medicationsList = medications.map((med) {
          if (med is Map) {
            return med['name'] ?? med.toString();
          }
          return med.toString();
        }).join('\n');

        _answers['medications_list'] = medicationsList;
        _prefilledFields.add('medications_list');
      } else {
        _answers['taking_medications'] = 'No';
        _prefilledFields.add('taking_medications');
      }

      // Section 5: Lifestyle Factors
      if (lifestyleFactors != null) {
        // Smoking
        final smokingOption = _mapSmokingStatus(lifestyleFactors);
        if (smokingOption != null) {
          _answers['smoking'] = smokingOption;
          _prefilledFields.add('smoking');
        }

        // Alcohol
        final alcoholOption = _mapAlcoholFrequency(lifestyleFactors);
        if (alcoholOption != null) {
          _answers['alcohol'] = alcoholOption;
          _prefilledFields.add('alcohol');
        }

        // Exercise
        final exerciseOption = _mapExerciseFrequency(lifestyleFactors);
        if (exerciseOption != null) {
          _answers['exercise'] = exerciseOption;
          _prefilledFields.add('exercise');
        }
      }

      // Section 6: Additional Information
      if (assessment['recommendation'] != null) {
        _answers['additional_concerns'] = 'Assessment recommendation: ${assessment['recommendation']}';
        _prefilledFields.add('additional_concerns');
      }

      setState(() {}); // Trigger UI update
      _updateProgressInRealTime(); // Calculate progress from pre-filled answers

      print('Pre-filled ${_prefilledFields.length} fields from assessment data');
    } catch (e) {
      print('Error pre-filling from assessment: $e');
    }
  }

  // Manually reload from assessment (with confirmation)
  Future<void> _reloadFromAssessment() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          isFilipino
              ? 'I-reload ang datos ng assessment?'
              : 'Reload from Assessment?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isFilipino
              ? 'Ang lahat ng inyong kasalukuyang sagot ay mabubura at papalitan ng datos mula sa assessment. Gusto ninyong magpatuloy?'
              : 'This will overwrite all your current answers with data from the assessment. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(isFilipino ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.lightRed,
            ),
            child: Text(isFilipino ? 'I-reload' : 'Reload'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear current answers
      setState(() {
        _answers.clear();
        _prefilledFields.clear();
      });

      // Reload from assessment (progress will be calculated inside _prefillFromAssessment)
      await _prefillFromAssessment();

      Get.snackbar(
        isFilipino ? 'Na-reload' : 'Reloaded',
        isFilipino
            ? 'Ang datos ng assessment ay na-load na'
            : 'Assessment data has been loaded',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Check if assessment data is stale (>30 days old)
  bool _isAssessmentStale() {
    if (widget.appointment.assessmentData == null) return false;

    try {
      final assessmentDate = widget.appointment.assessmentData!['date'];
      if (assessmentDate == null) return false;

      final date = DateTime.parse(assessmentDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      return difference.inDays > 30;
    } catch (e) {
      return false;
    }
  }

  // Get formatted assessment date
  String _getAssessmentDate() {
    try {
      final assessmentDate = widget.appointment.assessmentData!['date'];
      if (assessmentDate == null) return '';

      final date = DateTime.parse(assessmentDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  // Calculate and update progress in real-time (without saving)
  void _updateProgressInRealTime() {
    if (_questionnaire == null) return;

    try {
      final questions = QuestionnaireTemplates.getGeneralQuestions();

      // Only count required questions that are currently visible
      final requiredQuestions = questions.where((q) =>
        q.isRequired && QuestionnaireService.shouldShowQuestion(q, _questionnaire!)
      ).toList();

      // Count answered required questions
      final answeredRequired = _answers.entries
          .where((entry) {
            // Check if this answer is for a required question
            if (!requiredQuestions.any((q) => q.id == entry.key)) return false;

            // Check if answer has a value
            final value = entry.value;
            if (value == null) return false;

            // Handle different value types
            if (value is String && value.isEmpty) return false;
            if (value is List && value.isEmpty) return false;

            return true;
          })
          .length;

      // Calculate progress percentage
      final progress = requiredQuestions.isEmpty
          ? 0
          : ((answeredRequired / requiredQuestions.length) * 100).round();

      // Update questionnaire state locally (without saving to storage)
      setState(() {
        _questionnaire = _questionnaire!.copyWith(progressPercentage: progress);
      });
    } catch (e) {
      print('Error calculating real-time progress: $e');
    }
  }

  Future<void> _saveDraft() async {
    if (_questionnaire == null) return;

    setState(() => _isSaving = true);

    try {
      // Update all answers
      for (final entry in _answers.entries) {
        await QuestionnaireService.updateAnswer(
          _questionnaire!.id,
          entry.key,
          entry.value,
        );
      }

      // Reload questionnaire to get updated progress
      final updated = await QuestionnaireService.getQuestionnaireForAppointment(
        widget.appointment.id,
      );

      setState(() {
        _questionnaire = updated;
        _isSaving = false;
      });

      Get.snackbar(
        Get.locale?.languageCode == 'fil' ? 'Na-save' : 'Saved',
        Get.locale?.languageCode == 'fil'
            ? 'Ang iyong draft ay na-save'
            : 'Your draft has been saved',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar(
        Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
        Get.locale?.languageCode == 'fil'
            ? 'Hindi ma-save ang draft'
            : 'Failed to save draft',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _submitQuestionnaire() async {
    if (_questionnaire == null) return;

    final isFilipino = Get.locale?.languageCode == 'fil';

    // Validate all required questions
    final List<String> missingFields = [];
    for (final question in _questions) {
      if (question.isRequired &&
          QuestionnaireService.shouldShowQuestion(question, _questionnaire!)) {
        if (!_answers.containsKey(question.id) ||
            _answers[question.id] == null ||
            _answers[question.id].toString().isEmpty) {
          missingFields.add(question.getQuestionText(isFilipino));
        }
      }
    }

    if (missingFields.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: Text(
            isFilipino
                ? 'May kulang na sagot'
                : 'Missing Required Fields',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFilipino
                    ? 'Pakilagyan ng sagot ang mga sumusunod:'
                    : 'Please answer the following questions:',
              ),
              const SizedBox(height: 12),
              ...missingFields.take(5).map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $field',
                        style: TextStyle(fontSize: 13)),
                  )),
              if (missingFields.length > 5)
                Text(
                  '... ${isFilipino ? 'at iba pa' : 'and ${missingFields.length - 5} more'}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Save all answers first
    await _saveDraft();

    // Submit questionnaire
    final success =
        await QuestionnaireService.submitQuestionnaire(_questionnaire!.id);

    if (success) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              Text(
                isFilipino ? 'Naisumite!' : 'Submitted!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Text(
            isFilipino
                ? 'Ang iyong pre-consultation questionnaire ay naisumite na. Makikita ng doktor ito bago ang inyong appointment.'
                : 'Your pre-consultation questionnaire has been submitted successfully. The doctor will review it before your appointment.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.back(result: true); // Return to previous screen
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: ColorConstant.lightRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } else {
      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Hindi maisumite ang questionnaire'
            : 'Failed to submit questionnaire',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickImage(String questionId) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        if (!_uploadedFiles.containsKey(questionId)) {
          _uploadedFiles[questionId] = [];
        }
        _uploadedFiles[questionId]!.add(result.path);
        _answers[questionId] = _uploadedFiles[questionId];
      });
    }
  }

  Future<void> _pickFile(String questionId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (!_uploadedFiles.containsKey(questionId)) {
          _uploadedFiles[questionId] = [];
        }
        for (final file in result.files) {
          if (file.path != null) {
            _uploadedFiles[questionId]!.add(file.path!);
          }
        }
        _answers[questionId] = _uploadedFiles[questionId];
      });
    }
  }

  void _removeFile(String questionId, String filePath) {
    setState(() {
      _uploadedFiles[questionId]?.remove(filePath);
      if (_uploadedFiles[questionId]?.isEmpty ?? true) {
        _uploadedFiles.remove(questionId);
        _answers.remove(questionId);
      } else {
        _answers[questionId] = _uploadedFiles[questionId];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isFilipino ? 'Pre-Consultation Form' : 'Pre-Consultation Form',
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          if (_questionnaire?.status == QuestionnaireStatus.draft)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveDraft,
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorConstant.lightRed,
                      ),
                    )
                  : Icon(Icons.save_outlined, size: 20),
              label: Text(isFilipino ? 'I-save' : 'Save'),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.lightRed,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress indicator
                if (_questionnaire != null)
                  _buildProgressIndicator(isFilipino),

                // Stale assessment data warning
                if (_isAssessmentStale() && _prefilledFields.isNotEmpty)
                  _buildStaleDataWarning(isFilipino),

                // Questionnaire content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Introduction card
                      _buildIntroductionCard(isFilipino),
                      const SizedBox(height: 24),

                      // Questions
                      ..._buildQuestions(isFilipino),

                      const SizedBox(height: 24),

                      // Submit button
                      if (_questionnaire?.status == QuestionnaireStatus.draft)
                        _buildSubmitButton(isFilipino),

                      // Submitted status
                      if (_questionnaire?.status ==
                          QuestionnaireStatus.submitted)
                        _buildSubmittedStatus(isFilipino),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: widget.appointment.assessmentData != null &&
              _questionnaire?.status == QuestionnaireStatus.draft
          ? FloatingActionButton.extended(
              onPressed: _reloadFromAssessment,
              backgroundColor: ColorConstant.lightRed,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                isFilipino ? 'I-reload' : 'Reload',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildProgressIndicator(bool isFilipino) {
    final progress = _questionnaire!.progressPercentage / 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFilipino ? 'Progress' : 'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.bluedark,
                ),
              ),
              Text(
                '${_questionnaire!.progressPercentage}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstant.lightRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: ColorConstant.lightRed,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStaleDataWarning(bool isFilipino) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isFilipino
                  ? 'Ang datos ng assessment mula ${_getAssessmentDate()} - Pakisukat mabuti'
                  : 'Assessment data from ${_getAssessmentDate()} - Please review carefully',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: ColorConstant.lightRed, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFilipino
                        ? 'Tungkol sa Form na Ito'
                        : 'About This Form',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isFilipino
                  ? 'Pakisagutan ang form na ito bago ang inyong teleconsultation appointment. Ang impormasyong ito ay tutulong sa doktor na maghanda para sa inyong consultation at magbigay ng mas epektibong pangangalaga.'
                  : 'Please complete this form before your teleconsultation appointment. This information will help the doctor prepare for your consultation and provide more effective care.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.lightRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFilipino
                          ? 'Ang inyong impormasyon ay ligtas at confidential'
                          : 'Your information is secure and confidential',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstant.lightRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestions(bool isFilipino) {
    if (_questionnaire == null) return [];

    final List<Widget> widgets = [];
    String? currentSection;

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];

      // Skip if conditional and condition not met
      if (!QuestionnaireService.shouldShowQuestion(
          question, _questionnaire!)) {
        continue;
      }

      // Add section headers (simple grouping by question type or ID prefix)
      String newSection = _getSectionHeader(question, isFilipino);
      if (newSection != currentSection) {
        widgets.add(_buildSectionHeader(newSection));
        currentSection = newSection;
      }

      // Add question widget
      widgets.add(_buildQuestionWidget(question, isFilipino));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  String _getSectionHeader(Question question, bool isFilipino) {
    if (question.id.startsWith('chief_') ||
        question.id.startsWith('symptom_')) {
      return isFilipino ? 'Pangunahing Reklamo' : 'Chief Complaint';
    } else if (question.id.startsWith('chest_') ||
        question.id.startsWith('shortness_') ||
        question.id.startsWith('palpitations') ||
        question.id.startsWith('dizziness')) {
      return isFilipino ? 'Kasalukuyang Sintomas' : 'Current Symptoms';
    } else if (question.id.startsWith('existing_') ||
        question.id.startsWith('previous_') ||
        question.id.startsWith('heart_issues')) {
      return isFilipino ? 'Medikal na Kasaysayan' : 'Medical History';
    } else if (question.id.startsWith('taking_') ||
        question.id.startsWith('medications_') ||
        question.id.startsWith('allergies')) {
      return isFilipino ? 'Kasalukuyang Gamot' : 'Current Medications';
    } else if (question.id.startsWith('smoking') ||
        question.id.startsWith('alcohol') ||
        question.id.startsWith('exercise')) {
      return isFilipino ? 'Lifestyle Factors' : 'Lifestyle Factors';
    } else {
      return isFilipino ? 'Karagdagang Impormasyon' : 'Additional Information';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: ColorConstant.bluedark,
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question question, bool isFilipino) {
    switch (question.type) {
      case QuestionType.text:
        return _buildTextQuestion(question, isFilipino);
      case QuestionType.number:
        return _buildNumberQuestion(question, isFilipino);
      case QuestionType.yesNo:
        return _buildYesNoQuestion(question, isFilipino);
      case QuestionType.singleChoice:
        return _buildSingleChoiceQuestion(question, isFilipino);
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceQuestion(question, isFilipino);
      case QuestionType.fileUpload:
        return _buildFileUploadQuestion(question, isFilipino);
      default:
        return Container();
    }
  }

  Widget _buildTextQuestion(Question question, bool isFilipino) {
    final isPrefilled = _prefilledFields.contains(question.id);

    return Card(
      elevation: 1,
      color: isPrefilled ? Color(0xFFF0F8FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPrefilled) ...[
                  Icon(Icons.auto_awesome, size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    question.getQuestionText(isFilipino),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(
                text: _answers[question.id]?.toString() ?? '',
              ),
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
                _updateProgressInRealTime();
              },
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isFilipino
                    ? 'Isulat ang inyong sagot dito...'
                    : 'Write your answer here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberQuestion(Question question, bool isFilipino) {
    final isPrefilled = _prefilledFields.contains(question.id);

    return Card(
      elevation: 1,
      color: isPrefilled ? Color(0xFFF0F8FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPrefilled) ...[
                  Icon(Icons.auto_awesome, size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    question.getQuestionText(isFilipino),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (question.minValue != null && question.maxValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${question.minValue}-${question.maxValue}${question.unit ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(
                text: _answers[question.id]?.toString() ?? '',
              ),
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
                _updateProgressInRealTime();
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: isFilipino ? 'Numero' : 'Number',
                suffixText: question.unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoQuestion(Question question, bool isFilipino) {
    final currentValue = _answers[question.id]?.toString();
    final isPrefilled = _prefilledFields.contains(question.id);

    return Card(
      elevation: 1,
      color: isPrefilled ? Color(0xFFF0F8FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPrefilled) ...[
                  Icon(Icons.auto_awesome, size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    question.getQuestionText(isFilipino),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _answers[question.id] = 'Yes';
                      });
                      _updateProgressInRealTime();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: currentValue == 'Yes'
                          ? ColorConstant.lightRed
                          : Colors.transparent,
                      foregroundColor: currentValue == 'Yes'
                          ? Colors.white
                          : ColorConstant.lightRed,
                      side: BorderSide(color: ColorConstant.lightRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFilipino ? 'Oo' : 'Yes',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _answers[question.id] = 'No';
                      });
                      _updateProgressInRealTime();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: currentValue == 'No'
                          ? ColorConstant.lightRed
                          : Colors.transparent,
                      foregroundColor: currentValue == 'No'
                          ? Colors.white
                          : ColorConstant.lightRed,
                      side: BorderSide(color: ColorConstant.lightRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFilipino ? 'Hindi' : 'No',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChoiceQuestion(Question question, bool isFilipino) {
    final currentValue = _answers[question.id]?.toString();
    final options = question.getOptions(isFilipino) ?? [];
    final isPrefilled = _prefilledFields.contains(question.id);

    return Card(
      elevation: 1,
      color: isPrefilled ? Color(0xFFF0F8FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPrefilled) ...[
                  Icon(Icons.auto_awesome, size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    question.getQuestionText(isFilipino),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final isSelected = currentValue == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _answers[question.id] = option;
                    });
                    _updateProgressInRealTime();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorConstant.lightRed.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? ColorConstant.lightRed
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? ColorConstant.lightRed
                              : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? ColorConstant.bluedark
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion(Question question, bool isFilipino) {
    List<String> currentValue = [];
    if (_answers[question.id] is List) {
      currentValue = List<String>.from(_answers[question.id] as List);
    } else if (_answers[question.id] != null) {
      currentValue = [_answers[question.id].toString()];
    }

    final options = question.getOptions(isFilipino) ?? [];
    final isPrefilled = _prefilledFields.contains(question.id);

    return Card(
      elevation: 1,
      color: isPrefilled ? Color(0xFFF0F8FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPrefilled) ...[
                  Icon(Icons.auto_awesome, size: 16, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    question.getQuestionText(isFilipino),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isFilipino
                    ? 'Maaaring pumili ng marami'
                    : 'You can select multiple',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final isSelected = currentValue.contains(option);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        currentValue.remove(option);
                      } else {
                        currentValue.add(option);
                      }
                      _answers[question.id] = currentValue;
                    });
                    _updateProgressInRealTime();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorConstant.lightRed.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? ColorConstant.lightRed
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isSelected
                              ? ColorConstant.lightRed
                              : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? ColorConstant.bluedark
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadQuestion(Question question, bool isFilipino) {
    final uploadedFiles = _uploadedFiles[question.id] ?? [];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.getQuestionText(isFilipino),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'PDF, JPG, PNG',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(question.id),
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: Text(
                      isFilipino ? 'Larawan' : 'Photo',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstant.lightRed,
                      side: BorderSide(color: ColorConstant.lightRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFile(question.id),
                    icon: const Icon(Icons.attach_file, size: 20),
                    label: Text(
                      isFilipino ? 'File' : 'File',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstant.lightRed,
                      side: BorderSide(color: ColorConstant.lightRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Uploaded files list
            if (uploadedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...uploadedFiles.map((filePath) {
                final fileName = filePath.split('/').last;
                final isImage = filePath.toLowerCase().endsWith('.jpg') ||
                    filePath.toLowerCase().endsWith('.jpeg') ||
                    filePath.toLowerCase().endsWith('.png');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isImage ? Icons.image : Icons.picture_as_pdf,
                          color: ColorConstant.lightRed,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeFile(question.id, filePath),
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isFilipino) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitQuestionnaire,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.lightRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          isFilipino ? 'Isumite ang Questionnaire' : 'Submit Questionnaire',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedStatus(bool isFilipino) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFilipino ? 'Naisumite na' : 'Submitted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFilipino
                      ? 'Nasuri na ng doktor ang inyong questionnaire'
                      : 'Your questionnaire has been reviewed by the doctor',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[800],
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
