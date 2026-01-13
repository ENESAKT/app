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
        println("🔍 SIGNING CONFIGURATION DEBUG INFO")
        println("════════════════════════════════════════════════════════")
        
        // Working directory
        println("📁 Current Working Directory:")
        println("   ${project.projectDir.absolutePath}")
        println()
        
        // Keystore dosya kontrolü - birden fazla olası yol
        val possiblePaths = listOf(
            File(project.projectDir, "upload-keystore.jks"),
            File(project.rootProject.projectDir, "app/upload-keystore.jks"),
            File(project.projectDir.parentFile, "upload-keystore.jks")
        )
        
        println("📄 Keystore File Search:")
        possiblePaths.forEachIndexed { index, file ->
            println("   ${index + 1}. ${file.absolutePath}")
            println("      Exists: ${if (file.exists()) "✅ YES (${file.length()} bytes)" else "❌ NO"}")
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
        println("⚠️  key.properties not found, using environment variables only")
    }

    // 🔐 Signing Configurations - DOSYA YOLU GARANTİLİ
    signingConfigs {
        create("release") {
            println("════════════════════════════════════════════════════════")
            println("🔐 Configuring Release Signing...")
            println("════════════════════════════════════════════════════════")
            
            // Environment variables'ı oku
            val alias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            
            // 🔥 KRİTİK: NULL KONTROLÜ
            val missingVars = mutableListOf<String>()
            if (alias == null) missingVars.add("KEY_ALIAS")
            if (keyPass == null) missingVars.add("KEY_PASSWORD") 
            if (storePass == null) missingVars.add("KEYSTORE_PASSWORD")
            
            if (missingVars.isNotEmpty()) {
                throw GradleException("""
                    ❌ Missing signing credentials: ${missingVars.joinToString(", ")}
                    
                    GitHub Actions: Add these secrets to repository settings
                    Local build: Create key.properties in android/ directory
                """.trimIndent())
            }
            
            // 🔥 DOSYA YOLU KONTROLÜ - Birden fazla olası yol dene
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
            
            // Dosyayı bulmak için farklı yolları kontrol et
            val keystoreFile = when {
                // 1. Önce mevcut dizinde (app/) ara
                File(project.projectDir, storeFilePath).exists() -> {
                    File(project.projectDir, storeFilePath)
                }
                // 2. Rootproject/app/ dizininde ara
                File(project.rootProject.projectDir, "app/$storeFilePath").exists() -> {
                    File(project.rootProject.projectDir, "app/$storeFilePath")
                }
                // 3. Parent directory'de ara
                File(project.projectDir.parentFile, storeFilePath).exists() -> {
                    File(project.projectDir.parentFile, storeFilePath)
                }
                // 4. Hiçbir yerde bulunamadı - default path kullan ama hata verecek
                else -> File(project.projectDir, storeFilePath)
            }
            
            println("📁 Project Directory: ${project.projectDir.absolutePath}")
            println("🔍 Looking for keystore: $storeFilePath")
            println("📄 Keystore Path: ${keystoreFile.absolutePath}")
            println("✅ File Exists: ${keystoreFile.exists()}")
            
            // Dosya bulunamadıysa detaylı hata ver
            if (!keystoreFile.exists()) {
                val searchedPaths = listOf(
                    "${project.projectDir}/$storeFilePath",
                    "${project.rootProject.projectDir}/app/$storeFilePath",
                    "${project.projectDir.parentFile}/$storeFilePath"
                )
                
                throw GradleException("""
                    ❌ KEYSTORE FILE NOT FOUND!
                    
                    Expected filename: $storeFilePath
                    Current directory: ${project.projectDir.absolutePath}
                    
                    Searched locations:
                    ${searchedPaths.joinToString("\n") { "  - $it" }}
                    
                    GitHub Actions: Verify keystore decode step creates the file in android/app/
                    Local build: Place upload-keystore.jks in android/app/ directory
                """.trimIndent())
            }
            
            // Dosya boyutu kontrolü
            if (keystoreFile.length() == 0L) {
                throw GradleException("❌ Keystore file is EMPTY! (0 bytes)")
            }
            
            // ✅ Tüm kontroller geçti, signing config ayarla
            keyAlias = alias!!
            keyPassword = keyPass!!
            storeFile = keystoreFile
            storePassword = storePass!!
            
            println("✅ Key Alias: $alias")
            println("✅ Store File: ${keystoreFile.absolutePath}")
            println("✅ File Size: ${keystoreFile.length()} bytes")
            println("✅ Signing configuration complete!")
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