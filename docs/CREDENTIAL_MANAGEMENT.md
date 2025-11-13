# Juan Heart Mobile - Credential Management & Security

## Status: NOT VERIFIED AND TESTED
**Last Updated:** January 10, 2025
**Security Level:** P0 CRITICAL
**Owner:** DevOps Team / Project Administrator

---

## Executive Summary

This document outlines secure credential management practices for the Juan Heart Mobile application. Following these guidelines is **MANDATORY** to prevent security breaches and protect patient data.

### Current Security Status

**CRITICAL FINDINGS (as of Jan 10, 2025):**
- **Twilio credentials**: EXPOSED in .env file (not yet committed to git)
- **Google API Key**: EXPOSED in .env file (not yet committed to git)
- **Git History**: CLEAN - no credentials found in commit history
- **Action Required**: Immediate credential rotation recommended

---

## 1. Environment Variables Overview

### Critical Secrets (MUST ROTATE if exposed)

| Variable | Service | Risk Level | Rotation Required |
|----------|---------|------------|-------------------|
| `ACCOUNT_SID` | Twilio | HIGH | YES - if committed |
| `AUTH_TOKEN` | Twilio | HIGH | YES - if committed |
| `TWILIO_NUMBER` | Twilio | MEDIUM | NO (phone number) |
| `GOOGLE_GEOCODING_API_KEY` | Google Cloud | MEDIUM | YES - if committed |

### Non-Critical Configuration

| Variable | Risk Level | Notes |
|----------|------------|-------|
| `GENKIT_BACKEND_URL` | LOW | Public endpoint (intended) |
| `EDUCATIONAL_CONTENT_API_URL` | LOW | Local dev URL |
| `FEATURE_FLAGS_URL` | LOW | Optional remote config |

---

## 2. Local Development Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/Juan-Heart-Mobile.git
cd Juan-Heart-Mobile
```

### Step 2: Create .env File

```bash
# Copy the template
cp .env.example .env

# Edit with your actual credentials
nano .env  # or use your preferred editor
```

### Step 3: Obtain Credentials

#### Twilio SMS (Required for OTP/SMS features)
1. Sign up at https://console.twilio.com/
2. Navigate to **Console Dashboard**
3. Copy `ACCOUNT_SID` and `AUTH_TOKEN`
4. Purchase a phone number → Copy `TWILIO_NUMBER`
5. Paste values into `.env`

#### Google Geocoding API (Required for GPS features)
1. Go to https://console.cloud.google.com/
2. Enable **Geocoding API**
3. Create credentials → **API Key**
4. **CRITICAL**: Restrict key to:
   - API: Geocoding API only
   - Application: Android/iOS app bundle ID
5. Paste `GOOGLE_GEOCODING_API_KEY` into `.env`

### Step 4: Verify Setup

```bash
# Run the setup script (creates .env if missing)
bash scripts/setup_env.sh

# Verify no .env in git tracking
git status | grep .env
# Should show: nothing (or only .env.example as untracked)
```

---

## 3. Security Best Practices

### DO's

- **Use .env.example** as template with placeholder values
- **Add .env to .gitignore** (already configured at lines 137, 227)
- **Rotate credentials** immediately if exposed in git history
- **Use API key restrictions** in Google Cloud Console
- **Enable 2FA** on all service accounts (Twilio, Google Cloud)
- **Store production secrets** in secure vaults (GitHub Secrets, AWS Secrets Manager)
- **Review git history** before pushing: `git log --all -- .env`

### DON'Ts

- **NEVER commit .env** to version control
- **NEVER share .env** via email, Slack, or messaging apps
- **NEVER hardcode credentials** in source code
- **NEVER use production credentials** in local development
- **NEVER push commits** without checking `git status` first
- **NEVER paste credentials** in public channels (Discord, GitHub issues)

---

## 4. Credential Rotation Protocol

### When to Rotate

1. **Immediately** if credentials were committed to git
2. **Immediately** if credentials were shared publicly
3. **Quarterly** as part of routine security maintenance
4. **After team member departure** with credential access

### Rotation Checklist

#### Twilio Credentials (HIGH PRIORITY)

- [ ] Log in to https://console.twilio.com/
- [ ] Navigate to **Account → API keys & tokens**
- [ ] Click **Create new Auth Token**
- [ ] **Invalidate old token** (click "View" → "Revoke")
- [ ] Update `.env` with new `AUTH_TOKEN`
- [ ] Test SMS functionality in app
- [ ] Notify team via secure channel
- [ ] Update CI/CD secrets (GitHub Actions, etc.)

#### Google API Key (MEDIUM PRIORITY)

- [ ] Go to https://console.cloud.google.com/apis/credentials
- [ ] Click **Create credentials** → **API Key**
- [ ] Apply same restrictions as old key:
  - API: Geocoding API only
  - Application restrictions: Android/iOS bundle IDs
- [ ] Update `.env` with new `GOOGLE_GEOCODING_API_KEY`
- [ ] Test GPS/location features in app
- [ ] **Delete old API key** from Google Cloud Console
- [ ] Update CI/CD secrets

---

## 5. CI/CD Secret Management

### GitHub Actions (Recommended)

1. Navigate to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add each credential:
   - Name: `TWILIO_ACCOUNT_SID`
   - Secret: [paste value]
   - Repeat for all environment variables

### Access in Workflow

```yaml
# .github/workflows/build.yml
env:
  ACCOUNT_SID: ${{ secrets.TWILIO_ACCOUNT_SID }}
  AUTH_TOKEN: ${{ secrets.TWILIO_AUTH_TOKEN }}
  GOOGLE_GEOCODING_API_KEY: ${{ secrets.GOOGLE_GEOCODING_API_KEY }}
