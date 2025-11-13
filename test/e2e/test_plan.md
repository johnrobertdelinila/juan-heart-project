# Juan Heart Mobile - End-to-End Test Plan

**Version:** 1.0
**Date:** January 2025
**Test Lead:** JH-QA-Guardian
**Priority:** P1 - High (Production Readiness)

---

## Executive Summary

This document outlines the comprehensive End-to-End (E2E) testing strategy for Juan Heart Mobile, a cardiovascular health assessment application designed for the Philippines healthcare system. The testing ensures all critical user journeys function correctly across multiple device configurations, network conditions, and edge cases.

---

## Test Objectives

### Primary Objectives
1. **Functional Validation:** Verify all critical user journeys work end-to-end
2. **Data Integrity:** Ensure no data loss in offline/online transitions
3. **Performance:** Validate performance benchmarks on target devices
4. **Clinical Accuracy:** Verify risk assessment calculations (1-25 scale)
5. **Offline-First:** Confirm offline functionality and sync reliability
6. **User Experience:** Validate smooth workflows and error handling

### Success Criteria
- ✅ 0 critical bugs in production paths
- ✅ All performance benchmarks met on low-end devices
- ✅ 100% clinical algorithm accuracy (PHC validated)
- ✅ Offline-to-online sync success rate >95%
- ✅ All edge cases handled gracefully
- ✅ Bilingual support (EN/FIL) working correctly

---

## Test Scope

### In Scope

**Critical User Journeys:**
1. Registration → Assessment → Referral → Appointment
2. Offline Assessment → Online Sync → Clinical Validation
3. Emergency Alert Flow (Stroke Detection, SOS, Location Services)
4. Appointment Booking → Confirmation → Reminder

**Feature Areas:**
- User authentication (registration, login, session management)
- Heart risk assessment (symptoms, vital signs, medical history, lifestyle)
- Risk calculation (Likelihood × Impact = 1-25)
- Facility recommendations (GPS-based, distance sorting)
- PDF/CSV generation (referral documents, analytics reports)
- Appointment management (booking, rescheduling, cancellation)
- Emergency features (stroke checklist, SOS, nearest hospital)
- Offline sync queue (FIFO, exponential backoff, conflict resolution)
- Notifications (appointment reminders, emergency alerts)
- Analytics dashboard (risk trends, assessment history)
- Multi-language support (English, Filipino)

**Device Matrix:**
- Android: Low-end (2GB RAM, Android 7), Mid-range (4GB RAM, Android 10), High-end (8GB RAM, Android 13)
- iOS: iPhone 8 (iOS 15), iPhone 12 (iOS 16)

**Network Conditions:**
- 2G Edge (240 Kbps) - Rural Philippines
- 3G (1 Mbps) - Common in provinces
- 4G (10 Mbps) - Urban areas
- WiFi (Various speeds)
- Offline mode
- Intermittent connectivity

### Out of Scope
- Backend API unit tests (covered separately)
- Widget-level unit tests (covered by widget tests)
- Load testing (>1000 concurrent users)
- Security penetration testing (separate audit)
- iOS-specific UIKit/SwiftUI components

---

## Test Environment

### Hardware Requirements

**Android Devices:**
- Samsung Galaxy J2 (2GB RAM, Android 7.0) - **Primary low-end target**
- Oppo A3s (2GB RAM, Android 8.1)
- Samsung A52 (6GB RAM, Android 11)
- Samsung S23 (8GB RAM, Android 13)

**iOS Devices:**
- iPhone 8 (iOS 15)
- iPhone 12 (iOS 16)

**Development Machines:**
- macOS 12+ (for iOS testing)
- Linux/macOS/Windows (for Android testing)

