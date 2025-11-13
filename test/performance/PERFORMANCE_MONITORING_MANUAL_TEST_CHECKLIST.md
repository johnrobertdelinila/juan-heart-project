# Firebase Performance Monitoring - Manual Testing Checklist

**Project:** Juan Heart Mobile
**Feature:** Firebase Performance Monitoring Integration
**Test Version:** 1.0
**Last Updated:** 2025-11-03
**Tester:** JH-QA-Guardian

---

## Overview

This checklist provides comprehensive manual testing procedures for validating the Firebase Performance Monitoring implementation in Juan Heart Mobile. The goal is to ensure all custom traces are correctly firing, metrics are being recorded, and privacy compliance is maintained.

**Important Notes:**
- Firebase Performance data appears in the console **24-48 hours after collection**
- Testing requires a device with internet connectivity
- Analytics must be enabled in privacy settings
- Firebase project must be properly configured

---

## Pre-Test Setup

### 1. Firebase Console Access

- [ ] Access Firebase Console: https://console.firebase.google.com
- [ ] Navigate to Juan Heart Project
- [ ] Open Performance section from left sidebar
- [ ] Verify you have appropriate permissions
- [ ] Note the project ID: `________________`

### 2. Test Device Preparation

- [ ] Device Name: `________________`
- [ ] OS Version: `________________`
- [ ] App Version: `________________`
- [ ] Network: WiFi/4G/3G (circle one)
- [ ] Install latest build with performance monitoring enabled
- [ ] Enable analytics in app privacy settings:
  - Settings → Privacy → Analytics: **ON**
- [ ] Clear app data/cache for fresh start
- [ ] Verify Firebase SDK initialized (check app logs)

### 3. Testing Environment

- [ ] Date/Time: `________________`
- [ ] Tester: `________________`
- [ ] Build Number: `________________`
- [ ] Firebase Performance SDK Version: `0.9.3+7`

---

## Test Categories

## 1. App Launch Test

**Objective:** Verify `app_start` trace captures cold start performance

**Target Performance:** <3s (low-end), <2s (mid-range), <1.5s (high-end)

### Test Steps

1. **Cold Start Test**
   - [ ] Force close Juan Heart app completely
   - [ ] Clear app from recent apps/app switcher
   - [ ] Wait 10 seconds
   - [ ] Launch app from home screen
   - [ ] Start timer when tapping icon
   - [ ] Stop timer when home screen fully visible
   - [ ] Record actual time: `______s`
   - [ ] Result: PASS / FAIL (circle one)

2. **Warm Start Test**
   - [ ] Minimize app (home button)
   - [ ] Wait 5 seconds
   - [ ] Reopen from app switcher
   - [ ] Record time: `______s`
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data (after 24-48h)

- Trace Name: `app_start`
- Duration: Match recorded time
- Attributes: None
- Metrics: None

### Notes

```
[Add any observations, issues, or anomalies]
```

---

## 2. Assessment Flow Test

**Objective:** Verify complete CVD risk assessment traces all phases

**Target Performance:** <30s total assessment time

### Test Scenario A: Assessment with AI

#### Setup
- [ ] Ensure analytics enabled
- [ ] Ensure internet connectivity
- [ ] Navigate to Home screen

#### Test Steps

1. **Start Assessment**
   - [ ] Tap "Start Assessment" button
   - [ ] Record start time: `______`

2. **Symptom Checker Phase**
   - [ ] Select 3+ symptoms (e.g., Chest Pain, Shortness of Breath, Fatigue)
   - [ ] Symptom 1: `________________`
   - [ ] Symptom 2: `________________`
   - [ ] Symptom 3: `________________`
   - [ ] Total symptoms selected: `______`
   - [ ] Tap "Continue"

3. **Vital Signs Phase**
   - [ ] Enter Blood Pressure: `120/80`
   - [ ] Enter Heart Rate: `75 bpm`
   - [ ] Enter Weight: `70 kg`
   - [ ] Enter Height: `170 cm`
   - [ ] All 4 vital signs entered: ✓
   - [ ] Tap "Calculate Risk"

4. **Risk Calculation (AI)**
   - [ ] Verify AI processing indicator appears
   - [ ] Wait for Genkit API response
   - [ ] API response time: `______s` (target: <3s)
   - [ ] Likelihood Score displayed: `______` (1-5)
   - [ ] Impact Score displayed: `______` (1-5)
   - [ ] Final Risk Score: `______` (1-25)
   - [ ] Risk Level: Low / Mild / Moderate / High / Critical (circle one)

