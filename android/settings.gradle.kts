pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.3.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}

include(":app")

// Force Java 17 for compatibility
System.setProperty("java.version", "17")
System.setProperty("java.runtime.version", "17")
System.setProperty("java.vm.version", "17")

// Set JAVA_HOME to prevent system variable conflicts
System.setProperty("java.home", "C:/Program Files/Android/Android Studio/jbr")