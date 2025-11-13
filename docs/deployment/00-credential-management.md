# Credential Management & Security

## Security Audit Results

### Git History Audit (January 2025)

**Status:** ✅ **SECURE** - No credentials exposed in git history

**Audit Performed:**
```bash
# Checked .env file commit history
git log --all --full-history --source --all -- .env

# Searched for specific credentials
git log --all -S "TWILIO_ACCOUNT_SID"
git log --all -S "GOOGLE_GEOCODING_API_KEY"
```

**Findings:**
- ✅ `.env` file has **never** been committed to git
- ✅ No Twilio credentials found in git history
- ✅ No Google API keys found in git history
- ✅ `.env` properly listed in `.gitignore` (lines 130, 220)

**Risk Assessment:** **LOW** - No immediate credential rotation required

---

## Credential Inventory

### Active Credentials (As of January 2025)

| Service | Credential Type | Usage | Location |
|---------|----------------|-------|----------|
| **Twilio** | Account SID | SMS notifications, OTP | `.env` |
| **Twilio** | Auth Token | SMS authentication | `.env` |
| **Google Cloud** | Geocoding API Key | Reverse geocoding (GPS → location) | `.env` |
| **Firebase** | google-services.json | Android Firebase SDK | `android/app/google-services.json` |
| **Firebase** | GoogleService-Info.plist | iOS Firebase SDK | `ios/Runner/GoogleService-Info.plist` |
| **Genkit** | Cloud Function URL | AI risk assessment | `.env` (public endpoint) |

---

## GitHub Secrets Configuration

### Required Secrets for CI/CD

Configure these secrets in **GitHub Repository Settings → Secrets and variables → Actions**:

#### 1. Android Code Signing

```bash
# Android release keystore (base64 encoded)
ANDROID_KEYSTORE_BASE64

# Keystore password
ANDROID_KEYSTORE_PASSWORD

# Key alias
ANDROID_KEY_ALIAS

# Key password
ANDROID_KEY_PASSWORD

# Store password (often same as keystore password)
ANDROID_STORE_PASSWORD
```

**How to encode keystore:**
```bash
base64 -i juan-heart-release.jks | pbcopy
# Paste into GitHub Secret ANDROID_KEYSTORE_BASE64
```

#### 2. Google Play Console Deployment

```bash
# Service account JSON (base64 encoded)
PLAY_STORE_SERVICE_ACCOUNT_JSON

# Package name
ANDROID_PACKAGE_NAME=com.example.juan_heart
```

**How to create service account:**
1. Go to Google Play Console → Settings → API access
2. Create new service account
3. Grant "Release Manager" permissions
4. Download JSON key
5. Encode and store:
```bash
base64 -i service-account.json | pbcopy
# Paste into GitHub Secret PLAY_STORE_SERVICE_ACCOUNT_JSON
```

#### 3. iOS Code Signing (Future - Pending Apple Developer Account)

```bash
# Apple Distribution Certificate (p12, base64 encoded)
IOS_CERTIFICATE_BASE64

# Certificate password
IOS_CERTIFICATE_PASSWORD

# Provisioning profile (base64 encoded)
IOS_PROVISION_PROFILE_BASE64

# App Store Connect API Key (p8 file, base64 encoded)
APP_STORE_CONNECT_API_KEY_BASE64

# App Store Connect Issuer ID
APP_STORE_CONNECT_ISSUER_ID

# App Store Connect Key ID
APP_STORE_CONNECT_KEY_ID
```

#### 4. Runtime Environment Variables

```bash
# Twilio credentials
TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN
TWILIO_NUMBER

# Google Geocoding API
GOOGLE_GEOCODING_API_KEY

# Educational Content API
EDUCATIONAL_CONTENT_API_URL
```

---

## Credential Rotation Procedures

### When to Rotate Credentials

**Immediate rotation required if:**
- ❌ Credentials committed to public repository
- ❌ Credentials leaked in logs or error messages
- ❌ Suspected unauthorized access
- ❌ Team member with access leaves organization
- ❌ Security audit discovers exposure

**Scheduled rotation (recommended):**
- 🔄 Every 90 days for API keys
- 🔄 Every 180 days for code signing certificates
- 🔄 Annually for production keystores

### How to Rotate Twilio Credentials

