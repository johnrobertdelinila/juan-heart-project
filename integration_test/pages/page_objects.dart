import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// Page Object Model for E2E Testing
///
/// This file contains page objects representing different screens:
/// - LoginPage
/// - RegistrationPage
/// - HomePage
/// - AssessmentPage
/// - ReferralPage
/// - AppointmentPage
/// - EmergencyPage
///
/// Each page object encapsulates:
/// - Element finders
/// - User actions
/// - Assertions

// ==================== Login Page ====================

class LoginPage {
  final WidgetTester tester;

  LoginPage(this.tester);

  // Element finders
  Finder get emailField => find.byKey(const Key('email_field'));
  Finder get passwordField => find.byKey(const Key('password_field'));
  Finder get loginButton => find.text('Sign In');
  Finder get signUpLink => find.text('Sign Up');
  Finder get forgotPasswordLink => find.text('Forgot Password?');

  // Actions
  Future<void> enterEmail(String email) async {
    await TestHelpers.enterText(tester, 'email_field', email);
  }

  Future<void> enterPassword(String password) async {
    await TestHelpers.enterText(tester, 'password_field', password);
  }

  Future<void> tapLogin() async {
    await TestHelpers.tapButtonByText(tester, 'Sign In');
  }

  Future<void> tapSignUp() async {
    await TestHelpers.tapButtonByText(tester, 'Sign Up');
  }

  Future<void> login(String email, String password) async {
    await enterEmail(email);
    await enterPassword(password);
    await tapLogin();
  }

  // Assertions
  void assertLoginScreenVisible() {
    TestHelpers.assertTextVisible('Sign In', reason: 'Login screen should be visible');
  }

  void assertLoginError(String error) {
    TestHelpers.assertTextVisible(error, reason: 'Login error should be displayed');
  }
}

// ==================== Registration Page ====================

class RegistrationPage {
  final WidgetTester tester;

  RegistrationPage(this.tester);

  // Element finders
  Finder get emailField => find.byKey(const Key('reg_email_field'));
  Finder get passwordField => find.byKey(const Key('reg_password_field'));
  Finder get confirmPasswordField => find.byKey(const Key('reg_confirm_password_field'));
  Finder get firstNameField => find.byKey(const Key('reg_first_name_field'));
  Finder get lastNameField => find.byKey(const Key('reg_last_name_field'));
  Finder get contactNumberField => find.byKey(const Key('reg_contact_field'));
  Finder get birthDateField => find.byKey(const Key('reg_birth_date_field'));
  Finder get genderDropdown => find.byKey(const Key('reg_gender_dropdown'));
  Finder get addressField => find.byKey(const Key('reg_address_field'));
  Finder get signUpButton => find.text('Create Account');

  // Actions
  Future<void> fillRegistrationForm(Map<String, String> userData) async {
    await TestHelpers.enterText(tester, 'reg_email_field', userData['email']!);
    await TestHelpers.enterText(tester, 'reg_password_field', userData['password']!);
    await TestHelpers.enterText(tester, 'reg_confirm_password_field', userData['password']!);
    await TestHelpers.enterText(tester, 'reg_first_name_field', userData['firstName']!);
    await TestHelpers.enterText(tester, 'reg_last_name_field', userData['lastName']!);
    await TestHelpers.enterText(tester, 'reg_contact_field', userData['contactNumber']!);
    await TestHelpers.enterText(tester, 'reg_birth_date_field', userData['birthDate']!);
    await TestHelpers.enterText(tester, 'reg_address_field', userData['address']!);
  }

  Future<void> selectGender(String gender) async {
    await tester.tap(genderDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(gender));
    await tester.pumpAndSettle();
  }

  Future<void> tapSignUp() async {
    await TestHelpers.tapButtonByText(tester, 'Create Account');
  }

  Future<void> completeRegistration(Map<String, String> userData) async {
    await fillRegistrationForm(userData);
    await selectGender(userData['gender']!);
    await tapSignUp();
  }

  // Assertions
  void assertRegistrationScreenVisible() {
    TestHelpers.assertTextVisible('Create Account');
  }

  void assertRegistrationSuccess() {
    TestHelpers.assertTextVisible('Registration Successful');
  }

