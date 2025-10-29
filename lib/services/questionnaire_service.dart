import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/models/questionnaire_model.dart';
import 'package:uuid/uuid.dart';

/// Service for managing pre-consultation questionnaires
class QuestionnaireService {
  static const String _storageKey = 'juan_heart_questionnaires';
  static const Uuid _uuid = Uuid();

  /// Get all questionnaires from storage
  static Future<List<PreConsultationQuestionnaire>> getAllQuestionnaires() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) =>
              PreConsultationQuestionnaire.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading questionnaires: $e');
      return [];
    }
  }

  /// Get questionnaire for a specific appointment
  static Future<PreConsultationQuestionnaire?> getQuestionnaireForAppointment(
      String appointmentId) async {
    try {
      final questionnaires = await getAllQuestionnaires();
      return questionnaires.firstWhere(
        (q) => q.appointmentId == appointmentId,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new questionnaire draft
  static Future<PreConsultationQuestionnaire> createQuestionnaire(
      String appointmentId) async {
    final questionnaire = PreConsultationQuestionnaire(
      id: _uuid.v4(),
      appointmentId: appointmentId,
      status: QuestionnaireStatus.draft,
      answers: [],
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      progressPercentage: 0,
    );

    await saveQuestionnaire(questionnaire);
    return questionnaire;
  }

  /// Save or update a questionnaire
  static Future<bool> saveQuestionnaire(
      PreConsultationQuestionnaire questionnaire) async {
    try {
      final questionnaires = await getAllQuestionnaires();

      // Find existing questionnaire or add new one
      final index = questionnaires.indexWhere((q) => q.id == questionnaire.id);

      if (index != -1) {
        questionnaires[index] = questionnaire.copyWith(
          lastModifiedAt: DateTime.now(),
        );
      } else {
        questionnaires.add(questionnaire);
      }

      await _saveQuestionnairesList(questionnaires);
      print('✅ Questionnaire saved: ${questionnaire.id}');
      return true;
    } catch (e) {
      print('❌ Error saving questionnaire: $e');
      return false;
    }
  }

  /// Update answer for a specific question
  static Future<bool> updateAnswer(
    String questionnaireId,
    String questionId,
    dynamic answer,
  ) async {
    try {
      final questionnaires = await getAllQuestionnaires();
      final index = questionnaires.indexWhere((q) => q.id == questionnaireId);

      if (index == -1) {
        return false;
      }

      final questionnaire = questionnaires[index];
      final answers = List<QuestionAnswer>.from(questionnaire.answers);

      // Remove existing answer if present
      answers.removeWhere((a) => a.questionId == questionId);

      // Add new answer
      answers.add(QuestionAnswer(
        questionId: questionId,
        answer: answer,
        answeredAt: DateTime.now(),
      ));

      // Calculate progress (only count visible required questions)
      final questions = QuestionnaireTemplates.getGeneralQuestions();

      // Create temporary questionnaire for visibility checks
      final tempQuestionnaire = questionnaire.copyWith(answers: answers);

      // Only count required questions that are currently visible
      final requiredQuestions = questions.where((q) =>
        q.isRequired && shouldShowQuestion(q, tempQuestionnaire)
      ).toList();

      final answeredRequired = answers
          .where((a) => requiredQuestions.any((q) => q.id == a.questionId))
          .length;
      final progress = requiredQuestions.isEmpty
          ? 0
          : ((answeredRequired / requiredQuestions.length) * 100).round();

      // Update questionnaire
      questionnaires[index] = questionnaire.copyWith(
        answers: answers,
        lastModifiedAt: DateTime.now(),
        progressPercentage: progress,
      );

      await _saveQuestionnairesList(questionnaires);
      return true;
    } catch (e) {
      print('❌ Error updating answer: $e');
      return false;
    }
  }

  /// Submit questionnaire
  static Future<bool> submitQuestionnaire(String questionnaireId) async {
    try {
      final questionnaires = await getAllQuestionnaires();
      final index = questionnaires.indexWhere((q) => q.id == questionnaireId);

      if (index == -1) {
        return false;
      }

      // Validate all required questions are answered
      final questionnaire = questionnaires[index];
      final questions = QuestionnaireTemplates.getGeneralQuestions();
      final requiredQuestions =
          questions.where((q) => q.isRequired).toList();

      for (final question in requiredQuestions) {
        if (!questionnaire.hasAnswer(question.id)) {
          print('❌ Missing required answer for: ${question.id}');
          return false;
        }
      }

      // Update status to submitted
      questionnaires[index] = questionnaire.copyWith(
        status: QuestionnaireStatus.submitted,
        submittedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
      );

      await _saveQuestionnairesList(questionnaires);
      print('✅ Questionnaire submitted: $questionnaireId');
      return true;
    } catch (e) {
      print('❌ Error submitting questionnaire: $e');
      return false;
    }
  }

  /// Delete a questionnaire
  static Future<bool> deleteQuestionnaire(String questionnaireId) async {
    try {
      final questionnaires = await getAllQuestionnaires();
      questionnaires.removeWhere((q) => q.id == questionnaireId);

      await _saveQuestionnairesList(questionnaires);
      print('✅ Questionnaire deleted: $questionnaireId');
      return true;
    } catch (e) {
      print('❌ Error deleting questionnaire: $e');
      return false;
    }
  }

  /// Get questionnaire completion statistics
  static Future<Map<String, int>> getStats() async {
    final questionnaires = await getAllQuestionnaires();

    return {
      'total': questionnaires.length,
      'drafts': questionnaires
          .where((q) => q.status == QuestionnaireStatus.draft)
          .length,
      'submitted': questionnaires
          .where((q) => q.status == QuestionnaireStatus.submitted)
          .length,
      'reviewed': questionnaires
          .where((q) => q.status == QuestionnaireStatus.reviewed)
          .length,
    };
  }

  /// Check if question should be visible based on conditionals
  static bool shouldShowQuestion(
    Question question,
    PreConsultationQuestionnaire questionnaire,
  ) {
    if (question.conditionalOn == null || question.conditionalAnswer == null) {
      return true; // No condition, always show
    }

    final parentAnswer = questionnaire.getAnswer(question.conditionalOn!);

    if (parentAnswer == null) {
      return false; // Parent not answered yet
    }

    // Check if parent answer matches the conditional answer
    if (question.type == QuestionType.yesNo) {
      return parentAnswer.toString() == question.conditionalAnswer;
    }

    return parentAnswer.toString() == question.conditionalAnswer;
  }

  /// Validate answer for a question
  static String? validateAnswer(Question question, dynamic answer) {
    if (question.isRequired && (answer == null || answer.toString().isEmpty)) {
      return 'This field is required';
    }

    if (question.type == QuestionType.number && answer != null) {
      final numValue = int.tryParse(answer.toString());
      if (numValue == null) {
        return 'Please enter a valid number';
      }
      if (question.minValue != null && numValue < question.minValue!) {
        return 'Value must be at least ${question.minValue}';
      }
      if (question.maxValue != null && numValue > question.maxValue!) {
        return 'Value must not exceed ${question.maxValue}';
      }
    }

    return null;
  }

  /// Private helper to save questionnaires list
  static Future<void> _saveQuestionnairesList(
      List<PreConsultationQuestionnaire> questionnaires) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = questionnaires.map((q) => q.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Clear all questionnaires (for testing/debugging)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('✅ All questionnaires cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing questionnaires: $e');
      return false;
    }
  }
}