### Software Requirements
- Flutter 3.x
- Dart 3.0+
- Android Studio / Xcode
- Flutter DevTools
- Backend API (http://localhost:8000 or staging)

### Test Data
- 8 test facilities (Philippine Heart Center, PGH, etc.)
- 50 test users with varied profiles
- 100 sample assessments (all risk levels)
- 25 test appointments (various statuses)

---

## Test Cases

### TC-001: Complete User Journey (Registration → Appointment)

**Priority:** P1 - Critical
**Estimated Duration:** 15 seconds
**Device:** All devices

**Preconditions:**
- Clean app state (no existing user)
- Backend API available
- Network connectivity

**Test Steps:**
1. Launch app
2. Navigate to registration
3. Fill registration form (all required fields)
4. Submit registration
5. Verify home screen appears
6. Navigate to Heart Risk Assessment
7. Start assessment
8. Fill symptoms (high-risk profile: chest pain severity 5, shortness of breath severity 5)
9. Enter vital signs (BP: 180/110, HR: 110, Weight: 95kg, Height: 165cm)
10. Select medical history (hypertension, diabetes, heart disease)
11. Select lifestyle factors (current smoker, heavy alcohol, no exercise)
12. Submit assessment
13. Verify risk score displayed (should be 20-25)
14. Navigate to facility recommendations
15. Select nearest facility
16. Generate PDF referral
17. Book appointment (date: +7 days, time: 10:00 AM)
18. Verify confirmation message
19. Check appointment appears in list

**Expected Results:**
- ✅ User registered successfully
- ✅ Assessment completed with risk score 20-25 (Critical/High)
- ✅ Risk category matches score (Critical: 21-25, High: 16-20)
- ✅ Facilities sorted by distance
- ✅ PDF generated successfully
- ✅ Appointment booked with status: pending
- ✅ Confirmation notification displayed
- ✅ Total time <15 seconds

**Performance Benchmarks:**
- Registration: <3s
- Assessment: <5s
- Referral generation: <2s
- Appointment booking: <3s

---

### TC-002: Offline Assessment with Sync Validation

**Priority:** P1 - Critical
**Estimated Duration:** 1 minute
**Device:** All devices

**Preconditions:**
- User logged in
- Network disabled

**Test Steps:**
1. Launch app (offline)
2. Navigate to Heart Risk Assessment
3. Complete full assessment (all sections)
4. Submit assessment
5. Verify assessment saved locally
6. Verify sync operation queued
7. Create 5 additional assessments offline
8. Verify all queued
9. Enable network
10. Wait for automatic sync
11. Verify all assessments synced
12. Check backend received all data
13. Verify no data loss or corruption

**Expected Results:**
- ✅ Assessment saved locally in <1s
- ✅ All 6 assessments queued for sync
- ✅ Automatic sync triggered when online
- ✅ All assessments synced successfully
- ✅ Risk scores match calculations (Likelihood × Impact)
- ✅ Sync timestamp recorded
- ✅ Queue cleared after successful sync

**Performance Benchmarks:**
- Offline save: <1s per assessment
- Queue 5 assessments: <500ms each
- Sync 6 assessments: <1 minute total

---

### TC-003: Emergency Alert Flow (Stroke Detection)

**Priority:** P1 - Critical
**Estimated Duration:** 10 seconds
**Device:** All devices

**Preconditions:**
- Location permission granted
- Emergency contacts configured

**Test Steps:**
1. Launch app
2. Trigger emergency (button or stroke assessment)
3. Verify SOS screen appears
4. Check emergency warning displayed
5. Verify "Call 911" button visible
6. Tap "Find Nearest Hospital"
7. Verify location services activated
8. Check facility results (sorted by distance)
9. Tap on nearest facility
10. Verify navigation option available
11. Check emergency contact list
12. Verify stroke checklist (F.A.S.T. protocol)

**Expected Results:**
- ✅ SOS screen appears in <500ms
- ✅ Emergency warning prominent (red, large text)
- ✅ Location acquired in <3s
- ✅ Nearest facility found in <2s
- ✅ Navigation link works
- ✅ Emergency contacts accessible
- ✅ Stroke checklist complete (Face, Arm, Speech, Time)
- ✅ Emergency event logged

**Performance Benchmarks:**
- SOS display: <500ms
- Location acquisition: <3s
- Facility search: <2s
- Event logging: <1s

---

### TC-004: Appointment Complete Flow

**Priority:** P1 - Critical
**Estimated Duration:** 20 seconds
**Device:** All devices

**Preconditions:**
- User logged in
- Facilities loaded
- Notification permission granted

**Test Steps:**
1. Navigate to My Appointments
2. Tap "Book Appointment"
3. Search for "Philippine Heart Center"
4. Select facility
5. Choose date (+7 days from now)
6. Select time (10:00 AM)
7. Select appointment type (Consultation)
8. Enter notes
9. Submit booking
10. Verify confirmation message
11. Check appointment in list
12. Verify reminder scheduled
13. Tap appointment card
14. Tap "Reschedule"
15. Select new date (+14 days)
16. Select new time (2:00 PM)
17. Confirm reschedule
18. Verify updated appointment
19. Tap "Cancel Appointment"
20. Confirm cancellation
21. Verify status changed to "Cancelled"

**Expected Results:**
- ✅ Facility search in <2s
- ✅ Booking completed in <3s
- ✅ Confirmation displayed in <1s
- ✅ Appointment appears in list
- ✅ Reminder notification scheduled
- ✅ Reschedule completed in <2s
- ✅ Cancellation completed in <1s
- ✅ All operations synced to backend

**Performance Benchmarks:**
- Facility search: <2s
- Booking: <3s
- Confirmation: <1s
- Reschedule: <2s
- Cancellation: <1s

---

### TC-005: Edge Case - Network Interruption During Submission

**Priority:** P2 - High
**Device:** All devices

**Test Steps:**
1. Start assessment
2. Fill all sections
3. Disable network mid-submission
4. Verify assessment saved locally
5. Check queued for sync
6. Enable network
7. Verify automatic sync
8. Confirm data integrity

**Expected Results:**
- ✅ No error message to user
- ✅ Assessment saved locally
- ✅ Queued for later sync
- ✅ Automatic sync when online
- ✅ No data loss

---

### TC-006: Edge Case - App Backgrounding During Form

**Priority:** P2 - High
**Device:** All devices

**Test Steps:**
1. Start assessment
2. Fill partial data
3. Background app
4. Wait 30 seconds
5. Foreground app
6. Verify form data persisted

**Expected Results:**
- ✅ Form data not lost
- ✅ User can continue from where they left off

---

### TC-007: Edge Case - Invalid Blood Pressure Values

**Priority:** P2 - High
**Device:** All devices

**Test Steps:**
1. Navigate to assessment vital signs
2. Enter systolic: 80, diastolic: 140 (invalid)
3. Try to proceed

**Expected Results:**
- ✅ Validation error displayed
- ✅ Cannot proceed with invalid values
- ✅ Error message clear and helpful

---

### TC-008: Edge Case - Concurrent Assessment Submissions

**Priority:** P2 - High
**Device:** All devices

**Test Steps:**
1. Create 10 assessments programmatically (concurrent)
2. Submit all simultaneously
3. Verify queue integrity
4. Verify no data corruption

**Expected Results:**
- ✅ All 10 assessments queued
- ✅ No race conditions
- ✅ All data intact

---

### TC-009: Clinical Validation - Risk Score Accuracy

**Priority:** P1 - Critical
**Device:** Any

**Test Steps:**
1. Create assessment with Likelihood=1, Impact=1
2. Verify score = 1, category = Low
3. Create assessment with Likelihood=5, Impact=5
4. Verify score = 25, category = Critical
5. Test all boundaries (1-5, 6-10, 11-15, 16-20, 21-25)

**Expected Results:**
- ✅ Score = Likelihood × Impact (always)
- ✅ Category mapping correct:
  - 1-5: Low
  - 6-10: Mild
  - 11-15: Moderate
  - 16-20: High
  - 21-25: Critical

---

### TC-010: Performance - Large Dataset Handling

**Priority:** P2 - High
**Device:** Low-end (Samsung Galaxy J2)

**Test Steps:**
1. Create 100 assessments in database
2. Open analytics screen
3. Measure load time
4. Scroll through all assessments
5. Check memory usage

**Expected Results:**
- ✅ Load time <3s
- ✅ Smooth scrolling (no lag)
- ✅ Memory usage <150MB

---

## Performance Benchmarks

### App Launch
- **Low-end devices:** <3 seconds to interactive
- **Mid-range:** <2 seconds
- **High-end:** <1.5 seconds

### Assessment Completion
- **Full flow (symptoms + vitals + save):** <30 seconds
- **Risk calculation:** <1 second
- **PDF generation:** <3 seconds

### Memory Usage
- **Idle:** <100MB
- **Active assessment:** <150MB
- **Peak (PDF generation):** <200MB
- **No memory leaks over 10-minute session**

### Battery Drain
- **Background:** <2% per hour
- **Active use:** <10% per hour
- **GPS active:** <15% per hour

### Network Performance
- **API response time:** <2 seconds on 3G
- **Sync queue processing:** <1 minute for 10 items
- **Timeout handling:** Graceful degradation

---

## Acceptance Criteria

### Automated Tests
- ✅ 0 critical test failures
- ✅ <5 high priority test failures
- ✅ 80% unit test coverage
- ✅ 70% widget test coverage
- ✅ Core integration tests pass
- ✅ `flutter analyze` returns 0 issues

### Manual Tests
- ✅ All critical paths validated
- ✅ Offline functionality works
- ✅ Sync queue operates correctly
- ✅ PDF generation successful
- ✅ GPS recommendations accurate

### Performance
- ✅ All benchmarks met on low-end devices
- ✅ No memory leaks detected
- ✅ Battery drain within limits
- ✅ Network error handling graceful

### Security
- ✅ All security checklist items pass
- ✅ No sensitive data exposed
- ✅ AES-256 encryption verified
- ✅ TLS 1.3 for all API calls
- ✅ Compliance requirements met (Data Privacy Act)

### Accessibility
- ✅ WCAG 2.1 AA compliance
- ✅ Screen reader support (TalkBack/VoiceOver)
- ✅ Touch targets meet minimum size (48x48dp)
- ✅ Color contrast ratios sufficient

---

## Release Decision

### GO Criteria
All of the following must be true:
- All P1 test cases passed
- 0 critical bugs
- <3 high priority bugs
- All performance benchmarks met
- Clinical accuracy validated
- Security scan passed
- Accessibility audit passed

### NO-GO Criteria
Any of the following:
- Any P1 test case failed
- Any critical bug found
- >3 high priority bugs
- Performance benchmark failures
- Clinical algorithm inaccuracy
- Security vulnerability found
- Data loss scenario detected

---

## Test Execution Schedule

### Phase 1: Infrastructure Setup (2 hours)
- Set up test devices
- Configure test environment
- Prepare test data
- Install test builds

### Phase 2: Critical Path Testing (6 hours)
- Execute TC-001 through TC-004
- Document all findings
- Run on all devices
- Test all network conditions

### Phase 3: Edge Case Testing (2 hours)
- Execute TC-005 through TC-008
- Test permission scenarios
- Validate error handling
- Test data corruption scenarios

### Phase 4: Device Matrix Testing (2 hours)
- Run core tests on all 5 devices
- Document device-specific issues
- Validate performance benchmarks
- Generate device compatibility report

---

## Risk Mitigation

### High-Risk Areas
1. **Offline Sync Queue:** Complex logic, potential for data loss
2. **Risk Calculation:** Clinical accuracy is critical
3. **GPS Location:** Unreliable in certain areas
4. **Low-End Devices:** Performance may degrade

### Mitigation Strategies
1. **Extensive offline testing:** Simulate various network scenarios
2. **Clinical validation:** PHC review of all risk calculations
3. **Fallback mechanisms:** Manual facility search if GPS fails
4. **Performance profiling:** Optimize for Samsung Galaxy J2 specifically

---

## Test Deliverables

1. **Test Execution Report** (`test_results.md`)
2. **Bug Report** (if issues found)
3. **Device Compatibility Matrix** (`device_matrix.md`)
4. **Performance Benchmark Report**
5. **Edge Case Documentation** (`edge_cases.md`)
6. **Regression Test Suite** (automated)
7. **GO/NO-GO Recommendation**

---

## Notes

### Critical Reminders
- **DO NOT MODIFY** clinical assessment algorithm without PHC approval
- Risk calculation (Likelihood × Impact = 1-25) is validated by healthcare professionals
- Test it thoroughly but never change its logic
- Low-end device focus: Samsung Galaxy J2 is the primary target
- Offline-first is non-negotiable: Healthcare workers often have poor connectivity
- Patient data security is paramount: Any security vulnerability is critical
- Bilingual testing: Test both English and Filipino languages

### Known Issues (Fixed in M5.2)
- ✅ 401 errors fixed (public endpoint)
- ✅ 500 errors fixed (risk enum mapping)
- ✅ 422 errors fixed (date validation)
- ✅ Date picker blocks past times
- ✅ Appointment ENUM validation working

---

**Document Control:**
Last Updated: January 2025
Next Review: Before each major release
Contact: JH-QA-Guardian