```

---

## 6. Emergency Response: Exposed Credentials

### Immediate Actions (within 1 hour)

1. **Stop all pushes** to repository
2. **Rotate all exposed credentials** (see Section 4)
3. **Notify team lead** and security officer
4. **Check access logs** on Twilio/Google Cloud for unauthorized usage

### Git History Cleanup (if committed)

**WARNING**: This rewrites git history. Coordinate with entire team.

```bash
# Method 1: BFG Repo-Cleaner (recommended)
brew install bfg  # macOS
bfg --delete-files .env
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Method 2: git filter-branch (built-in)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all

# Force push to remote (ALL team members must re-clone)
git push origin --force --all
git push origin --force --tags
```

### Post-Incident Actions (within 24 hours)

- [ ] Document incident in security log
- [ ] Review access controls and permissions
- [ ] Conduct team training on credential security
- [ ] Update this documentation with lessons learned
- [ ] Enable GitHub secret scanning (if not already enabled)

---

## 7. Verification Checklist

Before marking this as "VERIFIED AND TESTED", complete:

- [ ] Twilio credentials rotated (if previously exposed)
- [ ] Google API key rotated (if previously exposed)
- [ ] `.env` file never committed to git (verified via `git log`)
- [ ] `.env.example` contains only placeholder values
- [ ] `.gitignore` includes `.env` (lines 137, 227)
- [ ] Setup script (`scripts/setup_env.sh`) tested on clean clone
- [ ] CI/CD secrets configured in GitHub Actions
- [ ] Team trained on credential management best practices
- [ ] Emergency response protocol tested in staging environment
- [ ] All team members have read and acknowledged this document

---

## 8. Team Acknowledgment

| Team Member | Role | Date Read | Signature |
|-------------|------|-----------|-----------|
| ___________ | Lead Dev | ___/___/___ | _________ |
| ___________ | DevOps | ___/___/___ | _________ |
| ___________ | Backend | ___/___/___ | _________ |
| ___________ | QA Lead | ___/___/___ | _________ |

---

## 9. Contact Information

**Security Incidents**: [security@juanheart.ph] (replace with actual email)
**DevOps Team**: [devops@juanheart.ph] (replace with actual email)
**On-Call Engineer**: [TBD - add on-call rotation contact]

---

## Appendix A: .env File Structure

```bash
# Twilio SMS Configuration
ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_NUMBER=+1XXXXXXXXXX

# Genkit AI Assessment
GENKIT_BACKEND_URL=https://us-central1-juan-heart-project.cloudfunctions.net/assessHeartRiskHttp

# Feature Flags (optional)
FEATURE_FLAGS_URL=

# Educational Content API
EDUCATIONAL_CONTENT_API_URL=http://localhost:8000/api/v1/mobile

# Google Geocoding API
GOOGLE_GEOCODING_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## Appendix B: Security Tools

### Recommended Tools

1. **git-secrets** (AWS): Prevents committing secrets
   ```bash
   brew install git-secrets
   git secrets --install
   git secrets --register-aws
   ```

2. **detect-secrets** (Yelp): Pre-commit hook
   ```bash
   pip install detect-secrets
   detect-secrets scan > .secrets.baseline
   ```

3. **GitHub Secret Scanning**: Enable in repo settings
4. **Dependabot Alerts**: Auto-enabled for security vulnerabilities

---

**Document Version**: 1.0
**Last Security Audit**: January 10, 2025
**Next Review Date**: April 10, 2025 (quarterly)

---

**REMEMBER**: This document contains critical security information. Do not share publicly or commit to version control without redacting sensitive details.
