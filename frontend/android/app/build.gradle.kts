// Build tetikleme denemesi

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.friendapp.frontend"

    // 🔐 Keystore Properties (GitHub Secrets veya lokal key.properties)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }

    // ✅ GÜNCELLEME: SDK 36 (Plugins require this)
    compileSdk = 36

    // NDK version
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // 🔐 Signing Configurations
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
        }
    }

    defaultConfig {
        applicationId = "com.friendapp.frontend"

        minSdk = flutter.minSdkVersion
        targetSdk = 36 

        versionCode = 1
        versionName = "1.0"
        
        // ✅ MultiDex support (Supabase + Firebase = many methods)
        multiDexEnabled = true
    }

    buildTypes {
        // ✅ DEBUG BUILD TYPE - ProGuard KAPALI
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
            
            // Debug için signing (development)
            signingConfig = signingConfigs.getByName("debug")
        }
        
        // ✅ RELEASE BUILD TYPE - ProGuard AÇIK + Release Keystore
        release {
            // ✅ PRODUCTION KEYSTORE ile imzala
            signingConfig = signingConfigs.getByName("release")
            
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            
            // ProGuard rules to protect Supabase, Firebase, and Flutter
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}