5. **Complete Assessment**
   - [ ] Tap "Save Assessment"
   - [ ] Record end time: `______`
   - [ ] Total time: `______s` (target: <30s)
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data

**1. `assessment_flow` trace**
- Duration: ~Total assessment time
- Metrics:
  - `likelihood_score`: Match displayed value
  - `impact_score`: Match displayed value
  - `symptom_count`: Number of symptoms selected
  - `final_score`: likelihood × impact
- Attributes:
  - `used_ai`: `true`

**2. `symptom_checker` trace**
- Duration: Time spent selecting symptoms
- Metrics:
  - `symptom_count`: Number selected

**3. `vital_signs_input` trace**
- Duration: Time spent entering vitals
- Metrics:
  - `vital_signs_count`: 4

**4. `risk_calculation` trace**
- Duration: AI calculation time
- Metrics:
  - `final_score`: Calculated risk score
- Attributes:
  - `calculation_type`: `ai`

**5. `genkit_api_call` trace**
- Duration: API round-trip time (target: <3s)
- Metrics:
  - `response_size_bytes`: API response size
- Attributes:
  - `success`: `true`

### Test Scenario B: Assessment with Rule-Based Calculation

**Repeat steps 1-5 above, but:**
- [ ] Disable AI in settings or simulate AI failure
- [ ] Verify `calculation_type`: `rule_based`
- [ ] Verify `used_ai`: `false`
- [ ] Result: PASS / FAIL

---

## 3. Screen Load Test

**Objective:** Verify `screen_load` traces fire for all instrumented screens

**Target Performance:** <500ms per screen

### Instrumented Screens

#### Screen 1: Home Screen

- [ ] Navigate to Home Screen
- [ ] Record load time: `______ms`
- [ ] Screen fully interactive: ✓
- [ ] Result: PASS / FAIL

**Firebase Console:**
- Trace Name: `screen_load`
- Attribute: `screen_name` = `HomeScreen`
- Duration: <500ms

#### Screen 2: Analytics Screen

- [ ] Navigate to Analytics Screen
- [ ] Record load time: `______ms`
- [ ] Charts render correctly: ✓
- [ ] Result: PASS / FAIL

**Firebase Console:**
- Trace Name: `screen_load`
- Attribute: `screen_name` = `AnalyticsScreen`
- Duration: <500ms

#### Screen 3: Book Appointment Screen

- [ ] Navigate to Book Appointment Screen
- [ ] Record load time: `______ms`
- [ ] Form fields visible: ✓
- [ ] Result: PASS / FAIL

**Firebase Console:**
- Trace Name: `screen_load`
- Attribute: `screen_name` = `BookAppointmentScreen`
- Duration: <500ms

#### Screen 4: Risk Assessment Screen

- [ ] Navigate to Risk Assessment Screen
- [ ] Record load time: `______ms`
- [ ] Assessment form ready: ✓
- [ ] Result: PASS / FAIL

**Firebase Console:**
- Trace Name: `screen_load`
- Attribute: `screen_name` = `RiskAssessmentScreen`
- Duration: <500ms

#### Screen 5: Facility Selection Screen

- [ ] Navigate to Facility Selection Screen
- [ ] Record load time: `______ms`
- [ ] Facilities loaded: ✓
- [ ] GPS permission granted: ✓
- [ ] Result: PASS / FAIL

**Firebase Console:**
- Trace Name: `screen_load`
- Attribute: `screen_name` = `FacilitySelectionScreen`
- Duration: <500ms

---

## 4. Appointment Sync Test

**Objective:** Verify `appointment_sync` trace records sync operations

**Target Performance:** <1 minute for 10 appointments

### Test Scenario A: Successful Sync

#### Setup
- [ ] Create 5 test appointments while **OFFLINE**
- [ ] Appointment 1: Facility `______`, Date `______`
- [ ] Appointment 2: Facility `______`, Date `______`
- [ ] Appointment 3: Facility `______`, Date `______`
- [ ] Appointment 4: Facility `______`, Date `______`
- [ ] Appointment 5: Facility `______`, Date `______`

#### Test Steps

1. **Trigger Sync**
   - [ ] Go **ONLINE** (enable WiFi/data)
   - [ ] Record sync start time: `______`
   - [ ] Wait for sync completion
   - [ ] Record sync end time: `______`
   - [ ] Total sync time: `______s`

2. **Verify Results**
   - [ ] All 5 appointments synced successfully: ✓
   - [ ] Sync queue cleared: ✓
   - [ ] No error messages: ✓
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data

