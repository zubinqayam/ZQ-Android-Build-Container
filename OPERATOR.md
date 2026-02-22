# OPERATOR.md – New-Project Workflow Guide

> This guide is for **operators** (DevOps engineers, team leads, or anyone
> creating a new Android project from this template).  It walks you through
> every step from forking the template to shipping your first signed release.

---

## Prerequisites

| Tool | Minimum version | Install |
|------|-----------------|---------|
| Git  | 2.x | https://git-scm.com |
| Java (JDK) | 17 | https://adoptium.net |
| Gradle | 8.6+ | https://gradle.org/install/ |
| Android Studio | 2024.x (optional) | https://developer.android.com/studio |
| `zip` / `unzip` | any | via package manager |

---

## Step 1 – Fork or Clone the Template

### Option A – GitHub Fork (recommended)
1. Navigate to https://github.com/zubinqayam/ZQ-Android-Build-Container
2. Click **Fork** → choose your organisation / username.
3. Clone your fork:
   ```bash
   git clone https://github.com/<YOUR_ORG>/<YOUR_REPO>.git
   cd <YOUR_REPO>
   ```

### Option B – Extract from ZIP
```bash
bash create-repo-zip.sh \
  --appName "MyNewApp" \
  --package "com.myorg.mynewapp" \
  --output my-new-app.zip

unzip my-new-app.zip -d my-new-app
cd my-new-app
git init
git add .
git commit -m "Initial commit from ZQ sovereign pipeline scaffold"
```

---

## Step 2 – Customise App Name & Package

If you did **not** use `create-repo-zip.sh --appName/--package`, apply the
changes manually:

1. **Display name** (`app/src/main/res/values/strings.xml`):
   ```xml
   <string name="app_name">Your App Name Here</string>
   ```

2. **Project name** (`settings.gradle`):
   ```groovy
   rootProject.name = "YourAppName"
   ```

3. **Package identifier** (`app/build.gradle`):
   ```groovy
   namespace   'com.yourorg.yourapp'
   applicationId "com.yourorg.yourapp"
   ```

4. **Manifest** (`app/src/main/AndroidManifest.xml`):
   ```xml
   <manifest … package="com.yourorg.yourapp">
   ```

5. **Rename source directory** and update `package` declaration:
   ```bash
   mkdir -p app/src/main/java/com/yourorg/yourapp
   mv app/src/main/java/com/example/app/MainActivity.java \
      app/src/main/java/com/yourorg/yourapp/
   sed -i 's/^package com\.example\.app;/package com.yourorg.yourapp;/' \
      app/src/main/java/com/yourorg/yourapp/MainActivity.java
   rm -rf app/src/main/java/com/example
   ```

6. **OTA manifest** (`.github/ota/ota-manifest.json`):
   ```json
   { "appId": "com.yourorg.yourapp", "appName": "Your App Name Here", … }
   ```

---

## Step 3 – Bootstrap the Gradle Wrapper

The `gradlew` stubs in the template will refuse to run without a real wrapper
JAR.  Bootstrap it once:

```bash
# Option A: local Gradle installation
gradle wrapper --gradle-version 8.7 --distribution-type all

# Option B: Android Studio
# File → Project Structure → Project → Gradle Version → 8.7 → OK
```

Commit the generated files:
```bash
git add gradlew gradlew.bat gradle/wrapper/gradle-wrapper.jar \
        gradle/wrapper/gradle-wrapper.properties
git commit -m "chore: add Gradle wrapper"
```

Verify the wrapper works:
```bash
chmod +x ./gradlew
./gradlew --version
```

---

## Step 4 – Install the Android SDK (local development)

### In GitHub Codespaces
The SDK is installed automatically when the Codespace starts.  Skip this step.

### Locally
```bash
export ANDROIDSDKROOT=/opt/android-sdk   # choose any writable path
bash .devcontainer/install-android-sdk.sh
```

Add to your shell profile:
```bash
echo 'export ANDROIDSDKROOT=/opt/android-sdk' >> ~/.bashrc
echo 'export ANDROID_HOME=/opt/android-sdk'   >> ~/.bashrc
echo 'export PATH="${PATH}:${ANDROIDSDKROOT}/cmdline-tools/latest/bin:${ANDROIDSDKROOT}/platform-tools"' >> ~/.bashrc
source ~/.bashrc
```

