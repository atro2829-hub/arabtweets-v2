import java.io.FileInputStream
import java.util.Properties

pluginManagement {
    val propertiesFile = file("local.properties")
    val properties = Properties()
    if (propertiesFile.exists()) {
        properties.load(FileInputStream(propertiesFile))
    }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
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