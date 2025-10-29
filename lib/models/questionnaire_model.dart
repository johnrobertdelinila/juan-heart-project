import 'package:get/get.dart';

/// Enum for questionnaire question types
enum QuestionType {
  text,
  multipleChoice,
  singleChoice,
  number,
  yesNo,
  fileUpload,
  date,
}

/// Enum for questionnaire status
enum QuestionnaireStatus {
  draft,
  submitted,
  reviewed,
}

/// Model for a single question in the questionnaire
class Question {
  final String id;
  final String questionText;
  final String questionTextFilipino;
  final QuestionType type;
  final bool isRequired;
  final List<String>? options; // For choice questions
  final List<String>? optionsFilipino; // Filipino translations for options
  final String? conditionalOn; // Show only if this question ID has specific answer
  final String? conditionalAnswer; // The answer that triggers visibility
  final int? minValue; // For number questions
  final int? maxValue; // For number questions
  final String? unit; // For number questions (e.g., "mg", "kg")

  const Question({
    required this.id,
    required this.questionText,
    required this.questionTextFilipino,
    required this.type,
    this.isRequired = false,
    this.options,
    this.optionsFilipino,
    this.conditionalOn,
    this.conditionalAnswer,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  String getQuestionText(bool isFilipino) =>
      isFilipino ? questionTextFilipino : questionText;

  List<String>? getOptions(bool isFilipino) =>
      isFilipino && optionsFilipino != null ? optionsFilipino : options;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'questionTextFilipino': questionTextFilipino,
      'type': type.name,
      'isRequired': isRequired,
      'options': options,
      'optionsFilipino': optionsFilipino,
      'conditionalOn': conditionalOn,
      'conditionalAnswer': conditionalAnswer,
      'minValue': minValue,
      'maxValue': maxValue,
      'unit': unit,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      questionTextFilipino: json['questionTextFilipino'] as String,
      type: QuestionType.values.firstWhere((e) => e.name == json['type']),
      isRequired: json['isRequired'] as bool? ?? false,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      optionsFilipino: json['optionsFilipino'] != null
          ? List<String>.from(json['optionsFilipino'] as List)
          : null,
      conditionalOn: json['conditionalOn'] as String?,
      conditionalAnswer: json['conditionalAnswer'] as String?,
      minValue: json['minValue'] as int?,
      maxValue: json['maxValue'] as int?,
      unit: json['unit'] as String?,
    );
  }
}

/// Model for a questionnaire answer
class QuestionAnswer {
  final String questionId;
  final dynamic answer; // Can be String, List<String>, int, or List<String> for files
  final DateTime answeredAt;

  const QuestionAnswer({
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionId: json['questionId'] as String,
      answer: json['answer'],
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }
}

/// Model for a complete pre-consultation questionnaire
class PreConsultationQuestionnaire {
  final String id;
  final String appointmentId;
  final QuestionnaireStatus status;
  final List<QuestionAnswer> answers;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? lastModifiedAt;
  final int progressPercentage; // 0-100

  const PreConsultationQuestionnaire({
    required this.id,
    required this.appointmentId,
    required this.status,
    required this.answers,
    required this.createdAt,
    this.submittedAt,
    this.lastModifiedAt,
    this.progressPercentage = 0,
  });

  // Get answer for a specific question
  dynamic getAnswer(String questionId) {
    try {
      return answers.firstWhere((a) => a.questionId == questionId).answer;
    } catch (e) {
      return null;
    }
  }

  // Check if a question has been answered
  bool hasAnswer(String questionId) {
    return answers.any((a) => a.questionId == questionId);
  }

  // Get status text
  String getStatusText(bool isFilipino) {
    switch (status) {
      case QuestionnaireStatus.draft:
        return isFilipino ? 'Draft' : 'Draft';
      case QuestionnaireStatus.submitted:
        return isFilipino ? 'Naisumite' : 'Submitted';
      case QuestionnaireStatus.reviewed:
        return isFilipino ? 'Nasuri na' : 'Reviewed';
    }
  }

  // Copy with method
  PreConsultationQuestionnaire copyWith({
    String? id,
    String? appointmentId,
    QuestionnaireStatus? status,
    List<QuestionAnswer>? answers,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? lastModifiedAt,
    int? progressPercentage,
  }) {
    return PreConsultationQuestionnaire(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      status: status ?? this.status,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'status': status.name,
      'answers': answers.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'progressPercentage': progressPercentage,
    };
  }

