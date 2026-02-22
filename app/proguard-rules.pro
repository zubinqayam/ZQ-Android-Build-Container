# =============================================================================
# proguard-rules.pro  –  ProGuard / R8 rules for the release build
#
# ProGuard is currently DISABLED in app/build.gradle (minifyEnabled = false).
# When you are ready to enable it, set minifyEnabled = true and shrinkResources
# = true in the release buildType, then add your keep rules here.
#
# ── Common rules you may need ─────────────────────────────────────────────────
# Keep your model classes if you use Gson / Moshi / Jackson:
# -keep class com.yourorg.yourapp.model.** { *; }
#
# Keep Retrofit service interfaces:
# -keep interface com.yourorg.yourapp.network.** { *; }
#
# AndroidX / Jetpack rules are bundled with the libraries themselves via
# @Keep annotations and consumer ProGuard files.
#
# Docs: https://developer.android.com/build/shrink-code
# =============================================================================

# Add project-specific ProGuard rules here.