1. **Generate new credentials:**
   - Login to [Twilio Console](https://console.twilio.com/)
   - Navigate to Account → Keys & Credentials
   - Create new API key or reset Auth Token
   - Copy new credentials

2. **Update all locations:**
   ```bash
   # Local development
   nano .env
   # Update ACCOUNT_SID and AUTH_TOKEN

   # GitHub Secrets
   # Settings → Secrets → Update TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN
   ```

3. **Test in staging:**
   ```bash
   flutter test test/services/twilio_*
   # Verify SMS sending still works
   ```

4. **Deploy to production:**
   ```bash
   git tag -a v1.0.1-hotfix -m "Rotate Twilio credentials"
   git push origin v1.0.1-hotfix
   # Triggers automated deployment
   ```

5. **Revoke old credentials:**
   - Return to Twilio Console
   - Delete old API key
   - **Wait 24h** before revoking to allow rollback if issues occur

### How to Rotate Google Geocoding API Key

1. **Create new API key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Select project: `juan-heart-project`
   - Click "Create Credentials" → "API Key"
   - **Restrict key** to Geocoding API only
   - Set application restrictions (Android/iOS bundle IDs)

2. **Update environments:**
   ```bash
   # Local
   echo "GOOGLE_GEOCODING_API_KEY=NEW_KEY_HERE" >> .env

   # GitHub Secrets
   # Update GOOGLE_GEOCODING_API_KEY
   ```

3. **Test geocoding:**
   ```bash
   flutter test test/services/geospatial_service_test.dart
   ```

4. **Deploy and monitor:**
   - Deploy new version with updated key
   - Monitor Firebase Crashlytics for API errors
   - Check Geocoding API quota usage in Google Cloud Console

5. **Delete old key after 7 days**

### Android Keystore Rotation (Emergency Only)

**⚠️ WARNING:** Rotating Android keystore requires re-signing all APKs and will break app updates.

**When rotation is necessary:**
- Keystore file compromised
- Keystore password exposed
- Security compliance requirement

**Procedure:**
1. Generate new keystore (see Phase 1.4 below)
2. **Contact Google Play Support** for key upgrade
3. Follow Google's [app signing key upgrade process](https://support.google.com/googleplay/android-developer/answer/9842756)
4. Test signed APK installation over existing app
5. Submit updated keystore to Google Play Console
6. **Coordinate with users** for app update

---

## Best Practices

### 1. Never Commit Secrets

**Bad:**
```dart
// NEVER do this
const twilioAuthToken = "90059dd7de9558c5b187e6e2a3303523";
```

**Good:**
```dart
// Use environment variables
final twilioAuthToken = dotenv.env['TWILIO_AUTH_TOKEN'];
```

### 2. Use Environment-Specific Configurations

Create multiple environments:
```
.env.development  (local dev, safe to share dummy values)
.env.staging      (staging backend)
.env.production   (production secrets, never committed)
```

### 3. Restrict API Key Permissions

**Google Cloud API Keys:**
- ✅ Restrict to specific APIs (Geocoding only)
- ✅ Restrict to Android/iOS app bundle IDs
- ✅ Set quota limits to prevent abuse
- ✅ Enable billing alerts

**Twilio:**
- ✅ Use API keys instead of master credentials
- ✅ Restrict permissions to SMS only
- ✅ Set spending limits
- ✅ Enable anomaly detection

### 4. Monitor Credential Usage

**Setup alerts for:**
- Unusual API usage spikes
- Failed authentication attempts
- Quota exceeded warnings
- Geographic anomalies

**Tools:**
- Firebase Crashlytics for runtime errors
- Google Cloud Monitoring for API usage
- Twilio Console usage dashboard
- GitHub Security Alerts for code scanning

### 5. Document Credential Ownership

Maintain a credential matrix:

| Credential | Owner | Backup Owner | Rotation Schedule | Last Rotated |
|------------|-------|--------------|-------------------|--------------|
| Twilio Auth Token | DevOps Lead | Backend Lead | 90 days | 2025-01-15 |
| Google Geocoding API | Frontend Lead | DevOps Lead | 90 days | 2025-01-15 |
| Android Keystore | DevOps Lead | CTO | 365 days | 2025-01-15 |
| iOS Distribution Cert | iOS Lead | DevOps Lead | 365 days | TBD |

---

## Emergency Response Plan

### If Credentials Are Leaked

**1. Immediate Actions (Within 1 hour):**
```bash
# 1. Revoke compromised credentials immediately
# Twilio: Console → Delete API Key
# Google: Cloud Console → Delete API Key

# 2. Audit git history for exposure
git log --all --full-history -S "LEAKED_CREDENTIAL"

# 3. If found in git history, contact GitHub Support
# Request repository credential scanning: https://docs.github.com/en/code-security/secret-scanning
```

**2. Short-term Actions (Within 24 hours):**
- Rotate all compromised credentials
- Update all environments (dev, staging, production)
- Force new app release if credentials embedded in app
- Monitor for unauthorized API usage
- Check billing for unexpected charges

**3. Post-Incident Actions (Within 1 week):**
- Conduct security review
- Update credential rotation schedule
- Implement additional monitoring
- Train team on security best practices
- Document incident and lessons learned

---

## Compliance & Auditing

### Regular Security Audits

**Monthly:**
- Review GitHub Secret last update dates
- Check API quota usage for anomalies
- Verify `.env` still in `.gitignore`
- Test credential rotation procedures

**Quarterly:**
- Rotate Twilio and Google API credentials
- Audit Firebase console access logs
- Review Google Play Console service account permissions
- Update credential documentation

**Annually:**
- Full security assessment
- Penetration testing
- Compliance review (Data Privacy Act of 2012)
- Update disaster recovery plan

---

## References

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Google Cloud API Security Best Practices](https://cloud.google.com/docs/authentication/api-keys-best-practices)
- [Twilio API Key Best Practices](https://www.twilio.com/docs/iam/keys/api-key-best-practices)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

**Last Updated:** January 2025
**Next Review:** April 2025
**Document Owner:** DevOps Lead
