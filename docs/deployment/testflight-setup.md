# TestFlight Beta Testing Setup Guide

## BLOCKED STATUS

**Current Status:** BLOCKED - Apple Developer Account Required

**⚠️ IMPORTANT:** This guide cannot be executed until the following prerequisites are met:

1. **Apple Developer Account enrollment** ($99/year)
2. **Organization verification** (may take 1-2 weeks)
3. **Payment method** on file with Apple
4. **D-U-N-S Number** (if enrolling as organization)

**Timeline to unblock:** 2-4 weeks from account creation

**Responsible party:** Project Lead / University of Cordilleras Finance Department

---

## Overview

This comprehensive guide walks through setting up TestFlight for iOS beta testing of Juan Heart Mobile. TestFlight is Apple's official platform for distributing pre-release iOS apps to beta testers.

**Target:** 30+ beta testers from PHC, University of Cordilleras, and pilot healthcare facilities

**Timeline Estimate:**
- Account setup: 1-2 weeks (verification period)
- Initial configuration: 4-6 hours
- First build upload: 2-3 hours
- Subsequent releases: 45 minutes

---

## Table of Contents

1. [Prerequisites (BLOCKED)](#prerequisites-blocked)
2. [Apple Developer Account Setup](#apple-developer-account-setup)
3. [App Store Connect Configuration](#app-store-connect-configuration)
4. [Certificates and Provisioning Profiles](#certificates-and-provisioning-profiles)
5. [Xcode Project Configuration](#xcode-project-configuration)
6. [Building and Archiving](#building-and-archiving)
7. [Uploading to App Store Connect](#uploading-to-app-store-connect)
8. [TestFlight Configuration](#testflight-configuration)
9. [Managing Beta Testers](#managing-beta-testers)
10. [Beta Testing Process](#beta-testing-process)
11. [Feedback Collection](#feedback-collection)
12. [CI/CD Integration](#cicd-integration)
13. [Troubleshooting](#troubleshooting)

---

## Prerequisites (BLOCKED)

### Required Items

- [ ] **Apple Developer Account** ($99/year) - **BLOCKED**
- [ ] Mac computer with macOS 12.0+ (for Xcode)
- [ ] Xcode 14.0 or later
- [ ] Valid D-U-N-S Number (for organization enrollment)
- [ ] University of Cordilleras authorization letter
- [ ] Philippine Heart Center partnership documentation
- [ ] App privacy policy URL
- [ ] App screenshots for iOS (iPhone and iPad)
- [ ] App icon (1024 x 1024 px)
- [ ] List of initial beta tester email addresses (Apple IDs)

### Cost Breakdown

| Item | Cost | Frequency |
|------|------|-----------|
| Apple Developer Program | $99 USD | Annual |
| Mac computer (if needed) | ~$1,000 USD | One-time |
| Code signing certificate | Included | N/A |
| TestFlight distribution | Free | N/A |
| **Total first year** | **$99-$1,099 USD** | - |

---

## Apple Developer Account Setup

### Step 1: Choose Account Type

**Option A: Individual Account**
- **Cost:** $99/year
- **Approval time:** 24-48 hours
- **Best for:** Solo developers, quick testing
- **App Store listing:** Shows individual name
- **⚠️ Not recommended** for institutional apps like Juan Heart

**Option B: Organization Account (RECOMMENDED)**
- **Cost:** $99/year
- **Approval time:** 1-2 weeks
- **Requirements:** D-U-N-S Number, legal entity verification
- **App Store listing:** Shows "University of Cordilleras" or "Philippine Heart Center"
- **✅ Recommended** for credibility and institutional ownership

### Step 2: Obtain D-U-N-S Number (Organizations Only)

A D-U-N-S (Data Universal Numbering System) number is a unique 9-digit identifier for businesses.

1. **Check if you already have one:**
   - Go to [D&B D-U-N-S Lookup](https://www.dnb.com/duns-number/lookup.html)
   - Search for "University of Cordilleras" or "Philippine Heart Center"

2. **Request new D-U-N-S Number (if needed):**
   - Go to [Apple D-U-N-S Request](https://developer.apple.com/enroll/duns-lookup/)
   - Fill in organization details:
     ```
     Legal Entity Name: University of Cordilleras
     Headquarters Address: Gov. Pack Road, Baguio City, Benguet, 2600, Philippines
     Phone: +63 74 442 3316
     Website: https://uc.edu.ph
     ```
   - **Processing time:** 5-14 business days
   - **Cost:** Free for Apple Developer enrollment

3. **Verify D-U-N-S Number:**
   - Dun & Bradstreet will contact you to verify details
   - Provide business registration documents if requested

### Step 3: Enroll in Apple Developer Program

**⚠️ BLOCKED UNTIL D-U-N-S NUMBER OBTAINED**

1. **Start enrollment:**
   - Go to [Apple Developer](https://developer.apple.com/programs/enroll/)
   - Sign in with Apple ID or create new one
   - **Recommended email:** developer@juanheart.ph or devteam@uc.edu.ph

2. **Choose entity type:**
   - Select "Organization"
   - Enter D-U-N-S Number
   - Confirm organization details match D&B records exactly

3. **Provide organization information:**
   ```
   Legal Entity Name: University of Cordilleras
   Website: https://uc.edu.ph
   Headquarters Address: Gov. Pack Road, Baguio City, Benguet, 2600
   Phone: +63 74 442 3316
   Work Email: developer@uc.edu.ph (must match organization domain)
   ```

4. **Assign authority:**
   - You must be legally authorized to bind the organization
   - Options:
     - University President
     - IT Department Head
     - Authorized representative with documentation

5. **Accept agreements:**
   - Apple Developer Program License Agreement
   - Read terms carefully (covers app distribution, payment, etc.)

6. **Complete payment:**
   - **Cost:** $99 USD
   - Payment methods: Credit/debit card, institutional purchase order
   - **Billing cycle:** Annual renewal

7. **Wait for verification:**
   - **Timeline:** 1-2 weeks
   - Apple will:
     - Verify D-U-N-S Number with Dun & Bradstreet
     - Contact you via phone to verify authority
     - Request additional documentation (business license, authorization letter)
   - **Status updates:** Check email and developer.apple.com/account

### Step 4: Verification Call Preparation

Apple will call the phone number on file to verify enrollment.

**Prepare for call:**
- Ensure authorized person is available
- Have these documents ready:
  - University business registration certificate
  - Authorization letter from University President
  - Government-issued ID of authorized person
  - Proof of domain ownership (uc.edu.ph email)

**Questions Apple may ask:**
- What is your organization's primary business?
  - Answer: "Higher education and research institution specializing in healthcare technology"
- What type of app will you publish?
  - Answer: "Medical/health app for cardiovascular disease prevention in partnership with Philippine Heart Center"
- Are you authorized to enroll on behalf of the organization?
  - Answer: "Yes, I have written authorization from [Position, Name]"

---

## App Store Connect Configuration

**⚠️ BLOCKED UNTIL DEVELOPER ACCOUNT APPROVED**

### Step 1: Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Sign in with Apple Developer account credentials
3. Accept App Store Connect terms (if first time)

### Step 2: Create App Record

1. **Navigate to:** My Apps → + (Add New App)

2. **Platform:** iOS

3. **App Information:**
   - **Name:** `Juan Heart Mobile`
     - Must be unique across App Store
     - If taken, try: `Juan Heart - CVD Prevention`, `Juan Heart Health`
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Create new
     - **Bundle ID Suffix:** `com.uc.juanheart` or `ph.juanheart.mobile`
     - **Description:** Juan Heart Mobile App
     - Click "Register"
   - **SKU:** `JUANHEART-IOS-001` (internal identifier, not public)
   - **User Access:** Full Access

4. Click "Create"

### Step 3: Configure App Information

1. **Navigate to:** App Information

2. **Category:**
   - **Primary Category:** Medical
   - **Secondary Category:** Health & Fitness

3. **Content Rights:**
   - Check "Contains third-party content" if using:
     - Educational content from external sources
     - Map data (Google Maps)
     - Icons/images from libraries

4. **Age Rating:**
   - Click "Edit" next to Age Rating
   - Answer questionnaire:
     - Medical/Treatment Information: "Frequent/Intense"
     - None for violence, sexual content, etc.
   - **Expected rating:** 12+ (due to medical content)

### Step 4: Configure Privacy Policy and Data Usage

1. **Privacy Policy URL:**
   ```
   https://juanheart.ph/privacy-policy
   ```
   (Must be hosted and accessible)

2. **App Privacy:**
   - Navigate to: App Privacy
   - Click "Get Started"
   - **Does your app collect data?** Yes

   **Data types collected:**
   - **Contact Info:**
     - Name
     - Email Address
     - Phone Number
     - Purpose: App Functionality, Analytics
     - Linked to user: Yes
   - **Health & Fitness:**
     - Health data (cardiovascular risk assessments)
     - Purpose: App Functionality, Analytics
     - Linked to user: Yes
   - **Location:**
     - Approximate Location
     - Purpose: App Functionality (facility search)
     - Linked to user: Yes
   - **Identifiers:**
     - User ID
     - Device ID
     - Purpose: App Functionality, Crash Reporting
     - Linked to user: Yes

3. **Data handling:**
   - ✅ Data is collected
   - ✅ Data is used for tracking (analytics)
   - ✅ Data is linked to user identity
   - ✅ Users can request deletion

### Step 5: App Store Information

1. **Navigate to:** App Store → [Version] → App Information

2. **Subtitle (optional, 30 chars):**
   ```
   CVD Prevention & Assessment
   ```

3. **Description (4000 chars):**
   ```
   Juan Heart Mobile is a comprehensive clinical decision support system designed to prevent cardiovascular disease (CVD) in the Philippines. Developed in partnership with the Philippine Heart Center and University of Cordilleras, this app empowers healthcare workers with evidence-based risk assessment tools.

   KEY FEATURES:
   • Heart Risk Assessment (validated PHC algorithm)
   • Medical Triage for Emergency Care
   • Appointment Booking with Partner Facilities
   • AI-Powered Risk Scoring (Gemini Flash 1.5)
   • Offline-First Architecture - works without internet
   • Bilingual Support (English/Filipino)
   • PDF Report Generation
   • Educational Resources on heart health
   • Real-time Analytics Dashboard

   DESIGNED FOR HEALTHCARE PROFESSIONALS:
   • Primary care physicians and nurses
   • Rural health unit staff
   • Community health workers
   • CVD prevention program coordinators

   TECHNICAL HIGHLIGHTS:
   • Works on older iPhones (iOS 12+)
   • Offline data collection with intelligent sync
   • Philippine Data Privacy Act compliant
   • Secure end-to-end encryption (AES-256)
   • HIPAA-aligned data protection

   EVIDENCE-BASED CARE:
   The heart risk assessment uses the validated Philippine Heart Center algorithm, which considers:
   - Blood pressure and heart rate
   - Cholesterol levels
   - Diabetes and smoking status
   - Family history
   - Lifestyle factors

   ABOUT THE PARTNERSHIP:
   This app is the result of collaboration between the University of Cordilleras College of Computer Studies and the Philippine Heart Center Department of Preventive Cardiology. It supports the national CVD prevention strategy by making clinical decision support accessible to frontline healthcare workers.

   SUPPORT:
   For technical assistance: support@juanheart.ph
   Medical inquiries: clinical@juanheart.ph
   ```

4. **Keywords (100 chars):**
   ```
   cardiovascular,heart,medical,assessment,health,cvd,prevention,clinical,cardiology,healthcare
   ```

5. **Support URL:**
   ```
   https://juanheart.ph/support
   ```

6. **Marketing URL (optional):**
   ```
   https://juanheart.ph
   ```

---

## Certificates and Provisioning Profiles

**⚠️ REQUIRES MAC WITH XCODE**

### Step 1: Install Xcode

1. **Download Xcode:**
   - Open App Store on Mac
   - Search "Xcode"
   - Click "Get" or "Install"
   - **Size:** ~15 GB
   - **Time:** 30-60 minutes depending on internet speed

2. **Launch Xcode:**
   - Open from Applications folder
   - Accept license agreement
   - Install additional components when prompted

3. **Verify installation:**
   ```bash
   xcode-select --install
   xcode-select -p
   # Should output: /Applications/Xcode.app/Contents/Developer
   ```

### Step 2: Create Distribution Certificate

**Method 1: Automatic (Xcode Managed Signing - Recommended)**

1. Open project in Xcode:
   ```bash
   cd ~/AndroidStudioProjects/Juan-Heart-Mobile
   open ios/Runner.xcworkspace
   ```

2. **Select Runner target** in left sidebar

3. **Navigate to:** Signing & Capabilities tab

4. **Team:** Select your Apple Developer account
   - Click "Add Account" if not listed
   - Sign in with Apple ID used for developer enrollment

5. **Enable "Automatically manage signing"**
   - Xcode will create certificates and profiles automatically
   - Bundle Identifier: `com.uc.juanheart` (must match App Store Connect)

6. **Verify:**
   - Provisioning Profile: "Xcode Managed Profile"
   - Signing Certificate: "Apple Development" or "Apple Distribution"

**Method 2: Manual Certificate Creation**

1. **Generate Certificate Signing Request (CSR):**
   - Open Keychain Access (Applications → Utilities)
   - Menu: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - **User Email:** developer@uc.edu.ph
   - **Common Name:** Juan Heart iOS Distribution
   - **Request is:** Saved to disk
   - **Save as:** JuanHeartCertificateRequest.certSigningRequest

2. **Create Distribution Certificate:**
   - Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates)
   - Click + (Add)
   - **Type:** iOS Distribution (App Store and Ad Hoc)
   - Click "Continue"
   - Upload CSR file
   - Click "Continue"
   - Download certificate: `ios_distribution.cer`

3. **Install Certificate:**
   - Double-click `ios_distribution.cer`
   - Keychain Access will open
   - Certificate appears in "My Certificates"
   - Expand to verify it has a private key (🔑 icon)

### Step 3: Register App ID

1. **Go to:** [Apple Developer Identifiers](https://developer.apple.com/account/resources/identifiers)

2. **Click +** (Register a new identifier)

3. **Select:** App IDs → Continue

4. **Type:** App

5. **Description:** Juan Heart Mobile iOS App

6. **Bundle ID:** Explicit
   - Enter: `com.uc.juanheart`
   - **Must match** Xcode project and App Store Connect

7. **Capabilities (check these):**
   - ✅ Associated Domains (for deep linking)
   - ✅ Push Notifications
   - ✅ Background Modes
   - ✅ Sign In with Apple (if planning to add)
   - ✅ HealthKit (if integrating wearables)

8. Click "Continue" → "Register"

### Step 4: Create Provisioning Profile

**For TestFlight (Ad Hoc Distribution):**

1. **Go to:** [Apple Developer Profiles](https://developer.apple.com/account/resources/profiles)

2. **Click +** (Generate a new profile)

3. **Type:** Ad Hoc
   - Use for TestFlight internal testing
   - Limited to 100 devices

4. **Select App ID:** com.uc.juanheart

5. **Select Certificate:** iOS Distribution certificate created earlier

6. **Select Devices:**
   - Click "Select All" (or specific test devices)
   - Note: Only registered devices can install TestFlight builds

7. **Profile Name:** Juan Heart TestFlight Ad Hoc

8. Click "Generate"

9. **Download:** `Juan_Heart_TestFlight_Ad_Hoc.mobileprovision`

10. **Install:**
    ```bash
    open Juan_Heart_TestFlight_Ad_Hoc.mobileprovision
    ```

**For App Store Distribution:**

Repeat above steps but select "App Store" distribution type instead of "Ad Hoc".

---

## Xcode Project Configuration

### Step 1: Open iOS Project

```bash
cd ~/AndroidStudioProjects/Juan-Heart-Mobile

# Install iOS dependencies
cd ios
pod install
cd ..

# Open in Xcode (MUST use .xcworkspace, not .xcodeproj)
open ios/Runner.xcworkspace
```

### Step 2: Configure Signing

1. **Select "Runner" target** in left sidebar

2. **Navigate to:** Signing & Capabilities

3. **Team:** University of Cordilleras (or your organization)

4. **Bundle Identifier:** `com.uc.juanheart`
   - ⚠️ Must match App Store Connect exactly

5. **Signing method:**
   - ✅ **Recommended:** Automatically manage signing
   - Manual: Select provisioning profiles created earlier

6. **Verify configurations:**
   - Debug: Automatic signing (development)
   - Release: Automatic signing (distribution)

### Step 3: Update Info.plist

1. **Open:** ios/Runner/Info.plist

2. **Add/update required keys:**

   **App Transport Security (REMOVE for production):**
   ```xml
   <!-- ⚠️ REMOVE BEFORE PRODUCTION SUBMISSION -->
   <!-- Current Info.plist has NSAllowsArbitraryLoads = true for development -->
   <!-- For production, delete entire NSAppTransportSecurity section -->
   ```

   **Privacy usage descriptions (already configured):**
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Juan Heart needs location access to find nearby healthcare facilities</string>

   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>Juan Heart needs background location for emergency services</string>

   <key>NSUserNotificationsUsageDescription</key>
   <string>Juan Heart sends appointment reminders and health alerts</string>
   ```

3. **Update display name:**
   ```xml
   <key>CFBundleDisplayName</key>
   <string>Juan Heart</string>
   ```

4. **Verify bundle ID:**
   ```xml
   <key>CFBundleIdentifier</key>
   <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   <!-- This will use com.uc.juanheart from project settings -->
   ```

### Step 4: Configure Build Settings

1. **Select Runner target → Build Settings**

2. **Search for "Code Signing Identity":**
   - Debug: Apple Development
   - Release: Apple Distribution

3. **Search for "Development Team":**
   - Set to your team ID (visible in Signing & Capabilities)

4. **Search for "Provisioning Profile":**
   - Debug: Xcode Managed
   - Release: Xcode Managed (or manual profile)

5. **Verify iOS Deployment Target:**
   - **Minimum:** iOS 12.0
   - Allows older devices (iPhone 6S and later)

---

## Building and Archiving

### Step 1: Prepare for Archive

1. **Clean build folder:**
   ```bash
   cd ~/AndroidStudioProjects/Juan-Heart-Mobile
   flutter clean
   flutter pub get
   cd ios
   pod install
   ```

2. **Update version:**
   Edit `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1  # 1.0.0 = version, 1 = build number
   ```

3. **Verify .env configuration:**
   ```bash
   cat .env | grep -E "(API_URL|EDUCATIONAL_CONTENT_API_URL)"
   # Ensure using HTTPS production URLs (not localhost)
   ```

4. **Remove development exceptions from Info.plist:**
   ```bash
   # Backup current file
   cp ios/Runner/Info.plist ios/Runner/Info.plist.backup

   # Remove NSAppTransportSecurity section
   # Use Xcode to manually delete or use plutil:
   /usr/libexec/PlistBuddy -c "Delete :NSAppTransportSecurity" ios/Runner/Info.plist
   ```

### Step 2: Build with Flutter

```bash
# Build iOS release
flutter build ios --release

# Verify build succeeded
ls -lh build/ios/iphoneos/Runner.app
```

### Step 3: Create Archive in Xcode

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select "Any iOS Device (arm64)" as build target**
   - Do NOT select a simulator

3. **Menu:** Product → Archive
   - This compiles the app in release mode
   - **Time:** 5-10 minutes

4. **Verify archive appears:**
   - Archives window opens automatically
   - Or: Window → Organizer → Archives

5. **Check archive details:**
   - Version: 1.0.0
   - Build: 1
   - Identity: iOS Distribution certificate

### Step 4: Validate Archive

Before uploading, validate the archive to catch issues early.

1. **In Organizer:** Select your archive

2. **Click "Validate App"**

3. **Distribution method:** App Store Connect

4. **App Store distribution options:**
   - ✅ Upload app symbols (for crash reporting)
   - ✅ Manage version and build number (Xcode managed)

5. **Signing:**
   - Automatically manage signing (recommended)
   - Or select provisioning profiles manually

6. **Click "Validate"**

7. **Wait for validation** (2-5 minutes)

**Common validation errors:**

- **Missing compliance:** Add export compliance in Info.plist
- **Invalid provisioning profile:** Regenerate in developer portal
- **Code signing error:** Check certificate is not expired
- **Missing icons:** Ensure all required icon sizes present

---

## Uploading to App Store Connect

### Step 1: Upload Archive

1. **In Xcode Organizer:** Select validated archive

2. **Click "Distribute App"**

3. **Distribution method:** App Store Connect

4. **Destination:** Upload

5. **App Store distribution options:**
   - ✅ Upload app symbols
   - ✅ Manage version and build number

6. **Signing:** Automatically manage signing

7. **Review summary:**
   - App: Juan Heart Mobile
   - Bundle ID: com.uc.juanheart
   - Version: 1.0.0
   - Build: 1

8. **Click "Upload"**

9. **Wait for upload** (5-15 minutes depending on size and connection)

10. **Success message:**
    ```
    Upload Successful
    Juan Heart Mobile has been uploaded to App Store Connect.
    ```

### Step 2: Verify Upload

1. **Go to App Store Connect:**
   - https://appstoreconnect.apple.com/

2. **Navigate to:** My Apps → Juan Heart Mobile

3. **Check Activity tab:**
   - Build 1.0.0 (1) should appear
   - Status: "Processing" or "Ready to Submit"

4. **Processing time:** 10-30 minutes
   - Apple scans for malware, symbols, etc.
   - You'll receive email when processing completes

---

## TestFlight Configuration

**⚠️ BLOCKED UNTIL FIRST BUILD UPLOADED**

### Step 1: Configure TestFlight Information

1. **Navigate to:** TestFlight tab → App Information

2. **Beta App Information:**
   - **What to Test:**
     ```
     Welcome to Juan Heart Mobile Beta!

     TESTING PRIORITIES:
     1. Complete 3-5 heart risk assessments
     2. Book and reschedule appointments
     3. Test offline mode (enable airplane mode)
     4. Generate and share PDF reports
     5. Review analytics dashboard
     6. Explore educational content

     FEEDBACK AREAS:
     • Accuracy of risk assessments
     • User interface clarity
     • Performance on your device
     • Offline functionality
     • Any bugs or crashes

     Contact: beta-feedback@juanheart.ph
     ```

   - **Beta App Description:**
     ```
     Juan Heart Mobile is a clinical decision support tool for cardiovascular disease prevention. This beta version is for healthcare workers at PHC partner facilities and University of Cordilleras research team.
     ```

   - **Feedback Email:**
     ```
     beta-feedback@juanheart.ph
     ```

   - **Marketing URL (optional):**
     ```
     https://juanheart.ph
     ```

3. **Test Information:**
   - **First Name:** Juan Heart
   - **Last Name:** Support Team
   - **Email:** support@juanheart.ph
   - **Phone:** +63 2 8925 2401

4. **Localization:**
   - Add Filipino (Tagalog) if you have translated release notes

### Step 2: Export Compliance

Required for apps using encryption (which Juan Heart does - AES-256, TLS 1.3).

1. **Navigate to:** TestFlight → App Information → Export Compliance

2. **Is your app exempt from export compliance?**
   - Answer: **No** (we use encryption)

3. **Does your app use encryption?**
   - Answer: **Yes**

4. **Does your app qualify for any exemptions?**
   - Select: "Your app uses encryption for authentication only"
   - Or: "Your app uses standard encryption (HTTPS, TLS)"
   - This is Category 5, Part 2 exemption

5. **Save**

**Alternative: Add to Info.plist**
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

---

## Managing Beta Testers

### Step 1: Internal Testing Group

Internal testing allows up to 100 testers from your development team.

1. **Navigate to:** TestFlight → Internal Testing

2. **Click "+" to create group:**
   - **Group Name:** PHC Core Team
   - **Enable automatic distribution:** Yes (auto-send new builds)

3. **Add testers:**
   - Click "Testers" → "+"
   - **Add via email:**
     ```
     developer1@uc.edu.ph
     developer2@uc.edu.ph
     clinical.lead@pchrd.doh.gov.ph
     ```
   - Testers must have Apple ID with these email addresses

4. **Build selection:**
   - Select your uploaded build (1.0.0 build 1)
   - Testers receive email invite immediately

**Internal testing benefits:**
- No beta app review required (immediate access)
- Up to 100 testers
- 90-day testing period per build
- Automatic crash reports

### Step 2: External Testing Group

External testing allows up to 10,000 testers. Requires Apple beta app review (1-2 days).

1. **Navigate to:** TestFlight → External Testing

2. **Create group:**
   - **Group Name:** Pilot Healthcare Facilities
   - **Public link:** Disabled (invite-only)

3. **Add testers:**
   - Click "+" → Enter emails
   - Or: Import CSV file
     ```csv
     email,first_name,last_name
     nurse1@clinic.gov.ph,Maria,Santos
     doctor2@hospital.ph,Juan,Cruz
     ```

4. **Configure build:**
   - Select build to test
   - Add "What to Test" instructions (release notes)

5. **Submit for review:**
   - Click "Submit for Review"
   - **Review time:** 1-2 days
   - Apple checks for guideline compliance

**External testing limitations:**
- Requires beta app review for each new version
- 90-day testing period per build
- 10,000 tester limit per group

### Step 3: Public Link Testing (Optional)

For wider distribution beyond 10,000 testers.

1. **Navigate to:** External Testing → Your Group

2. **Enable "Public Link"**

3. **Copy public link:**
   ```
   https://testflight.apple.com/join/XXXXXXXX
   ```

4. **Share link:**
   - Anyone with link can join (up to 10,000)
   - No email invitation required
   - Good for community beta programs

**Use cases:**
- Open beta for healthcare workers
- Conference demonstrations
- Public health campaigns

---

## Beta Testing Process

### Step 1: Tester Invitation

**For internal testers:**

1. Testers receive email: "You're Invited to Test Juan Heart Mobile"
2. Email contains:
   - TestFlight redemption code
   - Link to install TestFlight app
   - Instructions

**Email template to send alongside:**

```
Subject: Join Juan Heart Mobile Beta Testing (iOS)

Dear Beta Tester,

You've been invited to test Juan Heart Mobile on iOS via TestFlight!

GETTING STARTED:

1. Install TestFlight app from App Store:
   https://apps.apple.com/app/testflight/id899247664

2. Check email for TestFlight invitation
   (from: testflightapple.com)

3. Tap "View in TestFlight" or enter code: XXXXXX

4. Tap "Accept" and then "Install"

5. Launch Juan Heart from home screen

6. Sign up using: {{tester_email}}

WHAT TO TEST:
• Complete 3-5 heart risk assessments
• Test appointment booking
• Enable airplane mode - verify offline mode works
• Generate and share PDF reports
• Provide feedback via in-app form or email

SUPPORT:
Email: beta-feedback@juanheart.ph
Phone: +63 2 8925 2401
Testing guide: https://juanheart.ph/beta-testing-guide

Thank you for your valuable feedback!

Juan Heart Development Team
```

### Step 2: Tester Enrollment

**From tester perspective:**

1. Receive TestFlight invitation email
2. Tap "View in TestFlight"
3. TestFlight app opens (install if needed)
4. Tap "Accept"
5. Tap "Install"
6. Juan Heart app installs with orange "Beta" badge
7. Launch and begin testing

**Enrollment timeline:**
- Internal testers: Immediate access
- External testers: 1-2 days (after Apple review)

### Step 3: Providing Feedback

Testers can provide feedback three ways:

**1. In-app TestFlight feedback:**
- Shake device while in app
- Tap "Send Beta Feedback"
- Attach screenshot and description
- Feedback goes to App Store Connect

**2. Email:**
- Send to: beta-feedback@juanheart.ph
- Include device model and iOS version

**3. Crash reports:**
- Automatic if tester opts in
- Visible in Xcode Organizer → Crashes

### Step 4: Monitoring Beta Testing

1. **Navigate to:** TestFlight → Your Build

2. **View metrics:**
   - **Installs:** Number of testers who installed
   - **Sessions:** Total app launches
   - **Crashes:** Crash rate and reports
   - **Feedback:** Tester-submitted feedback

3. **Review feedback:**
   - TestFlight → Feedback
   - Click each item to see details
   - Respond via email (no in-app replies)

---

## Feedback Collection

### TestFlight Built-in Feedback

1. **Access feedback:**
   - App Store Connect → TestFlight → Feedback

2. **Review each item:**
   - Tester name and email
   - Screenshot (if attached)
   - Device and iOS version
   - Feedback text

3. **Export feedback:**
   - Click "Export" to download CSV
   - Share with team for triage

### External Feedback Channels

**Google Forms survey:**

```
Juan Heart Mobile iOS Beta Feedback

1. Device model:
   [ ] iPhone 8 or older
   [ ] iPhone X/11/12
   [ ] iPhone 13/14/15
   [ ] iPad

2. iOS version:
   [ ] iOS 12-13
   [ ] iOS 14-15
   [ ] iOS 16+

3. Overall experience (1-5 stars):
   ⭐⭐⭐⭐⭐

4. Feature ratings:
   - Heart Risk Assessment: ⭐⭐⭐⭐⭐
   - Appointment Booking: ⭐⭐⭐⭐⭐
   - Offline Mode: ⭐⭐⭐⭐⭐
   - PDF Reports: ⭐⭐⭐⭐⭐
   - Performance: ⭐⭐⭐⭐⭐

5. Did you encounter crashes or bugs?
   [Text field]

6. What feature would improve your workflow?
   [Text field]

7. Would you use this in your clinic?
   [ ] Yes  [ ] No  [ ] Maybe
```

---

## CI/CD Integration

**⚠️ REQUIRES MAC BUILD AGENT**

GitHub Actions cannot directly build iOS apps (requires macOS runner). Options:

### Option 1: Self-Hosted macOS Runner

**Setup:**

1. **Prepare Mac:**
   - macOS 12+
   - Xcode 14+
   - Install Flutter
   - Install fastlane: `sudo gem install fastlane`

2. **Install GitHub Actions runner:**
   ```bash
   # Go to GitHub repo → Settings → Actions → Runners → New self-hosted runner
   # Follow instructions to download and configure runner
   ```

3. **Store credentials:**
   ```bash
   # Add to ~/.netrc for App Store Connect
   machine appstoreconnect.apple.com
     login your-apple-id@uc.edu.ph
     password APP_SPECIFIC_PASSWORD
   ```

### Option 2: Fastlane Match (Recommended)

Securely sync certificates across team.

1. **Install fastlane:**
   ```bash
   cd ios
   fastlane init
   ```

2. **Set up match:**
   ```bash
   fastlane match init
   # Choose: git
   # Repo: https://github.com/uc-juanheart/certificates-private
   ```

3. **Generate certificates:**
   ```bash
   fastlane match appstore
   # Enter passphrase for encryption
   ```

4. **Update Fastfile:**
   ```ruby
   # ios/fastlane/Fastfile
   default_platform(:ios)

   platform :ios do
     desc "Build and upload to TestFlight"
     lane :beta do
       # Sync certificates
       match(type: "appstore", readonly: true)

       # Build app
       build_app(
         workspace: "Runner.xcworkspace",
         scheme: "Runner",
         export_method: "app-store"
       )

       # Upload to TestFlight
       upload_to_testflight(
         username: "developer@uc.edu.ph",
         app_identifier: "com.uc.juanheart",
         skip_waiting_for_build_processing: false
       )
     end
   end
   ```

5. **Run deployment:**
   ```bash
   fastlane beta
   ```

### Option 3: Codemagic (Cloud CI)

Commercial service with macOS builders.

1. **Sign up:** https://codemagic.io/
2. **Connect GitHub repo**
3. **Configure build:**
   - Select Flutter iOS
   - Add code signing (match or manual)
   - Configure TestFlight upload
4. **Pricing:** Free tier available, paid plans start at $95/month

---

## Troubleshooting

### Issue: Developer Account Verification Stuck

**Status:** "Enrollment pending" for >2 weeks

**Solution:**
1. Check enrollment email for requests for additional documentation
2. Call Apple Developer Support: +1 (800) 633-2152
3. Verify D-U-N-S Number matches exactly (name, address)
4. Provide authorization letter from university president

### Issue: Code Signing Failed

**Error:**
```
Code signing "Runner" failed. No signing certificate "iOS Distribution" found.
```

**Solution:**
1. Open Keychain Access → My Certificates
2. Verify "iOS Distribution" certificate exists with private key
3. If missing private key, delete certificate and regenerate CSR
4. Download new certificate from developer.apple.com/account
5. Double-click to install

### Issue: Provisioning Profile Invalid

**Error:**
```
Provisioning profile "Juan Heart TestFlight" doesn't include signing certificate.
```

**Solution:**
1. Go to developer.apple.com/account → Profiles
2. Edit provisioning profile
3. Select correct distribution certificate
4. Download new profile
5. Drag to Xcode to install

### Issue: Archive Build Failed

**Error:**
```
Build input file cannot be found: '.../Runner.app'
```

**Solution:**
1. Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Re-run pod install:
   ```bash
   cd ios
   pod deintegrate
   pod install
   ```
4. Archive again

### Issue: Upload Rejected - ITMS-90809

**Error:**
```
ITMS-90809: Deprecated API Usage - Apple will stop accepting submissions of apps that use UIWebView APIs.
```

**Solution:**
1. Check dependencies for UIWebView usage:
   ```bash
   grep -r "UIWebView" ios/
   ```
2. Update Flutter: `flutter upgrade`
3. Update iOS dependencies: `cd ios && pod update`
4. If dependency still uses UIWebView, contact maintainer or find alternative

### Issue: TestFlight Invite Not Received

**Tester reports:** "No invitation email"

**Solution:**
1. Check email address is correct in App Store Connect
2. Verify tester has Apple ID with that email
3. Check spam folder
4. Resend invite: TestFlight → Testers → Select tester → Resend
5. Alternative: Use public link instead of email invite

### Issue: Build Stuck in "Processing"

**Status:** Build shows "Processing" for >6 hours

**Solution:**
1. Wait up to 24 hours (rare but happens)
2. Check Activity page for error messages
3. If still stuck, re-upload build with incremented build number
4. Contact Apple Developer Support if persists

---

## Checklist for First iOS Beta Release

### Pre-Enrollment (CURRENTLY BLOCKED)

- [ ] Obtain D-U-N-S Number for organization
- [ ] Prepare authorization letter from university president
- [ ] Enroll in Apple Developer Program ($99 payment)
- [ ] Wait for verification call from Apple (1-2 weeks)
- [ ] Account approved and active

### Development Setup

- [ ] Mac with macOS 12+ available
- [ ] Xcode 14+ installed
- [ ] iOS project opens in Xcode without errors
- [ ] Distribution certificate created
- [ ] App ID registered (com.uc.juanheart)
- [ ] Provisioning profiles generated
- [ ] Code signing configured in Xcode

### App Store Connect

- [ ] App record created
- [ ] Bundle ID matches Xcode project
- [ ] Privacy policy URL added
- [ ] App privacy questionnaire completed
- [ ] Screenshots uploaded (iPhone and iPad)
- [ ] App icon uploaded (1024x1024)
- [ ] Description and keywords set
- [ ] Age rating configured

### Build and Upload

- [ ] NSAppTransportSecurity removed from Info.plist
- [ ] Version number updated in pubspec.yaml
- [ ] Release build successful: `flutter build ios --release`
- [ ] Archive created in Xcode
- [ ] Archive validated successfully
- [ ] Archive uploaded to App Store Connect
- [ ] Build processing completed (check Activity tab)

### TestFlight Setup

- [ ] TestFlight information configured
- [ ] Export compliance documented
- [ ] Internal testing group created
- [ ] Initial testers added
- [ ] Build assigned to testing group
- [ ] Testers receive invitation emails
- [ ] At least one successful install confirmed

### Monitoring

- [ ] TestFlight metrics dashboard bookmarked
- [ ] Feedback email monitored: beta-feedback@juanheart.ph
- [ ] Crash reports reviewed in Xcode Organizer
- [ ] Beta testing survey created and distributed
- [ ] Support channel active (email, phone, WhatsApp)

---

## Cost and Resource Summary

| Resource | Cost | Frequency | Status |
|----------|------|-----------|--------|
| Apple Developer Program | $99 USD | Annual | **REQUIRED - NOT ACQUIRED** |
| D-U-N-S Number | Free | One-time | **REQUIRED - CHECK IF EXISTS** |
| Mac Computer | $1,000+ | One-time | **REQUIRED - VERIFY AVAILABILITY** |
| Xcode | Free | N/A | Requires Mac |
| TestFlight Distribution | Free | N/A | Included with developer account |
| CI/CD (Codemagic) | $95+/month | Monthly | Optional |
| CI/CD (Self-hosted Mac) | Free | N/A | Requires dedicated Mac |

**Total to unblock iOS beta:** $99 (if Mac already available) or $1,099+ (if Mac needed)

---

## Timeline to First iOS Beta

**Assuming Mac is available:**

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Obtain D-U-N-S Number | 5-14 days | Organization registration documents |
| Apple Developer enrollment | 1-2 weeks | D-U-N-S Number, payment, verification call |
| Certificate setup | 2 hours | Approved developer account |
| App Store Connect configuration | 3 hours | Screenshots, descriptions ready |
| First build and upload | 2 hours | Xcode properly configured |
| TestFlight approval (internal) | Immediate | N/A |
| TestFlight approval (external) | 1-2 days | Apple beta review |
| **Total time to beta** | **3-4 weeks** | From enrollment start |

**Critical path:** Apple Developer account approval (longest wait time)

---

## Next Steps to Unblock

1. **Immediate (Week 1):**
   - [ ] Check if University of Cordilleras has D-U-N-S Number
   - [ ] Request if needed: https://developer.apple.com/enroll/duns-lookup/
   - [ ] Obtain authorization letter from university president
   - [ ] Identify responsible person for verification call
   - [ ] Secure budget approval for $99 annual fee

2. **Week 2-3:**
   - [ ] Enroll in Apple Developer Program
   - [ ] Prepare for verification call
   - [ ] Monitor enrollment status daily

3. **Week 3-4 (After Approval):**
   - [ ] Set up certificates and provisioning profiles
   - [ ] Configure App Store Connect
   - [ ] Upload first build
   - [ ] Invite internal testers

4. **Week 5-6:**
   - [ ] Collect initial feedback
   - [ ] Fix critical bugs
   - [ ] Expand to external testers
   - [ ] Monitor metrics and crashes

---

## Additional Resources

- [Apple Developer Program](https://developer.apple.com/programs/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Fastlane for iOS](https://docs.fastlane.tools/getting-started/ios/setup/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

---

**Document Version:** 1.0
**Status:** BLOCKED - Awaiting Apple Developer Account
**Last Updated:** January 2025
**Next Review:** After account approval
**Owner:** iOS Development Lead
**Blocker:** Apple Developer Program enrollment ($99/year)
**Estimated time to unblock:** 3-4 weeks from enrollment initiation