---

## Step 5 – Build a Debug APK

```bash
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/app-debug.apk
```

---

## Step 6 – Configure Signed Release Builds

> Complete this step before shipping to production or uploading to any store.

1. **Generate a release keystore** (do this once; store the `.jks` securely):
   ```bash
   keytool -genkey -v -keystore release.jks \
           -alias mykey \
           -keyalg RSA -keysize 4096 -validity 10000
   ```
   > ⚠️ Back up `release.jks` in a password manager or HSM.
   > **Never commit it to source control.**

2. **Base64-encode the keystore**:
   ```bash
   base64 -w0 release.jks > release.jks.b64
   # macOS: base64 -i release.jks -o release.jks.b64
   ```

3. **Add repository secrets** (GitHub → Settings → Secrets and variables →
   Actions → New repository secret):
   | Name                   | Value                             |
   |------------------------|-----------------------------------|
   | `RELEASE_KEYSTORE_B64` | Paste the full content of `release.jks.b64` |
   | `KEY_ALIAS`            | `mykey` (or your chosen alias)    |
   | `KEY_PASSWORD`         | The key password you chose        |
   | `STORE_PASSWORD`       | The store password you chose      |

4. **Enable signing in `app/build.gradle`** by un-commenting the
   `signingConfigs.release` block and `signingConfig signingConfigs.release`
   inside `buildTypes.release`.

---

## Step 7 – Push Your First Release Tag

```bash
# Ensure the main branch is clean and committed
git checkout main
git pull

# Tag the release (semver, starting with 'v')
git tag v1.0.0
git push origin v1.0.0
```

The `release-apk.yml` workflow will:
1. Assemble and sign the APK
2. Create a GitHub Release with the APK attached
3. Update `.github/ota/ota-manifest.json` with the version, SHA-256, and
   download URL

---

## Step 8 – Configure OTA Updates (optional)

1. Point your MDM or update-check client at:
   ```
   https://raw.githubusercontent.com/<ORG>/<REPO>/main/.github/ota/ota-manifest.json
   ```
2. If you operate a private store, implement the API shape described in
   `.github/ota/private-store-stub.json` and set `privateStoreEndpoint` in
   `ota-manifest.json`.

---

## Day-2 Operations

### Releasing a new version
```bash
# Bump versionCode and versionName in app/build.gradle, then:
git tag v1.1.0
git push origin v1.1.0
```

### Updating the Android SDK version
Edit the following in **one place**:
- `install-android-sdk.sh` – `BUILD_TOOLS_VERSION`, `COMPILE_SDK_VERSION`
- `.github/workflows/build-apk.yml` and `release-apk.yml` – `COMPILE_SDK`, `BUILD_TOOLS`
- `app/build.gradle` – `compileSdk`, `targetSdk`

### Updating AGP and Gradle
1. `build.gradle` → `agpVersion`
2. `gradle/wrapper/gradle-wrapper.properties` → `distributionUrl`
3. Check the [compatibility matrix](https://developer.android.com/build/releases/gradle-plugin)

### Rotating the signing key
1. Generate a new keystore.
2. Update the four `RELEASE_KEYSTORE_B64` / `KEY_*` / `STORE_PASSWORD` secrets.
3. If distributing via Play Store, follow Google's key rotation documentation.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `gradlew: Permission denied` | wrapper not executable | `chmod +x ./gradlew` |
| `gradle-wrapper.jar is missing` | wrapper not bootstrapped | Run `gradle wrapper …` (Step 3) |
| `SDK location not found` | `ANDROIDSDKROOT` not set | Export the variable (Step 4) |
| `License for package … not accepted` | fresh SDK install | `yes \| sdkmanager --licenses` |
| Release build unsigned | signing not activated | Un-comment `signingConfigs` in `app/build.gradle` and add secrets (Step 6) |
| OTA manifest not updated | CI push failed | Check runner `contents: write` permission in `release-apk.yml` |
