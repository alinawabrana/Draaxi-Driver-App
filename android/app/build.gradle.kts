import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Load secrets: project-root `.env` first, then android/secrets.properties, then local.properties.
    // Later files override earlier ones for the same key.
    val secrets = Properties().apply {
        fun loadIfExists(file: java.io.File) {
            if (!file.exists()) return
            file.inputStream().use { stream ->
                stream.bufferedReader().useLines { lines ->
                    lines.forEach { raw ->
                        val line = raw.trim()
                        if (line.isEmpty() || line.startsWith("#")) return@forEach
                        val idx = line.indexOf('=')
                        if (idx <= 0) return@forEach
                        val key = line.substring(0, idx).trim()
                        var value = line.substring(idx + 1).trim()
                        if ((value.startsWith("\"") && value.endsWith("\"")) ||
                            (value.startsWith("'") && value.endsWith("'"))
                        ) {
                            value = value.substring(1, value.length - 1)
                        }
                        setProperty(key, value)
                    }
                }
            }
        }

        // android/ -> project root
        loadIfExists(rootProject.file("../.env"))
        loadIfExists(rootProject.file("secrets.properties"))
        loadIfExists(rootProject.file("local.properties"))
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
