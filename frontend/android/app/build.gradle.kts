plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.friendapp.frontend"

    // ✅ GÜNCELLEME: SDK 35 daha stabil (36 çok yeni olabilir)
    compileSdk = 35

    // NDK version
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.friendapp.frontend"

        minSdk = flutter.minSdkVersion
        targetSdk = 34 

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
        
        // ✅ RELEASE BUILD TYPE - ProGuard AÇIK
        release {
            signingConfig = signingConfigs.getByName("debug")
            
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