  void assertValidationError(String error) {
    TestHelpers.assertTextVisible(error);
  }
}

// ==================== Home Page ====================

class HomePage {
  final WidgetTester tester;

  HomePage(this.tester);

  // Element finders
  Finder get assessmentCard => find.text('Heart Risk Assessment');
  Finder get appointmentsCard => find.text('My Appointments');
  Finder get healthCornerCard => find.text('Health Corner');
  Finder get analyticsCard => find.text('Analytics');
  Finder get emergencyButton => find.byKey(const Key('emergency_button'));
  Finder get profileIcon => find.byKey(const Key('profile_icon'));
  Finder get notificationIcon => find.byKey(const Key('notification_icon'));

  // Actions
  Future<void> tapAssessment() async {
    await TestHelpers.tapButtonByText(tester, 'Heart Risk Assessment');
  }

  Future<void> tapAppointments() async {
    await TestHelpers.tapButtonByText(tester, 'My Appointments');
  }

  Future<void> tapHealthCorner() async {
    await TestHelpers.tapButtonByText(tester, 'Health Corner');
  }

  Future<void> tapAnalytics() async {
    await TestHelpers.tapButtonByText(tester, 'Analytics');
  }

  Future<void> tapEmergency() async {
    await TestHelpers.tapButtonByKey(tester, const Key('emergency_button'));
  }

  Future<void> tapProfile() async {
    await TestHelpers.tapButtonByKey(tester, const Key('profile_icon'));
  }

  Future<void> tapNotifications() async {
    await TestHelpers.tapButtonByKey(tester, const Key('notification_icon'));
  }

  // Assertions
  void assertHomeScreenVisible() {
    TestHelpers.assertTextVisible('Juan Heart');
  }

  void assertWelcomeMessage(String userName) {
    TestHelpers.assertTextVisible('Welcome, $userName');
  }

  void assertAssessmentCardVisible() {
    TestHelpers.assertTextVisible('Heart Risk Assessment');
  }
}

// ==================== Assessment Page ====================

class AssessmentPage {
  final WidgetTester tester;

  AssessmentPage(this.tester);

  // Element finders
  Finder get startButton => find.text('Start Assessment');
  Finder get nextButton => find.text('Next');
  Finder get previousButton => find.text('Previous');
  Finder get submitButton => find.text('Complete Assessment');
  Finder get cancelButton => find.text('Cancel');

  // Actions
  Future<void> tapStart() async {
    await TestHelpers.tapButtonByText(tester, 'Start Assessment');
  }

  Future<void> selectSymptom(String symptom, int severity) async {
    // Find symptom card
    final symptomFinder = find.text(symptom);
    expect(symptomFinder, findsOneWidget, reason: 'Symptom "$symptom" should be visible');

    await tester.tap(symptomFinder);
    await tester.pumpAndSettle();

    // Select severity
    final severityFinder = find.byKey(Key('severity_$severity'));
    if (severityFinder.evaluate().isNotEmpty) {
      await tester.tap(severityFinder);
      await tester.pumpAndSettle();
    }
  }

  Future<void> enterVitalSign(String vitalSign, String value) async {
    await TestHelpers.enterText(tester, 'vital_$vitalSign', value);
  }

  Future<void> enterBloodPressure(int systolic, int diastolic) async {
    await TestHelpers.enterText(tester, 'vital_systolic_bp', systolic.toString());
    await TestHelpers.enterText(tester, 'vital_diastolic_bp', diastolic.toString());
  }

  Future<void> enterHeartRate(int heartRate) async {
    await TestHelpers.enterText(tester, 'vital_heart_rate', heartRate.toString());
  }

  Future<void> enterWeight(double weight) async {
    await TestHelpers.enterText(tester, 'vital_weight', weight.toString());
  }

  Future<void> enterHeight(double height) async {
    await TestHelpers.enterText(tester, 'vital_height', height.toString());
  }

  Future<void> selectMedicalHistory(String condition, bool hasCondition) async {
    final conditionFinder = find.byKey(Key('medical_history_$condition'));
    if (conditionFinder.evaluate().isNotEmpty) {
      final checkbox = tester.widget<Checkbox>(conditionFinder);
      if (checkbox.value != hasCondition) {
        await tester.tap(conditionFinder);
        await tester.pumpAndSettle();
      }
    }
  }

