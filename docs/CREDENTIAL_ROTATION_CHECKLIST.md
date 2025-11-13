# Juan Heart Mobile - Credential Rotation Checklist

## Status: NOT VERIFIED AND TESTED
**Date Created:** January 10, 2025
**Priority:** P0 - CRITICAL SECURITY ACTION REQUIRED
**Owner:** DevOps Lead / Security Team

---

## Executive Summary

This document provides a step-by-step checklist for rotating credentials that were identified as exposed in the `.env` file. While these credentials have **NOT** been committed to git history (verified), it is **STRONGLY RECOMMENDED** to rotate them immediately as a precautionary security measure.

---

## Exposed Credentials Audit

### Critical Findings (as of January 10, 2025)

| Credential | Current Value (First 8 chars) | Risk Level | Rotation Required |
|------------|------------------------------|------------|-------------------|
| Twilio Account SID | `ACcecc8d...` | HIGH | **YES** |
| Twilio Auth Token | `90059dd7...` | HIGH | **YES** |
| Twilio Phone Number | `+16205248455` | MEDIUM | Optional |
| Google Geocoding API Key | `AIzaSyBQ...` | MEDIUM | **YES** |

### Git History Status

```
✓ VERIFIED: No .env file found in git commit history
✓ VERIFIED: No .env file found in git objects
✓ VERIFIED: .gitignore properly configured (lines 137, 227)
✓ STATUS: Credentials never reached public repository
```

**Recommendation**: Despite clean git history, rotate all credentials as best practice since they existed in plaintext on local machines and may have been exposed through other channels (IDE sync, cloud backups, etc.).

---

## Rotation Priority Timeline

### Immediate (Within 24 hours) - P0

- [ ] Twilio Auth Token
- [ ] Google Geocoding API Key

### Medium (Within 1 week) - P1

- [ ] Twilio Phone Number (if exposed in public documentation)
- [ ] Review all team members with credential access

### Long-term (Quarterly) - P2

- [ ] Establish regular credential rotation schedule
- [ ] Implement automated secret scanning
- [ ] Enable Google Cloud API key restrictions

---

## Detailed Rotation Procedures

### 1. Twilio Credentials Rotation

#### Pre-Rotation Checklist

- [ ] Confirm you have admin access to Twilio account
- [ ] Identify all systems using current credentials (app, CI/CD, testing)
- [ ] Schedule maintenance window (if SMS is critical for production)
- [ ] Backup current `.env` file: `cp .env .env.backup.$(date +%Y%m%d)`

#### Rotation Steps (Account SID + Auth Token)

**Step 1: Access Twilio Console**

1. Log in to https://console.twilio.com/
2. Navigate to **Account → Keys & Credentials → API Keys & Tokens**
3. Locate current **Auth Token** (partially masked)

**Step 2: Generate New Auth Token**

1. Click **Create new API Key** (or use the main Auth Token)
2. Select **Standard** key type
3. Give it a friendly name: `Juan-Heart-Mobile-Jan2025`
4. Click **Create API Key**
5. **IMPORTANT**: Copy the SID and Secret immediately (shown only once)

**Step 3: Update .env File**

```bash
# Open .env file
nano .env

# Replace old values:
# OLD: ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# NEW: ACCOUNT_SID=AC[new-sid-from-step-2]

# OLD: AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# NEW: AUTH_TOKEN=[new-token-from-step-2]

# Save and exit
```

**Step 4: Test SMS Functionality**

```bash
# Run the app in debug mode
flutter run

# Test features:
# 1. User registration (OTP SMS)
# 2. Password reset (OTP SMS)
# 3. Appointment reminders (if applicable)

# Check Twilio logs for successful message delivery:
# https://console.twilio.com/monitor/logs/messages
```

**Step 5: Update CI/CD Secrets**

If using GitHub Actions:

1. Go to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **Update** on existing secrets:
   - `TWILIO_ACCOUNT_SID` → [new value]
   - `TWILIO_AUTH_TOKEN` → [new value]
3. Trigger test build to verify

**Step 6: Revoke Old Credentials**

**WARNING**: Only do this AFTER confirming new credentials work!