  factory PreConsultationQuestionnaire.fromJson(Map<String, dynamic> json) {
    return PreConsultationQuestionnaire(
      id: json['id'] as String,
      appointmentId: json['appointmentId'] as String,
      status: QuestionnaireStatus.values
          .firstWhere((e) => e.name == json['status']),
      answers: (json['answers'] as List)
          .map((a) => QuestionAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
      progressPercentage: json['progressPercentage'] as int? ?? 0,
    );
  }
}

/// Predefined questionnaire templates
class QuestionnaireTemplates {
  /// General pre-consultation questionnaire
  static List<Question> getGeneralQuestions() {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return [
      // Section 1: Chief Complaint
      Question(
        id: 'chief_complaint',
        questionText: 'What is the main reason for your consultation today?',
        questionTextFilipino: 'Ano ang pangunahing dahilan ng iyong konsultasyon ngayon?',
        type: QuestionType.text,
        isRequired: true,
      ),

      Question(
        id: 'symptom_duration',
        questionText: 'How long have you been experiencing these symptoms?',
        questionTextFilipino: 'Gaano katagal mo nang nararanasan ang mga sintomas na ito?',
        type: QuestionType.singleChoice,
        isRequired: true,
        options: [
          'Less than 24 hours',
          '1-7 days',
          '1-4 weeks',
          'More than 1 month',
        ],
        optionsFilipino: [
          'Mas mababa sa 24 oras',
          '1-7 araw',
          '1-4 linggo',
          'Higit sa 1 buwan',
        ],
      ),

      // Section 2: Current Symptoms
      Question(
        id: 'chest_pain',
        questionText: 'Are you experiencing chest pain or discomfort?',
        questionTextFilipino: 'Mayroon ka bang sakit o discomfort sa dibdib?',
        type: QuestionType.yesNo,
        isRequired: true,
      ),

      Question(
        id: 'chest_pain_severity',
        questionText: 'On a scale of 1-10, how severe is the chest pain?',
        questionTextFilipino: 'Sa scale na 1-10, gaano kalala ang sakit sa dibdib?',
        type: QuestionType.number,
        isRequired: false,
        conditionalOn: 'chest_pain',
        conditionalAnswer: 'Yes',
        minValue: 1,
        maxValue: 10,
      ),

      Question(
        id: 'shortness_breath',
        questionText: 'Are you experiencing shortness of breath?',
        questionTextFilipino: 'Nahihirapan ka ba sa paghinga?',
        type: QuestionType.yesNo,
        isRequired: true,
      ),

      Question(
        id: 'palpitations',
        questionText: 'Do you feel your heart racing or skipping beats?',
        questionTextFilipino: 'Nararamdaman mo ba na bumibilis o sumasayaw ang tibok ng puso mo?',
        type: QuestionType.yesNo,
        isRequired: true,
      ),

      Question(
        id: 'dizziness',
        questionText: 'Are you experiencing dizziness or lightheadedness?',
        questionTextFilipino: 'Nahihilo ka ba o pakiramdam mo ay lulutang?',
        type: QuestionType.yesNo,
        isRequired: false,
      ),

      // Section 3: Medical History
      Question(
        id: 'existing_conditions',
        questionText: 'Do you have any existing medical conditions?',
        questionTextFilipino: 'Mayroon ka bang mga kondisyong medikal?',
        type: QuestionType.multipleChoice,
        isRequired: true,
        options: [
          'High blood pressure',
          'Diabetes',
          'High cholesterol',
          'Heart disease',
          'Asthma',
          'None',
        ],
        optionsFilipino: [
          'Mataas na presyon',
          'Diabetes',
          'Mataas na kolesterol',
          'Sakit sa puso',
          'Hika',
          'Wala',
        ],
      ),

      Question(
        id: 'previous_heart_issues',
        questionText: 'Have you had any previous heart problems or surgeries?',
        questionTextFilipino: 'Mayroon ka bang nakaraang problema sa puso o operasyon?',
        type: QuestionType.yesNo,
        isRequired: true,
      ),

      Question(
        id: 'heart_issues_details',
        questionText: 'Please describe your previous heart problems or surgeries',
        questionTextFilipino: 'Pakipaliwanag ang iyong nakaraang problema sa puso o operasyon',
        type: QuestionType.text,
        isRequired: false,
        conditionalOn: 'previous_heart_issues',
        conditionalAnswer: 'Yes',
      ),

      // Section 4: Current Medications
      Question(
        id: 'taking_medications',
        questionText: 'Are you currently taking any medications?',
        questionTextFilipino: 'Umiinom ka ba ng anumang gamot ngayon?',
        type: QuestionType.yesNo,
        isRequired: true,
      ),

      Question(
        id: 'medications_list',
        questionText: 'Please list all medications you are currently taking (including dosage)',
        questionTextFilipino: 'Ilista ang lahat ng gamot na iyong iniinom (kasama ang dosis)',
        type: QuestionType.text,
        isRequired: false,
        conditionalOn: 'taking_medications',
        conditionalAnswer: 'Yes',
      ),

      Question(
        id: 'allergies',
        questionText: 'Do you have any medication allergies?',
        questionTextFilipino: 'Mayroon ka bang allergy sa gamot?',
        type: QuestionType.text,
        isRequired: false,
      ),

      // Section 5: Lifestyle Factors
      Question(
        id: 'smoking',
        questionText: 'Do you smoke?',
        questionTextFilipino: 'Naninigarilyo ka ba?',
        type: QuestionType.singleChoice,
        isRequired: true,
        options: [
          'Never',
          'Former smoker',
          'Current smoker (less than 1 pack/day)',
          'Current smoker (1+ pack/day)',
        ],
        optionsFilipino: [
          'Hindi kailanman',
          'Dating naninigarilyo',
          'Naninigarilyo ngayon (mas mababa sa 1 pack/araw)',
          'Naninigarilyo ngayon (1+ pack/araw)',
        ],
      ),

      Question(
        id: 'alcohol',
        questionText: 'How often do you drink alcohol?',
        questionTextFilipino: 'Gaano ka kadalas uminom ng alak?',
        type: QuestionType.singleChoice,
        isRequired: true,
        options: [
          'Never',
          'Occasionally (1-2 times/month)',
          'Regularly (1-2 times/week)',
          'Frequently (3+ times/week)',
        ],
        optionsFilipino: [
          'Hindi kailanman',
          'Paminsan-minsan (1-2 beses/buwan)',
          'Regular (1-2 beses/linggo)',
          'Madalas (3+ beses/linggo)',
        ],
      ),

      Question(
        id: 'exercise',
        questionText: 'How often do you exercise?',
        questionTextFilipino: 'Gaano ka kadalas mag-ehersisyo?',
        type: QuestionType.singleChoice,
        isRequired: true,
        options: [
          'Never',
          'Rarely (less than once/week)',
          'Sometimes (1-2 times/week)',
          'Regularly (3-4 times/week)',
          'Daily',
        ],
        optionsFilipino: [
          'Hindi kailanman',
          'Bihira (mas mababa sa isang beses/linggo)',
          'Paminsan (1-2 beses/linggo)',
          'Regular (3-4 beses/linggo)',
          'Araw-araw',
        ],
      ),

      // Section 6: Additional Information
      Question(
        id: 'recent_tests',
        questionText: 'Have you had any recent medical tests or lab work?',
        questionTextFilipino: 'Mayroon ka bang kamakailang medical test o laboratory?',
        type: QuestionType.yesNo,
        isRequired: false,
      ),

      Question(
        id: 'test_results_upload',
        questionText: 'Please upload any recent test results or medical reports (optional)',
        questionTextFilipino: 'Mag-upload ng mga kamakailang test result o medical report (optional)',
        type: QuestionType.fileUpload,
        isRequired: false,
        conditionalOn: 'recent_tests',
        conditionalAnswer: 'Yes',
      ),

      Question(
        id: 'additional_concerns',
        questionText: 'Do you have any additional concerns or questions for the doctor?',
        questionTextFilipino: 'Mayroon ka pa bang ibang alalahanin o tanong para sa doktor?',
        type: QuestionType.text,
        isRequired: false,
      ),
    ];
  }
}
