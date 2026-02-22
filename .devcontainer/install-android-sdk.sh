#!/usr/bin/env bash
# =============================================================================
# install-android-sdk.sh
# Idempotent Android SDK installer for Codespaces / CI containers.
#
# Canonical SDK root variable: ANDROIDSDKROOT
#   – always set via devcontainer.json "remoteEnv" or the CI workflow "env:"
#   – never hard-code a path here; read from the environment instead.
#
# Versions: bump CMDLINE_TOOLS_VERSION to the latest from
#   https://developer.android.com/studio#command-line-tools-only
#
# Usage (standalone):
#   export ANDROIDSDKROOT=/opt/android-sdk
#   bash .devcontainer/install-android-sdk.sh
# =============================================================================
set -euo pipefail

# ── Configurable versions ─────────────────────────────────────────────────────
CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-11076708}"   # r11 (2024-03)
BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-34.0.0}"
COMPILE_SDK_VERSION="${COMPILE_SDK_VERSION:-34}"
PLATFORM_TOOLS_VERSION="platform-tools"                       # always "latest"
JDK_PACKAGE="${JDK_PACKAGE:-openjdk-17-jdk}"

# ── Resolve SDK root ──────────────────────────────────────────────────────────
# ANDROIDSDKROOT must be exported by the calling environment (devcontainer.json
# or a workflow file). Fall back to /opt/android-sdk only as a last resort so
# that misconfiguration is visible, not silently swallowed.
SDK_ROOT="${ANDROIDSDKROOT:-/opt/android-sdk}"
TOOLS_DIR="${SDK_ROOT}/cmdline-tools"

echo "==> Android SDK installer"
echo "    SDK root  : ${SDK_ROOT}"
echo "    Build tools : ${BUILD_TOOLS_VERSION}"
echo "    Compile SDK : android-${COMPILE_SDK_VERSION}"

# ── Install system dependencies ───────────────────────────────────────────────
echo "==> Installing system packages…"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  "${JDK_PACKAGE}" \
  unzip \
  curl \
  wget \
  git \
  ca-certificates \
  2>/dev/null

# ── Download command-line tools (skip if already present) ────────────────────
CMDLINE_ZIP="/tmp/cmdline-tools.zip"
INSTALL_MARKER="${TOOLS_DIR}/latest/.installed"

if [[ -f "${INSTALL_MARKER}" ]]; then
  echo "==> Android command-line tools already installed – skipping download."
else
  echo "==> Downloading Android command-line tools (build ${CMDLINE_TOOLS_VERSION})…"
  wget -q --show-progress \
    "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" \
    -O "${CMDLINE_ZIP}"

  sudo mkdir -p "${TOOLS_DIR}"
  sudo unzip -q "${CMDLINE_ZIP}" -d "${TOOLS_DIR}"

  # Google bundles the tools inside a "cmdline-tools/" subdirectory inside the
  # zip; rename it to "latest" so sdkmanager paths resolve correctly.
  if [[ -d "${TOOLS_DIR}/cmdline-tools" ]]; then
    sudo mv "${TOOLS_DIR}/cmdline-tools" "${TOOLS_DIR}/latest"
  fi

  sudo touch "${INSTALL_MARKER}"
  rm -f "${CMDLINE_ZIP}"
fi

# ── Configure PATH for this session ───────────────────────────────────────────
export PATH="${TOOLS_DIR}/latest/bin:${SDK_ROOT}/platform-tools:${PATH}"

# Fix ownership so the non-root "vscode" / runner user can write to SDK_ROOT
sudo chown -R "$(id -u):$(id -g)" "${SDK_ROOT}" 2>/dev/null || true

# ── Accept licenses (non-interactive) ────────────────────────────────────────
echo "==> Accepting Android SDK licenses…"
yes | sdkmanager --sdk_root="${SDK_ROOT}" --licenses > /dev/null 2>&1 || true

# ── Install SDK components ─────────────────────────────────────────────────────
echo "==> Installing SDK components…"
sdkmanager --sdk_root="${SDK_ROOT}" \
  "${PLATFORM_TOOLS_VERSION}" \
  "platforms;android-${COMPILE_SDK_VERSION}" \
  "build-tools;${BUILD_TOOLS_VERSION}"

# ── Optional: install an emulator (disabled by default) ───────────────────────
# Uncomment the following block to add emulator support.
# Requires KVM on the host; do NOT enable on shared GitHub-hosted runners.
#
# sdkmanager --sdk_root="${SDK_ROOT}" \
#   "emulator" \
#   "system-images;android-${COMPILE_SDK_VERSION};google_apis;x86_64"
# echo "no" | avdmanager create avd \
#   --name "Pixel_6_API_${COMPILE_SDK_VERSION}" \
#   --package "system-images;android-${COMPILE_SDK_VERSION};google_apis;x86_64" \
#   --device "pixel_6" --force

# ── Persist environment variables for Codespaces ─────────────────────────────
# Append to ~/.bashrc so re-opened terminals inherit the correct PATH.
{
  echo ""
  echo "# ── Android SDK (added by install-android-sdk.sh) ──────────────────"
  echo "export ANDROIDSDKROOT=\"${SDK_ROOT}\""
  echo "export ANDROID_HOME=\"${SDK_ROOT}\""
  echo "export PATH=\"\${PATH}:${TOOLS_DIR}/latest/bin:${SDK_ROOT}/platform-tools\""
} >> "${HOME}/.bashrc" 2>/dev/null || true

echo ""
echo "==> Android SDK installation complete."
echo "    ANDROIDSDKROOT=${SDK_ROOT}"
sdkmanager --sdk_root="${SDK_ROOT}" --list_installed 2>/dev/null | grep -E "^  " | head -20 || true
