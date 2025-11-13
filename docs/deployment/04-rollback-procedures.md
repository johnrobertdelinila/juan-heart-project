# Rollback Procedures Guide

**Estimated Time:** 30 minutes - 2 hours (depending on platform and method)
**Last Updated:** January 2025
**Document Owner:** JH-Git-Guardian

---

## Table of Contents
- [When to Rollback](#when-to-rollback)
- [Rollback vs Forward-Fix Decision](#rollback-vs-forward-fix-decision)
- [Google Play Rollback](#google-play-rollback)
- [App Store Rollback](#app-store-rollback)
- [Database Migration Rollback](#database-migration-rollback)
- [User Communication Plan](#user-communication-plan)
- [Testing Rolled-Back Version](#testing-rolled-back-version)
- [Post-Rollback Incident Report](#post-rollback-incident-report)

---

## When to Rollback

### Immediate Rollback Triggers (Within 1 hour)

#### Critical Issues (NO DISCUSSION NEEDED)
- **Data Corruption:** Users reporting lost or corrupted assessments/appointments
- **Massive Crash Spike:** Crash-free users drop below 95% (>5% crash rate)
- **Security Breach:** API keys exposed, unauthorized data access detected
- **Authentication Failure:** >50% of users unable to sign in
- **PHC Algorithm Broken:** Risk scores calculating incorrectly for majority of assessments
- **Legal Violation:** GDPR/HIPAA compliance breach, privacy policy violation

#### High-Priority Issues (Discuss with team lead, rollback if no quick fix)
- **Core Feature Broken:** Assessment submission fails for >25% of users
- **Severe Performance Degradation:** App unusable (freeze/ANR rate >5%)
- **Payment System Down:** In-app purchases failing (if applicable)
- **Critical User Flow Blocked:** Cannot complete booking, sync, or assessment

### Rollback Decision Checklist

```
Answer YES/NO to each question:

❌ Is the new version WORSE than the old version?
   (Crash rate, data loss, user complaints)

❌ Is there NO quick forward-fix available (<2 hours)?

❌ Are >25% of users affected?

❌ Is user data at risk?

❌ Is there a workaround that users can't easily perform?

If 3+ answers are YES → ROLLBACK IMMEDIATELY
If 2 answers are YES → Strongly consider rollback
If 0-1 answers are YES → Forward-fix is better
```

---

## Rollback vs Forward-Fix Decision

### Decision Matrix

| Factor | Favor Rollback | Favor Forward-Fix |
|--------|---------------|-------------------|
| **Severity** | Critical (data loss, crashes >5%) | High/Medium (UI bugs, <5% users) |
| **Fix Complexity** | Complex (requires refactor, >4 hours) | Simple (1-line fix, <2 hours) |
| **Users Affected** | >25% of user base | <10% of user base |
| **Data Integrity** | At risk | Not at risk |
| **Workaround** | No workaround available | Users can work around issue |
| **Original Bug** | Minor/fixed in old version | Critical (can't reintroduce) |
| **Testing Time** | Forward-fix needs extensive testing | Quick fix, easy to validate |

### Decision Tree

```
┌─────────────────────────────────┐
│ Production Issue Detected       │
└──────────────┬──────────────────┘
               │
               ▼
     ┌─────────────────────┐
     │ Is new version WORSE│
     │ than old version?   │
     └─────┬─────────┬─────┘
          YES       NO
           │         │
           │         ▼
           │    ┌──────────────┐
           │    │ FORWARD-FIX  │
           │    └──────────────┘
           ▼
     ┌─────────────────────┐
     │ Can fix in <2 hours?│
     └─────┬─────────┬─────┘
          YES       NO
           │         │
           │         ▼
           │    ┌──────────────┐
           │    │ ROLLBACK     │
           │    └──────────────┘
           ▼
     ┌─────────────────────┐
     │ Will rollback       │
     │ reintroduce critical│
     │ bug?                │
     └─────┬─────────┬─────┘
          YES       NO
           │         │
           │         ▼
           │    ┌──────────────┐
           │    │ ROLLBACK     │
           │    └──────────────┘
           ▼
     ┌─────────────────────┐
     │ FORWARD-FIX         │
     │ (accept risk of     │
     │ old bug temporarily)│
     └─────────────────────┘
```

### Example Scenarios

#### Scenario 1: Clear Rollback Case
```
Situation:
- Deployed v1.5.0 with new sync algorithm
- Crash rate jumped from 1% → 8%
- 40% of users affected
- Users reporting lost assessments

Decision: ROLLBACK to v1.4.0
Reasoning:
✅ New version is WORSE (8% crash vs. 1%)
✅ Users affected >25%
✅ Data integrity at risk
✅ Old version was stable
❌ No quick fix available (sync algorithm rewrite needed)
```

#### Scenario 2: Clear Forward-Fix Case
```
Situation:
- Deployed v1.5.0 with new UI design
- Minor layout bug on analytics screen
- 5% of users affected
- No crashes, no data loss
- Fix is 3-line CSS change

Decision: FORWARD-FIX to v1.5.1
Reasoning:
❌ New version is not worse overall
✅ Quick fix available (<30 minutes)
✅ Users affected <10%
✅ No data risk
✅ Easy workaround (use different screen)
```

#### Scenario 3: Complex Decision
```
Situation:
- Deployed v1.5.0 (hotfix for sync crash)
- Original sync crash fixed ✅
- But introduced authentication delay (3-5 seconds)
- 100% of users affected by delay
- No crashes, no data loss

Decision: FORWARD-FIX to v1.5.1
Reasoning:
⚠️ New version has new issue BUT old version had critical crash
✅ Can optimize auth in 2 hours
❌ Rollback would reintroduce sync crash (worse than delay)
✅ Users can still authenticate (just slower)

Action: Deploy v1.5.1 forward-fix within 4 hours
```

---

## Google Play Rollback

### Method 1: Reduce Rollout Percentage (Fastest - 5 minutes)

**Use When:** Currently in staged rollout (not yet 100%)

```bash
# Steps:
1. Go to Google Play Console
   URL: https://play.google.com/console

2. Navigate to: Production → Manage rollout

3. Current rollout: 50% (example)
   Reduce to: 0% (or previous stable percentage)

4. Click "Update rollout"

5. Confirmation dialog:
   "This will stop the rollout and revert users to the previous version."
   Click "Reduce rollout"

# Result:
- New version stops rolling out
- Users who already updated: STAY on new version (cannot auto-downgrade)
- New installs/updates: Get previous stable version
- Takes effect: Within 1-2 hours
```

**Limitations:**
- Cannot force users who already updated to downgrade
- Only works if rollout is <100%
- Users on new version must manually reinstall old version

### Method 2: Halt Rollout + Promote Old Version (Standard - 30 minutes)

**Use When:** Need to completely stop new version distribution

```bash
# Steps:
1. Go to Play Console → Production track

2. Click "Halt rollout" on current version (v1.5.0)
   Reason: "Critical bug - reverting to v1.4.0"

3. Create new release (v1.4.0 re-upload)
   Upload: Previous stable AAB file (v1.4.0)

   IMPORTANT: You CANNOT upload same version code
   Workaround: Increment build number
   - Old: v1.4.0+12
   - Re-upload as: v1.4.0+14 (skip +13 which was broken v1.5.0)

4. Release notes:
"Temporary Rollback to v1.4.0

We've temporarily reverted to version 1.4.0 while we investigate
an issue in version 1.5.0. Your data is safe.

We apologize for the inconvenience and will release a fix soon.

If you're experiencing issues, please reinstall the app or contact
support@juanheart.ph"

5. Rollout: 100% (full rollout, no staging needed for rollback)

6. Submit for review (typically approved in 2-4 hours)
```

**Timeline:**
- Upload + submit: 5 minutes
- Google Play review: 2-4 hours
- Live to users: Within 1 hour after approval
- Total: ~3-5 hours

### Method 3: Emergency Rollback (Google Play Support - 1-2 hours)

**Use When:** Critical security issue, data loss affecting >50% of users

```bash
# Steps:
1. Contact Google Play Support
   URL: https://support.google.com/googleplay/android-developer/contact/

2. Select: "Technical Issue" → "Emergency Rollback Request"

3. Email template:

Subject: URGENT: Emergency Rollback Request - Juan Heart Mobile

Dear Google Play Support,

We need to immediately rollback Juan Heart Mobile (com.juanheart.mobile)
from version 1.5.0 to 1.4.0 due to a critical issue.

APP DETAILS:
- App Name: Juan Heart Mobile
- Package: com.juanheart.mobile
- Current Version: 1.5.0 (versionCode 13)
- Rollback To: 1.4.0 (versionCode 12)

ISSUE:
[Specific issue: e.g., "Data corruption causing patient assessment loss"]

IMPACT:
- Users Affected: 5,000+ (50% of active users)
- Severity: Critical (healthcare data loss)
- Support Tickets: 500+ in last 6 hours

URGENCY:
Juan Heart is a medical app used for CVD screening. Data loss impacts
patient care and follow-up treatments.

REQUEST:
Please expedite rollback approval or advise on fastest rollback method.

ACTIONS TAKEN:
- Halted rollout in Play Console
- Uploaded v1.4.0 as new release (versionCode 14)
- Prepared user communication

Contact: support@juanheart.ph
Phone: +63-XXX-XXX-XXXX

# 4. Google typically responds within 1-2 hours
# 5. They may manually rollback or approve your new release faster
```

### Post-Rollback Actions (Google Play)

```bash
# After rollback is live:

1. Verify rollback in Play Console
   - Check "Production" track shows old version
   - Verify rollout percentage is 100%

2. Test on real device
   adb uninstall com.juanheart.mobile
   # Install from Play Store
   # Verify it's the old version (check About screen)

3. Monitor metrics
   - Play Console → Android Vitals → Crashes
   - Verify crash rate returns to normal (<1%)
   - Check sync success rate improves

4. Notify team
   Slack #dev-team: "Rollback complete. v1.4.0 live on Play Store."

5. Schedule post-mortem
   - Within 48 hours of rollback
   - Identify root cause
   - Plan proper fix
```

---

## App Store Rollback

### Important Limitations

**Apple does NOT support automatic rollback:**
- ❌ Cannot revert users who already updated
- ❌ Cannot force users to downgrade
- ❌ Cannot re-upload old version with same version number

**Your options:**
1. **Remove from sale** (stops new downloads, doesn't help existing users)
2. **Submit new version** (forward-fix, takes 1-3 days review)
3. **Submit old version with new version number** (takes 1-3 days review)

### Method 1: Remove Version from Sale (Immediate but Limited)

```bash
# Use When: Must immediately stop new downloads while preparing fix

Steps:
1. Go to App Store Connect
   URL: https://appstoreconnect.apple.com

2. My Apps → Juan Heart Mobile

3. App Store → Version 1.5.0

4. Click "Remove from Sale"

5. Confirmation: "Remove Juan Heart Mobile from the App Store?"
   Click "Remove"

# Result:
- App disappears from App Store immediately
- New users cannot download
- Existing users KEEP the broken version
- Users who already purchased can re-download from purchase history

# Limitations:
- Existing users stuck on broken version
- Stops all new user acquisition
- Bad for app visibility/ranking
```

**When to Use:**
- Critical security vulnerability (must stop distribution immediately)
- Waiting for expedited review approval
- Temporary measure while preparing proper fix

### Method 2: Submit Old Version with New Version Number (Standard)

```bash
# Most common rollback method for App Store

Steps:
1. Update version number in pubspec.yaml
   # You CANNOT reuse version numbers on App Store

   # Broken version: 1.5.0+13
   # Old stable code: 1.4.0+12
   # Rollback version: 1.4.1+14 (NEW version number required)

   version: 1.4.1+14

2. Build from old stable commit
   git checkout tags/v1.4.0  # Tag for last stable version

   # Update version in pubspec.yaml to 1.4.1+14
   # (This is old code with NEW version number)

3. Build IPA
   cd ios
   fastlane beta  # Upload to TestFlight

4. After TestFlight processing, submit to App Store
   fastlane release

5. Request Expedited Review
   App Store Connect → Contact Us → Request Expedited Review

   Reason: Critical Bug Fix

   Explanation:
   "Version 1.5.0 of Juan Heart Mobile has a critical data loss bug.
   Version 1.4.1 rolls back to stable code while we develop proper fix.

   This is a medical app - data loss impacts patient care.

   Request expedited review for rollback version 1.4.1."

6. Release notes:
"Temporary Rollback - v1.4.1

We've temporarily reverted to our previous stable version while
we investigate an issue in v1.5.0.

Your data is safe. We apologize for the inconvenience.

What's Restored:
• Stable assessment sync
• Reliable appointment booking
• Consistent app performance

We're working on a proper fix and will release an update soon.

Contact: support@juanheart.ph"

# Timeline:
- Build + upload: 1 hour
- TestFlight processing: 30 minutes
- App Review (expedited): 24-48 hours
- Total: 2-3 days
```

### Method 3: Emergency Forward-Fix (Preferred if Possible)

```bash
# If you can fix the bug quickly, forward-fix is better than rollback

Steps:
1. Create hotfix branch from master (broken version)
   git checkout master
   git checkout -b hotfix/1.5.1-fix-issue

2. Implement MINIMAL fix (surgical change only)

3. Bump version: 1.5.0 → 1.5.1
   version: 1.5.1+14

4. Build and upload
   cd ios
   fastlane beta
   fastlane release

5. Request Expedited Review (same as rollback process)

6. Release notes:
"Critical Bug Fix - v1.5.1

Fixed:
• [Specific issue that was broken in v1.5.0]

This hotfix resolves a critical issue introduced in v1.5.0.
We apologize for the inconvenience.

Contact: support@juanheart.ph"

# Advantages over rollback:
✅ Keeps v1.5.0 features
✅ Users don't notice "downgrade"
✅ Cleaner version history
✅ Same timeline as rollback (2-3 days)
```

### Post-Rollback Actions (App Store)

```bash
# After rollback version is approved:

1. Verify in App Store Connect
   - Status: "Ready for Sale"
   - Version: 1.4.1 (rollback version)

2. Test on real device
   - Delete Juan Heart from iPhone
   - Download from App Store
   - Verify it's the rollback version

3. Monitor metrics
   Xcode → Window → Organizer → Crashes
   - Verify crash rate returns to normal
   - Check user reviews for feedback

4. Notify team
   Slack #dev-team: "iOS rollback live on App Store (v1.4.1)"

5. Plan proper fix
   - Schedule sprint to fix root cause
   - Target: v1.5.1 or v1.6.0 with proper fix
```

---

## Database Migration Rollback

### When Database Changes Are Involved

**CRITICAL:** If your new version includes database schema changes, rollback is more complex.

### Scenario 1: Forward-Only Migrations (Safe)

```dart
// Example: Added new column in v1.5.0
// File: lib/database/migrations.dart

// Migration 1.5.0: Add 'ai_consent' column
await db.execute('''
  ALTER TABLE users ADD COLUMN ai_consent INTEGER DEFAULT 0
''');

// Rollback to v1.4.0:
// ✅ SAFE: v1.4.0 code ignores new column
// Old code SELECT * returns extra column but doesn't use it
// No migration rollback needed
```

**Safe because:**
- Old code doesn't reference new column
- Extra columns don't break old queries
- Data preserved when re-upgrading to v1.5.1

### Scenario 2: Schema Changes Breaking Old Code (UNSAFE)

```dart
// Example: Renamed column in v1.5.0
// Migration 1.5.0: Rename 'user_name' to 'full_name'
await db.execute('''
  ALTER TABLE users RENAME COLUMN user_name TO full_name
''');

// Rollback to v1.4.0:
// ❌ UNSAFE: v1.4.0 code expects 'user_name' column
// Queries will fail: "no such column: user_name"
// MUST run reverse migration
```

### Database Rollback Procedure

#### Step 1: Assess Migration Impact

```dart
// Before rolling back, check what changed in migrations

// File: lib/database/migrations.dart

// v1.4.0 schema (old)
// - users table: id, user_name, email
// - assessments table: id, user_id, score

// v1.5.0 schema (new)
// - users table: id, full_name, email, ai_consent  // RENAMED + ADDED
// - assessments table: id, user_id, score, risk_level  // ADDED

// Impact of rollback:
// - user_name → full_name: BREAKING (v1.4.0 expects user_name)
// - ai_consent: NON-BREAKING (v1.4.0 ignores it)
// - risk_level: NON-BREAKING (v1.4.0 ignores it)
```

#### Step 2: Write Reverse Migration

```dart
// File: lib/database/migrations.dart

class DatabaseMigrations {
  // Forward migration (v1.4.0 → v1.5.0)
  static Future<void> migrateToV15(Database db) async {
    await db.execute('ALTER TABLE users RENAME COLUMN user_name TO full_name');
    await db.execute('ALTER TABLE users ADD COLUMN ai_consent INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE assessments ADD COLUMN risk_level TEXT');
  }

  // Reverse migration (v1.5.0 → v1.4.0)
  static Future<void> rollbackToV14(Database db) async {
    // Reverse column rename
    await db.execute('ALTER TABLE users RENAME COLUMN full_name TO user_name');

    // Drop new columns (SQLite doesn't support DROP COLUMN directly)
    // Workaround: Create new table without column, copy data, rename
    await db.execute('''
      CREATE TABLE users_backup (
        id INTEGER PRIMARY KEY,
        user_name TEXT,
        email TEXT
      )
    ''');
    await db.execute('INSERT INTO users_backup SELECT id, full_name, email FROM users');
    await db.execute('DROP TABLE users');
    await db.execute('ALTER TABLE users_backup RENAME TO users');

    // assessments.risk_level: Leave it (non-breaking, will be ignored)
  }
}

// Run reverse migration BEFORE deploying rollback version
```

#### Step 3: Deploy Data Migration Script

```bash
# Option 1: Server-side migration (if using MySQL backend)

# SQL script to run on production database
# File: migrations/rollback_v1.5.0_to_v1.4.0.sql

-- Backup data first
CREATE TABLE users_backup_20250115 AS SELECT * FROM users;

-- Reverse column rename
ALTER TABLE users RENAME COLUMN full_name TO user_name;

-- Drop new column (if it breaks old code)
ALTER TABLE users DROP COLUMN ai_consent;

-- Verify data integrity
SELECT COUNT(*) FROM users WHERE user_name IS NOT NULL;

# Run on production:
mysql -u admin -p juan_heart_db < migrations/rollback_v1.5.0_to_v1.4.0.sql
```

```bash
# Option 2: Client-side migration (SQLite in-app database)

# Include migration in rollback app version (v1.4.1)

// lib/database/database_helper.dart
class DatabaseHelper {
  Future<void> onOpen(Database db) async {
    int currentVersion = await db.getVersion();

    // Detect if upgrading from broken v1.5.0
    if (currentVersion == 15) {
      print('Detected v1.5.0 database. Running rollback migration...');
      await DatabaseMigrations.rollbackToV14(db);
      await db.setVersion(14);  // Reset to v1.4.0 schema version
    }
  }
}
```

### Database Rollback Checklist

```
Before rolling back app version:
- [ ] Identify all database schema changes in new version
- [ ] Determine which changes are breaking vs. non-breaking
- [ ] Write reverse migration script for breaking changes
- [ ] Test reverse migration on staging database
- [ ] Backup production database (CRITICAL)
- [ ] Run reverse migration on production
- [ ] Verify data integrity after migration
- [ ] Deploy rollback app version
- [ ] Monitor for migration errors in logs

Post-rollback:
- [ ] Verify old app version works with rolled-back schema
- [ ] Check for data loss or corruption
- [ ] Plan forward migration for proper fix
```

---

## User Communication Plan

### Communication Timeline

| Time After Rollback | Action | Audience | Channel |
|---------------------|--------|----------|---------|
| **Immediate (0-30 min)** | Alert internal team | Developers, Support | Slack #alerts |
| **30 min - 1 hour** | Notify support team | Support agents | Email + Slack |
| **1-2 hours** | In-app message | Active users | Push notification |
| **2-4 hours** | Email blast | All users | Email |
| **6-12 hours** | Social media update | Public | Twitter, Facebook |
| **24 hours** | Follow-up status | All users | Email |

### Template 1: Internal Team Alert (Slack)

```markdown
**Channel:** #alerts, #dev-team
**Priority:** CRITICAL

---

🚨 **ROLLBACK IN PROGRESS: Juan Heart Mobile v1.5.0 → v1.4.0**

**Issue:** Critical sync failure causing assessment data loss
**Decision:** Rollback to v1.4.0 (last stable version)
**Timeline:** Rollback live in 2-4 hours (Play Console approval)

**Immediate Actions:**
- @jh-git-guardian: Executing rollback procedure
- @support-team: Prepare user communication (template in thread)
- @jh-dev-prime: Root cause analysis (report by EOD)

**User Impact:**
- Users on v1.5.0: Recommend reinstall to v1.4.0
- Users on v1.4.0: No action needed (already on stable version)

**Next Update:** 12:00 PHT (2 hours)

**Incident Tracking:** JIRA ticket JH-678

---
Posted by: @jh-git-guardian | 2025-01-15 10:00 PHT
```

### Template 2: Support Team Briefing (Email)

```
Subject: URGENT: Rollback Procedure - Juan Heart v1.5.0

Dear Support Team,

We are rolling back Juan Heart Mobile from v1.5.0 to v1.4.0 due to a
critical bug affecting assessment sync.

TIMELINE:
- Rollback initiated: 10:00 PHT
- Expected live: 12:00-14:00 PHT
- User communication: 11:00 PHT (in-app message)

USER COMMUNICATION SCRIPT:
-------------------------------
"Thank you for contacting Juan Heart Support.

We're aware of sync issues affecting version 1.5.0 and are rolling
back to version 1.4.0 (our previous stable version).

To resolve immediately:
1. Uninstall Juan Heart
2. Reinstall from Play Store
3. Sign in with your existing account
4. Your data is safe and will sync automatically

The rollback will be complete by 2:00 PM today. If you prefer to wait,
your app will auto-update to the stable version within 24 hours.

We apologize for the inconvenience. Your data is our priority."
-------------------------------

EXPECTED USER QUESTIONS:
Q: Will I lose my data?
A: No, all data is safely stored on our servers. Reinstalling will sync
   your data automatically.

Q: Why is this happening?
A: Version 1.5.0 had a bug affecting offline sync. We're reverting to
   the stable version (1.4.0) while we fix the issue.

Q: When will the fix be available?
A: We're working on a proper fix and expect to release v1.5.1 within
   3-5 days. You'll be notified when it's ready.

ESCALATION:
For users reporting data loss (assessments/appointments missing):
- Escalate to: support-lead@juanheart.ph
- Include: User ID, email, date of affected assessments
- SLA: Respond within 2 hours

Thank you for your patience and professionalism.

Support Lead
Juan Heart Team
```

### Template 3: In-App Message (Push Notification)

```dart
// lib/services/push_notification_service.dart

// Send to all users on v1.5.0
void sendRollbackNotification() {
  FirebaseMessaging.instance.send(
    notification: Notification(
      title: 'Important Update - Please Reinstall',
      body: 'We\'ve fixed a sync issue. Please update Juan Heart from the Play Store.',
    ),
    data: {
      'type': 'rollback_notification',
      'action': 'update_app',
      'priority': 'high',
    },
  );
}

// In-app dialog (shown on next app launch)
class RollbackDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Text('Important Update'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We\'ve detected you\'re on an outdated version with a sync issue.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Please update Juan Heart to the latest version:\n\n'
            '1. Open Play Store\n'
            '2. Search "Juan Heart"\n'
            '3. Tap "Update"\n\n'
            'Your data is safe and will sync automatically.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            launchUrl('market://details?id=com.juanheart.mobile');
          },
          child: Text('Update Now'),
        ),
      ],
    );
  }
}
```

### Template 4: Email to All Users

```
Subject: Juan Heart Update - Action Required

Dear Juan Heart User,

We recently released version 1.5.0 with new features, but identified
a bug affecting assessment synchronization for some users.

WHAT WE'VE DONE:
We've rolled back to version 1.4.0 (our previous stable version) to
ensure reliable service while we fix the issue.

WHAT YOU NEED TO DO:
If you're experiencing sync issues, please update Juan Heart:

Method 1 (Recommended):
1. Uninstall Juan Heart
2. Reinstall from Play Store
3. Sign in with your existing account

Method 2 (Wait for Auto-Update):
Your app will automatically update to the stable version within 24 hours.

YOUR DATA IS SAFE:
All assessments and appointments are securely stored on our servers.
Reinstalling will sync your data automatically - nothing will be lost.

WHAT'S NEXT:
We're working on a proper fix and will release version 1.5.1 within
3-5 days with the original features plus bug fixes.

We sincerely apologize for the inconvenience. Your trust is important
to us, and we're committed to providing reliable service.

If you have questions or need assistance:
Email: support@juanheart.ph
Phone: +63-XXX-XXX-XXXX
Hours: 8:00 AM - 8:00 PM PHT (Mon-Sat)

Thank you for your patience and for using Juan Heart.

Best regards,
The Juan Heart Team

---
Juan Heart - Heart Health for Filipinos
Privacy Policy: https://juanheart.ph/privacy
Unsubscribe: https://juanheart.ph/unsubscribe
```

---

## Testing Rolled-Back Version

### Pre-Rollback Testing (Before Going Live)

```bash
# 1. Build old version locally with new version number
git checkout tags/v1.4.0
# Update pubspec.yaml: version: 1.4.1+14
flutter build apk --release

# 2. Install on test devices
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3. Smoke test critical flows (30 minutes)
```

### Smoke Test Checklist (Rolled-Back Version)

```
Device: Android 13 (Samsung S21)
Version: 1.4.1+14 (rolled-back code with new version number)
Tester: @jh-qa-guardian

Core Functionality:
- [ ] App launches without crash
- [ ] Sign in with existing account works
- [ ] Complete CVD assessment (online mode)
- [ ] Assessment saves and syncs successfully
- [ ] Enable airplane mode
- [ ] Complete assessment (offline mode)
- [ ] Disable airplane mode → verify sync (should work in v1.4.0)
- [ ] Book appointment
- [ ] View analytics dashboard
- [ ] Generate PDF report

Data Integrity:
- [ ] Previous assessments visible in history
- [ ] Previous appointments visible
- [ ] User profile data intact
- [ ] No data loss from rollback

Regressions:
- [ ] No new crashes introduced
- [ ] Performance similar to original v1.4.0
- [ ] UI renders correctly (no missing assets)

PASS/FAIL: ___________
Notes: ___________________________________________
```

### Post-Rollback Testing (After Live)

```bash
# 1. Install from Play Store (verify rollback is live)
adb uninstall com.juanheart.mobile
# Install from Play Store
# Verify version in About screen: 1.4.1 (or 1.4.0 depending on method)

# 2. Monitor metrics for 24 hours
Play Console → Android Vitals
- Crash-free users: Should return to >99.5%
- ANR rate: Should return to <0.1%
- Sync success rate: Should improve to >95%

# 3. Review user feedback
Play Console → Ratings and reviews
- Check for complaints about rollback
- Respond to confused users (explain rollback)

# 4. Verify backend sync
Check backend logs (MySQL database)
- Sync attempts: Should increase (users re-syncing)
- Sync failures: Should decrease significantly
```

---

## Post-Rollback Incident Report

### Incident Report Template

```markdown
# Incident Report: Rollback of Juan Heart Mobile v1.5.0

**Incident ID:** INC-2025-001
**Date:** 2025-01-15
**Severity:** CRITICAL
**Status:** RESOLVED

---

## Executive Summary

On January 15, 2025, we rolled back Juan Heart Mobile from version 1.5.0
to 1.4.0 due to a critical bug causing assessment sync failures and data
loss for ~15% of users.

**Timeline:**
- Issue detected: 09:30 PHT
- Rollback decision: 10:00 PHT
- Rollback live: 14:00 PHT
- Resolution confirmed: 16:00 PHT
- Total incident duration: 6.5 hours

**Impact:**
- Users affected: 750 (15% of active base)
- Data loss: 37 assessments (5% of affected submissions)
- Support tickets: 150
- App Store rating: Dropped from 4.6 to 4.3 stars

---

## Incident Timeline

| Time (PHT) | Event | Action Taken |
|------------|-------|--------------|
| 09:00 | v1.5.0 released to 50% of users | Staged rollout active |
| 09:30 | Crash reports spike (2% → 8%) | Monitoring detected anomaly |
| 09:45 | Support tickets increase (5 → 50/hour) | Support team escalates to dev |
| 10:00 | Rollback decision made | Team huddle, rollback approved |
| 10:15 | Rollback initiated (Play Console) | Upload v1.4.0 with new build number |
| 12:00 | Support team briefed | Email + Slack communication sent |
| 13:00 | Rollback build uploaded | Pending Google Play approval |
| 13:45 | Google Play approves rollback | v1.4.1 available for download |
| 14:00 | Rollback live (100% rollout) | In-app message sent to users |
| 14:30 | User emails sent | Communication to all 5,000 users |
| 16:00 | Metrics stabilize | Crash rate drops to 0.5% ✅ |
| 18:00 | Post-mortem scheduled | Team retrospective on 2025-01-17 |

---

## Root Cause Analysis

**Problem:** Assessment sync failures causing 8% crash rate and data loss

**Immediate Cause:**
NullPointerException in SyncQueueService.processQueue() when handling
assessments created offline.

**Root Cause (5 Whys):**
1. Why crash? → Assessment object was null
2. Why null? → Database query returned null for corrupted records
3. Why corrupted? → App force-closed during save operation
4. Why did force-close corrupt data? → No database transaction wrapper
5. Why no transaction? → Not implemented in original design

**Ultimate Root Cause:**
Missing database transaction wrapper for critical data writes, combined
with insufficient null safety checks.

---

## Impact Assessment

**Users:**
- Total affected: 750 users (15% of 5,000 active users)
- Data lost: 37 assessments (0.7% of all assessments)
- Data recovered: 713 assessments (95% recovery rate)
- User complaints: 150 support tickets

**Business:**
- App Store rating: 4.6 → 4.3 stars (-0.3)
- Negative reviews: +45 (1-star and 2-star)
- User churn: 3 users uninstalled (0.06% churn rate)
- Revenue impact: $0 (app is free, no in-app purchases)

**Reputation:**
- PHC stakeholder confidence: Minor concern (resolved quickly)
- User trust: Moderate impact (transparent communication helped)
- Healthcare provider feedback: 2 facilities paused usage temporarily

**Operational:**
- Developer hours: 20 hours (4 people × 5 hours)
- Support hours: 40 hours (handling tickets + communication)
- Total cost: ~$3,000 (estimated labor + Google Play expedited review)

---

## What Went Well ✅

1. **Detection:** Crash spike detected within 30 minutes via automated monitoring
2. **Decision Speed:** Rollback decision made within 30 minutes of detection
3. **Coordination:** Team responded quickly, clear roles assigned
4. **Communication:** Transparent user communication (email, in-app, social)
5. **Data Recovery:** 95% of affected assessments recovered via backend scripts
6. **Rollback Speed:** Rollback live within 4.5 hours of decision

---

## What Didn't Go Well ❌

1. **Testing:** Null pointer scenario not covered in unit tests
2. **Staged Rollout:** Should have started at 5%, not 50% (affected fewer users)
3. **Database Design:** No transaction wrappers for critical writes
4. **Monitoring:** No real-time alert for crash rate >2% (manual detection)
5. **Staging Environment:** No staging environment to test v1.5.0 before production

---

## Action Items

| Action | Owner | Due Date | Priority | Status |
|--------|-------|----------|----------|--------|
| Implement database transactions for all writes | @jh-dev-prime | 2025-01-24 | CRITICAL | In Progress |
| Add null safety tests for all services | @jh-qa-guardian | 2025-01-24 | HIGH | Pending |
| Set up staging environment | @jh-git-guardian | 2025-01-31 | HIGH | Pending |
| Configure Crashlytics auto-alerts (>2% crash rate) | @jh-git-guardian | 2025-01-20 | HIGH | Pending |
| Reduce initial staged rollout to 5% | @jh-git-guardian | Immediate | MEDIUM | Done ✅ |
| Create automated data recovery scripts | @jh-dev-prime | 2025-01-24 | HIGH | In Progress |
| Update testing checklist (null scenarios) | @jh-qa-guardian | 2025-01-18 | MEDIUM | Pending |
| Document rollback procedures (THIS DOC) | @jh-git-guardian | 2025-01-17 | DONE | Done ✅ |

---

## Lessons Learned

**Technical:**
1. Always wrap database writes in transactions
2. Add null checks for ALL database query results
3. Unit tests MUST cover null/edge cases
4. Implement local data backup before attempting sync

**Process:**
1. Start staged rollouts at 5% (not 50%) for major releases
2. Set up automated crash rate alerts (don't rely on manual checks)
3. Require staging environment testing before production
4. Create rollback playbook (this document) for future incidents

**Communication:**
1. Transparent communication builds user trust (despite incident)
2. Pre-brief support team on potential issues before releases
3. In-app messages more effective than email for critical updates
4. Respond to user reviews within 24 hours during incidents

---

## Preventive Measures

**Implemented:**
- ✅ Rollback procedures documented (this guide)
- ✅ Fast-track testing checklist created
- ✅ Communication templates standardized

**Planned:**
- ⚠️ Database transaction wrappers (by Jan 24)
- ⚠️ Staging environment setup (by Jan 31)
- ⚠️ Automated crash alerts (by Jan 20)
- ⚠️ Enhanced null safety testing (by Jan 24)

---

## Sign-Off

**Incident Owner:** @jh-git-guardian
**Reviewed By:** @tech-lead, @product-owner
**Approved By:** @cto
**Date:** 2025-01-17

**Status:** RESOLVED
**Follow-Up:** Retrospective scheduled for 2025-01-17 10:00 PHT

---

**Attachments:**
- Crash logs: /incidents/INC-2025-001/crash_logs.txt
- User communication templates: /incidents/INC-2025-001/communication/
- Metrics screenshots: /incidents/INC-2025-001/metrics/
```

---

## Quick Reference Commands

```bash
# Google Play Rollback (Standard)
# 1. Halt current rollout
Play Console → Production → Halt rollout

# 2. Upload old version with new build number
flutter build appbundle --release
# Upload v1.4.0 code as v1.4.1+14

# 3. Release at 100% (no staging for rollback)

# App Store Rollback (Submit old code with new version)
git checkout tags/v1.4.0
# Update version: 1.4.1+14
cd ios && fastlane beta
# Request expedited review

# Database Rollback (if needed)
mysql -u admin -p juan_heart_db < migrations/rollback_v1.5.0_to_v1.4.0.sql

# Post-Rollback Verification
adb uninstall com.juanheart.mobile
# Install from store → test critical flows
```

---

## Related Documentation
- [01-google-play-release.md](./01-google-play-release.md) - Regular Android releases
- [02-app-store-release.md](./02-app-store-release.md) - Regular iOS releases
- [03-hotfix-deployment.md](./03-hotfix-deployment.md) - Emergency hotfixes
- [troubleshooting.md](./troubleshooting.md) - Common deployment errors

---

**Document History:**
- v1.0 (Jan 2025): Initial rollback guide for Juan Heart Mobile
- Owner: JH-Git-Guardian
- Review Cycle: After each rollback incident (continuous improvement)
