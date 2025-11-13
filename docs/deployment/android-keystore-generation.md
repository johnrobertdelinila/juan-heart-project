# Android Production Keystore Generation Guide

## Overview

This guide walks through generating a production-grade Android keystore for signing release APKs/AABs.

**⚠️ CRITICAL:** The keystore is the **ONLY** way to sign app updates. If lost, you **CANNOT** update the app on Google Play Store.

---

## Prerequisites

- Java Development Kit (JDK) 8 or higher
- Access to secure password manager
- Backup storage (encrypted USB drive or secure cloud storage)

---

## Step 1: Generate Keystore

### Command

```bash
cd ~/AndroidStudioProjects/Juan-Heart-Mobile/android/app

keytool -genkey -v \
  -keystore juan-heart-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias juan-heart-key
```

### Interactive Prompts

**You will be asked for:**

1. **Keystore password:** (minimum 6 characters)
   - Choose a strong password (16+ characters, mixed case, numbers, symbols)
   - Example: `JuanHeart2025!SecureKey#App`
   - **SAVE THIS IMMEDIATELY** in password manager

2. **Re-enter keystore password:** (confirmation)

3. **Key password:** (can be same as keystore password)
   - Recommended: Use **same password** as keystore for simplicity
   - Press ENTER to use same password

4. **First and Last name:**
   - Enter: `Juan Heart Development Team`

5. **Organizational unit:**
   - Enter: `Mobile Development`

6. **Organization:**
   - Enter: `University of Cordilleras` or `Philippine Heart Center`

7. **City or Locality:**
   - Enter: `Quezon City` or your city

8. **State or Province:**
   - Enter: `Metro Manila`

9. **Two-letter country code:**
   - Enter: `PH`

10. **Confirm information:**
    - Type: `yes`

### Example Output

```
Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA)
with a validity of 10,000 days for: CN=Juan Heart Development Team,
OU=Mobile Development, O=University of Cordilleras, L=Quezon City, ST=Metro Manila, C=PH

Enter keystore password: ****************
Re-enter new password: ****************
Enter key password for <juan-heart-key>
        (RETURN if same as keystore password): [Press ENTER]

[Storing juan-heart-release.jks]
```

---

## Step 2: Verify Keystore

```bash
keytool -list -v -keystore juan-heart-release.jks -alias juan-heart-key
```

Expected output should show:
```
Alias name: juan-heart-key
Creation date: Jan 15, 2025
Entry type: PrivateKeyEntry
Certificate chain length: 1
Certificate[1]:
Owner: CN=Juan Heart Development Team, OU=Mobile Development...
Issuer: CN=Juan Heart Development Team, OU=Mobile Development...
Serial number: 1a2b3c4d
Valid from: Wed Jan 15 10:00:00 PST 2025 until: Sat Oct 11 10:00:00 PST 2052
Certificate fingerprints:
         SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
         SHA256: XX:XX:XX:...
```

---

## Step 3: Secure Keystore File

### Immediate Actions

1. **Move keystore to secure location:**
   ```bash
   # Keep one copy in android/app (git-ignored)
   # This copy is used for local release builds
   ls -la android/app/juan-heart-release.jks

   # Create backup copy
   cp android/app/juan-heart-release.jks ~/secure-backups/
   ```

2. **Verify .gitignore excludes keystore:**
   ```bash
   grep -n "*.jks" .gitignore
   # Should show: *.jks
   ```

3. **Test keystore NOT in git:**
   ```bash
   git status
   # juan-heart-release.jks should NOT appear
   ```

### Backup Strategy

**Create 3 copies:**

1. **Primary:** `android/app/juan-heart-release.jks` (for CI/CD, git-ignored)
2. **Backup 1:** Encrypted USB drive (store in safe/lockbox)
3. **Backup 2:** Secure cloud storage (Google Drive, 1Password, etc.)
   - Encrypt before uploading:
     ```bash
     zip -e juan-heart-keystore-backup.zip juan-heart-release.jks
     # Enter strong password
     ```

**Document keystore location:**
```
Keystore Location Registry (CONFIDENTIAL)

File: juan-heart-release.jks
Created: 2025-01-15
Owner: DevOps Lead

Primary Location: android/app/juan-heart-release.jks (git-ignored)
Backup 1: USB Drive "JH-Secure-2025" in office safe
Backup 2: Google Drive (encrypted zip) - shared with CTO only
GitHub Secrets: ANDROID_KEYSTORE_BASE64

Passwords stored in: 1Password vault "Juan Heart Production"
```

---

## Step 4: Configure Gradle for Release Signing

### 4A: Create key.properties

```bash
cd ~/AndroidStudioProjects/Juan-Heart-Mobile/android

cat > key.properties <<EOF
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=juan-heart-key
storeFile=juan-heart-release.jks
EOF

# Verify file is git-ignored
grep -n "key.properties" .gitignore
# Should show: key.properties
```

### 4B: Update android/app/build.gradle

