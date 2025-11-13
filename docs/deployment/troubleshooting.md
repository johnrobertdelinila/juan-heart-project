# Deployment Troubleshooting Guide

**Last Updated:** January 2025
**Document Owner:** JH-Git-Guardian

---

## Table of Contents
1. [Build Errors](#build-errors)
2. [Code Signing Failures](#code-signing-failures)
3. [CI/CD Workflow Errors](#cicd-workflow-errors)
4. [Deployment API Errors](#deployment-api-errors)
5. [Store Rejection Reasons](#store-rejection-reasons)
6. [ProGuard/Obfuscation Issues](#proguardobfuscation-issues)
7. [Version Conflict Errors](#version-conflict-errors)
8. [Quick Diagnostics](#quick-diagnostics)

---

## Build Errors

### 1. Flutter Build Fails with "Gradle sync failed"

**Symptom:**
```
FAILURE: Build failed with an exception.
* What went wrong:
A problem occurred configuring root project 'android'.
> Could not resolve all artifacts for configuration ':classpath'.
```

**Root Cause:** Gradle dependencies not downloaded or version mismatch

**Solution:**
```bash
# Step 1: Clean Flutter build cache
flutter clean

# Step 2: Delete Gradle cache
rm -rf ~/.gradle/caches/
rm -rf android/.gradle/

# Step 3: Invalidate Android Studio cache (if using Android Studio)
# File → Invalidate Caches / Restart

# Step 4: Get dependencies
flutter pub get

# Step 5: Rebuild
cd android && ./gradlew clean
cd ..
flutter build apk --release

# Step 6: If still failing, check Gradle version compatibility
# File: android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
# Update to latest compatible version

# Step 7: Update Gradle plugin version
# File: android/build.gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.1'  // Update this
}
```

**Prevention:**
- Lock Gradle versions in `gradle-wrapper.properties`
- Use Android Studio's "Sync Project with Gradle Files" regularly

---

### 2. Build Fails with "Execution failed for task ':app:lintVitalRelease'"

**Symptom:**
```
> Task :app:lintVitalRelease FAILED
Lint found errors in the project; aborting build.
```

**Root Cause:** Lint warnings treated as errors in release builds

**Solution:**
```gradle
// File: android/app/build.gradle

android {
    lintOptions {
        // Disable lint abort on error for release builds
        checkReleaseBuilds false
        // Or ignore specific warnings:
        abortOnError false
        disable 'InvalidPackage', 'MissingTranslation'
    }
}
```

**Better Solution (Fix lint issues instead of ignoring):**
```bash
# Run lint report
cd android && ./gradlew lint

# Open report: android/app/build/reports/lint-results.html
# Fix issues one by one

# Common fixes:
# - Missing translations: Add strings to strings.xml
# - Invalid package: Add to lintOptions.disable
# - Deprecated API: Update to new API
```

---

### 3. Build Fails with "Unsupported class file major version 61"

**Symptom:**
```
Unsupported class file major version 61
```

**Root Cause:** Java version mismatch (code compiled with Java 17 but running Java 11)

**Solution:**
```bash
# Check current Java version
java -version

# Expected: openjdk version "11.0.x" or higher

# If wrong version, install correct Java:
# macOS:
brew install openjdk@11

# Set JAVA_HOME
export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Verify
java -version

# Update Gradle to use Java 11
# File: android/gradle.properties
org.gradle.java.home=/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home

# Rebuild
flutter clean && flutter build apk --release
```

**Prevention:**
- Document required Java version in README.md
- Set JAVA_HOME in CI/CD environment variables

---

### 4. iOS Build Fails with "Pods not found"

**Symptom:**
```
CocoaPods not installed or not in valid state.
```

**Root Cause:** Missing or outdated CocoaPods dependencies

**Solution:**
```bash
# Step 1: Clean pods
cd ios
rm -rf Pods/ Podfile.lock .symlinks/

# Step 2: Update CocoaPods
sudo gem install cocoapods

# Step 3: Install pods
pod install --repo-update

# Step 4: If still failing, deintegrate and reinstall
pod deintegrate
pod install

# Step 5: Rebuild
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

**Prevention:**
- Commit `ios/Podfile.lock` to track pod versions
- Run `pod install` after every `flutter pub get`

---

### 5. Build Fails with "Insufficient storage space"

**Symptom:**
```
No space left on device
```

**Root Cause:** Build cache consuming disk space

**Solution:**
```bash
# Check disk usage
df -h

# Clean Flutter cache (saves ~5-10 GB)
flutter clean

# Clean Gradle cache (saves ~2-5 GB)
rm -rf ~/.gradle/caches/

# Clean Android Studio cache (saves ~1-3 GB)
rm -rf ~/Library/Caches/AndroidStudio*

# Clean Xcode derived data (saves ~10-20 GB)
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Clean npm cache (if using backend-genkit)
npm cache clean --force

# Check disk usage again
df -h
```

---

## Code Signing Failures

### 6. Android Keystore Not Found

**Symptom:**
```
FileNotFoundException: android/app/juan-heart-release-key.jks
```

**Root Cause:** Keystore file missing or path incorrect

**Solution:**
```bash
# Step 1: Verify keystore exists
ls -la android/app/juan-heart-release-key.jks

# If missing, restore from backup:
# - Check team password manager (1Password, LastPass)
# - Ask team members for backup copy
# - DO NOT commit keystore to git (security risk)

# Step 2: Verify key.properties file exists
ls -la android/key.properties

# If missing, create it:
cat > android/key.properties <<EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=juan-heart-release
storeFile=juan-heart-release-key.jks
EOF

# Step 3: Verify build.gradle references key.properties
# File: android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

# Step 4: Rebuild
flutter build appbundle --release
```

**Prevention:**
- Store keystore in secure location (DO NOT commit to git)
- Backup keystore to team password manager + secure cloud storage
- Document keystore recovery procedure in team wiki

---

### 7. iOS Code Signing Error: "No profiles for 'com.juanheart.mobile' were found"

**Symptom:**
```
error: No profiles for 'com.juanheart.mobile' were found
Xcode couldn't find any iOS App Store provisioning profiles matching 'com.juanheart.mobile'.
```

**Root Cause:** Provisioning profile missing or expired

**Solution:**
```bash
# Step 1: Check provisioning profiles in Xcode
open ios/Runner.xcworkspace
# Xcode → Preferences → Accounts → [Your Apple ID] → Manage Certificates

# Step 2: Download provisioning profiles
# Developer Portal: https://developer.apple.com/account/resources/profiles/list
# Download "Juan Heart App Store" profile

# Step 3: Install provisioning profile (double-click .mobileprovision file)

# Step 4: In Xcode project settings:
# Runner → Signing & Capabilities
# - Team: [Select your team]
# - Provisioning Profile: [Select downloaded profile]
# - Signing Certificate: Apple Distribution

# Step 5: Clean and rebuild
flutter clean
cd ios
xcodebuild clean
cd ..
flutter build ios --release

# Alternative: Use automatic signing (easier but less control)
# Xcode → Runner → Signing & Capabilities
# ✅ Automatically manage signing
```

**Prevention:**
- Renew certificates 1 month before expiration
- Set calendar reminders for certificate expiry dates
- Use fastlane match for team certificate management

---

### 8. Android Keystore Password Incorrect

**Symptom:**
```
Keystore was tampered with, or password was incorrect
```

**Root Cause:** Wrong password in key.properties

**Solution:**
```bash
# Step 1: Verify keystore password
keytool -list -v -keystore android/app/juan-heart-release-key.jks
# Enter keystore password: [try different passwords]

# If password unknown:
# - Check team password manager
# - Ask developer who created keystore
# - Check CI/CD environment variables

# Step 2: Update key.properties with correct password
# File: android/key.properties
storePassword=CORRECT_PASSWORD
keyPassword=CORRECT_PASSWORD

# Step 3: Rebuild
flutter build appbundle --release
```

**CRITICAL:** If keystore password is lost and no backup exists:
```
YOU CANNOT RECOVER THE KEYSTORE.

Impact:
- Cannot update existing app on Play Store
- Must create NEW app listing with NEW package name
- All users must reinstall (lose all local data)

Prevention:
- ALWAYS backup keystore + password to secure location
- Store password in team password manager (1Password, LastPass)
- Document keystore details in team wiki
```

---

## CI/CD Workflow Errors

### 9. GitHub Actions Build Fails with "flutter: command not found"

**Symptom:**
```
/home/runner/work/_temp/script.sh: line 1: flutter: command not found
```

**Root Cause:** Flutter not installed in CI environment

**Solution:**
```yaml
# File: .github/workflows/build.yml

name: Build and Test

on:
  push:
    branches: [master, develop]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      # Step 1: Checkout code
      - uses: actions/checkout@v3

      # Step 2: Set up Flutter (FIX)
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      # Step 3: Verify Flutter
      - name: Verify Flutter installation
        run: |
          flutter --version
          flutter doctor -v

      # Step 4: Get dependencies
      - name: Install dependencies
        run: flutter pub get

      # Step 5: Run tests
      - name: Run tests
        run: flutter test

      # Step 6: Build APK
      - name: Build APK
        run: flutter build apk --release
```

---

### 10. CI/CD Build Fails with "secrets.KEYSTORE_PASSWORD not set"

**Symptom:**
```
Error: Required secret 'KEYSTORE_PASSWORD' is not set
```

**Root Cause:** GitHub Secrets not configured

**Solution:**
```bash
# Step 1: Go to GitHub repository
# Settings → Secrets and variables → Actions

# Step 2: Add secrets:
# - KEYSTORE_PASSWORD (keystore password)
# - KEY_PASSWORD (key password)
# - KEYSTORE_BASE64 (base64-encoded keystore file)

# Step 3: Encode keystore to base64
base64 -i android/app/juan-heart-release-key.jks | pbcopy
# Paste into KEYSTORE_BASE64 secret

# Step 4: Update workflow to decode keystore
# File: .github/workflows/build.yml
- name: Decode keystore
  env:
    KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
  run: |
    echo "$KEYSTORE_BASE64" | base64 -d > android/app/juan-heart-release-key.jks

- name: Create key.properties
  env:
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
  run: |
    cat > android/key.properties <<EOF
    storePassword=$KEYSTORE_PASSWORD
    keyPassword=$KEY_PASSWORD
    keyAlias=juan-heart-release
    storeFile=juan-heart-release-key.jks
    EOF

- name: Build APK
  run: flutter build apk --release
```

---

### 11. fastlane Build Fails with "Could not find action 'upload_to_play_store'"

**Symptom:**
```
[!] Could not find action, lane or variable 'upload_to_play_store'.
```

**Root Cause:** fastlane plugin not installed

**Solution:**
```bash
# Step 1: Install fastlane supply plugin
cd android  # or ios for App Store
fastlane add_plugin supply

# Step 2: Verify Gemfile includes plugin
# File: android/Gemfile
source "https://rubygems.org"

gem "fastlane"
gem "fastlane-plugin-supply"  # Add this line

# Step 3: Install gems
bundle install

# Step 4: Verify plugin
fastlane search_plugins supply

# Step 5: Retry deployment
fastlane deploy
```

---

## Deployment API Errors

### 12. Google Play API Error: "APK with versionCode X already exists"

**Symptom:**
```
Google Api Error: apkUpgradeVersionConflict: APK specifies a version code that has already been used.
```

**Root Cause:** Version code not incremented

**Solution:**
```bash
# Step 1: Check current version in Play Console
# Production → Current version: 1.4.0 (versionCode: 12)

# Step 2: Increment version code in pubspec.yaml
# Old: version: 1.4.0+12
# New: version: 1.5.0+13  # Build number MUST be 13 or higher

# Step 3: Update android/app/build.gradle
android {
    defaultConfig {
        versionCode 13  # Must be higher than 12
        versionName "1.5.0"
    }
}

# Step 4: Rebuild and upload
flutter build appbundle --release
# Upload to Play Console
```

**Prevention:**
- Use automated version bumping script (see 01-google-play-release.md)
- CI/CD pipeline auto-increments build number

---

### 13. Google Play API Error: "The keystore used to sign the APK is different"

**Symptom:**
```
Upload failed: You uploaded an APK that is signed with a different certificate to your previous APKs.
```

**Root Cause:** Using different keystore than original app

**Solution:**
```
THIS IS A CRITICAL ERROR - CANNOT BE FIXED BY RE-SIGNING.

Google Play permanently associates an app with its original keystore.

Options:
1. Find the original keystore (check backups, team members)
2. If lost, you CANNOT update the existing app
3. Must create NEW app with NEW package name
4. All users must reinstall

Prevention (for future):
- ALWAYS backup keystore to multiple secure locations
- Use Google Play App Signing (Play Console manages keystore)
- Store keystore in team password manager + cloud backup
```

**How to Enable Google Play App Signing (RECOMMENDED):**
```bash
# Step 1: Generate upload key (different from app signing key)
keytool -genkey -v -keystore upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Step 2: Sign APK with upload key
# Update android/key.properties to use upload-key.jks

# Step 3: Upload to Play Console
# Play Console → Release → Setup → App integrity → App signing
# ✅ Enroll in Play App Signing

# Step 4: Upload app signed with upload key
# Google Play will re-sign with its own key before distribution

# Benefits:
# - Google manages the app signing key (no loss risk)
# - You only manage upload key (can be reset if lost)
```

---

### 14. App Store Connect API Error: "This bundle is invalid. The bundle identifier is not valid."

**Symptom:**
```
ERROR ITMS-90168: "The bundle identifier 'com.juanheart.mobile' does not match the bundle identifier in your App Store Connect record 'com.juanheart.app'."
```

**Root Cause:** Bundle ID mismatch between app and App Store Connect

**Solution:**
```bash
# Step 1: Check bundle ID in App Store Connect
# App Store Connect → My Apps → Juan Heart Mobile
# Expected: com.juanheart.mobile

# Step 2: Verify bundle ID in Xcode
open ios/Runner.xcworkspace
# Runner → General → Bundle Identifier: com.juanheart.mobile

# Step 3: If mismatch, update Info.plist
# File: ios/Runner/Info.plist
<key>CFBundleIdentifier</key>
<string>com.juanheart.mobile</string>  # Must match App Store Connect

# Step 4: Clean and rebuild
flutter clean
flutter build ios --release

# Step 5: Re-upload to App Store Connect
cd ios
fastlane beta
```

---

### 15. Deployment Timeout Error: "Upload to Play Store timed out after 10 minutes"

**Symptom:**
```
Timeout: Upload to Google Play Console timed out after 600 seconds
```

**Root Cause:** Slow network or large AAB file

**Solution:**
```bash
# Option 1: Increase timeout in fastlane
# File: android/fastlane/Fastfile
lane :deploy do
  upload_to_play_store(
    track: 'production',
    aab: '../build/app/outputs/bundle/release/app-release.aab',
    timeout: 1800  # Increase to 30 minutes (1800 seconds)
  )
end

# Option 2: Reduce AAB size
# - Optimize images (use WebP format)
# - Remove unused assets
# - Enable ProGuard shrinking

# Option 3: Upload manually via web UI
# - Go to Play Console
# - Production → Create new release
# - Upload AAB manually (more reliable for large files)

# Option 4: Check network connection
# - Use wired connection instead of WiFi
# - Disable VPN (can slow uploads)
```

---

## Store Rejection Reasons

### 16. Google Play Rejection: "Your app contains security vulnerabilities"

**Reason:**
```
Your app has been rejected due to security vulnerabilities in third-party libraries.

Vulnerable libraries:
- com.google.android.gms:play-services-auth:19.0.0 (CVE-2023-XXXX)
```

**Solution:**
```bash
# Step 1: Identify vulnerable libraries
flutter pub outdated

# Step 2: Update dependencies in pubspec.yaml
dependencies:
  google_sign_in: ^6.1.0  # Update to latest version

# Step 3: Update Gradle dependencies
# File: android/app/build.gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'  # Updated
}

# Step 4: Run security audit
flutter pub audit

# Step 5: Rebuild and resubmit
flutter clean
flutter build appbundle --release
# Upload to Play Console
```

**Prevention:**
- Run `flutter pub outdated` monthly
- Subscribe to security advisories (GitHub Dependabot)
- Enable automated dependency updates in CI/CD

---

### 17. Google Play Rejection: "Missing privacy policy link"

**Reason:**
```
Your app collects personal data but does not provide a privacy policy link.
```

**Solution:**
```bash
# Step 1: Verify privacy policy exists and is accessible
# URL: https://juanheart.ph/privacy
# Must be publicly accessible (no login required)

# Step 2: Add privacy policy link in Play Console
# Play Console → App content → Privacy policy
# URL: https://juanheart.ph/privacy
# Save and resubmit

# Step 3: Add privacy policy link in app settings
# File: lib/presentation/pages/settings/privacy_preferences_screen.dart
ListTile(
  title: Text('Privacy Policy'),
  trailing: Icon(Icons.open_in_new),
  onTap: () => launchUrl('https://juanheart.ph/privacy'),
),
```

---

### 18. App Store Rejection: "Guideline 2.1 - App Completeness - App crashed during review"

**Reason:**
```
Your app crashed when we tried to [specific action] during review.

Crash log:
Fatal Exception: java.lang.NullPointerException
at com.juanheart.mobile.MainActivity.onCreate(MainActivity.java:42)
```

**Solution:**
```bash
# Step 1: Reproduce crash using reviewer's steps
# - Device: iPhone 15 Pro (iOS 17.2)
# - Steps: [Reviewer provided steps]

# Step 2: Fix crash (example: null check)
// Before:
String userName = user.getName();

// After:
String userName = user != null ? user.getName() : "Guest";

# Step 3: Add regression test
test('MainActivity should handle null user', () {
  final activity = MainActivity(user: null);
  expect(() => activity.onCreate(), returnsNormally);
});

# Step 4: Test on physical device (NOT simulator)
flutter run --release -d [physical iPhone]

# Step 5: Resubmit with note:
"We've fixed the crash that occurred during review. The issue was a null
pointer exception when the user object was null. We've added null safety
checks and tested on iPhone 15 Pro (iOS 17.2).

Build: 1.5.1 (15)
Test account: reviewer@juanheart.ph / ReviewPass2025!"
```

---

### 19. App Store Rejection: "Guideline 5.1.1 - Data Collection - Health data consent missing"

**Reason:**
```
Your app collects health data (CVD risk scores, blood pressure) but does not obtain explicit user consent before collection.
```

**Solution:**
```dart
// File: lib/presentation/widgets/health_data_consent_dialog.dart

// Show BEFORE first assessment
class HealthDataConsentDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Health Data Collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Juan Heart collects the following health data to assess your cardiovascular disease risk:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildDataItem('Blood pressure readings'),
          _buildDataItem('Cholesterol levels'),
          _buildDataItem('Medical history responses'),
          _buildDataItem('CVD risk assessment scores'),
          SizedBox(height: 12),
          Text(
            'This data is:\n'
            '• Encrypted with AES-256\n'
            '• Stored securely on our servers\n'
            '• Used only for risk assessment\n'
            '• Never shared without your permission\n\n'
            'You can revoke consent and request data deletion anytime in Settings.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('I Consent'),
        ),
      ],
    );
  }

  Widget _buildDataItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// Usage: Show before first assessment
final consent = await showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (context) => HealthDataConsentDialog(),
);

if (consent == true) {
  await PrivacyService.saveHealthDataConsent(userId);
  // Proceed with assessment
} else {
  // Redirect to home screen
}
```

**Resubmit with note:**
```
"We've added explicit health data consent dialog that appears before the
first assessment. Users must actively consent before any health data is
collected. Consent can be revoked in Settings → Privacy Preferences.

The consent dialog clearly lists:
- What health data is collected
- How it's used
- How it's protected
- User's right to revoke consent

Please test with demo account:
- Username: reviewer@juanheart.ph
- Password: ReviewPass2025!
- On first login, consent dialog will appear before assessment."
```

---

## ProGuard/Obfuscation Issues

### 20. App Crashes in Release Build (Works Fine in Debug)

**Symptom:**
```
App works perfectly in debug mode but crashes immediately in release mode.

Crash log:
java.lang.NoSuchMethodError: No virtual method getName()
```

**Root Cause:** ProGuard obfuscation breaking reflection or method calls

**Solution:**
```proguard
# File: android/app/proguard-rules.pro

# Keep Juan Heart models (used with JSON serialization)
-keep class com.juanheart.mobile.models.** { *; }

# Keep BLoC classes
-keep class ** extends com.bloc.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Prevent obfuscation of model field names (breaks JSON parsing)
-keepclassmembers class com.juanheart.mobile.models.** {
    <fields>;
    <init>();
}

# Debugging: Print mappings (helps identify obfuscation issues)
-printmapping build/outputs/mapping/release/mapping.txt
-printusage build/outputs/mapping/release/unused.txt
-printseeds build/outputs/mapping/release/seeds.txt
```

**Rebuild and test:**
```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
# Test thoroughly on physical device
```

**Debugging ProGuard issues:**
```bash
# Step 1: Disable ProGuard to verify it's the cause
# File: android/app/build.gradle
buildTypes {
    release {
        minifyEnabled false  # Temporarily disable
        shrinkResources false
    }
}

# Step 2: If crash goes away, ProGuard is the issue
# Re-enable and add specific keep rules

# Step 3: Use ProGuard mapping to decode obfuscated crash logs
# Upload mapping.txt to Play Console → Deobfuscation files
```

---

### 21. Missing ProGuard Mapping File (Cannot Decode Crash Logs)

**Symptom:**
```
Crash log shows obfuscated method names:
at com.juanheart.mobile.a.b.c(Unknown Source)

Cannot identify where crash occurred.
```

**Solution:**
```bash
# Step 1: Locate mapping file
ls -la android/app/build/outputs/mapping/release/mapping.txt

# If missing, rebuild release APK:
flutter build apk --release

# Step 2: Upload mapping file to Play Console
# Play Console → Release → App bundle → [Version] → Deobfuscation files
# Upload: mapping.txt

# Step 3: Re-download crash report
# Play Console → Crashes and ANRs → [Select crash]
# Crash log will now show deobfuscated method names

# Step 4: Archive mapping files for all releases
mkdir -p mappings/
cp android/app/build/outputs/mapping/release/mapping.txt mappings/v1.5.0-mapping.txt
# DO NOT commit to git (contains reverse-engineering info)
# Store in secure location (team password manager or private cloud)
```

**Prevention:**
```yaml
# File: .github/workflows/build.yml

# Automatically archive mapping files in CI/CD
- name: Archive ProGuard mapping
  if: github.ref == 'refs/heads/master'
  run: |
    mkdir -p mappings
    cp android/app/build/outputs/mapping/release/mapping.txt \
       mappings/mapping-${{ github.sha }}.txt

- name: Upload mapping artifact
  uses: actions/upload-artifact@v3
  with:
    name: proguard-mapping
    path: mappings/
    retention-days: 90  # Keep for 90 days
```

---

## Version Conflict Errors

### 22. "versionCode cannot be less than previous release"

**Symptom:**
```
Google Play Console error: Version code 12 has already been used. Try a different version code.
```

**Solution:**
```bash
# Increment build number (NEVER reuse version codes)
# File: pubspec.yaml
version: 1.5.0+13  # Build number MUST be ≥13

# File: android/app/build.gradle
versionCode 13

# Rebuild
flutter build appbundle --release
```

---

### 23. "Version conflict: CFBundleShortVersionString does not match"

**Symptom:**
```
ERROR ITMS-90062: "The bundle version '1.5.0' does not match the version '1.4.0' in the Info.plist file."
```

**Solution:**
```bash
# Ensure version matches across files

# File: pubspec.yaml
version: 1.5.0+13

# File: ios/Runner/Info.plist
<key>CFBundleShortVersionString</key>
<string>1.5.0</string>  # Must match pubspec.yaml
<key>CFBundleVersion</key>
<string>13</string>  # Must match build number

# Rebuild
flutter clean
flutter build ios --release
```

---

### 24. Dependency Version Conflict

**Symptom:**
```
Because juan_heart depends on package_a >=2.0.0 and package_b <2.0.0 which depends on package_a >=1.0.0 <2.0.0, version solving failed.
```

**Solution:**
```bash
# Option 1: Update conflicting package
# File: pubspec.yaml
dependencies:
  package_b: ^3.0.0  # Update to version that supports package_a 2.0.0

# Option 2: Override dependency version (use with caution)
dependency_overrides:
  package_a: ^2.0.0  # Force version 2.0.0

# Option 3: Downgrade package_a
dependencies:
  package_a: ^1.9.0  # Use version compatible with package_b

# Run dependency resolution
flutter pub get
flutter pub outdated  # Check for available updates

# Test thoroughly after resolving conflicts
flutter test
```

---

## Quick Diagnostics

### Diagnostic Checklist (Run Before Seeking Help)

```bash
#!/bin/bash
# File: scripts/diagnostic_check.sh
# Run this script when encountering deployment issues

echo "=== Juan Heart Mobile Deployment Diagnostics ==="
echo ""

# 1. Flutter version
echo "1. Flutter Version:"
flutter --version
echo ""

# 2. Java version
echo "2. Java Version:"
java -version
echo ""

# 3. Android SDK
echo "3. Android SDK:"
echo $ANDROID_HOME
ls -la $ANDROID_HOME/platforms/
echo ""

# 4. Xcode version (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "4. Xcode Version:"
  xcodebuild -version
  echo ""
fi

# 5. Dependencies
echo "5. Dependency Status:"
flutter pub outdated
echo ""

# 6. Build configuration
echo "6. Build Configuration:"
cat pubspec.yaml | grep "version:"
cat android/app/build.gradle | grep -E "versionCode|versionName"
echo ""

# 7. Code signing
echo "7. Code Signing:"
if [ -f "android/app/juan-heart-release-key.jks" ]; then
  echo "✅ Android keystore found"
else
  echo "❌ Android keystore MISSING"
fi

if [ -f "android/key.properties" ]; then
  echo "✅ key.properties found"
else
  echo "❌ key.properties MISSING"
fi
echo ""

# 8. Disk space
echo "8. Disk Space:"
df -h | grep -E "Filesystem|/$"
echo ""

# 9. Flutter doctor
echo "9. Flutter Doctor:"
flutter doctor -v
echo ""

echo "=== Diagnostics Complete ==="
echo "Save this output when asking for help."
```

**Usage:**
```bash
chmod +x scripts/diagnostic_check.sh
./scripts/diagnostic_check.sh > diagnostic_output.txt
# Share diagnostic_output.txt when asking for help
```

---

### Common Error Messages Decoder

| Error Message | Likely Cause | Quick Fix |
|---------------|--------------|-----------|
| `Gradle sync failed` | Gradle cache corrupted | `flutter clean && rm -rf android/.gradle` |
| `Pods not found` | CocoaPods not installed | `cd ios && pod install` |
| `Command not found: flutter` | Flutter not in PATH | `export PATH="$PATH:/flutter/bin"` |
| `Keystore was tampered` | Wrong keystore password | Check team password manager |
| `Version code already used` | Forgot to increment build number | Bump `versionCode` in build.gradle |
| `No space left on device` | Build cache too large | `flutter clean && rm -rf ~/.gradle/caches` |
| `Unsupported class file major version` | Java version mismatch | `export JAVA_HOME=/path/to/java11` |
| `Certificate has expired` | iOS certificate expired | Renew certificate in Apple Developer Portal |
| `Bundle ID does not match` | Info.plist bundle ID wrong | Update CFBundleIdentifier in Info.plist |
| `Lint found errors` | Lint errors blocking build | Disable with `abortOnError false` or fix issues |

---

## Emergency Contacts

**When to Escalate:**
- Cannot resolve issue after 2 hours of troubleshooting
- Blocking production deployment
- User-impacting incident in progress

**Escalation Path:**
1. **Team Slack** (#dev-team): Quick questions, common issues
2. **Tech Lead** (@tech-lead): Complex build/deployment issues
3. **DevOps Team** (@devops): CI/CD, infrastructure issues
4. **Google Play Support**: Store-specific issues (response: 24-48 hours)
5. **Apple Developer Support**: App Store issues (response: 1-3 days)

---

## Related Documentation
- [01-google-play-release.md](./01-google-play-release.md) - Google Play deployment
- [02-app-store-release.md](./02-app-store-release.md) - App Store deployment
- [03-hotfix-deployment.md](./03-hotfix-deployment.md) - Emergency hotfixes
- [04-rollback-procedures.md](./04-rollback-procedures.md) - Rollback guide

---

**Document History:**
- v1.0 (Jan 2025): Initial troubleshooting guide with 24+ scenarios
- Owner: JH-Git-Guardian
- Review Cycle: Update after each unique deployment issue encountered