1. Return to Twilio Console → **API Keys & Tokens**
2. Find the old API key (if it's a secondary key) or main Auth Token
3. Click **Delete** or **Revoke**
4. Confirm revocation

**Step 7: Verify Revocation**

```bash
# Temporarily restore old credentials in a test environment
# Attempt to send SMS - should fail with 401 Unauthorized
# This confirms old credentials are invalidated
```

#### Post-Rotation Checklist

- [ ] New credentials tested in local development
- [ ] New credentials tested in staging environment
- [ ] CI/CD pipeline updated and tested
- [ ] Old credentials revoked in Twilio Console
- [ ] Old credentials confirmed as non-functional
- [ ] Team notified of credential rotation
- [ ] `.env.backup` deleted securely: `shred -u .env.backup.*` (Linux) or `rm -P .env.backup.*` (macOS)
- [ ] Update credential rotation log (see Section 5)

---

### 2. Google Geocoding API Key Rotation

#### Pre-Rotation Checklist

- [ ] Confirm you have admin access to Google Cloud Console
- [ ] Identify project using the API key: `juan-heart-project` (likely)
- [ ] Review current API key restrictions
- [ ] Backup current `.env` file: `cp .env .env.backup.$(date +%Y%m%d)`

#### Rotation Steps

**Step 1: Access Google Cloud Console**

1. Log in to https://console.cloud.google.com/
2. Select correct project (e.g., `juan-heart-project`)
3. Navigate to **APIs & Services → Credentials**

**Step 2: Create New API Key**

1. Click **+ CREATE CREDENTIALS** → **API Key**
2. New API key created → **Copy to clipboard**
3. Click **EDIT API KEY** to set restrictions

**Step 3: Apply Security Restrictions**

**Application Restrictions:**
- Select: **Android apps** and **iOS apps**
- Add package names:
  - Android: `com.juanheart.mobile` (verify in `android/app/build.gradle`)
  - iOS: `com.juanheart.JuanHeartMobile` (verify in `ios/Runner.xcodeproj`)

**API Restrictions:**
- Select: **Restrict key**
- Check **ONLY**: Geocoding API
- Uncheck all other APIs

**Save restrictions**

**Step 4: Update .env File**

```bash
# Open .env file
nano .env

# Replace old value:
# OLD: GOOGLE_GEOCODING_API_KEY=AIzaSyBQ47eHfZH3asw0Fl8PxCNoyOTKQ2gjNhA
# NEW: GOOGLE_GEOCODING_API_KEY=[new-key-from-step-2]

# Save and exit
```

**Step 5: Test GPS/Location Features**

```bash
# Run the app in debug mode
flutter run

# Test features:
# 1. Facility search with GPS location
# 2. Reverse geocoding (coordinates → city/region)
# 3. Emergency services location finder

# Check for any API errors in console logs
```

**Step 6: Update CI/CD Secrets**

If using GitHub Actions:

1. Go to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **Update** on `GOOGLE_GEOCODING_API_KEY`
3. Paste new API key value
4. Trigger test build

**Step 7: Delete Old API Key**

**WARNING**: Only do this AFTER confirming new key works!

1. Return to Google Cloud Console → **Credentials**
2. Find old API key: `AIzaSyBQ47eHfZH3asw0Fl8PxCNoyOTKQ2gjNhA`
3. Click **⋮** (three dots) → **Delete**
4. Confirm deletion

**Step 8: Verify Deletion**

```bash
# Temporarily restore old API key in test environment
# Attempt to make geocoding request - should fail with 403 Forbidden
# This confirms old key is invalidated
```

#### Post-Rotation Checklist

- [ ] New API key tested in local development
- [ ] New API key tested in staging environment
- [ ] API restrictions verified (Android/iOS bundle IDs)
- [ ] CI/CD pipeline updated and tested
- [ ] Old API key deleted in Google Cloud Console
- [ ] Old API key confirmed as non-functional
- [ ] Team notified of credential rotation
- [ ] `.env.backup` deleted securely: `shred -u .env.backup.*` (Linux) or `rm -P .env.backup.*` (macOS)
- [ ] Update credential rotation log (see Section 5)

---

### 3. Twilio Phone Number Rotation (Optional)

**Risk Assessment**: MEDIUM - Phone numbers are semi-public (visible in SMS sender)

**When to Rotate**:
- If phone number was exposed in public documentation
- If receiving spam/abuse on the number
- If regulatory compliance requires it

**Rotation Steps**:

1. Purchase new Twilio phone number: https://console.twilio.com/phone-numbers/incoming
2. Update `.env` with new `TWILIO_NUMBER`
3. Test SMS sending from new number
4. Release old phone number (if no longer needed)
5. Update any public-facing documentation with new number

**Note**: Phone number rotation is optional and may incur additional costs.

---

## 4. Verification & Testing

### Automated Testing Script

Create a test script to verify all credentials work:

```bash
#!/bin/bash
# test_credentials.sh

echo "Testing Twilio credentials..."
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$ACCOUNT_SID/Messages.json" \
  --data-urlencode "Body=Test from Juan Heart" \
  --data-urlencode "From=$TWILIO_NUMBER" \
  --data-urlencode "To=+1234567890" \
  -u "$ACCOUNT_SID:$AUTH_TOKEN"

echo "Testing Google Geocoding API..."
curl "https://maps.googleapis.com/maps/api/geocode/json?latlng=14.5995,120.9842&key=$GOOGLE_GEOCODING_API_KEY"

echo "Done!"
```

**Run test**:
```bash
source .env
bash test_credentials.sh
```

### Manual Testing Checklist

- [ ] SMS OTP sent successfully (Twilio)
- [ ] SMS received by test phone number
- [ ] Geocoding returns correct address
- [ ] No API errors in application logs
- [ ] CI/CD build passes with new credentials
- [ ] Staging deployment successful
- [ ] Production deployment successful (if applicable)

---

## 5. Credential Rotation Log

### Rotation History

| Date | Credential | Rotated By | Reason | Old Value (first 8) | New Value (first 8) | Status |
|------|-----------|------------|--------|---------------------|---------------------|--------|
| 2025-01-10 | Twilio Auth Token | [TBD] | Precautionary (exposed in .env) | `90059dd7...` | `[TBD]` | PENDING |
| 2025-01-10 | Google API Key | [TBD] | Precautionary (exposed in .env) | `AIzaSyBQ...` | `[TBD]` | PENDING |

**Instructions**:
- Fill in "Rotated By" with your name after completing rotation
- Update "New Value" with first 8 characters of new credential (for audit trail)
- Change "Status" to "COMPLETED" when verified and tested
- Add any notes in a new "Notes" column if needed

---

## 6. Communication Plan

### Internal Notification

**Email Template** (send AFTER rotation is complete):

```
Subject: [ACTION REQUIRED] Juan Heart Mobile - Credentials Rotated

Team,

We have rotated the following credentials for Juan Heart Mobile as a security precaution:

1. Twilio Auth Token
2. Google Geocoding API Key

Actions Required:
- Pull latest .env.example from repository
- Re-run setup script: bash scripts/setup_env.sh
- Obtain new credentials from [DevOps Lead Name] via secure channel (Slack DM, encrypted email)
- Test your local development environment

Timeline:
- Completed: [Date/Time]
- Deadline for team updates: [Date + 24 hours]

Please confirm receipt and successful update by replying to this email.

Security Team
```

### External Notification (if needed)

If credentials were exposed publicly (e.g., committed to GitHub):

1. File incident report with security team
2. Notify stakeholders (PHC, University of Cordilleras)
3. Document in compliance/audit log
4. Review and improve security procedures

---

## 7. Prevention Measures

### Immediate Actions (This Week)

- [ ] Install `git-secrets` on all developer machines
- [ ] Enable GitHub secret scanning (Settings → Security → Secret scanning)
- [ ] Add pre-commit hooks to prevent `.env` commits
- [ ] Create `.env.local` for developer-specific overrides (also ignored by git)

### Short-term (This Month)

- [ ] Migrate to secure secret management (AWS Secrets Manager, HashiCorp Vault)
- [ ] Implement automated credential rotation (Terraform, AWS Lambda)
- [ ] Enable Google Cloud API key usage alerts (alert if quota exceeded)
- [ ] Set up Twilio usage alerts (alert if unexpected SMS volume)

### Long-term (This Quarter)

- [ ] Quarterly credential rotation schedule
- [ ] Security training for all team members
- [ ] Regular security audits (penetration testing, code review)
- [ ] Implement least-privilege access (not all devs need production credentials)

---

## 8. Rollback Procedure

If new credentials cause issues:

**Emergency Rollback Steps**:

1. Restore backup `.env` file:
   ```bash
   cp .env.backup.[date] .env
   ```

2. Restart application services

3. Verify functionality restored

4. Investigate root cause of credential failure

5. Re-attempt rotation with corrections

**Note**: Old credentials will only work if NOT yet revoked in Twilio/Google Cloud Console.

---

## 9. Final Verification Checklist

Before marking this document as "VERIFIED AND TESTED":

- [ ] Twilio Auth Token rotated successfully
- [ ] Google Geocoding API Key rotated successfully
- [ ] All local development environments updated
- [ ] All CI/CD pipelines updated
- [ ] Old credentials revoked and confirmed non-functional
- [ ] New credentials tested in production (if applicable)
- [ ] Team notified and confirmed updates
- [ ] Rotation log updated with completion date/time
- [ ] Backup `.env` files securely deleted
- [ ] Prevention measures implemented (git-secrets, secret scanning)
- [ ] This checklist reviewed by DevOps Lead and Security Team

---

## 10. Sign-off

### Credential Rotation Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| DevOps Lead | ____________ | ___/___/___ | __________ |
| Security Officer | ____________ | ___/___/___ | __________ |
| Project Manager | ____________ | ___/___/___ | __________ |

**Status**: Once all checkboxes above are complete, update document status to "VERIFIED AND TESTED".

---

**Document Version**: 1.0
**Created**: January 10, 2025
**Last Updated**: January 10, 2025
**Next Review**: January 17, 2025 (1 week post-rotation)

---

**CONFIDENTIAL**: This document contains sensitive security information. Do not share outside the core development team.
