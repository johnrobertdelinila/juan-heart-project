# GitHub Secrets Setup Guide

## Quick Reference

**Repository:** `https://github.com/YOUR_ORG/Juan-Heart-Mobile`
**Path:** Settings → Secrets and variables → Actions → New repository secret

---

## Step-by-Step Setup

### 1. Navigate to GitHub Secrets

1. Go to repository on GitHub
2. Click **Settings** tab
3. In left sidebar, expand **Secrets and variables**
4. Click **Actions**
5. Click **New repository secret** button

### 2. Add Required Secrets

Copy-paste the following secrets (replace `PLACEHOLDER_VALUE` with actual values):

#### Android Code Signing Secrets

```bash
# Secret Name: ANDROID_KEYSTORE_BASE64
# Value: [base64 encoded keystore file]
# How to get: base64 -i android/juan-heart-release.jks | pbcopy

# Secret Name: ANDROID_KEYSTORE_PASSWORD
# Value: [your keystore password]

# Secret Name: ANDROID_KEY_ALIAS
# Value: juan-heart-key

# Secret Name: ANDROID_KEY_PASSWORD
# Value: [your key password]

# Secret Name: ANDROID_STORE_PASSWORD
# Value: [usually same as keystore password]
```

#### Google Play Deployment Secrets

```bash
# Secret Name: PLAY_STORE_SERVICE_ACCOUNT_JSON
# Value: [base64 encoded service account JSON]
# How to get: base64 -i play-store-service-account.json | pbcopy

# Secret Name: ANDROID_PACKAGE_NAME
# Value: com.example.juan_heart
```

#### Runtime Environment Variables

```bash
# Secret Name: TWILIO_ACCOUNT_SID
# Value: [from Twilio Console]

# Secret Name: TWILIO_AUTH_TOKEN
# Value: [from Twilio Console]

# Secret Name: TWILIO_NUMBER
# Value: [from Twilio Console]

# Secret Name: GOOGLE_GEOCODING_API_KEY
# Value: [from Google Cloud Console]

# Secret Name: EDUCATIONAL_CONTENT_API_URL
# Value: https://your-backend-api.com/api/v1/mobile
```

---

## Verification

After adding all secrets, run this verification script:

```bash
# From repository root
./scripts/verify-github-secrets.sh
```

Expected output:
```
✅ ANDROID_KEYSTORE_BASE64 exists
✅ ANDROID_KEYSTORE_PASSWORD exists
✅ ANDROID_KEY_ALIAS exists
✅ ANDROID_KEY_PASSWORD exists
✅ ANDROID_STORE_PASSWORD exists
✅ PLAY_STORE_SERVICE_ACCOUNT_JSON exists
✅ ANDROID_PACKAGE_NAME exists
✅ TWILIO_ACCOUNT_SID exists
✅ TWILIO_AUTH_TOKEN exists
✅ TWILIO_NUMBER exists
✅ GOOGLE_GEOCODING_API_KEY exists
✅ EDUCATIONAL_CONTENT_API_URL exists

All required secrets configured!
```

---

## Using Secrets in GitHub Actions

### Example: Android Build Workflow

```yaml
name: Build Android APK

on:
  push:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'temurin'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Decode keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## Security Best Practices

### ✅ DO

- Use descriptive secret names (e.g., `ANDROID_KEYSTORE_PASSWORD` not `PASSWORD`)
- Store keystore files as base64-encoded strings
- Use separate secrets for development and production
- Rotate secrets every 90 days
- Document which workflows use which secrets
- Use environment-specific secrets when possible

### ❌ DON'T

- Commit secrets to repository
- Print secret values in workflow logs
- Share secrets via Slack/email
- Use production secrets in development
- Store secrets in code comments
- Reuse passwords across services

---

## Troubleshooting

### Secret not found error

```
Error: Secret ANDROID_KEYSTORE_BASE64 not found
```

**Solution:**
1. Verify secret name matches exactly (case-sensitive)
2. Check secret is added to correct repository
3. Verify secret is not expired or deleted
4. Re-add secret and re-run workflow

### Invalid base64 encoding

```
Error: illegal base64 data at input byte 0
```

**Solution:**
```bash
# Ensure proper base64 encoding (no line breaks)
base64 -i file.jks | tr -d '\n' | pbcopy
```

### Permission denied errors

```
Error: Resource not accessible by integration
```

**Solution:**
1. Check workflow has correct permissions in YAML:
   ```yaml
   permissions:
     contents: write
     packages: write
   ```
2. Verify repository settings allow Actions
3. Check branch protection rules

---

## Secret Rotation Checklist

When rotating secrets:

- [ ] Generate new credential
- [ ] Update secret in GitHub
- [ ] Update local `.env` file
- [ ] Test in CI/CD pipeline
- [ ] Deploy to production
- [ ] Monitor for errors
- [ ] Revoke old credential (after 24h)
- [ ] Document rotation in credential matrix

---

**Last Updated:** January 2025
**Next Review:** Monthly
