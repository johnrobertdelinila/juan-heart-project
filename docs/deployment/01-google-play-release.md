# Google Play Production Release Guide

**Estimated Time:** 3-4 hours (initial release) | 1-2 hours (subsequent releases)
**Last Updated:** January 2025
**Document Owner:** JH-Git-Guardian

---

## Table of Contents
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Version Bumping](#version-bumping)
- [Building Release APK/AAB](#building-release-apkaab)
- [Upload to Google Play Console](#upload-to-google-play-console)
- [Staged Rollout Configuration](#staged-rollout-configuration)
- [Release Notes](#release-notes)
- [Post-Deployment Verification](#post-deployment-verification)
- [Monitoring During Rollout](#monitoring-during-rollout)
- [Rollout Decision Matrix](#rollout-decision-matrix)

---

## Pre-Deployment Checklist

### Code Quality Gates (MANDATORY)
```bash
# Run from project root
cd /Users/johnrobertdelinila/AndroidStudioProjects/Juan-Heart-Mobile

# 1. Run all tests
flutter test
# Expected: All tests pass, coverage ≥80%

# 2. Run analyzer
flutter analyze
# Expected: No issues found

# 3. Run integration tests
flutter test integration_test/
# Expected: All critical user flows pass

# 4. Check for hardcoded values
grep -r "http://10.0.2.2" lib/
# Expected: No output (use environment variables)

# 5. Verify .env is not committed
git ls-files | grep .env
# Expected: No output

# 6. Check code signing
ls -la android/app/juan-heart-release-key.jks
# Expected: Keystore exists (DO NOT commit to git)
```

### Clinical Validation
- [ ] PHC algorithm unchanged (Likelihood × Impact = 1-25)
- [ ] Risk level mapping verified (Low/Mild/Moderate/High/Critical)
- [ ] Test assessments match expected outputs
- [ ] No modifications to assessment scoring without PHC approval

### Security Checklist
- [ ] AES-256 encryption enabled for sensitive data
- [ ] TLS 1.3 configured for API calls
- [ ] API keys stored in environment variables (not hardcoded)
- [ ] ProGuard rules configured (`android/app/proguard-rules.pro`)
- [ ] Network security config verified (`android/app/src/main/res/xml/network_security_config.xml`)

### Feature Validation
- [ ] Offline mode works (disconnect device, test assessments)
- [ ] Sync queue processes successfully
- [ ] Appointment booking flow complete
- [ ] AI consent dialog appears (if feature flag enabled)
- [ ] PDF generation works
- [ ] GPS facility search functional
- [ ] All Material Design icons render correctly (no missing emojis)

### Performance Benchmarks
```bash
# Build release APK and measure
flutter build apk --release
# Check APK size: MUST be <40MB

# Measure cold start time (use Android Studio Profiler)
# Target: <3 seconds on mid-range device (e.g., Samsung A32)
```

### Documentation
- [ ] CHANGELOG.md updated with user-facing changes
- [ ] PLANNING.md reflects current architecture
- [ ] TASKS.md marked complete for included features
- [ ] API changes documented in relevant service files

---

## Version Bumping

### Semantic Versioning Strategy
**Format:** `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR:** Breaking changes, major UI overhauls (e.g., 2.0.0)
- **MINOR:** New features, non-breaking changes (e.g., 1.5.0)
- **PATCH:** Bug fixes, minor improvements (e.g., 1.4.3)
- **BUILD:** Auto-increments with each release (internal tracking)

### Update `pubspec.yaml`
```yaml
# File: pubspec.yaml
version: 1.5.0+15  # Change this line

# Examples:
# - Bug fix: 1.4.2+14 → 1.4.3+15
# - New feature: 1.4.3+15 → 1.5.0+16
# - Breaking change: 1.5.0+16 → 2.0.0+17
```

**Build Number Rules:**
- MUST increment by 1 for every release
- Google Play rejects if build number ≤ previous version
- Never reuse build numbers (even for rolled-back versions)

### Update Build Configuration
```gradle
// File: android/app/build.gradle
android {
    defaultConfig {
        applicationId "com.juanheart.mobile"
        versionCode 15  // Match build number from pubspec.yaml
        versionName "1.5.0"  // Match version from pubspec.yaml
    }
}
```

### Version Bump Automation
```bash
# Use this script to auto-bump version
#!/bin/bash
# File: scripts/bump_version.sh

CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
MAJOR=$(echo $CURRENT_VERSION | cut -d. -f1)
MINOR=$(echo $CURRENT_VERSION | cut -d. -f2)
PATCH=$(echo $CURRENT_VERSION | cut -d. -f3 | cut -d+ -f1)
BUILD=$(echo $CURRENT_VERSION | cut -d+ -f2)

echo "Current version: $CURRENT_VERSION"
echo "Select bump type:"
echo "1) Patch (bug fix): ${MAJOR}.${MINOR}.$((PATCH+1))+$((BUILD+1))"
echo "2) Minor (feature): ${MAJOR}.$((MINOR+1)).0+$((BUILD+1))"
echo "3) Major (breaking): $((MAJOR+1)).0.0+$((BUILD+1))"
read -p "Choice: " choice

case $choice in
  1) NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH+1))+$((BUILD+1))" ;;
  2) NEW_VERSION="${MAJOR}.$((MINOR+1)).0+$((BUILD+1))" ;;
  3) NEW_VERSION="$((MAJOR+1)).0.0+$((BUILD+1))" ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "Updated to $NEW_VERSION"
```

---

## Building Release APK/AAB

### Environment Setup
```bash
# 1. Ensure Flutter is up to date
flutter --version
# Expected: Flutter 3.16.0 or higher

# 2. Clean previous builds
flutter clean
flutter pub get

# 3. Verify code signing keystore exists
export KEYSTORE_PATH=android/app/juan-heart-release-key.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
  echo "ERROR: Keystore not found at $KEYSTORE_PATH"
  exit 1
fi

# 4. Load keystore credentials (NEVER commit these)
# Create android/key.properties:
# storePassword=<your-store-password>
# keyPassword=<your-key-password>
# keyAlias=juan-heart-release
# storeFile=juan-heart-release-key.jks
```

### Build Android App Bundle (AAB) - RECOMMENDED
```bash
# AAB supports dynamic delivery and smaller downloads
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
# Verify size: MUST be <40MB
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### Build APK (Legacy/Testing)
```bash
# For devices that don't support AAB
flutter build apk --release --split-per-abi

# Outputs (smaller files due to ABI splitting):
# - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32-bit ARM)
# - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (64-bit ARM)
# - build/app/outputs/flutter-apk/app-x86_64-release.apk (64-bit x86)
```

### Verify Build
```bash
# 1. Check ProGuard obfuscation
unzip -l build/app/outputs/bundle/release/app-release.aab | grep "classes.dex"
# Expected: classes.dex should exist

# 2. Verify minimum SDK version
aapt dump badging build/app/outputs/bundle/release/app-release.aab | grep sdkVersion
# Expected: minSdkVersion:'21' (Android 5.0+)

# 3. Check permissions
aapt dump badging build/app/outputs/bundle/release/app-release.aab | grep "uses-permission"
# Verify only required permissions are listed

# 4. Test on physical device BEFORE upload
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# Manual testing checklist:
# - Launch app (cold start <3s)
# - Complete full assessment flow
# - Book appointment (online mode)
# - Enable airplane mode → complete assessment (offline mode)
# - Disable airplane mode → verify sync
# - Generate PDF report
# - GPS facility search
```

---

## Upload to Google Play Console

### Access Play Console
1. Navigate to: https://play.google.com/console
2. Select **Juan Heart Mobile** app
3. Go to **Release** → **Production**

### Upload Process
```bash
# Option 1: Manual Upload via Web UI
# 1. Click "Create new release"
# 2. Upload app-release.aab
# 3. Google Play will analyze the bundle (2-5 minutes)
# 4. Review warnings/errors (see troubleshooting section)

# Option 2: Automated Upload via fastlane (RECOMMENDED)
# Install fastlane first:
# gem install fastlane

# Configure fastlane (one-time setup)
# File: android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Upload to Google Play Console"
  lane :deploy do
    upload_to_play_store(
      track: 'production',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end

# Deploy command:
cd android
fastlane deploy
```

### Review Pre-Release Report
Google Play automatically analyzes the bundle:

| Check | Expected Result | Action if Failed |
|-------|----------------|------------------|
| **APK Size** | <150MB | Optimize assets, enable ProGuard |
| **64-bit Support** | Required | Verify `arm64-v8a` ABI included |
| **Target API Level** | 33+ (Android 13) | Update `android/app/build.gradle` |
| **Permissions** | Only declared permissions | Remove unused permissions |
| **Security Vulnerabilities** | None found | Update dependencies |
| **Pre-Launch Report** | Crashes: 0 | Fix crashes before proceeding |

**Pre-Launch Report:** Google tests on ~20 devices automatically
- Check for crashes, ANRs, security vulnerabilities
- Review screenshots to verify UI renders correctly
- Fix any issues before proceeding to rollout

---

## Staged Rollout Configuration

### Why Staged Rollout?
- **Risk Mitigation:** Catch critical bugs with small user base
- **Performance Monitoring:** Verify server load handling
- **Gradual Validation:** Monitor crash rates, ANRs before full release

### Rollout Stages (RECOMMENDED)

| Stage | Percentage | Duration | Success Criteria | Decision Point |
|-------|-----------|----------|------------------|----------------|
| **Alpha** | 5% | 24 hours | Crash rate <0.5%, ANR <0.1% | Proceed or halt |
| **Beta** | 20% | 48 hours | Crash rate <0.3%, no critical bugs | Proceed or halt |
| **Phase 1** | 50% | 72 hours | Crash rate <0.2%, positive feedback | Proceed or halt |
| **Phase 2** | 100% | - | Monitor for 7 days | - |

### Configure Rollout in Play Console
```
1. In "Create new release" screen:
2. Expand "Release details"
3. Select "Staged rollout"
4. Set initial percentage: 5%
5. Click "Save" → "Review release"
6. Click "Start rollout to Production"
```

### Increase Rollout Percentage
```bash
# After success criteria met at each stage:
1. Go to Play Console → Production track
2. Click "Manage rollout"
3. Select new percentage: 20% → 50% → 100%
4. Click "Update rollout"

# Rollout increases take effect within 1-2 hours
```

---

## Release Notes

### Template
```markdown
# Juan Heart Mobile v1.5.0

## New Features
- Feature name: Brief description (1-2 sentences)
- Feature name: Benefits to users

## Improvements
- Improved performance: Specific metric (e.g., "30% faster sync")
- Enhanced UI: What changed

## Bug Fixes
- Fixed issue where [scenario] caused [problem]
- Resolved crash when [action performed]

## What's Coming Next
- Teaser for next version features

---

**For Healthcare Providers:**
- Clinical validation: [PHC approval reference if applicable]
- Data accuracy: [Any changes to risk assessment]

**Security & Privacy:**
- Encryption: AES-256 maintained
- Compliance: HIPAA/PDPA compliant (if applicable)
```

### Example Release Notes (v1.5.0)
```markdown
# What's New in Juan Heart v1.5.0

## New Features
- **AI-Powered Risk Assessment:** Get instant CVD risk scores powered by Google Gemini (with your consent)
- **Appointment History Export:** Download your complete appointment history as PDF

## Improvements
- Offline Mode: Improved sync reliability with automatic retry (3 attempts)
- GPS Facility Search: Now shows 8 nearby health facilities with accurate distances
- UI Polish: Replaced decorative emojis with Material Design icons for cleaner interface

## Bug Fixes
- Fixed date picker not allowing future appointments
- Resolved crash when viewing analytics without internet
- Fixed sync errors for users with special characters in names

## Technical Updates
- Backend Migration: Now syncs with centralized MySQL database
- Performance: 25% faster app startup time
- Security: Updated TLS to version 1.3

---

**For Healthcare Providers:**
This release has been clinically validated by the Public Health Council. The risk assessment algorithm (Likelihood × Impact = 1-25) remains unchanged.

**Privacy Notice:**
AI features require explicit consent. Your data is encrypted with AES-256 and never shared without permission.
```

### Release Notes Best Practices
- **User-Centric Language:** Avoid technical jargon (e.g., "BLoC refactor")
- **Highlight Benefits:** Focus on "what users can do now" vs. "what we changed"
- **Clinical Context:** Mention PHC validation for trust
- **Character Limit:** Google Play allows 500 characters for "What's New" (expand in full description)
- **Localization:** Provide Tagalog translations for Filipino users

---

## Post-Deployment Verification

### Immediate Checks (0-2 hours post-release)

#### 1. Play Store Listing Verification
```bash
# Check that update is live:
# - Open Play Store on Android device
# - Search "Juan Heart Mobile"
# - Verify version number matches deployed version
# - Check "What's New" section displays correctly
```

#### 2. Install Fresh Copy
```bash
# Install on test device to verify Play Store distribution
adb uninstall com.juanheart.mobile
# Then install from Play Store manually
# Test critical flows:
# - Sign up new user
# - Complete assessment
# - Book appointment
# - View analytics
```

#### 3. Monitor Crash Reports
```
Google Play Console → Quality → Android vitals → Crashes and ANRs
- Check crash-free users: MUST be >99.5%
- Review any new crash clusters
- Verify no crashes in critical flows (authentication, assessment)
```

#### 4. Backend Sync Verification
```bash
# Check backend logs (MySQL database)
# Verify new users are syncing successfully
# Check for error spikes in sync_queue_service logs

# Example query:
SELECT COUNT(*) FROM assessments
WHERE created_at > NOW() - INTERVAL 2 HOUR
AND app_version = '1.5.0';
# Expected: Assessments are being created
```

### First 24 Hours Monitoring

#### Crash Rate Dashboard
| Metric | Target | Alert Threshold | Action |
|--------|--------|----------------|--------|
| Crash-free users | >99.5% | <99% | Pause rollout, investigate |
| ANR rate | <0.1% | >0.3% | Check for blocking operations |
| Slow rendering (>16ms) | <5% | >10% | Optimize layouts |

#### User Feedback Review
```
Play Console → Ratings and reviews → Filter: "Last 7 days"
- Read 1-star and 2-star reviews first
- Identify common complaints
- Respond within 24 hours (builds trust)

Response template for negative reviews:
"Thank you for your feedback! We're sorry to hear about [issue].
Our team is investigating and will release a fix in the next update.
Please contact support@juanheart.ph for urgent assistance."
```

#### Analytics Validation
```bash
# Check Firebase Analytics (if integrated)
# Key events to monitor:
# - assessment_completed: Should match historical averages
# - appointment_booked: Verify conversion rate
# - sync_failure: MUST be <1% of sync attempts
# - app_crash: MUST be <0.5% of sessions
```

---

## Monitoring During Rollout

### Automated Monitoring Setup

#### Firebase Crashlytics Alerts
```yaml
# File: .github/workflows/monitor-crashlytics.yml
# Runs every 4 hours during rollout

name: Crashlytics Monitor
on:
  schedule:
    - cron: '0 */4 * * *'  # Every 4 hours

jobs:
  check-crashes:
    runs-on: ubuntu-latest
    steps:
      - name: Check crash rate
        run: |
          # Fetch crash rate from Firebase API
          CRASH_RATE=$(curl -H "Authorization: Bearer $FIREBASE_TOKEN" \
            "https://firebase.googleapis.com/v1beta1/projects/juan-heart/apps/android:com.juanheart.mobile/crashlytics" \
            | jq '.crashFreePercentage')

          if (( $(echo "$CRASH_RATE < 99.0" | bc -l) )); then
            echo "ALERT: Crash rate below threshold: $CRASH_RATE%"
            exit 1
          fi
```

#### Manual Checks Checklist (Every 8 hours)
- [ ] **Play Console Vitals:** Check crash-free users percentage
- [ ] **User Reviews:** Read latest 1-star and 2-star reviews
- [ ] **Backend Logs:** Check for error spikes in API logs
- [ ] **Sync Queue:** Verify sync success rate >95%
- [ ] **Performance:** Cold start time <3s (use Firebase Performance Monitoring)

### Metrics to Track

#### Critical Metrics (Halt rollout if thresholds breached)
| Metric | Target | Alert Threshold | Emergency Threshold |
|--------|--------|----------------|---------------------|
| Crash-free users | >99.5% | <99% | <98% |
| ANR rate | <0.1% | >0.3% | >0.5% |
| API error rate | <1% | >5% | >10% |
| Sync failure rate | <1% | >5% | >15% |

#### Quality Metrics (Monitor for trends)
| Metric | Target | Action |
|--------|--------|--------|
| Average rating | ≥4.5 stars | Investigate if drops below 4.0 |
| Slow rendering | <5% frames >16ms | Optimize if >10% |
| Cold start time | <3s | Investigate if >5s |
| App size | <40MB | Reduce assets if >45MB |

---

## Rollout Decision Matrix

### Decision Tree: Proceed to Next Stage?

```
┌─────────────────────────────────────┐
│ Check Current Stage Success Criteria│
└──────────────┬──────────────────────┘
               │
               ▼
     ┌─────────────────────┐
     │ Crash Rate <0.5%?   │
     └─────┬─────────┬─────┘
          YES       NO
           │         │
           │         ▼
           │    ┌──────────────┐
           │    │ HALT ROLLOUT │──► Investigate crashes
           │    └──────────────┘
           ▼
     ┌─────────────────────┐
     │ ANR Rate <0.1%?     │
     └─────┬─────────┬─────┘
          YES       NO
           │         │
           │         ▼
           │    ┌──────────────┐
           │    │ HALT ROLLOUT │──► Optimize blocking code
           │    └──────────────┘
           ▼
     ┌─────────────────────┐
     │ Critical Bugs?      │
     └─────┬─────────┬─────┘
          NO        YES
           │         │
           │         ▼
           │    ┌──────────────┐
           │    │ PAUSE ROLLOUT│──► Release hotfix
           │    └──────────────┘
           ▼
     ┌─────────────────────┐
     │ PROCEED TO NEXT     │
     │ STAGE (Increase %)  │
     └─────────────────────┘
```

### When to Pause Rollout

#### IMMEDIATE PAUSE (Within 1 hour)
- Crash-free users <98%
- Data loss or corruption reports
- Security vulnerability discovered
- Authentication failures preventing sign-in
- PHC algorithm producing incorrect risk scores

#### PAUSE WITHIN 4 HOURS
- Crash-free users <99%
- ANR rate >0.5%
- Sync failure rate >15%
- Multiple reports of critical feature broken (e.g., appointment booking)
- Negative reviews spike (>50% 1-star in last 24h)

#### MONITOR & DECIDE (Within 24 hours)
- Crash-free users 99-99.5%
- ANR rate 0.3-0.5%
- Sync failure rate 5-15%
- Minor UI bugs reported
- Average rating drops 0.3 stars

### How to Pause/Halt Rollout

#### Pause Rollout (Temporary)
```bash
# Stops rollout at current percentage (e.g., keeps 20%, doesn't increase to 50%)
1. Go to Play Console → Production track
2. Click "Manage rollout"
3. Select "Pause rollout"
4. Add reason: "Investigating [issue description]"
5. Click "Pause"

# Resume after fix:
1. Release hotfix (see 03-hotfix-deployment.md)
2. Click "Resume rollout" after validation
```

#### Halt Rollout (Permanent - Rollback Required)
```bash
# Completely stops rollout and reverts users to previous version
1. Go to Play Console → Production track
2. Click "Halt rollout"
3. Select previous stable version to rollback to
4. Check "Rollback traffic" (reduces current version to 0%)
5. Click "Halt and rollback"

# Follow rollback procedures in 04-rollback-procedures.md
```

---

## Success Criteria Summary

### Release is Successful if:
- ✅ Crash-free users ≥99.5% for 7 days post-100% rollout
- ✅ ANR rate ≤0.1% consistently
- ✅ Average Play Store rating ≥4.5 stars
- ✅ No critical bugs reported in user reviews
- ✅ Sync success rate ≥95%
- ✅ No security vulnerabilities detected
- ✅ Backend handles traffic without errors
- ✅ All critical user flows operational (assessment, booking, sync)

### Post-Release Activities (Within 7 days)
- [ ] Monitor crash reports daily
- [ ] Respond to user reviews (target: <24 hours)
- [ ] Review Firebase Analytics for anomalies
- [ ] Check backend logs for error spikes
- [ ] Update CHANGELOG.md with actual release date
- [ ] Mark TASKS.md items as deployed to production
- [ ] Schedule retrospective meeting to discuss lessons learned

---

## Quick Reference Commands

```bash
# Full release workflow
flutter clean && flutter pub get
flutter test && flutter analyze
flutter build appbundle --release
# Upload to Play Console
# Configure staged rollout (5% → 20% → 50% → 100%)

# Verify deployment
adb uninstall com.juanheart.mobile
# Install from Play Store
# Test critical flows

# Monitor metrics
# Play Console → Android vitals
# Firebase Crashlytics → Stability
```

---

## Related Documentation
- [02-app-store-release.md](./02-app-store-release.md) - iOS deployment
- [03-hotfix-deployment.md](./03-hotfix-deployment.md) - Emergency fixes
- [04-rollback-procedures.md](./04-rollback-procedures.md) - Rollback guide
- [troubleshooting.md](./troubleshooting.md) - Common deployment errors

---

**Document History:**
- v1.0 (Jan 2025): Initial guide for Juan Heart Mobile production releases
- Owner: JH-Git-Guardian
- Review Cycle: Before each major release
