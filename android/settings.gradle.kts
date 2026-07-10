pluginManagement {
    val localPropertiesFile = file("local.properties")
    val flutterSdkPath = if (localPropertiesFile.exists()) {
        localPropertiesFile.readLines()
            .firstOrNull { it.startsWith("flutter.sdk") }
            ?.substringAfter("=")
            ?.trim()
    } else null
    require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

include(":app")