- Trace Name: `appointment_sync`
- Duration: Sync time
- Metrics:
  - `synced_count`: 5
  - `failed_count`: 0

### Test Scenario B: Partial Sync Failure

#### Setup
- [ ] Create 5 appointments offline
- [ ] Simulate backend errors (use invalid facility ID for 2 appointments)

#### Test Steps

1. **Trigger Sync**
   - [ ] Go online
   - [ ] Record sync time: `______s`

2. **Verify Results**
   - [ ] 3 appointments synced: ✓
   - [ ] 2 appointments failed: ✓
   - [ ] Error messages displayed: ✓
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data

- Trace Name: `appointment_sync`
- Metrics:
  - `synced_count`: 3
  - `failed_count`: 2

---

## 5. Genkit AI Test

**Objective:** Verify `genkit_api_call` trace records AI interactions

**Target Performance:** <3s response time

### Test Scenario A: Successful AI Call

1. **Setup**
   - [ ] Ensure internet connectivity
   - [ ] Enable AI assessment in settings
   - [ ] Start new assessment

2. **Execute**
   - [ ] Complete symptoms and vitals
   - [ ] Tap "Calculate Risk" (AI)
   - [ ] Record API start time: `______`
   - [ ] Record API end time: `______`
   - [ ] API response time: `______s` (target: <3s)
   - [ ] Risk score displayed: `______`
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data

- Trace Name: `genkit_api_call`
- Duration: <3000ms
- Metrics:
  - `response_size_bytes`: >0
- Attributes:
  - `success`: `true`

### Test Scenario B: Failed AI Call (Fallback to Rule-Based)

1. **Setup**
   - [ ] Disable internet after entering symptoms
   - [ ] Or simulate Genkit API error

2. **Execute**
   - [ ] Tap "Calculate Risk"
   - [ ] Verify fallback to rule-based calculation
   - [ ] Record fallback time: `______s`
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data

- Trace Name: `genkit_api_call`
- Duration: Timeout or error time
- Metrics:
  - `response_size_bytes`: 0
- Attributes:
  - `success`: `false`

---

## 6. Network Monitoring Test

**Objective:** Verify automatic HTTP trace collection

**Firebase automatically tracks network requests. No custom code needed.**

### Test Network Calls

1. **GET /mobile/facilities**
   - [ ] Trigger facility fetch (open Facility Selection Screen)
   - [ ] Record network activity in Firebase Console
   - [ ] Response time: `______ms`
   - [ ] Status code: 200
   - [ ] Result: PASS / FAIL

2. **POST /api/appointments**
   - [ ] Create and sync appointment
   - [ ] Check Firebase Console for POST request
   - [ ] Response time: `______ms`
   - [ ] Status code: 200/201
   - [ ] Result: PASS / FAIL

3. **POST {GENKIT_URL}**
   - [ ] Trigger AI assessment
   - [ ] Check Firebase Console for Genkit API call
   - [ ] Response time: `______ms` (target: <3s)
   - [ ] Status code: 200
   - [ ] Result: PASS / FAIL

### Expected Firebase Console Data

Navigate to: **Performance → Network Requests**

- [ ] All network calls logged automatically
- [ ] Response times recorded
- [ ] Status codes captured
- [ ] Payload sizes tracked

---

## 7. Privacy Compliance Test

**Objective:** Verify performance monitoring respects user privacy settings

### Test Scenario A: Analytics Disabled

1. **Setup**
   - [ ] Navigate to Settings → Privacy
   - [ ] Disable "Analytics & Performance"
   - [ ] Confirm setting saved

2. **Execute**
   - [ ] Complete full assessment flow
   - [ ] Navigate to multiple screens
   - [ ] Create appointments
   - [ ] Trigger sync

3. **Verify**
   - [ ] App functions normally: ✓
   - [ ] No performance data sent to Firebase: ✓
   - [ ] No errors in logs: ✓
   - [ ] Result: PASS / FAIL

4. **Firebase Console Check (after 24-48h)**
   - [ ] No traces recorded during disabled period
   - [ ] Privacy respected: ✓

### Test Scenario B: Analytics Re-Enabled

1. **Setup**
   - [ ] Re-enable "Analytics & Performance"
   - [ ] Confirm setting saved

2. **Execute**
   - [ ] Repeat assessment flow
   - [ ] Verify traces resume

3. **Verify**
   - [ ] Traces fire correctly: ✓
   - [ ] Data appears in console: ✓
   - [ ] Result: PASS / FAIL

---

