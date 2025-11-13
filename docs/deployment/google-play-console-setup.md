# Google Play Console Beta Testing Setup Guide

## Overview

This comprehensive guide walks you through setting up Google Play Console for beta testing the Juan Heart Mobile application. By following these steps, you'll be able to distribute the app to PHC staff, pilot facilities, and external testers for validation before production release.

**Target:** 30+ beta testers from PHC, University of Cordilleras, and pilot healthcare facilities

**Timeline Estimate:** 3-4 hours for initial setup, 30 minutes for subsequent releases

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Google Play Console Setup](#initial-google-play-console-setup)
3. [App Store Listing Creation](#app-store-listing-creation)
4. [Internal Testing Track Setup](#internal-testing-track-setup)
5. [Closed Testing Track Setup](#closed-testing-track-setup)
6. [Building and Uploading AAB](#building-and-uploading-aab)
7. [Managing Tester Groups](#managing-tester-groups)
8. [Beta Tester Enrollment](#beta-tester-enrollment)
9. [Feedback Collection](#feedback-collection)
10. [CI/CD Integration](#cicd-integration)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Items

- [ ] Google Play Developer account ($25 one-time fee)
- [ ] Juan Heart production keystore (see `android-keystore-generation.md`)
- [ ] Completed app build with proper signing
- [ ] App privacy policy URL
- [ ] App screenshots (phone and tablet)
- [ ] Feature graphic (1024 x 500 px)
- [ ] App icon (512 x 512 px)
- [ ] List of initial beta tester email addresses

### Account Setup

If you don't have a Google Play Developer account:

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with Google account (use organization email: @uc.edu.ph or @pchrd.doh.gov.ph)
3. Click "Create Developer Account"
4. Accept Developer Distribution Agreement
5. Pay $25 registration fee (one-time)
6. Complete identity verification (may take 1-2 days)

---

## Initial Google Play Console Setup

### Step 1: Create New Application

1. **Access Play Console:**
   - Go to https://play.google.com/console
   - Sign in with your developer account

2. **Create App:**
   - Click "Create app" button
   - Fill in app details:
     - **App name:** `Juan Heart Mobile`
     - **Default language:** `English (United States)`
     - **App or game:** Select `App`
     - **Free or paid:** Select `Free`

3. **Accept Declarations:**
   - Check "I have read and agree to the Developer Program Policies"
   - Check "I have read and agree to the US export laws"
   - Click "Create app"

### Step 2: Configure App Access

1. **Navigate to:** App content → App access
2. **Select access type:**
   - Choose "All functionality is available without restrictions"
   - If login required for testing, select "All or some functionality is restricted" and provide test credentials:
     ```
     Test Account Email: beta.tester@juanheart.ph
     Test Account Password: JuanHeart2025Beta!
     ```
3. Click "Save"

### Step 3: Set Up Data Safety

1. **Navigate to:** App content → Data safety
2. **Complete questionnaire:**
   - **Does your app collect or share user data?** Yes
   - **Data types collected:**
     - Personal info: Name, Email, Phone number
     - Health and fitness: Health info (cardiovascular risk data)
     - Location: Approximate location (for facility search)
   - **Data usage:**
     - App functionality
     - Analytics
   - **Data handling:**
     - Data is encrypted in transit (TLS 1.3)
     - Data is encrypted at rest (AES-256)
     - Users can request data deletion
   - **Privacy policy URL:**
     ```
     https://juanheart.ph/privacy-policy
     ```
     (Replace with actual URL when available)

3. Click "Save" after each section

### Step 4: Configure App Category and Contact Details

1. **Navigate to:** App content → App details
2. **Fill in:**
   - **App name:** Juan Heart Mobile
   - **Short description (80 chars):**
     ```
     Clinical decision tool for cardiovascular disease prevention in the Philippines
     ```
   - **Full description (4000 chars):**
     ```
     Juan Heart Mobile is a comprehensive clinical decision support system designed to prevent cardiovascular disease (CVD) in the Philippines. Developed in partnership with the Philippine Heart Center and University of Cordilleras, this app empowers healthcare workers with evidence-based risk assessment tools.

     KEY FEATURES:
     • Heart Risk Assessment (PHC Algorithm)
     • Medical Triage for Emergency Care
     • Appointment Booking with 8 Partner Facilities
     • AI-Powered Risk Scoring (Gemini Flash 1.5)
     • Offline-First Architecture
     • Bilingual Support (English/Filipino)
     • PDF Report Generation
     • Educational Resources
     • Real-time Analytics Dashboard

     DESIGNED FOR:
     • Healthcare workers in primary care settings
     • Nurses and midwives in rural health units
     • Medical professionals in resource-constrained environments
     • CVD prevention program coordinators

     TECHNICAL HIGHLIGHTS:
     • Works on low-end devices (2GB RAM minimum)
     • Offline data collection with intelligent sync
     • Philippine Data Privacy Act compliant
     • Secure end-to-end encryption
     • Integration with PhilHealth systems

     This beta version is available to PHC staff, University of Cordilleras partners, and pilot healthcare facilities for validation testing.
     ```

3. **App category:**
   - **Category:** Medical
   - **Tags:** Healthcare, Medical, Cardiology, Clinical Decision Support

4. **Contact details:**
   - **Email:** support@juanheart.ph
   - **Phone:** +63 2 8925 2401 (PHC main line)
   - **Website:** https://juanheart.ph

5. Click "Save"

---

## App Store Listing Creation

### Step 1: Upload Graphics Assets

1. **Navigate to:** Main store listing → Graphics

2. **Upload required assets:**

   **App icon (512 x 512 px):**
   - Use PNG format
   - 32-bit color with alpha channel
   - Full square (no rounded corners)
   - Location: `assets/images/juan-heart-logo.png`

   **Feature graphic (1024 x 500 px):**
   - Create promotional banner
   - Include app name and tagline: "Preventing CVD, One Assessment at a Time"
   - Use Juan Heart brand colors (red/white)

   **Phone screenshots (at least 2, max 8):**
   - Resolution: 1080 x 2400 px (or device native resolution)
   - Capture key screens:
     1. Home dashboard with risk assessment cards
     2. Heart Risk Assessment questionnaire
     3. Risk score results with recommendations
     4. Facility search with map
     5. Appointment booking calendar
     6. Analytics dashboard
     7. Educational content library
     8. Profile screen

   **7-inch tablet screenshots (at least 2, max 8):**
   - Resolution: 1536 x 2048 px
   - Same screens as phone, showcasing tablet layout

3. **Optional promotional assets:**
   - Promo video (YouTube link, max 30 seconds)
   - TV banner (if planning Android TV release)

### Step 2: Create Screenshots

If you don't have screenshots yet:

```bash
# Run app on emulator
flutter run --release

# Use device screenshot tool
# Android Studio: Tools → Device File Explorer → Take Screenshot

# Or use adb
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png screenshots/home_screen.png
```

**Recommended tools:**
- [Fastlane Frameit](https://docs.fastlane.tools/actions/frameit/) - Add device frames
- [Figma](https://www.figma.com/) - Create feature graphic
- [Canva](https://www.canva.com/) - Design promotional materials

---

## Internal Testing Track Setup

Internal testing allows up to 100 testers without requiring app review. Perfect for PHC staff and development team.

### Step 1: Create Internal Test Release

1. **Navigate to:** Testing → Internal testing
2. Click "Create new release"

3. **App signing:**
   - Select "Use Google Play App Signing" (recommended)
   - Upload your keystore or let Google manage
   - Read and accept App Signing Terms

4. **Release details:**
   - **Release name:** `Beta v1.0.0 - Internal`
   - **Release notes (What's new):**
     ```
     Welcome to Juan Heart Mobile Beta!

     This internal release includes:
     • Core heart risk assessment functionality
     • Appointment booking with 8 partner facilities
     • AI-powered risk scoring (Gemini Flash 1.5)
     • Offline data collection and sync
     • PDF report generation
     • Educational content library

     TESTING PRIORITIES:
     1. Complete at least 3 heart risk assessments
     2. Book and reschedule appointments
     3. Test offline mode by disabling internet
     4. Generate and share PDF reports
     5. Review analytics dashboard
     6. Provide feedback via in-app form

     Known issues:
     • Calendar date picker may require double-tap
     • Sync queue shows duplicate entries (visual only)

     Please report bugs to: beta-feedback@juanheart.ph
     ```

5. Click "Save"

### Step 2: Add Internal Testers

1. **Create tester list:**
   - Navigate to: Testing → Internal testing → Testers
   - Click "Create email list"
   - **List name:** `PHC Core Team`
   - Add email addresses (one per line):
     ```
     developer1@uc.edu.ph
     developer2@uc.edu.ph
     clinical.lead@pchrd.doh.gov.ph
     qa.tester@pchrd.doh.gov.ph
     ```
   - Click "Save changes"

2. **Configure opt-in URL:**
   - Copy opt-in link (looks like: `https://play.google.com/apps/internaltest/...`)
   - Send to internal testers via email

### Step 3: Review and Publish

1. Click "Review release"
2. Verify all details are correct
3. Click "Start rollout to Internal testing"
4. **Timeline:** Available immediately (no review required)

---

## Closed Testing Track Setup

Closed testing supports up to 100,000 testers and requires app review. Use this for pilot facilities and external stakeholders.

### Step 1: Create Closed Test Release

1. **Navigate to:** Testing → Closed testing
2. Click "Create new release"

3. **Release details:**
   - **Release name:** `Beta v1.0.0 - Closed`
   - **Release notes:**
     ```
     Juan Heart Mobile - Beta Release for Pilot Facilities

     Thank you for participating in our beta program!

     NEW IN THIS RELEASE:
     • Heart Risk Assessment (validated PHC algorithm)
     • Medical Triage for Emergency Care
     • Appointment booking across 8 healthcare facilities
     • Offline-first data collection
     • AI-powered risk scoring with transparency
     • Bilingual interface (English/Filipino)

     HOW TO TEST:
     1. Complete user registration with real or test data
     2. Perform heart risk assessments on volunteer patients
     3. Book appointments and test rescheduling flow
     4. Enable airplane mode and verify offline functionality
     5. Generate PDF reports and share via email
     6. Explore educational content library

     FEEDBACK NEEDED:
     • Assessment accuracy and clinical relevance
     • User interface clarity and navigation
     • Performance on low-end devices
     • Offline sync reliability
     • Feature requests and improvements

     Report issues: beta-feedback@juanheart.ph
     Support: +63 2 8925 2401
     ```

### Step 2: Configure Countries

1. **Available countries:**
   - Select "Philippines" only (for beta testing)
   - Can expand to other countries for production

### Step 3: Create Tester Lists

Create multiple lists for different stakeholder groups:

**List 1: Pilot Facilities (PHC Partner Clinics)**
```
Name: PHC Pilot Facilities
Emails:
nurse.clinic1@health.gov.ph
doctor.clinic2@health.gov.ph
midwife.clinic3@health.gov.ph
```

**List 2: University of Cordilleras**
```
Name: UC Research Team
Emails:
researcher1@uc.edu.ph
researcher2@uc.edu.ph
faculty.advisor@uc.edu.ph
```

**List 3: PHC Staff**
```
Name: PHC Healthcare Workers
Emails:
cardiologist@pchrd.doh.gov.ph
nurse.cvd@pchrd.doh.gov.ph
program.coordinator@pchrd.doh.gov.ph
```

### Step 4: Publish Closed Test

1. Click "Review release"
2. Click "Start rollout to Closed testing"
3. **Timeline:** Google review takes 1-3 days
4. Monitor status at: Release → Testing → Closed testing

---

## Building and Uploading AAB

### Step 1: Prepare Release Build

1. **Clean previous builds:**
   ```bash
   cd ~/AndroidStudioProjects/Juan-Heart-Mobile
   flutter clean
   flutter pub get
   ```

2. **Verify keystore configuration:**
   ```bash
   # Check key.properties exists
   cat android/key.properties

   # Verify .env configuration
   cat .env | grep -E "(API_URL|EDUCATIONAL_CONTENT_API_URL)"
   ```

3. **Update version number:**
   Edit `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1  # 1.0.0 = version name, 1 = version code
   ```

   For subsequent releases:
   ```yaml
   version: 1.0.1+2  # Increment both version name and code
   ```

### Step 2: Build Android App Bundle (AAB)

```bash
# Build production AAB
flutter build appbundle --release

# Verify signing
cd build/app/outputs/bundle/release
keytool -printcert -jarfile app-release.aab
```

**Expected output:**
```
Signer #1:
Owner: CN=Juan Heart Development Team, OU=Mobile Development...
Issuer: CN=Juan Heart Development Team, OU=Mobile Development...
Valid from: ... until: ...
```

**File location:** `build/app/outputs/bundle/release/app-release.aab`

**File size:** Should be ~30-50 MB (includes all assets and dependencies)

### Step 3: Upload to Play Console

**Method 1: Manual Upload (Recommended for first release)**

1. Navigate to: Testing → Internal testing (or Closed testing)
2. Click "Create new release"
3. Under "App bundles", click "Upload"
4. Select `build/app/outputs/bundle/release/app-release.aab`
5. Wait for upload and processing (2-5 minutes)
6. Verify version code matches: `1`
7. Add release notes (see templates above)
8. Click "Review release" → "Start rollout"

**Method 2: Using Play Console Upload Tool**

```bash
# Install upload tool
npm install -g @google/play-console-uploader

# Upload AAB
play-console-upload \
  --package-name com.example.juan_heart \
  --track internal \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --service-account credentials.json
```

**Method 3: Fastlane (see CI/CD section)**

### Step 4: Verify Upload

1. **Check App Bundle Explorer:**
   - Navigate to: Release → App bundle explorer
   - Select your version
   - Review:
     - APK sizes per architecture
     - Permissions requested
     - App size breakdown
     - Supported devices

2. **Review Pre-launch Report:**
   - Google automatically tests on real devices
   - Check for crashes or warnings
   - Timeline: Available 30-60 minutes after upload

---

## Managing Tester Groups

### Creating Organized Tester Lists

**Best practices:**
- Separate lists by role (clinical staff, developers, QA)
- Use descriptive names
- Keep lists under 50 people for easy management
- Update lists monthly to remove inactive testers

### Adding Testers

1. **Navigate to:** Testing → [Track] → Testers
2. Click "Create email list" or "Manage"
3. Add emails (comma or newline separated)
4. Click "Save changes"

**Bulk import CSV:**
```csv
email,name,role
nurse1@clinic.gov.ph,Maria Santos,Clinical Tester
doctor2@hospital.ph,Dr. Juan Cruz,Medical Advisor
```

### Removing Testers

1. Go to tester list
2. Uncheck email addresses to remove
3. Click "Save changes"
4. Removed testers lose access within 24 hours

### Managing Tester Limits

- **Internal testing:** 100 testers (no review required)
- **Closed testing:** 100,000 testers (requires review)
- **Open testing:** Unlimited testers (public, requires review)

---

## Beta Tester Enrollment

### Step 1: Generate Opt-In URL

1. Navigate to: Testing → [Track] → Testers
2. Copy "Opt-in URL" from top of page
3. URL format: `https://play.google.com/apps/internaltest/4697496814251007506`

### Step 2: Invite Testers via Email

**Email template:**

```
Subject: You're Invited to Juan Heart Mobile Beta Program

Dear Beta Tester,

You've been selected to participate in the Juan Heart Mobile beta testing program! Your feedback will help us improve this clinical decision support tool for cardiovascular disease prevention.

GETTING STARTED:

1. Join the beta program:
   Click this link on your Android device:
   https://play.google.com/apps/internaltest/XXXXXXXXXX

2. Accept the invitation and click "Download it on Google Play"

3. Install the app from Google Play Store

4. Sign up using your email address: {{tester_email}}

5. Complete the onboarding tutorial

WHAT TO TEST:
• Heart risk assessments (try 3-5 assessments)
• Appointment booking and rescheduling
• Offline functionality (disable internet)
• PDF report generation
• Educational content library
• User profile and settings

FEEDBACK:
Please report bugs and suggestions to: beta-feedback@juanheart.ph

Or use the in-app feedback form: Settings → Send Feedback

SUPPORT:
For technical issues, contact: support@juanheart.ph
WhatsApp support: +63 917 123 4567

Thank you for helping us build a better healthcare tool!

Best regards,
Juan Heart Development Team
```

### Step 3: Tester Enrollment Process

**From tester perspective:**

1. Receive invitation email
2. Click opt-in URL on Android device
3. Sign in with Google account
4. Click "Become a tester"
5. Accept terms
6. Click "Download it on Google Play"
7. Install app normally from Play Store
8. Launch and sign up

**Enrollment timeline:**
- Link activation: Immediate
- Play Store listing appears: 1-2 hours
- Updates appear: Within 15 minutes

### Step 4: Monitor Enrollment

1. Navigate to: Testing → [Track] → Testers
2. View statistics:
   - **Opted in:** Testers who joined
   - **Installed:** Testers who downloaded app
   - **Last 7 days:** Recent activity

**Target metrics for 30+ testers:**
- Opt-in rate: >80% (24+ acceptances)
- Install rate: >90% (27+ installs)
- Active testers: >60% (18+ using app weekly)

---

## Feedback Collection

### In-App Feedback Integration

Add feedback button to app:

```dart
// In settings_screen.dart
ListTile(
  leading: Icon(Icons.feedback),
  title: Text('Send Beta Feedback'),
  onTap: () async {
    final uri = Uri.parse('mailto:beta-feedback@juanheart.ph?subject=Juan Heart Beta Feedback');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  },
)
```

### Play Console Feedback

1. **Navigate to:** Testing → [Track] → Feedback
2. **Monitor:**
   - User reviews (star ratings)
   - Written feedback
   - Crash reports
   - ANRs (Application Not Responding)

### Creating Feedback Survey

**Google Forms template:**

```
Juan Heart Mobile Beta Feedback Survey

1. How often do you use the app?
   [ ] Daily  [ ] Weekly  [ ] Monthly  [ ] Rarely

2. Rate the following features (1-5 stars):
   - Heart Risk Assessment: ⭐⭐⭐⭐⭐
   - Appointment Booking: ⭐⭐⭐⭐⭐
   - Offline Functionality: ⭐⭐⭐⭐⭐
   - User Interface: ⭐⭐⭐⭐⭐
   - Performance: ⭐⭐⭐⭐⭐

3. What device are you using?
   [ ] Budget phone (2-3GB RAM)
   [ ] Mid-range phone (4-6GB RAM)
   [ ] High-end phone (8GB+ RAM)
   [ ] Tablet

4. Have you encountered any bugs or crashes?
   [Text field]

5. What feature would you like to see added?
   [Text field]

6. Would you recommend this app to colleagues?
   [ ] Yes  [ ] No  [ ] Maybe

7. Additional comments:
   [Text area]
```

**Distribution:**
- Include link in welcome email
- Add to release notes
- Share in beta tester WhatsApp group

---

## CI/CD Integration

### Prerequisites

1. **Create Google Cloud Service Account:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select project or create new one
   - Navigate to: IAM & Admin → Service Accounts
   - Click "Create Service Account"
   - **Name:** `juan-heart-play-console-uploader`
   - **Role:** Service Account User
   - Click "Create and Continue"
   - Click "Done"

2. **Grant Play Console API Access:**
   - Go to [Play Console](https://play.google.com/console)
   - Navigate to: Settings → API access
   - Click "Link to a Google Cloud project"
   - Select your project
   - Under service accounts, find `juan-heart-play-console-uploader`
   - Click "Grant access"
   - **Permissions:** Release manager, Release to testing tracks
   - Click "Apply"

3. **Download Service Account Key:**
   - Go to: Google Cloud Console → IAM & Admin → Service Accounts
   - Find `juan-heart-play-console-uploader`
   - Click Actions (⋮) → Manage keys
   - Click "Add Key" → "Create new key"
   - **Type:** JSON
   - Click "Create"
   - Save as `play-console-credentials.json`

4. **Add to GitHub Secrets:**
   ```bash
   # Encode as base64
   base64 -i play-console-credentials.json | tr -d '\n' > credentials-base64.txt
   cat credentials-base64.txt | pbcopy
   ```

   - Go to GitHub → Settings → Secrets and variables → Actions
   - New secret: `PLAY_CONSOLE_CREDENTIALS_BASE64`
   - Paste base64 content

### GitHub Actions Workflow

Create `.github/workflows/beta-release.yml`:

```yaml
name: Beta Release to Google Play

on:
  push:
    tags:
      - 'v*.*.*-beta'

jobs:
  deploy_beta:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      - name: Install dependencies
        run: |
          flutter pub get
          flutter pub run build_runner build --delete-conflicting-outputs

      - name: Decode Android keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/juan-heart-release.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=juan-heart-release.jks
          EOF

      - name: Create .env file
        run: |
          cat > .env <<EOF
          API_URL=${{ secrets.API_URL }}
          EDUCATIONAL_CONTENT_API_URL=${{ secrets.EDUCATIONAL_CONTENT_API_URL }}
          EOF

      - name: Build Android App Bundle
        run: flutter build appbundle --release

      - name: Set up Play Console credentials
        run: |
          echo "${{ secrets.PLAY_CONSOLE_CREDENTIALS_BASE64 }}" | base64 --decode > play-console-credentials.json

      - name: Upload to Internal Testing Track
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJson: play-console-credentials.json
          packageName: com.example.juan_heart
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed
          whatsNewDirectory: fastlane/metadata/android

      - name: Notify team
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{
              "text": "Beta release ${{ github.ref_name }} uploaded to Google Play Internal Testing!",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Beta release *${{ github.ref_name }}* uploaded to Google Play Internal Testing!\n\nOpt-in URL: https://play.google.com/apps/internaltest/XXXXXXXXXX"
                  }
                }
              ]
            }'

      - name: Upload artifacts
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            build/app/outputs/bundle/release/
            android/app/build/outputs/logs/
```

### Triggering Beta Release

```bash
# Tag new beta version
git tag v1.0.0-beta
git push origin v1.0.0-beta

# GitHub Actions will automatically:
# 1. Build signed AAB
# 2. Upload to Internal Testing track
# 3. Notify team via Slack
```

### Manual Fastlane Setup (Alternative)

1. **Install Fastlane:**
   ```bash
   sudo gem install fastlane -NV
   ```

2. **Initialize Fastlane:**
   ```bash
   cd android
   fastlane init
   ```

3. **Create Fastfile:**
   ```ruby
   # android/fastlane/Fastfile
   default_platform(:android)

   platform :android do
     desc "Deploy to Internal Testing Track"
     lane :beta do
       gradle(
         task: "bundle",
         build_type: "Release",
         project_dir: "android"
       )

       upload_to_play_store(
         track: 'internal',
         aab: '../build/app/outputs/bundle/release/app-release.aab',
         json_key: 'play-console-credentials.json',
         skip_upload_metadata: true,
         skip_upload_images: true,
         skip_upload_screenshots: true
       )
     end
   end
   ```

4. **Run deployment:**
   ```bash
   fastlane android beta
   ```

---

## Troubleshooting

### Issue: Upload Failed - Version Code Conflict

**Error:**
```
Version code 1 has already been used. Try another version code.
```

**Solution:**
1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Increment version code from 1 to 2
   ```
2. Rebuild AAB:
   ```bash
   flutter clean
   flutter build appbundle --release
   ```
3. Upload new AAB

### Issue: Keystore Signature Mismatch

**Error:**
```
Upload failed: You uploaded an APK that is signed with a different certificate than your previous APKs.
```

**Solution:**
- Ensure you're using the same keystore file
- Verify key.properties has correct storeFile path
- Check keyAlias matches: `keytool -list -keystore juan-heart-release.jks`
- If first release, delete draft and re-upload

### Issue: Opt-in URL Not Working

**Error:**
Testers see "We couldn't find this page"

**Solution:**
- Ensure release is published (not draft)
- Wait 1-2 hours for propagation
- Check tester email is in approved list
- Try accessing from mobile device (not desktop)

### Issue: App Not Appearing in Play Store

**Possible causes:**
1. **Release not published:**
   - Check release status is "Live" not "Draft"
2. **Country restriction:**
   - Verify tester's country matches available countries
3. **Device incompatibility:**
   - Check minimum SDK version: `minSdkVersion 21`
   - Review excluded devices in Play Console
4. **Google account mismatch:**
   - Tester must use same Google account as opted-in email

**Solution:**
```bash
# Check device compatibility
flutter build apk --release
cd build/app/outputs/flutter-apk
aapt dump badging app-release.apk | grep -E "(sdkVersion|targetSdkVersion)"
```

### Issue: Pre-launch Report Shows Crashes

**Error:**
Pre-launch report shows crashes on specific devices

**Solution:**
1. Download crash logs from Play Console
2. Analyze stack trace:
   ```
   Navigate to: Release → Pre-launch report → Crashes
   ```
3. Common fixes:
   - **Missing permissions:** Add to AndroidManifest.xml
   - **Null pointer:** Add null checks in Dart code
   - **API compatibility:** Wrap with SDK version checks
4. Upload fixed version

### Issue: Slow Review Time (Closed Testing)

**Expected:** 1-3 days
**Actual:** 7+ days

**Solutions:**
- Use Internal Testing track (no review required)
- Contact Google Play support via Play Console
- Check for policy violations in rejection email
- Ensure data safety form is complete

### Issue: Service Account Upload Fails

**Error:**
```
The APK or AAB you uploaded was not authorized
```

**Solution:**
1. Verify service account has correct permissions:
   - Go to Play Console → Settings → API access
   - Check "Release manager" role is granted
2. Regenerate JSON key:
   - Go to Google Cloud Console → IAM → Service Accounts
   - Delete old key and create new one
3. Update GitHub secret with new credentials

---

## Checklist for First Beta Release

### Pre-Upload

- [ ] Keystore generated and backed up
- [ ] key.properties configured locally
- [ ] GitHub secrets configured
- [ ] .env file with production API URLs
- [ ] Version number updated in pubspec.yaml
- [ ] Release build tested on physical device
- [ ] Crash reporting configured (Firebase Crashlytics)
- [ ] Analytics tracking verified

### Play Console Setup

- [ ] Developer account created and verified
- [ ] App created in Play Console
- [ ] Store listing completed (description, screenshots, icon)
- [ ] Data safety form submitted
- [ ] Privacy policy URL added
- [ ] App category set to "Medical"
- [ ] Content rating questionnaire completed
- [ ] Contact details updated

### Testing Track

- [ ] Internal testing track created
- [ ] Tester lists created (PHC, UC, pilot facilities)
- [ ] Opt-in URL generated
- [ ] AAB uploaded successfully
- [ ] Release notes added
- [ ] Release published
- [ ] Pre-launch report reviewed

### Tester Management

- [ ] Invitation emails sent to all testers
- [ ] Support email set up (beta-feedback@juanheart.ph)
- [ ] Feedback survey created
- [ ] WhatsApp support group created
- [ ] Testing guide distributed

### CI/CD

- [ ] Service account created
- [ ] API access granted in Play Console
- [ ] Credentials added to GitHub secrets
- [ ] GitHub Actions workflow tested
- [ ] Automated notifications configured

### Monitoring

- [ ] Crashlytics dashboard checked daily
- [ ] Feedback emails monitored
- [ ] Play Console reviews checked
- [ ] Tester adoption tracked (target: 30+ installs)
- [ ] Bug reports triaged and prioritized

---

## Timeline Summary

| Phase | Duration | Action |
|-------|----------|--------|
| Google Play Console setup | 2-3 hours | Create account, configure app listing |
| Asset preparation | 3-4 hours | Screenshots, feature graphic, descriptions |
| First AAB build | 30 minutes | Build and verify signing |
| Internal testing setup | 1 hour | Create lists, upload AAB, publish |
| Tester invitation | 2 hours | Send emails, track enrollments |
| Google review (closed testing) | 1-3 days | Automated review process |
| Beta testing period | 2-4 weeks | Collect feedback, fix bugs |
| Subsequent releases | 30 minutes | Update version, rebuild, upload |

**Total time to first beta:** 4-6 hours of active work + 1-3 days review

---

## Best Practices

1. **Start with Internal Testing:**
   - No review required
   - Faster iteration cycles
   - Limit to 10-20 core testers initially

2. **Gradual Rollout:**
   - Week 1: 10 internal testers
   - Week 2: 30 closed testers (PHC staff)
   - Week 3: 50+ closed testers (pilot facilities)
   - Week 4: Evaluate feedback before production

3. **Version Naming Convention:**
   - Internal: `1.0.0-internal.1`, `1.0.0-internal.2`
   - Closed: `1.0.0-beta.1`, `1.0.0-beta.2`
   - Production: `1.0.0`, `1.0.1`

4. **Release Notes:**
   - List new features
   - Document known issues
   - Provide testing instructions
   - Include contact information

5. **Tester Communication:**
   - Weekly update emails
   - Acknowledge feedback within 24 hours
   - Share roadmap transparently
   - Celebrate milestones (e.g., "100 assessments completed!")

6. **Performance Monitoring:**
   - Set up Firebase Performance Monitoring
   - Track app start time, screen rendering
   - Monitor network requests
   - Alert on crashes >1% of sessions

---

## Additional Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Play Console API Documentation](https://developers.google.com/android-publisher)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)

---

**Document Version:** 1.0
**Last Updated:** January 2025
**Next Review:** After first beta release
**Owner:** DevOps Lead
**Contact:** support@juanheart.ph
