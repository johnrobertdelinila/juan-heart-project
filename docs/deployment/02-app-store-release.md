# App Store Production Release Guide

**Status:** BLOCKED - Apple Developer Account Required
**Estimated Time:** 4-6 hours (initial release) | 2-3 hours (subsequent releases)
**Last Updated:** January 2025
**Document Owner:** JH-Git-Guardian

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [iOS Build Configuration](#ios-build-configuration)
- [Building Release IPA](#building-release-ipa)
- [TestFlight Beta Testing](#testflight-beta-testing)
- [App Store Submission](#app-store-submission)
- [App Store Review Guidelines](#app-store-review-guidelines)
- [Metadata & Screenshots](#metadata--screenshots)
- [Review Process](#review-process)
- [Handling Rejections](#handling-rejections)
- [Post-Approval Release](#post-approval-release)

---

## Prerequisites

### Apple Developer Program Membership
**BLOCKER:** Juan Heart Mobile currently does not have an Apple Developer account.

#### Required Account Setup
```
1. Enroll in Apple Developer Program
   - Cost: $99/year (organization account recommended)
   - URL: https://developer.apple.com/programs/enroll/
   - Timeline: 1-5 business days for approval

2. Create App ID
   - Bundle Identifier: com.juanheart.mobile
   - Capabilities: Push Notifications, Location Services

3. Generate Certificates
   - iOS Distribution Certificate
   - Apple Push Notification Service (APNs) certificate

4. Create Provisioning Profile
   - Type: App Store Distribution
   - Link to App ID and Distribution Certificate

5. App Store Connect Setup
   - Create app record
   - Configure app information
   - Set up TestFlight
```

#### Estimated Setup Timeline
| Task | Duration | Owner |
|------|----------|-------|
| Developer account approval | 1-5 days | Admin |
| Certificate generation | 30 minutes | JH-Git-Guardian |
| Provisioning profile setup | 30 minutes | JH-Git-Guardian |
| App Store Connect config | 2 hours | JH-Git-Guardian |
| TestFlight setup | 1 hour | JH-Git-Guardian |

### Required Access
- [ ] Apple Developer account (organization)
- [ ] App Store Connect access (Admin or App Manager role)
- [ ] Xcode 15+ installed on macOS device
- [ ] Valid iOS Distribution Certificate
- [ ] App-specific password for fastlane (optional, for automation)

---

## Pre-Deployment Checklist

### Code Quality Gates (Same as Android)
```bash
# Run from project root
cd /Users/johnrobertdelinila/AndroidStudioProjects/Juan-Heart-Mobile

# 1. Run all tests
flutter test
# Expected: All tests pass, coverage ≥80%

# 2. Run analyzer
flutter analyze
# Expected: No issues found

# 3. iOS-specific checks
flutter build ios --release --no-codesign
# Expected: Build succeeds without errors
```

### iOS-Specific Requirements

#### Privacy Manifest (REQUIRED as of May 2024)
```xml
<!-- File: ios/Runner/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeHealthData</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryLocation</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>NSPrivacyAccessedAPICategoryLocationReasonAppFunctionality</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

#### Info.plist Permissions
```xml
<!-- File: ios/Runner/Info.plist -->
<!-- Add/verify these keys -->
<dict>
    <!-- Location Services -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Juan Heart needs your location to find nearby health facilities and emergency services.</string>

    <!-- Camera (for future QR code scanning) -->
    <key>NSCameraUsageDescription</key>
    <string>Juan Heart needs camera access to scan QR codes at health facilities.</string>

    <!-- Photo Library (for profile pictures) -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Juan Heart needs access to save health reports and assessment results.</string>

    <!-- Calendar (for appointment reminders) -->
    <key>NSCalendarsUsageDescription</key>
    <string>Juan Heart can add appointment reminders to your calendar.</string>
</dict>
```

#### App Transport Security
```xml
<!-- File: ios/Runner/Info.plist -->
<!-- Ensure secure connections -->
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>  <!-- MUST be false for App Store -->
        <key>NSExceptionDomains</key>
        <dict>
            <!-- Only add exceptions for specific domains if needed -->
            <key>api.juanheart.ph</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSTemporaryExceptionMinimumTLSVersion</key>
                <string>TLSv1.3</string>
            </dict>
        </dict>
    </dict>
</dict>
```

---

## iOS Build Configuration

### Update Version and Build Number
```yaml
# File: pubspec.yaml
version: 1.5.0+15  # Same as Android version

# iOS uses same version format:
# - Version: 1.5.0 (displayed to users)
# - Build: 15 (internal tracking)
```

### Configure Xcode Project
```bash
# Open Xcode project
open ios/Runner.xcworkspace

# Manual steps in Xcode:
# 1. Select "Runner" project in left sidebar
# 2. Select "Runner" target under TARGETS
# 3. General tab:
#    - Display Name: Juan Heart
#    - Bundle Identifier: com.juanheart.mobile
#    - Version: 1.5.0
#    - Build: 15
# 4. Signing & Capabilities:
#    - Team: [Select your Apple Developer team]
#    - Provisioning Profile: [Select App Store profile]
#    - Signing Certificate: Apple Distribution
```

### Automated Configuration (Recommended)
```bash
# Use fastlane to manage versioning
# File: ios/fastlane/Fastfile

default_platform(:ios)

platform :ios do
  desc "Increment build number"
  lane :bump_build do
    increment_build_number(
      xcodeproj: "Runner.xcodeproj",
      build_number: latest_testflight_build_number + 1
    )
  end

  desc "Set version number"
  lane :set_version do |options|
    increment_version_number(
      xcodeproj: "Runner.xcodeproj",
      version_number: options[:version]
    )
  end
end

# Usage:
# cd ios
# fastlane set_version version:1.5.0
# fastlane bump_build
```

---

## Building Release IPA

### Method 1: Flutter Build + Xcode Archive (Manual)

#### Step 1: Flutter Build
```bash
# Clean and build iOS release
flutter clean
flutter pub get
flutter build ios --release

# Output: ios/Flutter/Release.xcframework
# This does NOT create an IPA yet
```

#### Step 2: Xcode Archive
```bash
# Open Xcode workspace
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device (arm64)" as target (NOT simulator)
# 2. Product → Archive (Cmd+Shift+B)
# 3. Wait for archive to complete (5-10 minutes)
# 4. Organizer window opens automatically
```

#### Step 3: Export IPA
```bash
# In Xcode Organizer:
# 1. Select the archive
# 2. Click "Distribute App"
# 3. Select "App Store Connect"
# 4. Click "Upload"
# 5. Select distribution options:
#    - ✅ Upload symbols (for crash reports)
#    - ✅ Manage version and build number
#    - ❌ Strip Swift symbols (keep for debugging)
# 6. Review content (verify entitlements)
# 7. Click "Upload"
# 8. Wait for processing (10-30 minutes)
```

### Method 2: Fastlane (Automated - RECOMMENDED)

#### Setup Fastlane (One-time)
```bash
# Install fastlane
sudo gem install fastlane

# Initialize for iOS
cd ios
fastlane init

# Answer prompts:
# - Package name: com.juanheart.mobile
# - Apple ID: your-apple-id@example.com
# - App-specific password: [create at appleid.apple.com]
```

#### Configure Fastlane
```ruby
# File: ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Push to TestFlight"
  lane :beta do
    # Ensure clean state
    clean_build_artifacts

    # Increment build number
    increment_build_number(
      xcodeproj: "Runner.xcodeproj",
      build_number: latest_testflight_build_number + 1
    )

    # Build app
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.juanheart.mobile" => "Juan Heart App Store Profile"
        }
      }
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      apple_id: "your-apple-id@example.com"
    )

    # Notify team
    slack(
      message: "Juan Heart v#{get_version_number} build #{get_build_number} uploaded to TestFlight!",
      success: true
    )
  end

  desc "Release to App Store"
  lane :release do
    # Promote TestFlight build to production
    deliver(
      submit_for_review: true,
      automatic_release: false,  # Manual release after approval
      force: true,
      skip_screenshots: false,
      skip_metadata: false
    )
  end
end
```

#### Build and Upload
```bash
cd ios

# Upload to TestFlight
fastlane beta

# After TestFlight validation, submit to App Store
fastlane release
```

---

## TestFlight Beta Testing

### Why TestFlight?
- **Pre-submission validation:** Catch issues before App Store review
- **Beta tester feedback:** Get real-world usage data
- **Gradual rollout:** Test with small group before production
- **REQUIRED:** Apple processes builds through TestFlight first

### Configure TestFlight

#### 1. Internal Testing (Apple Employees/Developers)
```
App Store Connect → TestFlight → Internal Testing
- Add up to 100 internal testers
- Builds available immediately after processing
- No beta review required
```

#### 2. External Testing (Beta Testers)
```
App Store Connect → TestFlight → External Testing
- Add up to 10,000 external testers
- Requires beta review (1-24 hours)
- Create test groups:
  - "Healthcare Providers" (doctors, nurses)
  - "Patients" (general users)
  - "QA Team" (internal testers)
```

### Beta Testing Process

#### Timeline
| Stage | Duration | Participants | Focus |
|-------|----------|--------------|-------|
| Internal Testing | 1-2 days | 5-10 developers | Smoke testing, critical bugs |
| External Beta 1 | 3-5 days | 20-50 healthcare providers | Clinical workflow validation |
| External Beta 2 | 5-7 days | 100-200 patients | User experience, edge cases |
| Production Submission | - | - | Full App Store review |

#### Success Criteria for Beta
- Zero crashes in critical flows (assessment, booking)
- No data loss or sync failures
- All TestFlight testers complete at least 1 full assessment
- Average rating ≥4.0 stars from beta testers
- No major UI bugs reported

### TestFlight Checklist
```
Before submitting to TestFlight:
- [ ] Build number incremented
- [ ] Version matches pubspec.yaml
- [ ] All tests passing (flutter test)
- [ ] No Xcode build warnings
- [ ] Privacy manifest included
- [ ] Info.plist permissions accurate
- [ ] Export compliance set (non-encryption or declaration)

After TestFlight upload:
- [ ] Wait for processing (10-30 minutes)
- [ ] Add "What to Test" notes for beta testers
- [ ] Invite internal testers
- [ ] Monitor crash reports in Xcode Organizer
- [ ] Review beta tester feedback
```

---

## App Store Submission

### App Store Connect Configuration

#### App Information
```
App Store Connect → My Apps → Juan Heart Mobile → App Information

Primary Language: English (US)
Secondary Language: Filipino (Tagalog) [if localized]

Name: Juan Heart - CVD Risk Tool
Subtitle: Heart Health Assessment for Filipinos (max 30 chars)

Category:
- Primary: Medical
- Secondary: Health & Fitness

Content Rating: 4+ (Medical/Treatment Information)
```

#### Pricing and Availability
```
App Store Connect → Pricing and Availability

Price: Free
Availability:
- ✅ Philippines (primary market)
- ✅ All other countries (optional)

Pre-Order: No (for initial release)
```

#### Privacy Information (CRITICAL)
```
App Store Connect → App Privacy

Data Collection:
✅ Health and Fitness Data
  - CVD risk assessment scores
  - Blood pressure, cholesterol levels
  - Medical history responses
  - Linked to user identity
  - Purpose: App functionality, Analytics

✅ Location Data
  - Precise location (GPS)
  - Purpose: Find nearby health facilities
  - Linked to user identity

✅ Contact Information
  - Name, email, phone number
  - Purpose: Account creation, appointments
  - Linked to user identity

❌ Tracking Data
  - We do NOT track users across apps/websites

Data Retention:
- User can request deletion via settings
- Data deleted within 30 days of request
```

### Version Submission

#### Create New Version
```
App Store Connect → My Apps → Juan Heart Mobile → iOS App
Click "+ Version or Platform" → iOS
Enter version: 1.5.0
```

#### What's New in This Version
```markdown
# Template (4000 character limit)
What's New in Juan Heart v1.5.0

NEW FEATURES
• AI-Powered Risk Assessment: Get instant CVD risk scores with Google Gemini (requires consent)
• Appointment History Export: Download complete appointment records as PDF
• Enhanced Offline Mode: Complete assessments without internet, sync when reconnected

IMPROVEMENTS
• GPS Facility Search: Now shows 8 nearby health facilities with accurate distances
• Faster Sync: Improved reliability with automatic retry for failed uploads
• Cleaner Interface: Material Design icons replace emojis for professional appearance

BUG FIXES
• Fixed date picker not allowing future appointment dates
• Resolved crash when viewing analytics offline
• Fixed sync errors for users with special characters in names

PRIVACY & SECURITY
• All data encrypted with AES-256
• TLS 1.3 for secure connections
• HIPAA/PDPA compliant (healthcare data protection)

CLINICAL VALIDATION
This release has been validated by the Public Health Council of the Philippines. The risk assessment algorithm remains unchanged and clinically accurate.

---
Questions? Contact support@juanheart.ph
Privacy Policy: https://juanheart.ph/privacy
```

---

## App Store Review Guidelines

### Critical Guidelines for Juan Heart

#### Guideline 5.1.1: Data Collection and Storage
**Requirement:** Apps that collect health data MUST:
- ✅ Clearly disclose data collection in Privacy Policy
- ✅ Obtain explicit user consent before collecting health data
- ✅ Provide option to delete all user data
- ✅ Use encryption for sensitive data (AES-256)

**Juan Heart Compliance:**
```dart
// Implemented in lib/services/privacy_service.dart
// - Explicit consent dialog before first assessment
// - User can revoke consent in settings
// - Data deletion request feature available
```

#### Guideline 5.1.5: Location Services
**Requirement:** Apps using location MUST:
- ✅ Explain why location is needed (in Info.plist)
- ✅ Request only when-in-use permission (NOT always)
- ✅ Function without location (degrade gracefully)

**Juan Heart Compliance:**
```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Juan Heart needs your location to find nearby health facilities and emergency services.</string>

<!-- App works without location, but facility search requires it -->
```

#### Guideline 2.3.1: Accurate Metadata
**Requirement:**
- ✅ Screenshots MUST show actual app functionality (no mockups)
- ✅ Description MUST match app behavior
- ✅ No misleading health claims (e.g., "cure", "diagnose")

**Juan Heart Compliance:**
- Use phrase "risk assessment tool" NOT "diagnostic tool"
- Screenshots taken from actual app (not Figma designs)
- Clearly state: "Not a substitute for professional medical advice"

#### Guideline 4.5.4: Location Services - VPN Apps
**Requirement:** Apps using GPS MUST NOT:
- ❌ Track users without consent
- ❌ Share location with third parties without disclosure
- ❌ Use location for advertising

**Juan Heart Compliance:**
- Location only used for facility search (disclosed in privacy manifest)
- No third-party analytics tracking location
- No advertising in app

### Medical App Specific Guidelines

#### Required Disclaimers
```
App Description MUST include:
"Juan Heart is a cardiovascular disease risk assessment tool designed for
educational purposes and initial screening. It is NOT a diagnostic tool and
should NOT replace professional medical advice. Always consult a qualified
healthcare provider for medical decisions."

"Developed in collaboration with the Public Health Council of the Philippines
and the University of Cordilleras."
```

#### Prohibited Claims
- ❌ "Diagnose heart disease"
- ❌ "Cure cardiovascular conditions"
- ❌ "Replace doctor visits"
- ❌ "FDA/medical authority approved" (unless actually approved)

#### Allowed Claims
- ✅ "Assess cardiovascular disease risk"
- ✅ "Educational screening tool"
- ✅ "Clinical decision support"
- ✅ "Clinically validated algorithm"

---

## Metadata & Screenshots

### App Store Screenshots

#### Required Sizes (iPhone)
| Device | Resolution | Required |
|--------|-----------|----------|
| 6.7" Display (iPhone 15 Pro Max) | 1290 x 2796 | ✅ Yes |
| 6.5" Display (iPhone 11 Pro Max) | 1242 x 2688 | ✅ Yes |
| 5.5" Display (iPhone 8 Plus) | 1242 x 2208 | ⚠️ Optional |

#### Screenshot Guidelines
1. **Minimum:** 3 screenshots, **Maximum:** 10 screenshots
2. **Order matters:** First 3 appear in search results
3. **No text overlays** that duplicate App Store text
4. **Show actual app UI** (not mockups or marketing graphics)

#### Recommended Screenshots for Juan Heart
```
Order:
1. Home Screen - "Your Heart Health Hub" (shows main navigation)
2. Risk Assessment Screen - "Quick CVD Risk Screening" (shows questionnaire)
3. Results Screen - "Understand Your Risk Level" (shows risk score with chart)
4. Facility Locator - "Find Nearby Health Facilities" (shows map with pins)
5. Appointments Screen - "Book & Manage Appointments" (shows calendar)
6. Analytics Dashboard - "Track Your Health Trends" (shows graphs)
```

#### Creating Screenshots
```bash
# Use iOS Simulator to capture screenshots
# 1. Open Xcode → Product → Destination → Select simulator:
#    - iPhone 15 Pro Max (6.7")
#    - iPhone 11 Pro Max (6.5")

# 2. Run app in simulator
flutter run -d "iPhone 15 Pro Max"

# 3. Navigate to desired screen
# 4. Press Cmd+S to save screenshot (saved to Desktop)

# 5. Repeat for all required screens
```

### App Preview Videos (Optional but Recommended)

#### Requirements
- **Duration:** 15-30 seconds
- **Resolution:** Match screenshot sizes
- **Format:** MP4 or MOV
- **Audio:** Optional (no music with lyrics)
- **Captions:** Recommended for accessibility

#### Video Script for Juan Heart (30 seconds)
```
0:00-0:05: App icon animation → Home screen (text: "Juan Heart - Your CVD Companion")
0:05-0:10: Swipe through questionnaire (text: "Answer simple health questions")
0:10-0:15: Risk score animation (text: "Get instant risk assessment")
0:15-0:20: Facility map with pins (text: "Find nearby health facilities")
0:20-0:25: Book appointment flow (text: "Schedule consultations easily")
0:25-0:30: App icon with tagline (text: "Juan Heart - Heart Health for Filipinos")
```

### App Description

#### Template (4000 character limit)
```markdown
# Juan Heart - Cardiovascular Disease Risk Assessment

Juan Heart is a clinically validated mobile tool designed to assess cardiovascular disease (CVD) risk for Filipinos. Developed in collaboration with the Public Health Council of the Philippines and the University of Cordilleras, Juan Heart empowers you to take control of your heart health.

## KEY FEATURES

🩺 CVD Risk Assessment
Answer a quick questionnaire to calculate your CVD risk score using a clinically validated algorithm (Likelihood × Impact = 1-25). Understand your risk level: Low, Mild, Moderate, High, or Critical.

🤖 AI-Powered Insights (Optional)
Enable AI-powered assessments using Google Gemini for instant risk scoring. Your consent is required and can be revoked anytime.

🏥 Find Nearby Facilities
Use GPS to locate the nearest health facilities offering CVD screening and treatment. Get directions and contact information instantly.

📅 Appointment Booking
Schedule consultations with healthcare providers directly from the app. Manage appointments, receive reminders, and view your appointment history.

📊 Health Analytics
Track your CVD risk over time with interactive charts. Export your assessment history and appointment records as PDF for sharing with your doctor.

🌐 Offline Mode
Complete assessments even without internet. Your data syncs automatically when you reconnect.

🔒 Privacy & Security
- AES-256 encryption for all sensitive data
- TLS 1.3 secure connections
- HIPAA/PDPA compliant
- You control your data - request deletion anytime

## WHO IS JUAN HEART FOR?

- Individuals concerned about heart health
- Patients with CVD risk factors (hypertension, diabetes, family history)
- Healthcare providers conducting community screenings
- Public health workers in rural areas with limited connectivity

## IMPORTANT DISCLAIMER

Juan Heart is an educational screening tool and clinical decision support system. It is NOT a diagnostic tool and should NOT replace professional medical advice. Always consult a qualified healthcare provider for medical decisions.

## CLINICAL VALIDATION

The risk assessment algorithm has been validated by the Public Health Council of the Philippines and aligns with international CVD screening guidelines.

## SUPPORT

- Email: support@juanheart.ph
- Privacy Policy: https://juanheart.ph/privacy
- Terms of Service: https://juanheart.ph/terms

## LANGUAGES

- English
- Filipino (Tagalog)

Download Juan Heart today and take the first step toward better heart health!
```

### Keywords (100 character limit)
```
heart health,CVD,cardiovascular,risk assessment,health screening,
medical tool,heart disease,Filipino health,PHC,health facilities
```

### Support URL
```
https://juanheart.ph/support
```

### Marketing URL (Optional)
```
https://juanheart.ph
```

### Privacy Policy URL (REQUIRED)
```
https://juanheart.ph/privacy
```

---

## Review Process

### Submission Checklist
```
Before clicking "Submit for Review":
- [ ] All metadata filled (name, description, keywords, URLs)
- [ ] Screenshots uploaded for all required sizes
- [ ] App Privacy details accurate
- [ ] Export Compliance declared
- [ ] Content Rights verified (own all content)
- [ ] Advertising Identifier usage disclosed (if applicable)
- [ ] Age Rating questionnaire completed
- [ ] TestFlight build selected
- [ ] "What's New" text added
- [ ] Contact information current (for App Review team)
```

### Export Compliance
```
App Store Connect → Version Information → Export Compliance

Question: "Does your app use encryption?"
Answer: YES (AES-256 for local data, TLS for network)

Question: "Is encryption limited to standard encryption?"
Answer: YES (standard AES, no custom crypto)

Result: No export documentation required (qualifies for exemption)
Documentation: Self-classify as Category 5 Part 2 (ECCN 5D992)
```

### Submit for Review
```
App Store Connect → Version 1.5.0 → Submit for Review

App Review Information:
- First Name: Juan Heart
- Last Name: Support Team
- Phone: +63-XXX-XXX-XXXX
- Email: support@juanheart.ph

Demo Account (REQUIRED for apps requiring login):
- Username: reviewer@juanheart.ph
- Password: ReviewPass2025!
- Notes: "Test account pre-loaded with sample health data"

Notes for Reviewer:
"Juan Heart is a CVD risk assessment tool for Filipino communities.

KEY FEATURES TO TEST:
1. Complete a CVD risk assessment (Home → Heart Risk Assessment)
2. View risk score and recommendations
3. Find nearby facilities (Home → Nearby Facilities - requires location permission)
4. Book an appointment (select facility → choose date/time)

OFFLINE MODE:
- Enable Airplane Mode
- Complete an assessment
- Disable Airplane Mode → data syncs automatically

AI FEATURE (Optional):
- Enable AI consent in Settings
- Complete assessment with AI-powered scoring

Demo account includes pre-existing assessments for analytics testing.

Privacy Policy: https://juanheart.ph/privacy
Contact: support@juanheart.ph"
```

### Review Timeline
| Stage | Duration | Status |
|-------|----------|--------|
| **Waiting for Review** | 1-3 days | Pending in queue |
| **In Review** | 4-24 hours | Active testing |
| **Pending Developer Release** | N/A | Approved, awaiting manual release |
| **Ready for Sale** | Immediate | Live on App Store |

---

## Handling Rejections

### Common Rejection Reasons for Medical Apps

#### 1. Guideline 5.1.1 (iv) - Health Data
**Reason:** "Your app collects health data but doesn't provide a clear privacy policy link."

**Fix:**
```
1. Verify Privacy Policy URL is accessible: https://juanheart.ph/privacy
2. Ensure privacy policy covers:
   - What health data is collected (CVD risk scores, BP, cholesterol)
   - How data is used (risk assessment, analytics)
   - How data is stored (AES-256 encryption)
   - User rights (data deletion, export)
3. Add privacy policy link in app settings
4. Resubmit with note: "Privacy policy updated and accessible at [URL]"
```

#### 2. Guideline 2.3.1 - Accurate Metadata
**Reason:** "Screenshots contain misleading marketing text."

**Fix:**
```
1. Remove any text overlays claiming "cure" or "diagnose"
2. Re-capture screenshots showing actual app UI
3. Ensure screenshots match current app version
4. Resubmit with note: "Screenshots updated to show actual app functionality without marketing text"
```

#### 3. Guideline 2.1 - App Completeness
**Reason:** "App crashed during review on assessment submission."

**Fix:**
```
1. Reproduce crash with provided device logs
2. Fix bug (likely network timeout or null safety issue)
3. Upload new build to TestFlight
4. Test thoroughly with demo account
5. Resubmit with note: "Critical crash fixed in build [new build number]. Tested on iPhone [model] running iOS [version]."
```

#### 4. Guideline 4.5.4 - Location Services
**Reason:** "App requests location but doesn't explain why in Info.plist."

**Fix:**
```xml
<!-- ios/Runner/Info.plist -->
<!-- Update description to be more specific -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Juan Heart uses your location to find the nearest health facilities offering CVD screening. Location data is never shared with third parties and is only used when you search for facilities.</string>

<!-- Resubmit with note: "Location permission description clarified in Info.plist" -->
```

### Appeal Process

#### When to Appeal
- Review rejection seems incorrect based on guidelines
- App complies but reviewer misunderstood functionality
- Technical issue during review (not app bug)

#### How to Appeal
```
App Store Connect → Resolution Center → Appeal

Template:
"Subject: Appeal for Juan Heart Mobile v1.5.0 Rejection

Dear App Review Team,

We respectfully appeal the rejection of Juan Heart Mobile v1.5.0 for the following reasons:

REJECTION REASON:
[Copy exact rejection text]

OUR POSITION:
Juan Heart complies with Guideline [X.X.X] because:
1. [Specific compliance point with evidence]
2. [Reference to similar approved apps if applicable]
3. [Attach screenshots/documentation proving compliance]

SUPPORTING EVIDENCE:
- Privacy Policy: https://juanheart.ph/privacy (clearly discloses data collection)
- Clinical Validation: Attached letter from Public Health Council
- Similar Apps: [List 2-3 approved medical apps with similar functionality]

We have made no changes to the app since submission. We believe this may have been a misunderstanding during review and kindly request re-evaluation.

Thank you for your consideration.

Best regards,
Juan Heart Support Team
support@juanheart.ph"
```

### Expedited Review Request

#### When to Request
- Critical bug affecting production users
- Security vulnerability
- Time-sensitive feature (e.g., COVID-19 screening during pandemic)

#### How to Request
```
App Store Connect → Contact Us → Request Expedited Review

Reason: Critical Bug Fix

Explanation:
"Juan Heart v1.4.0 (currently in App Store) has a critical bug causing data loss when users complete assessments offline. This affects healthcare providers conducting screenings in rural areas without reliable internet.

IMPACT:
- 5,000+ users affected
- 200+ support requests received
- Patient data at risk of loss

FIX IMPLEMENTED:
Version 1.5.0 fixes the sync queue persistence issue (commit SHA: abc123).

URGENCY:
This is a healthcare app used for critical CVD screening. Delayed fix could result in patients missing follow-up appointments due to lost assessment data.

We respectfully request expedited review to minimize patient impact.

Thank you.
Contact: support@juanheart.ph"
```

**Approval Rate:** ~50% (only granted for legitimate emergencies)

---

## Post-Approval Release

### Manual Release (Recommended for v1.0)
```
App Store Connect → Version 1.5.0 → Status: Pending Developer Release

Click "Release This Version"
- App goes live within 24 hours
- Allows final checks before public availability
```

### Automatic Release
```
App Store Connect → Pricing and Availability → Version Release

Select: "Automatically release this version"
- App goes live immediately upon approval
- No manual intervention needed
- Use for routine updates after v1.0 stable
```

### Phased Release (RECOMMENDED)
```
App Store Connect → Version 1.5.0 → Phased Release

Enable: "Release this version over a 7-day period using phased release"

Day 1: 1% of users
Day 2: 2% of users
Day 3: 5% of users
Day 4: 10% of users
Day 5: 20% of users
Day 6: 50% of users
Day 7: 100% of users

Benefits:
- Catch critical bugs with small user base
- Monitor crash reports before full rollout
- Can pause/halt if issues detected
```

### Post-Release Monitoring

#### First 24 Hours
```
Xcode → Window → Organizer → Crashes
- Check crash rate (target: <1%)
- Review crash logs for new crashes
- Monitor energy usage (battery drain)

App Store Connect → Analytics
- Downloads: Track adoption rate
- App Units: Verify installs increasing
- Crashes: MUST be <0.5% crash-free users
```

#### First Week
```
App Store Connect → Ratings and Reviews
- Respond to 1-star and 2-star reviews within 24 hours
- Thank users for positive feedback
- Identify common complaints

Response Template:
"Thank you for your feedback! We're sorry to hear about [issue].
Our team is investigating and will release a fix soon.
Please email support@juanheart.ph for immediate assistance."
```

---

## Success Criteria

### Release is Successful if:
- ✅ App approved on first submission (or within 2 resubmissions)
- ✅ Crash-free users ≥99.5%
- ✅ Average rating ≥4.5 stars (after 50+ reviews)
- ✅ No critical bugs reported
- ✅ Download rate matches projections
- ✅ No emergency hotfixes needed within 7 days

---

## Quick Reference Commands

```bash
# Full iOS release workflow (when Apple Developer account ready)
flutter clean && flutter pub get
flutter test && flutter analyze
cd ios && fastlane beta  # Upload to TestFlight
# Test with beta testers (3-7 days)
fastlane release  # Submit to App Store
# Wait for approval (1-3 days)
# Release to production (manual or automatic)

# Monitor post-release
# Xcode Organizer → Crashes
# App Store Connect → Analytics
```

---

## Related Documentation
- [01-google-play-release.md](./01-google-play-release.md) - Android deployment
- [03-hotfix-deployment.md](./03-hotfix-deployment.md) - Emergency fixes
- [04-rollback-procedures.md](./04-rollback-procedures.md) - Rollback guide
- [troubleshooting.md](./troubleshooting.md) - Common deployment errors

---

**Document History:**
- v1.0 (Jan 2025): Initial guide for Juan Heart Mobile (BLOCKED pending Apple Developer account)
- Owner: JH-Git-Guardian
- Review Cycle: After Apple Developer account setup

**NEXT STEPS:**
1. Enroll in Apple Developer Program ($99/year)
2. Generate certificates and provisioning profiles
3. Configure App Store Connect
4. Update this guide with actual account details
5. Perform test submission to validate process
