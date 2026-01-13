import java.util.Properties
import java.io.FileInputStream
import java.io.File

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
        println("🔍 SIGNING CONFIGURATION DIAGNOSTICS")
        println("════════════════════════════════════════════════════════")
        
        println("📁 Project Directories:")
        println("   project.projectDir: ${project.projectDir.absolutePath}")
        println("   project.rootProject.projectDir: ${project.rootProject.projectDir.absolutePath}")
        println("   System user.dir: ${System.getProperty("user.dir")}")
        println()
        
        // Keystore arama
        val keystoreName = "upload-keystore.jks"
        println("🔍 Searching for: $keystoreName")
        
        val searchPaths = listOf(
            File(project.projectDir, keystoreName),
            File(project.rootProject.projectDir, "app/$keystoreName"),
            File("${project.rootProject.projectDir}/app", keystoreName)
        )
        
        searchPaths.forEachIndexed { index, file ->
            println("   ${index + 1}. ${file.absolutePath}")
            println("      Exists: ${if (file.exists()) "✅ YES (${file.length()} bytes)" else "❌ NO"}")
        }
        println()
        
        // Environment variables
        println("🔐 Environment Variables:")
        val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
        val keyAlias = System.getenv("KEY_ALIAS")
        val keyPassword = System.getenv("KEY_PASSWORD")
        
        println("   KEYSTORE_PASSWORD: ${if (keystorePassword != null) "✅ SET (${keystorePassword.length} chars)" else "❌ NULL"}")
        println("   KEY_ALIAS: ${if (keyAlias != null) "✅ SET ($keyAlias)" else "❌ NULL"}")
        println("   KEY_PASSWORD: ${if (keyPassword != null) "✅ SET (${keyPassword.length} chars)" else "❌ NULL"}")
        
        println("════════════════════════════════════════════════════════")
    }
}

android {
    namespace = "com.friendapp.frontend"

    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Keystore Properties (Lokal development için)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        println("✅ Loaded key.properties from: ${keystorePropertiesFile.absolutePath}")
    }

    signingConfigs {
        create("release") {
            println("════════════════════════════════════════════════════════")
            println("🔐 Configuring Release Signing")
            println("════════════════════════════════════════════════════════")
            
            // Credentials
            val alias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            
            // ❌ Credentials kontrolü
            if (alias == null || keyPass == null || storePass == null) {
                val missing = mutableListOf<String>()
                if (alias == null) missing.add("KEY_ALIAS")
                if (keyPass == null) missing.add("KEY_PASSWORD")
                if (storePass == null) missing.add("KEYSTORE_PASSWORD")
                
                throw GradleException("""
                    ════════════════════════════════════════════════════════
                    ❌ MISSING SIGNING CREDENTIALS!
                    ════════════════════════════════════════════════════════
                    Missing: ${missing.joinToString(", ")}
                    
                    GitHub Actions: Add secrets to repository settings
                    Local build: Create key.properties in android/ folder
                    ════════════════════════════════════════════════════════
                """.trimIndent())
            }
            
            // 🔍 Keystore dosyası arama - PROJE YAPISINA UYGUN
            // Proje yapısı: root/frontend/android/app
            // gradlew frontend/android dizininde çalışıyor
            // Bu dosya (build.gradle.kts) android/app dizininde
            
            val keystoreName = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
            
            // GitHub Actions: keystore app/ dizininde oluşturulmuş olmalı
            val keystoreFile = File(project.projectDir, keystoreName)
            
            println("📁 Looking for keystore:")
            println("   Name: $keystoreName")
            println("   Expected path: ${keystoreFile.absolutePath}")
            println("   File exists: ${keystoreFile.exists()}")
            
            if (!keystoreFile.exists()) {
                // Alternatif yolları da kontrol et
                val alternativePath1 = File(project.rootProject.projectDir, "app/$keystoreName")
                val alternativePath2 = File("${project.rootProject.projectDir.absolutePath}/app", keystoreName)
                
                println("   Alternative 1: ${alternativePath1.absolutePath} - ${alternativePath1.exists()}")
                println("   Alternative 2: ${alternativePath2.absolutePath} - ${alternativePath2.exists()}")
                
                throw GradleException("""
                    ════════════════════════════════════════════════════════
                    ❌ KEYSTORE FILE NOT FOUND!
                    ════════════════════════════════════════════════════════
                    Expected: ${keystoreFile.absolutePath}
                    
                    Searched locations:
                      1. ${keystoreFile.absolutePath}
                      2. ${alternativePath1.absolutePath}
                      3. ${alternativePath2.absolutePath}
                    
                    Project structure:
                      - project.projectDir: ${project.projectDir.absolutePath}
                      - rootProject.projectDir: ${project.rootProject.projectDir.absolutePath}
                    
                    GitHub Actions: Verify keystore decode creates file at:
                      frontend/android/app/upload-keystore.jks
                    
                    Local build: Place keystore in android/app/ folder
                    ════════════════════════════════════════════════════════
                """.trimIndent())
            }
            
            // Dosya boyutu kontrolü
            if (keystoreFile.length() == 0L) {
                throw GradleException("❌ Keystore file is EMPTY (0 bytes): ${keystoreFile.absolutePath}")
            }
            
            // ✅ Tüm kontroller geçti - Signing config ayarla
            keyAlias = alias
            keyPassword = keyPass
            storeFile = keystoreFile
            storePassword = storePass
            
            println("✅ Signing configured successfully!")
            println("   Alias: $alias")
            println("   Store: ${keystoreFile.absolutePath}")
            println("   Size: ${keystoreFile.length()} bytes")
            println("════════════════════════════════════════════════════════")
        }
    }

    defaultConfig {
        applicationId = "com.friendapp.frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        
        release {
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