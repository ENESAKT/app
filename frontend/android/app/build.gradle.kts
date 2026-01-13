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

    // 🔐 Keystore Properties - Hibrit Yapı (Lokal + CI/CD)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    
    // Lokal geliştirme için key.properties dosyasını yükle (varsa)
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    // 🔐 Signing Configurations - ZORUNLU KONTROLLER ile
    signingConfigs {
        create("release") {
            // Environment variables'ı oku
            val alias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            
            // 🔥 KRİTİK: NULL KONTROLÜ - Eksik varsa BUILD'İ DURDUR
            val missingVars = mutableListOf<String>()
            if (alias == null) missingVars.add("KEY_ALIAS")
            if (keyPass == null) missingVars.add("KEY_PASSWORD") 
            if (storePass == null) missingVars.add("KEYSTORE_PASSWORD")
            
            if (missingVars.isNotEmpty()) {
                val errorMsg = """
                    
                    ════════════════════════════════════════════════════════
                    ❌ RELEASE SIGNING CONFIG ERROR!
                    ════════════════════════════════════════════════════════
                    Missing required environment variables or key.properties:
                    ${missingVars.joinToString("\n") { "  - $it ❌" }}
                    
                    To fix this:
                    1. GitHub Actions: Add secrets to repository settings
                    2. Local build: Create key.properties file in android/
                    
                    Current status:
                      KEY_ALIAS: ${if (alias != null) "✅ SET" else "❌ MISSING"}
                      KEY_PASSWORD: ${if (keyPass != null) "✅ SET" else "❌ MISSING"}
                      KEYSTORE_PASSWORD: ${if (storePass != null) "✅ SET" else "❌ MISSING"}
                      Store File: $storeFilePath
                    ════════════════════════════════════════════════════════
                    
                """.trimIndent()
                
                throw GradleException(errorMsg)
            }
            
            // Tüm değerler mevcut, signing config'i ayarla
            keyAlias = alias!!
            keyPassword = keyPass!!
            storeFile = file(storeFilePath)
            storePassword = storePass!!
            
            println("════════════════════════════════════════════════════════")
            println("🔐 Release Signing Config: SUCCESS")
            println("════════════════════════════════════════════════════════")
            println("  Key Alias: $alias")
            println("  Store File: $storeFilePath")
            println("  All environment variables loaded correctly ✅")
            println("════════════════════════════════════════════════════════")
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