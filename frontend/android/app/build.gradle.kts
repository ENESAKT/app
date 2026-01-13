import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 🔍 DEBUG TASK - Signing Configuration Diagnostics
tasks.register("printSigningConfig") {
    doLast {
        println("════════════════════════════════════════════════════════")
        println("🔍 SIGNING CONFIGURATION DEBUG INFO")
        println("════════════════════════════════════════════════════════")
        
        // Keystore dosya kontrolü
        val keystoreFile = file("upload-keystore.jks")
        val absolutePath = keystoreFile.absolutePath
        val exists = keystoreFile.exists()
        val fileSize = if (exists) keystoreFile.length() else 0
        
        println("📄 Keystore File:")
        println("   Path: $absolutePath")
        println("   Exists: ${if (exists) "✅ YES" else "❌ NO"}")
        if (exists) {
            println("   Size: $fileSize bytes")
        }
        println()
        
        // Environment variables kontrolü
        val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
        val keyAlias = System.getenv("KEY_ALIAS")
        val keyPassword = System.getenv("KEY_PASSWORD")
        
        println("🔐 Environment Variables:")
        println("   KEYSTORE_PASSWORD: ${if (keystorePassword != null) "✅ LOADED (${keystorePassword.length} chars)" else "❌ NULL"}")
        println("   KEY_ALIAS: ${if (keyAlias != null) "✅ LOADED ($keyAlias)" else "❌ NULL"}")
        println("   KEY_PASSWORD: ${if (keyPassword != null) "✅ LOADED (${keyPassword.length} chars)" else "❌ NULL"}")
        println()
        
        // key.properties kontrolü
        val keyPropertiesFile = rootProject.file("key.properties")
        println("📋 key.properties File:")
        println("   Path: ${keyPropertiesFile.absolutePath}")
        println("   Exists: ${if (keyPropertiesFile.exists()) "✅ YES" else "❌ NO"}")
        println()
        
        // Working directory
        println("📁 Working Directory:")
        println("   ${System.getProperty("user.dir")}")
        println()
        
        println("════════════════════════════════════════════════════════")
    }
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
        println("✅ key.properties loaded from: ${keystorePropertiesFile.absolutePath}")
    } else {
        println("⚠️  key.properties not found, using environment variables")
    }

    // 🔐 Signing Configurations - ZORUNLU KONTROLLER ile
    signingConfigs {
        create("release") {
            // Environment variables'ı oku
            val alias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            
            println("════════════════════════════════════════════════════════")
            println("🔐 Configuring Release Signing...")
            println("════════════════════════════════════════════════════════")
            
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
                    1. GitHub Actions: Verify secrets are added to repository
                       Repository → Settings → Secrets and variables → Actions
                    2. Local build: Create key.properties file in android/
                    
                    Current status:
                      KEY_ALIAS: ${if (alias != null) "✅ SET" else "❌ MISSING"}
                      KEY_PASSWORD: ${if (keyPass != null) "✅ SET (${keyPass.length} chars)" else "❌ MISSING"}
                      KEYSTORE_PASSWORD: ${if (storePass != null) "✅ SET (${storePass.length} chars)" else "❌ MISSING"}
                      Store File: $storeFilePath
                      
                    Environment Check:
                      KEYSTORE_PASSWORD env: ${System.getenv("KEYSTORE_PASSWORD") ?: "NULL"}
                      KEY_ALIAS env: ${System.getenv("KEY_ALIAS") ?: "NULL"}
                      KEY_PASSWORD env: ${System.getenv("KEY_PASSWORD") ?: "NULL"}
                    ════════════════════════════════════════════════════════
                    
                """.trimIndent()
                
                throw GradleException(errorMsg)
            }
            
            // Keystore dosyasının tam yolu (app klasöründe)
            val keystoreFile = file(storeFilePath)
            
            // Dosya varlık kontrolü
            if (!keystoreFile.exists()) {
                val errorMsg = """
                    
                    ════════════════════════════════════════════════════════
                    ❌ KEYSTORE FILE NOT FOUND!
                    ════════════════════════════════════════════════════════
                    Expected location: ${keystoreFile.absolutePath}
                    File exists: ${keystoreFile.exists()}
                    
                    Working directory: ${System.getProperty("user.dir")}
                    
                    To fix this:
                    1. GitHub Actions: Check keystore decode step
                    2. Verify upload-keystore.jks is created in android/app/
                    ════════════════════════════════════════════════════════
                    
                """.trimIndent()
                
                throw GradleException(errorMsg)
            }
            
            // Tüm değerler mevcut, signing config'i ayarla
            keyAlias = alias!!
            keyPassword = keyPass!!
            storeFile = keystoreFile
            storePassword = storePass!!
            
            println("✅ Key Alias: $alias")
            println("✅ Store File: ${keystoreFile.absolutePath}")
            println("✅ File Size: ${keystoreFile.length()} bytes")
            println("✅ All credentials loaded successfully")
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