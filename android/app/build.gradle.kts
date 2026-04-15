plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.changaya"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications para usar APIs Java 8+ en SDKs antiguos.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID registrado en Firebase project changaya-dev.
        // NO cambiar sin actualizar google-services.json y re-registrar
        // en Firebase Console (el SHA-1 fingerprint esta asociado al par
        // applicationId + keystore).
        //
        // NOTA: el namespace Kotlin interno ("com.example.changaya" arriba)
        // puede diferir del applicationId — son conceptos independientes en
        // Android Gradle Plugin. El namespace afecta solo al paquete Java/Kotlin,
        // el applicationId es el ID publico de la app en Play Store y el que
        // Firebase/Google Services matchean.
        applicationId = "com.changaya.app"
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

flutter {
    source = "../.."
}

dependencies {
    // Soporte para APIs Java 8+ requerido por flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
