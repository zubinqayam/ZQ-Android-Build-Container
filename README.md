# ZQ Android Build Container

> **Universal Android sovereign pipeline** – a governance-grade, master-pattern
> repository template for building, signing, and distributing Android APKs via
> GitHub Actions, with full Codespaces / Dev Container support and an OTA update
> infrastructure stub.

---

## Table of Contents

1. [Overview](#overview)
2. [Repository Layout](#repository-layout)
3. [Quick Start](#quick-start)
4. [Codespaces / Dev Container](#codespaces--dev-container)
5. [Android SDK Setup](#android-sdk-setup)
6. [Gradle Wrapper Bootstrap](#gradle-wrapper-bootstrap)
7. [Build Workflows](#build-workflows)
   - [Debug Builds](#debug-builds)
   - [Release / Signed Builds](#release--signed-builds)
8. [Signing Configuration](#signing-configuration)
9. [OTA Update Infrastructure](#ota-update-infrastructure)
10. [Customising App Name & Package](#customising-app-name--package)
11. [Creating a Distribution ZIP](#creating-a-distribution-zip)
12. [Forking & Reuse](#forking--reuse)
13. [Governance & Security Notes](#governance--security-notes)
14. [License](#license)

---

## Overview

This repository provides a **complete, zero-waste scaffold** for Android
application development inside sovereign, self-hosted, or air-gapped
environments.  It is designed to be:

- **Forked once, customised in minutes** via `create-repo-zip.sh`
- **Fully CI-native** – debug and release builds run on GitHub Actions with no
  local toolchain required
- **Codespace-ready** – open in a browser and start coding in under 2 minutes
- **Governance-grade** – signed releases, SHA-256 attestation, OTA manifest
  updates, and audit-friendly workflow logs

---

## Repository Layout

```
.
├── .devcontainer/
│   ├── devcontainer.json          # Codespaces / Dev Container configuration
│   └── install-android-sdk.sh    # Idempotent Android SDK installer
│                                  #   uses ANDROIDSDKROOT (canonical variable)
│
├── .github/
│   ├── workflows/
│   │   ├── build-apk.yml         # Debug APK – triggers on every push/PR
│   │   └── release-apk.yml       # Signed release APK – triggers on v* tags
│   └── ota/
│       ├── ota-manifest.json     # OTA update manifest (auto-updated by CI)
│       └── private-store-stub.json  # Private/MDM store API shape (docs)
│
├── app/
│   ├── build.gradle              # Module-level build script
│   └── src/main/
│       ├── AndroidManifest.xml   # App manifest (change package here)
│       ├── java/com/example/app/
│       │   └── MainActivity.java # Skeleton entry-point activity
│       └── res/
│           ├── layout/activity_main.xml
│           └── values/strings.xml
│
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties  # Placeholder – see bootstrap section
│
├── build.gradle                  # Root build script (AGP version, repos)
├── settings.gradle               # Project name + module list
├── gradlew                       # Wrapper script (placeholder)
├── gradlew.bat                   # Wrapper script – Windows (placeholder)
│
├── create-repo-zip.sh            # Packages skeleton with --appName/--package
├── OPERATOR.md                   # Step-by-step new-project guide
└── README.md                     # This file
```

---

## Quick Start

```bash
# 1. Fork or clone this repository
git clone https://github.com/zubinqayam/ZQ-Android-Build-Container.git my-app
cd my-app

# 2. Bootstrap the Gradle wrapper (requires Gradle installed locally OR
#    use Android Studio → File → Project Structure → Gradle to set the version)
gradle wrapper --gradle-version 8.7 --distribution-type all

# 3. Build a debug APK
./gradlew assembleDebug

# The APK is at: app/build/outputs/apk/debug/app-debug.apk
```

See [OPERATOR.md](OPERATOR.md) for the full new-project workflow.

---

## Codespaces / Dev Container

Open this repository in a GitHub Codespace and the `.devcontainer/` configuration
will automatically:

1. Pull the `ubuntu-22.04` base image
2. Run `.devcontainer/install-android-sdk.sh` to install JDK 17 and the
   Android SDK under `$ANDROIDSDKROOT` (`/opt/android-sdk`)
3. Install recommended VS Code extensions (Java, Kotlin, Gradle, XML)

> **SDK root variable:** `ANDROIDSDKROOT` is the canonical variable name used
> throughout this repository.  `ANDROID_HOME` is set as an alias for backward
> compatibility.  **Do not rename** `ANDROIDSDKROOT` without also updating
> `devcontainer.json`, `install-android-sdk.sh`, and every workflow file.

---

## Android SDK Setup

### In Codespaces / CI
The SDK is installed automatically.  No manual steps required.

### Locally (without Codespaces)
```bash
export ANDROIDSDKROOT=/opt/android-sdk   # or any writable path
bash .devcontainer/install-android-sdk.sh
```

Versions are controlled by environment variables in `install-android-sdk.sh`:

| Variable               | Default   | Purpose                     |
|------------------------|-----------|-----------------------------|
| `CMDLINE_TOOLS_VERSION`| `11076708`| cmdline-tools build number  |
| `BUILD_TOOLS_VERSION`  | `34.0.0`  | Android build tools version |
| `COMPILE_SDK_VERSION`  | `34`      | `compileSdk` / platform     |
| `JDK_PACKAGE`          | `openjdk-17-jdk` | APT package name     |

---

## Gradle Wrapper Bootstrap

The `gradlew` / `gradlew.bat` files in this repo are **stubs** that print a
helpful error if `gradle-wrapper.jar` is missing.  Replace them by running:

```bash
# Option A – if Gradle is installed locally
gradle wrapper --gradle-version 8.7 --distribution-type all

# Option B – via Android Studio
# File → Project Structure → Project → Gradle Version → 8.7 → OK
```

Then commit the generated files:
```
gradle/wrapper/gradle-wrapper.jar    ← must be committed
gradle/wrapper/gradle-wrapper.properties
gradlew
gradlew.bat
```

> **AGP / Gradle compatibility:** AGP 8.4.x (declared in `build.gradle`)
> requires Gradle **8.6 or higher**.
> See the [compatibility matrix](https://developer.android.com/build/releases/gradle-plugin).

---

## Build Workflows

### Debug Builds

**File:** `.github/workflows/build-apk.yml`

| Trigger | Behaviour |
|---------|-----------|
| Push to any branch | Assembles a debug APK |
| Pull request | Assembles a debug APK |
| `workflow_dispatch` | Manual trigger from the Actions tab |

Output artifact: `debug-apk-<sha>` (retained 14 days).

### Release / Signed Builds

**File:** `.github/workflows/release-apk.yml`

| Trigger | Behaviour |
|---------|-----------|
| Push of a `v*.*.*` tag | Assembles, signs, and uploads a release APK |
| `workflow_dispatch` | Manual trigger (useful for pipeline testing) |

Output:
- GitHub Release with the signed APK attached
- `release-apk-<version>` artifact (retained 90 days)
- Updated `ota-manifest.json` committed back to the default branch

---

## Signing Configuration

### Local Development (unsigned)
By default `minifyEnabled` and signing are disabled in `app/build.gradle`.
Debug builds are signed automatically with the Android debug keystore.

### CI / Production Signing
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore release.jks \
           -alias <YOUR_ALIAS> -keyalg RSA -keysize 4096 -validity 10000
   ```
2. Base64-encode it:
   ```bash
   base64 -w0 release.jks > release.jks.b64
   ```
3. Add four **repository secrets** (Settings → Secrets → Actions):
   | Secret name            | Value                        |
   |------------------------|------------------------------|
   | `RELEASE_KEYSTORE_B64` | Contents of `release.jks.b64`|
   | `KEY_ALIAS`            | Your keystore alias           |
   | `KEY_PASSWORD`         | Key password                  |
   | `STORE_PASSWORD`       | Store password                |
4. Push a tag: `git tag v1.0.0 && git push origin v1.0.0`

To activate signing in **local** release builds, un-comment the
`signingConfigs` block in `app/build.gradle` and set the four
`SIGNING_*` environment variables.

> ⚠️ **Never commit a plaintext keystore or password to source control.**

---

## OTA Update Infrastructure

After each successful release build, the workflow automatically updates
`.github/ota/ota-manifest.json` with:
- `latestVersion` – the new semver version
- `sha256` – SHA-256 checksum of the signed APK
- `downloadUrl` – HTTPS link to the GitHub Release asset
- `releaseDate` – ISO 8601 date

Your MDM platform or custom update client can poll this manifest to detect and
install new versions.  See `.github/ota/private-store-stub.json` for the
minimal REST API shape your internal app store must implement.

To **disable** OTA manifest updates, delete the "Update OTA manifest" and
"Commit updated OTA manifest" steps from `release-apk.yml`.

---

## Customising App Name & Package

### Manual
1. **App name** – edit `app/src/main/res/values/strings.xml` → `app_name`
   and `settings.gradle` → `rootProject.name`
2. **Package identifier** – edit:
   - `AndroidManifest.xml` → `package` attribute
   - `app/build.gradle` → `namespace` and `applicationId`
   - Rename `app/src/main/java/com/example/app/` to match the new package
   - Update the `package` declaration in `MainActivity.java`
   - `.github/ota/ota-manifest.json` → `appId`

### Automated (via `create-repo-zip.sh`)
```bash
bash create-repo-zip.sh \
  --appName "FieldOps" \
  --package "com.acme.fieldops" \
  --output fieldops-skeleton.zip
```

This produces a ready-to-use ZIP with all substitutions applied.

---

## Creating a Distribution ZIP

`create-repo-zip.sh` packages the entire skeleton (excluding `.git/` and build
artifacts) as a ZIP archive, optionally rewriting the app name and package.

```bash
# Default (no substitution)
bash create-repo-zip.sh

# Custom app name + package
bash create-repo-zip.sh --appName "MySovereignApp" --package "gov.agency.mobile"

# Custom output path
bash create-repo-zip.sh --output /tmp/my-app-skeleton.zip

# Help
bash create-repo-zip.sh --help
```

The script prints the SHA-256 checksum of the archive for audit purposes.

---

## Forking & Reuse

This repository is designed to be **forked once and maintained independently**:

1. Fork on GitHub (or clone + push to your own remote).
2. Run `create-repo-zip.sh --appName … --package …` to generate a customised
   skeleton ZIP for each new project.
3. Unzip, commit, and push to a new project repository.
4. Add the four signing secrets and push a `v*` tag to trigger a release build.

### Keeping up with upstream changes
```bash
git remote add upstream https://github.com/zubinqayam/ZQ-Android-Build-Container.git
git fetch upstream
git merge upstream/main --allow-unrelated-histories
```

---

## Governance & Security Notes

| Concern | Mitigation |
|---------|------------|
| Keystore exposure | Stored as a base64 GitHub Secret; decoded to `$RUNNER_TEMP` and deleted in a `if: always()` cleanup step |
| Dependency pinning | All `uses:` action references include a major version pin; update to digest-pins for maximum supply-chain security |
| SDK version drift | `ANDROIDSDKROOT` / `COMPILE_SDK` / `BUILD_TOOLS` are declared in one place per environment (workflow `env:` block or `install-android-sdk.sh`) |
| Build reproducibility | Gradle wrapper version is pinned in `gradle-wrapper.properties`; JDK version is pinned in both workflows |
| OTA integrity | SHA-256 checksum is written into `ota-manifest.json` alongside the download URL |

---

## License

Apache License 2.0 – see [LICENSE](LICENSE).