## 8. Error Handling Test

**Objective:** Verify graceful degradation when Firebase unavailable

### Test Scenarios

1. **Airplane Mode ON**
   - [ ] Enable airplane mode
   - [ ] Complete assessment
   - [ ] Verify app doesn't crash: ✓
   - [ ] Verify traces queue locally: ✓
   - [ ] Disable airplane mode
   - [ ] Verify traces upload: ✓
   - [ ] Result: PASS / FAIL

2. **Firebase Service Unavailable**
   - [ ] Simulate Firebase service outage (if possible)
   - [ ] Use app normally
   - [ ] Verify no crashes: ✓
   - [ ] Verify error handling: ✓
   - [ ] Result: PASS / FAIL

---

## Firebase Console Validation Guide

**After 24-48 hours, validate data in Firebase Console:**

### Step 1: Access Firebase Console

1. Navigate to: https://console.firebase.google.com
2. Select: **Juan Heart Project**
3. Click: **Performance** (left sidebar)
4. Wait for dashboard to load

### Step 2: View Custom Traces

1. Click: **Custom traces** tab
2. Select time range: Last 7 days
3. Sort by: Trace name (alphabetically)

### Step 3: Validate Each Trace

#### ✓ `app_start` Trace

- [ ] Trace appears in list
- [ ] Average duration: <3s (low-end), <2s (mid-range), <1.5s (high-end)
- [ ] Sample count: >0
- [ ] No unusual spikes
- [ ] P50, P90, P99 percentiles within targets

#### ✓ `assessment_flow` Trace

- [ ] Trace appears in list
- [ ] Average duration: 10-30s
- [ ] Metrics visible:
  - [ ] `likelihood_score`: 1-5 range
  - [ ] `impact_score`: 1-5 range
  - [ ] `symptom_count`: 0-10 range
  - [ ] `final_score`: 1-25 range
- [ ] Attributes visible:
  - [ ] `used_ai`: true/false
- [ ] Sample count matches test executions

#### ✓ `symptom_checker` Trace

- [ ] Trace appears in list
- [ ] Average duration: <5s
- [ ] Metric `symptom_count` recorded

#### ✓ `vital_signs_input` Trace

- [ ] Trace appears in list
- [ ] Average duration: <10s
- [ ] Metric `vital_signs_count` recorded

#### ✓ `risk_calculation` Trace

- [ ] Trace appears in list
- [ ] Average duration: <3s (AI), <1s (rule-based)
- [ ] Metric `final_score` recorded
- [ ] Attribute `calculation_type`: ai/rule_based

#### ✓ `appointment_sync` Trace

- [ ] Trace appears in list
- [ ] Average duration: <60s for 10 items
- [ ] Metrics recorded:
  - [ ] `synced_count`
  - [ ] `failed_count`

#### ✓ `genkit_api_call` Trace

- [ ] Trace appears in list
- [ ] Average duration: <3s
- [ ] Metric `response_size_bytes` recorded
- [ ] Attribute `success`: true/false

#### ✓ `screen_load` Trace

- [ ] Trace appears in list
- [ ] Average duration: <500ms
- [ ] Attribute `screen_name` shows different screens:
  - [ ] HomeScreen
  - [ ] AnalyticsScreen
  - [ ] BookAppointmentScreen
  - [ ] RiskAssessmentScreen
  - [ ] FacilitySelectionScreen

### Step 4: View Network Requests

1. Click: **Network requests** tab
2. Sort by: Request count (descending)

#### Validate Key Endpoints

- [ ] GET /mobile/facilities (avg <2s)
- [ ] POST /api/appointments (avg <2s)
- [ ] POST {GENKIT_URL} (avg <3s)
- [ ] Status codes: Mostly 200/201
- [ ] Failure rate: <5%

### Step 5: Performance Trends

1. Click: **Dashboard** tab
2. Review charts:
   - [ ] App start time trend (should be stable)
   - [ ] Screen rendering (should be <500ms)
   - [ ] Network requests (should be <2s avg)
   - [ ] Success rates (should be >95%)

### Step 6: Generate Report

1. Click: **Download CSV** button
2. Export data for offline analysis
3. Share with development team

---

## Test Results Summary

### Overall Test Statistics

- **Total Test Cases:** 50+
- **Passed:** `______`
- **Failed:** `______`
- **Blocked:** `______`
- **Pass Rate:** `______%`

### Critical Findings

**Blockers (Must Fix Before Release):**
1.
2.
3.

**High Priority Issues:**
1.
2.
3.

