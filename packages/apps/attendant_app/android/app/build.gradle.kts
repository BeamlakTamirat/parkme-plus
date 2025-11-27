plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wepark.attendant_app"
    compileSdk = 35
    // Updated to NDK 29 as specified by user
    ndkVersion = "29.0.13846066"

    compileOptions {
        // Core library desugaring requires Java 8+
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wepark.attendant_app"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Core library desugaring for modern Java APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

// Fix for Flutter not finding APK - Copy APK to expected location
afterEvaluate {
    tasks.register<Copy>("copyDebugApk") {
        from("build/outputs/apk/debug")
        into("../../build/app/outputs/flutter-apk")
        include("*.apk")
        rename { "app-debug.apk" }
    }

    tasks.register<Copy>("copyReleaseApk") {
        from("build/outputs/apk/release")
        into("../../build/app/outputs/flutter-apk")
        include("*.apk")
        rename { "app-release.apk" }
    }

    // Automatically copy APK after assembling
    tasks.named("assembleDebug").configure {
        finalizedBy("copyDebugApk")
    }

    tasks.named("assembleRelease").configure {
        finalizedBy("copyReleaseApk")
    }
} 

