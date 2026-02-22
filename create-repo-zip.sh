#!/usr/bin/env bash
# =============================================================================
# create-repo-zip.sh
# Packages the sovereign-pipeline skeleton as a self-contained ZIP archive,
# optionally rewriting the app name and package identifier so the archive is
# ready to drop into a brand-new repository.
#
# Usage:
#   bash create-repo-zip.sh [OPTIONS]
#
# Options:
#   --appName  <name>     Human-readable app name (default: MyApp)
#                         Rewrites: res/values/strings.xml → app_name
#                                   settings.gradle → rootProject.name
#   --package  <id>       Reverse-DNS package identifier (default: com.example.app)
#                         Rewrites: AndroidManifest.xml → package
#                                   app/build.gradle → applicationId + namespace
#                                   MainActivity.java → package declaration
#                                   .github/ota/ota-manifest.json → appId
#   --output   <file>     Output zip file path (default: zq-android-pipeline.zip)
#   --help                Show this help message
#
# Examples:
#   bash create-repo-zip.sh
#   bash create-repo-zip.sh --appName "FieldOps" --package "com.acme.fieldops"
#   bash create-repo-zip.sh --appName "SovereignApp" --package "gov.agency.app" \
#                           --output sovereign-app-skeleton.zip
#
# ── What this script does ────────────────────────────────────────────────────
# 1. Copies the repo (minus .git/ and build artifacts) to a temp directory.
# 2. Applies --appName and --package substitutions using sed.
# 3. Renames the Java source directory to match the new package path.
# 4. Zips the result and places it at --output.
# 5. Prints a checksum of the archive for audit purposes.
# =============================================================================
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
APP_NAME="MyApp"
PACKAGE="com.example.app"
OUTPUT="zq-android-pipeline.zip"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Argument parsing ──────────────────────────────────────────────────────────
usage() {
  grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,2\}//' | head -30
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --appName)  APP_NAME="$2";  shift 2 ;;
    --package)  PACKAGE="$2";   shift 2 ;;
    --output)   OUTPUT="$2";    shift 2 ;;
    --help|-h)  usage ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

# Derive package path (com.example.app → com/example/app)
PACKAGE_PATH="${PACKAGE//.//}"

echo "==> Creating repo ZIP"
echo "    App name   : ${APP_NAME}"
echo "    Package    : ${PACKAGE}"
echo "    Output     : ${OUTPUT}"
echo ""

# ── Stage files into a temp directory ────────────────────────────────────────
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGE_DIR}"' EXIT

echo "==> Copying repository to staging area…"
rsync -a --exclude='.git' \
         --exclude='build/' \
         --exclude='.gradle/' \
         --exclude='*.zip' \
         "${REPO_ROOT}/" "${STAGE_DIR}/"

# ── Apply --appName substitutions ────────────────────────────────────────────
echo "==> Applying app name: '${APP_NAME}'"

# res/values/strings.xml – app_name value
sed -i "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">${APP_NAME}</string>|g" \
  "${STAGE_DIR}/app/src/main/res/values/strings.xml"

# settings.gradle – rootProject.name
sed -i "s|rootProject\.name = \".*\"|rootProject.name = \"${APP_NAME}\"|g" \
  "${STAGE_DIR}/settings.gradle"

# OTA manifest – appName
sed -i "s|\"appName\":[[:space:]]*\".*\"|\"appName\": \"${APP_NAME}\"|g" \
  "${STAGE_DIR}/.github/ota/ota-manifest.json"

# ── Apply --package substitutions ────────────────────────────────────────────
echo "==> Applying package: '${PACKAGE}'"

OLD_PACKAGE="com.example.app"
OLD_PACKAGE_PATH="com/example/app"

# AndroidManifest.xml – package attribute
sed -i "s|package=\"${OLD_PACKAGE}\"|package=\"${PACKAGE}\"|g" \
  "${STAGE_DIR}/app/src/main/AndroidManifest.xml"

# app/build.gradle – namespace + applicationId
sed -i "s|namespace[[:space:]]*'${OLD_PACKAGE}'|namespace '${PACKAGE}'|g" \
  "${STAGE_DIR}/app/build.gradle"
sed -i "s|applicationId \"${OLD_PACKAGE}\"|applicationId \"${PACKAGE}\"|g" \
  "${STAGE_DIR}/app/build.gradle"

# MainActivity.java – package declaration
sed -i "s|^package ${OLD_PACKAGE};|package ${PACKAGE};|g" \
  "${STAGE_DIR}/app/src/main/java/${OLD_PACKAGE_PATH}/MainActivity.java"

# OTA manifest – appId
sed -i "s|\"appId\":[[:space:]]*\"${OLD_PACKAGE}\"|\"appId\": \"${PACKAGE}\"|g" \
  "${STAGE_DIR}/.github/ota/ota-manifest.json"

# ── Rename Java source directory to match new package path ───────────────────
if [[ "${PACKAGE}" != "${OLD_PACKAGE}" ]]; then
  OLD_JAVA_DIR="${STAGE_DIR}/app/src/main/java/${OLD_PACKAGE_PATH}"
  NEW_JAVA_DIR="${STAGE_DIR}/app/src/main/java/${PACKAGE_PATH}"
  if [[ -d "${OLD_JAVA_DIR}" ]]; then
    echo "==> Renaming Java source directory to ${PACKAGE_PATH}"
    mkdir -p "$(dirname "${NEW_JAVA_DIR}")"
    mv "${OLD_JAVA_DIR}" "${NEW_JAVA_DIR}"
    # Remove now-empty ancestor directories
    rmdir --ignore-fail-on-non-empty \
      "${STAGE_DIR}/app/src/main/java/com/example" \
      "${STAGE_DIR}/app/src/main/java/com" 2>/dev/null || true
  fi
fi

# ── Resolve OUTPUT to an absolute path before cd-ing away ────────────────────
# If OUTPUT is relative, make it absolute relative to the original working dir.
if [[ "${OUTPUT}" != /* ]]; then
  OUTPUT="${REPO_ROOT}/${OUTPUT}"
fi

# ── Create the ZIP archive ────────────────────────────────────────────────────
echo "==> Creating archive: ${OUTPUT}"
(cd "${STAGE_DIR}" && zip -r -q "${OUTPUT}" .)

# ── Print checksum ────────────────────────────────────────────────────────────
echo ""
echo "==> Done!"
echo "    Archive : ${OUTPUT}"
if command -v sha256sum &>/dev/null; then
  echo "    SHA-256 : $(sha256sum "${OUTPUT}" | awk '{print $1}')"
elif command -v shasum &>/dev/null; then
  echo "    SHA-256 : $(shasum -a 256 "${OUTPUT}" | awk '{print $1}')"
fi
echo ""
echo "    Unzip with:"
echo "      unzip ${OUTPUT} -d my-new-android-app"
echo "      cd    my-new-android-app"
echo "      git init && git add . && git commit -m 'Initial sovereign pipeline scaffold'"