**Medium Priority Issues:**
1.
2.
3.

**Low Priority / Enhancement:**
1.
2.
3.

---

## Performance Benchmarks Summary

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| App Start (Low-End) | <3s | ______s | ✓ / ✗ |
| App Start (Mid-Range) | <2s | ______s | ✓ / ✗ |
| App Start (High-End) | <1.5s | ______s | ✓ / ✗ |
| Assessment Flow | <30s | ______s | ✓ / ✗ |
| Screen Load | <500ms | ______ms | ✓ / ✗ |
| Genkit API | <3s | ______s | ✓ / ✗ |
| Appointment Sync (10) | <60s | ______s | ✓ / ✗ |

---

## Device Testing Matrix

Test across multiple devices for comprehensive coverage:

### Low-End Devices (Critical)

**Device:** Samsung Galaxy J2 (2GB RAM, Android 5.0)
- [ ] App Start: `______s` (target: <3s)
- [ ] Assessment Flow: `______s` (target: <30s)
- [ ] Screen Load Avg: `______ms` (target: <500ms)
- [ ] Overall Performance: Acceptable / Needs Improvement

**Device:** Oppo A3s (2GB RAM, Android 8.1)
- [ ] App Start: `______s`
- [ ] Assessment Flow: `______s`
- [ ] Screen Load Avg: `______ms`
- [ ] Overall Performance: Acceptable / Needs Improvement

### Mid-Range Devices

**Device:** Samsung A52 (6GB RAM, Android 11)
- [ ] App Start: `______s` (target: <2s)
- [ ] Assessment Flow: `______s` (target: <20s)
- [ ] Screen Load Avg: `______ms` (target: <300ms)
- [ ] Overall Performance: Excellent / Good / Fair

### High-End Devices

**Device:** Samsung S23 (8GB RAM, Android 13)
- [ ] App Start: `______s` (target: <1.5s)
- [ ] Assessment Flow: `______s` (target: <15s)
- [ ] Screen Load Avg: `______ms` (target: <200ms)
- [ ] Overall Performance: Excellent / Good / Fair

---

## Network Condition Testing

### 2G Edge (240 Kbps) - Rural Philippines

- [ ] App functions: ✓ / ✗
- [ ] Genkit API timeout: `______s`
- [ ] Facility fetch: `______s`
- [ ] User experience: Acceptable / Poor

### 3G (1 Mbps) - Common in Provinces

- [ ] App functions: ✓ / ✗
- [ ] Genkit API: `______s` (target: <5s)
- [ ] Facility fetch: `______s` (target: <3s)
- [ ] User experience: Good / Acceptable

### 4G (10 Mbps) - Urban Areas

- [ ] App functions: ✓ / ✗
- [ ] Genkit API: `______s` (target: <3s)
- [ ] Facility fetch: `______s` (target: <2s)
- [ ] User experience: Excellent / Good

### WiFi

- [ ] Optimal performance: ✓
- [ ] All targets met: ✓

### Offline Mode

- [ ] Assessment works offline: ✓
- [ ] Sync queue properly stores data: ✓
- [ ] Reconnection syncs automatically: ✓

---

## Final Verdict

### Release Decision: **GO / NO-GO** (circle one)

**Rationale:**

```
[Provide detailed explanation for your decision]

- All critical traces firing correctly
- Performance targets met on low-end devices
- Privacy compliance verified
- No critical bugs found
- Firebase Console validation complete

OR

- [List blocking issues preventing release]
```

---

## Recommendations

### For Development Team

1.
2.
3.

### For Product Team

1.
2.
3.

### For Next Release

1.
2.
3.

---

## Appendix A: Firebase Console Screenshots

**Attach screenshots of:**
1. Custom traces dashboard
2. Assessment flow trace details
3. Network requests summary
4. Performance trends (7-day view)
5. Any anomalies or issues found

---

## Appendix B: Test Logs

**Attach relevant logs:**
- Flutter console logs during testing
- Firebase Performance debug logs
- Error logs (if any issues occurred)
- Network request logs

---

## Appendix C: Known Issues

**Document any known issues that are not blockers:**

1. **Issue:**
   - **Severity:** Low / Medium / High
   - **Impact:**
   - **Workaround:**
   - **Ticket:**

2. **Issue:**
   - **Severity:** Low / Medium / High
   - **Impact:**
   - **Workaround:**
   - **Ticket:**

---

**Tester Signature:** ___________________
**Date:** ___________________
**QA Lead Approval:** ___________________
**Date:** ___________________

---

**END OF CHECKLIST**
