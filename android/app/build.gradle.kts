import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val secrets = Properties().apply {
        val secretsFile = rootProject.file("secrets.properties")
        if (secretsFile.exists()) {
            secretsFile.inputStream().use { load(it) }
        }
        val localPropsFile = rootProject.file("local.properties")
        if (localPropsFile.exists()) {
            localPropsFile.inputStream().use { load(it) }
        }
    }

    val googleMapsApiKey =
        (secrets.getProperty("GOOGLE_MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() })
            ?: (secrets.getProperty("MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() })
            ?: (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)?.trim()?.takeIf { it.isNotEmpty() }
            ?: (project.findProperty("MAPS_API_KEY") as String?)?.trim()?.takeIf { it.isNotEmpty() }
            ?: System.getenv("GOOGLE_MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() }
            ?: System.getenv("MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() }

    namespace = "com.example.draaxi_driver"
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
        applicationId = "com.example.draaxi_driver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "google_maps_key", googleMapsApiKey ?: "")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
