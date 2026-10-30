plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.castilla.potion_post"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.castilla.potion_post"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "Potion Post")
    }

    flavorDimensions += "edition"
    productFlavors {
        create("standard") {
            dimension = "edition"
        }
        create("adtest") {
            dimension = "edition"
            applicationIdSuffix = ".adtest"
            resValue("string", "app_name", "Potion Post")
            signingConfig = signingConfigs.create("adsTest") {
                storeFile = rootProject.file("../test-signing/potion-post-ads-test.jks")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    // Reuse the local test key so subsequent test APKs can update this app.
    val testKeystore = rootProject.file("../test-signing/potion-post-test.jks")
    signingConfigs.getByName("debug") {
        if (testKeystore.exists()) {
            storeFile = testKeystore
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            // Flavor signing is used for the separate demo-ads APK.
            signingConfig = null
        }
    }
}

// The recovered archive ended before the old test keystore. Never silently
// replace that key and produce an incompatible update for the original app.
if (gradle.startParameter.taskNames.any { it.contains("StandardRelease", ignoreCase = true) }) {
    val originalKey = rootProject.file("../test-signing/potion-post-test.jks")
    require(originalKey.exists()) { "Restore the original Potion Post test keystore before building a standard update." }
    android.productFlavors.getByName("standard").signingConfig = android.signingConfigs.getByName("debug")
}

flutter {
    source = "../.."
}