  Future<void> selectLifestyleFactor(String factor, String option) async {
    final factorFinder = find.byKey(Key('lifestyle_$factor'));
    await tester.tap(factorFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  Future<void> tapNext() async {
    await TestHelpers.tapButtonByText(tester, 'Next');
  }

  Future<void> tapPrevious() async {
    await TestHelpers.tapButtonByText(tester, 'Previous');
  }

  Future<void> tapSubmit() async {
    await TestHelpers.tapButtonByText(tester, 'Complete Assessment');
  }

  Future<void> completeHighRiskAssessment() async {
    await tapStart();

    // Symptoms
    await selectSymptom('Chest pain or discomfort', 5);
    await selectSymptom('Shortness of breath', 5);
    await selectSymptom('Chronic fatigue', 4);
    await tapNext();

    // Vital Signs
    await enterBloodPressure(180, 110);
    await enterHeartRate(110);
    await enterWeight(95.0);
    await enterHeight(165.0);
    await tapNext();

    // Medical History
    await selectMedicalHistory('hypertension', true);
    await selectMedicalHistory('diabetes', true);
    await selectMedicalHistory('heart_disease', true);
    await tapNext();

    // Lifestyle
    await selectLifestyleFactor('smoking', 'Current smoker');
    await selectLifestyleFactor('alcohol', 'Heavy drinker');
    await selectLifestyleFactor('exercise', 'None');
    await tapNext();

    // Submit
    await tapSubmit();
  }

  // Assertions
  void assertAssessmentScreenVisible() {
    TestHelpers.assertTextVisible('Heart Risk Assessment');
  }

  void assertRiskScoreDisplayed(int expectedScore) {
    final scoreFinder = find.byKey(const Key('risk_score_display'));
    expect(scoreFinder, findsOneWidget, reason: 'Risk score should be displayed');

    final scoreWidget = tester.widget<Text>(scoreFinder);
    final displayedScore = int.parse(scoreWidget.data!.replaceAll(RegExp(r'[^0-9]'), ''));
    expect(displayedScore, equals(expectedScore));
  }

  void assertRiskCategoryDisplayed(String expectedCategory) {
    TestHelpers.assertTextVisible(expectedCategory);
  }

  void assertRecommendationsVisible() {
    TestHelpers.assertTextVisible('Recommendations');
  }
}

// ==================== Referral Page ====================

class ReferralPage {
  final WidgetTester tester;

  ReferralPage(this.tester);

  // Element finders
  Finder get facilityList => find.byKey(const Key('facility_list'));
  Finder get searchField => find.byKey(const Key('facility_search'));
  Finder get filterButton => find.byKey(const Key('filter_button'));
  Finder get sortButton => find.byKey(const Key('sort_button'));
  Finder get generatePdfButton => find.text('Generate PDF');
  Finder get shareButton => find.text('Share');

  // Actions
  Future<void> searchFacility(String query) async {
    await TestHelpers.enterText(tester, 'facility_search', query);
  }

  Future<void> selectFacility(String facilityName) async {
    final facilityFinder = find.text(facilityName);
    expect(facilityFinder, findsOneWidget, reason: 'Facility "$facilityName" should be visible');
    await tester.tap(facilityFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapGeneratePdf() async {
    await TestHelpers.tapButtonByText(tester, 'Generate PDF');
  }

  Future<void> tapShare() async {
    await TestHelpers.tapButtonByText(tester, 'Share');
  }

  Future<void> tapBookAppointment() async {
    await TestHelpers.tapButtonByText(tester, 'Book Appointment');
  }

  // Assertions
  void assertReferralScreenVisible() {
    TestHelpers.assertTextVisible('Facility Recommendations');
  }

  void assertFacilitySorted() {
    TestHelpers.assertTextVisible('Nearest First');
  }

  void assertPdfGenerated() {
    TestHelpers.assertTextVisible('PDF Generated Successfully');
  }
}

// ==================== Appointment Page ====================

class AppointmentPage {
  final WidgetTester tester;

  AppointmentPage(this.tester);

  // Element finders
  Finder get facilityDropdown => find.byKey(const Key('appointment_facility_dropdown'));
  Finder get dateField => find.byKey(const Key('appointment_date_field'));
  Finder get timeField => find.byKey(const Key('appointment_time_field'));
  Finder get doctorDropdown => find.byKey(const Key('appointment_doctor_dropdown'));
  Finder get notesField => find.byKey(const Key('appointment_notes_field'));
  Finder get bookButton => find.text('Book Appointment');
  Finder get cancelButton => find.text('Cancel Appointment');
  Finder get rescheduleButton => find.text('Reschedule');

  // Actions
  Future<void> selectFacility(String facilityName) async {
    await tester.tap(facilityDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(facilityName));
    await tester.pumpAndSettle();
  }

  Future<void> selectDate(DateTime date) async {
    await tester.tap(dateField);
    await tester.pumpAndSettle();

    // Tap OK button in date picker (simplified)
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> selectTime(String time) async {
    await tester.tap(timeField);
    await tester.pumpAndSettle();
    await tester.tap(find.text(time));
    await tester.pumpAndSettle();
  }

  Future<void> selectDoctor(String doctorName) async {
    await tester.tap(doctorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(doctorName));
    await tester.pumpAndSettle();
  }

  Future<void> enterNotes(String notes) async {
    await TestHelpers.enterText(tester, 'appointment_notes_field', notes);
  }

  Future<void> tapBook() async {
    await TestHelpers.tapButtonByText(tester, 'Book Appointment');
  }

  Future<void> tapCancel() async {
    await TestHelpers.tapButtonByText(tester, 'Cancel Appointment');
  }

  Future<void> tapReschedule() async {
    await TestHelpers.tapButtonByText(tester, 'Reschedule');
  }

  Future<void> bookAppointment({
    required String facility,
    required DateTime date,
    required String time,
    String? notes,
  }) async {
    await selectFacility(facility);
    await selectDate(date);
    await selectTime(time);
    if (notes != null) {
      await enterNotes(notes);
    }
    await tapBook();
  }

  // Assertions
  void assertAppointmentScreenVisible() {
    TestHelpers.assertTextVisible('Book Appointment');
  }

  void assertAppointmentBooked() {
    TestHelpers.assertTextVisible('Appointment Booked Successfully');
  }

  void assertAppointmentCancelled() {
    TestHelpers.assertTextVisible('Appointment Cancelled');
  }

  void assertDateValidationError() {
    TestHelpers.assertTextVisible('Please select a future date');
  }
}

// ==================== Emergency Page ====================

class EmergencyPage {
  final WidgetTester tester;

  EmergencyPage(this.tester);

  // Element finders
  Finder get sosButton => find.byKey(const Key('sos_button'));
  Finder get call911Button => find.text('Call 911');
  Finder get emergencyContactsButton => find.text('Emergency Contacts');
  Finder get nearestHospitalButton => find.text('Nearest Hospital');
  Finder get strokeChecklistButton => find.text('Stroke Checklist');

  // Actions
  Future<void> tapSOS() async {
    await TestHelpers.tapButtonByKey(tester, const Key('sos_button'));
  }

  Future<void> tapCall911() async {
    await TestHelpers.tapButtonByText(tester, 'Call 911');
  }

  Future<void> tapEmergencyContacts() async {
    await TestHelpers.tapButtonByText(tester, 'Emergency Contacts');
  }

  Future<void> tapNearestHospital() async {
    await TestHelpers.tapButtonByText(tester, 'Nearest Hospital');
  }

  Future<void> tapStrokeChecklist() async {
    await TestHelpers.tapButtonByText(tester, 'Stroke Checklist');
  }

  // Assertions
  void assertEmergencyScreenVisible() {
    TestHelpers.assertTextVisible('Emergency');
  }

  void assertSOSActivated() {
    TestHelpers.assertTextVisible('SOS Activated');
  }

  void assertLocationServicesActive() {
    TestHelpers.assertTextVisible('Location Services Active');
  }

  void assertNearestHospitalDisplayed() {
    TestHelpers.assertTextVisible('Nearest Hospital');
  }
}
