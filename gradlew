#!/usr/bin/env sh
# =============================================================================
# gradlew  –  Gradle wrapper launch script (Unix/macOS/Linux)
# PLACEHOLDER – see gradle/wrapper/gradle-wrapper.properties for instructions
#               on how to replace this with a real wrapper.
#
# This stub will print a clear error if invoked before a real wrapper has been
# bootstrapped, rather than failing silently with a cryptic error.
# =============================================================================

set -e

# ── Check whether a real wrapper JAR is present ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JAR="${SCRIPT_DIR}/gradle/wrapper/gradle-wrapper.jar"

if [ ! -f "${JAR}" ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════════╗"
  echo "║  gradle/wrapper/gradle-wrapper.jar is missing.                      ║"
  echo "║                                                                      ║"
  echo "║  This file is a PLACEHOLDER.  Generate the real Gradle wrapper by   ║"
  echo "║  running:                                                            ║"
  echo "║                                                                      ║"
  echo "║    gradle wrapper --gradle-version 8.7 --distribution-type all      ║"
  echo "║                                                                      ║"
  echo "║  Then commit gradlew, gradlew.bat, gradle/wrapper/gradle-wrapper.jar ║"
  echo "║  and gradle/wrapper/gradle-wrapper.properties.                      ║"
  echo "╚══════════════════════════════════════════════════════════════════════╝"
  echo ""
  exit 1
fi

# ── Delegate to the real wrapper ─────────────────────────────────────────────
exec java -jar "${JAR}" "$@"
