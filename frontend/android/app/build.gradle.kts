import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.friendapp.frontend"

    // 🔐 Keystore Properties - Hibrit Yapı (Lokal + CI/CD)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    
    // Lokal geliştirme için key.properties dosyasını yükle (varsa)
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    // ✅ SDK Ayarları
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // 🔐 Signing Configurations - Hem Lokal Hem CI/CD Destekli
    signingConfigs {
        create("release") {
            // Önce key.properties'den oku, yoksa environment variables kullan
            val alias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            
            // Null-safety check ve assignment
            if (alias != null && keyPass != null && storePass != null) {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = file(storeFilePath)
                storePassword = storePass
                
                println("🔐 Release signing configured successfully!")
                println("   Key Alias: $alias")
                println("   Store File: $storeFilePath")
            } else {
                println("⚠️  WARNING: Release signing config incomplete!")
                println("   Missing environment variables or key.properties")
                println("   KEY_ALIAS: ${if (alias != null) "✅" else "❌"}")
                println("   KEY_PASSWORD: ${if (keyPass != null) "✅" else "❌"}")
                println("   KEYSTORE_PASSWORD: ${if (storePass != null) "✅" else "❌"}")
            }
        }
    }

    defaultConfig {
        applicationId = "com.friendapp.frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 
        versionCode = 1
        versionName = "1.0"
        
        // MultiDex support
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        
        release {
            // ✅ PRODUCTION KEYSTORE ile imzala
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = true
            isShrinkResources = true
            
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