**Current state (using debug keystore):**
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.debug  // ❌ INSECURE
        minifyEnabled true
        shrinkResources true
    }
}
```

**Update to production keystore:**

1. **Add keystore configuration loading (before `android {` block):**

```gradle
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

2. **Add signing config (inside `android {` block, before `buildTypes`):**

```gradle
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

3. **Update release build type:**

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release  // ✅ PRODUCTION KEYSTORE
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**Complete example:**
```gradle
// Load keystore properties
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.example.juan_heart"
    compileSdkVersion flutter.compileSdkVersion

    // ... other config ...

    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## Step 5: Test Release Build

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build release APK with new keystore
flutter build apk --release

# Verify signing
cd build/app/outputs/flutter-apk
keytool -printcert -jarfile app-release.apk

# Should show your certificate details (not Android debug certificate)
```

**Expected output:**
```
Signer #1:

Signature:
Owner: CN=Juan Heart Development Team, OU=Mobile Development...
Issuer: CN=Juan Heart Development Team, OU=Mobile Development...
```

**❌ If you see "CN=Android Debug":**
- Keystore configuration failed
- Check key.properties path
- Verify passwords are correct

---

## Step 6: Upload Keystore to GitHub Secrets

```bash
# Encode keystore as base64
base64 -i android/app/juan-heart-release.jks | tr -d '\n' > keystore-base64.txt

# Copy to clipboard (macOS)
cat keystore-base64.txt | pbcopy

# Copy to clipboard (Linux)
cat keystore-base64.txt | xclip -selection clipboard

# Copy to clipboard (Windows)
type keystore-base64.txt | clip
```

**Add to GitHub:**
1. Go to repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `ANDROID_KEYSTORE_BASE64`
4. Value: Paste base64 content
5. Click "Add secret"

**Add keystore password:**
1. Click "New repository secret"
2. Name: `ANDROID_KEYSTORE_PASSWORD`
3. Value: Your keystore password
4. Click "Add secret"

Repeat for: `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`

---

## Step 7: Configure CI/CD to Use Keystore

**GitHub Actions workflow example:**

``yaml
- name: Decode and setup keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/juan-heart-release.jks

    cat > android/key.properties <<EOF
    storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}
    keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
    keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
    storeFile=juan-heart-release.jks
    EOF

- name: Build release APK
  run: flutter build apk --release
```

---

## Troubleshooting

### Error: keystore not found

```
FileNotFoundException: android/app/juan-heart-release.jks
```

**Solution:**
- Check file path in `key.properties`
- Ensure `storeFile=juan-heart-release.jks` (relative path)
- Verify keystore file exists: `ls android/app/*.jks`

### Error: keystore password incorrect

```
java.io.IOException: Keystore was tampered with, or password was incorrect
```

**Solution:**
- Double-check password in `key.properties`
- Verify you're using keystore password (not key password)
- Test password: `keytool -list -keystore juan-heart-release.jks`

### Error: alias not found

```
Failed to read key juan-heart-key from store: Given final block not properly padded
```

**Solution:**
- Check `keyAlias=juan-heart-key` matches alias used during generation
- List aliases: `keytool -list -keystore juan-heart-release.jks`

### Warning: Using debug certificate

If `flutter build apk --release` still uses debug certificate:

```bash
# Delete old build
rm -rf build/

# Verify key.properties exists
cat android/key.properties

# Rebuild
flutter clean
flutter build apk --release --verbose

# Check signing in verbose output
# Should show: "Using signing config 'release'"
```

---

## Security Checklist

Before going to production:

- [ ] Keystore password is strong (16+ characters)
- [ ] Keystore file is git-ignored (`.gitignore` includes `*.jks`)
- [ ] key.properties is git-ignored
- [ ] 3 backup copies created (primary + 2 backups)
- [ ] Passwords stored in password manager (not plain text)
- [ ] GitHub Secrets configured correctly
- [ ] Release build tested and verified
- [ ] Keystore details documented
- [ ] Team members know backup locations
- [ ] Disaster recovery plan updated

---

## Keystore Lifecycle

**Validity:** 10,000 days (~27 years)
**Expires:** October 11, 2052
**Renewal:** Not required during app lifecycle
**Rotation:** Only if compromised (requires Google Play Console support)

---

## Emergency Procedures

### If Keystore is Lost

**⚠️ CRITICAL:** Without keystore, you **CANNOT** update the app.

1. **Check all backup locations immediately**
2. **Search local machine:**
   ```bash
   find ~ -name "*.jks" -o -name "*keystore*" 2>/dev/null
   ```
3. **Check GitHub Secrets:** Settings → Secrets → ANDROID_KEYSTORE_BASE64
   - Download and decode:
     ```bash
     # Copy base64 value from GitHub
     echo "PASTE_BASE64_HERE" | base64 --decode > recovered-keystore.jks
     ```
4. **If truly lost:** Contact Google Play Console support for app signing key upgrade
   - This is a complex process requiring verification
   - May take weeks to complete
   - Document loss in incident report

### If Keystore is Compromised

1. **Immediately revoke access** to compromised systems
2. **Generate new keystore** following this guide
3. **Contact Google Play Console** for key upgrade process
4. **Force app update** with new keystore
5. **Conduct security audit** to identify breach source
6. **Update disaster recovery plan**

---

**Document Version:** 1.0
**Last Updated:** January 2025
**Next Review:** January 2026
**Owner:** DevOps Lead
