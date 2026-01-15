import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ═══════════════════════════════════════════════════════════════════════════
// FLUTTER VERSION - local.properties'den oku (pubspec.yaml'dan gelir)
// ═══════════════════════════════════════════════════════════════════════════
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"

println("════════════════════════════════════════════════════════")
println("📦 FLUTTER VERSION FROM local.properties")
println("════════════════════════════════════════════════════════")
println("   flutter.versionCode: $flutterVersionCode")
println("   flutter.versionName: $flutterVersionName")
println("════════════════════════════════════════════════════════")

// 🔍 DEBUG TASK
tasks.register("printSigningConfig") {
    doLast {
        println("════════════════════════════════════════════════════════")
        println("🔍 SIGNING CONFIGURATION DIAGNOSTICS")
        println("════════════════════════════════════════════════════════")
        
        println("📁 Directories:")
        println("   project.projectDir: ${project.projectDir.absolutePath}")
        println("   working dir: ${System.getProperty("user.dir")}")
        println()
        
        println("📦 Version Info:")
        println("   versionCode: $flutterVersionCode")
        println("   versionName: $flutterVersionName")
        println()
        
        println("🔍 Keystore search:")
        val keystoreFile = File(project.projectDir, "upload-keystore.jks")
        println("   Path: ${keystoreFile.absolutePath}")
        println("   Exists: ${keystoreFile.exists()}")
        if (keystoreFile.exists()) {
            println("   Size: ${keystoreFile.length()} bytes")
        }
        println()
        
        println("🔐 Environment Variables:")
        val pass = System.getenv("KEYSTORE_PASSWORD")
        val alias = System.getenv("KEY_ALIAS")
        val keyPass = System.getenv("KEY_PASSWORD")
        println("   KEYSTORE_PASSWORD: ${if (pass != null) "✅ SET (${pass.length} chars)" else "❌ NULL"}")
        println("   KEY_ALIAS: ${if (alias != null) "✅ SET ($alias)" else "❌ NULL"}")
        println("   KEY_PASSWORD: ${if (keyPass != null) "✅ SET (${keyPass.length} chars)" else "❌ NULL"}")
        
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

    // Lokal development için key.properties
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        println("✅ Loaded key.properties")
    }

    signingConfigs {
        create("release") {
            println("════════════════════════════════════════════════════════")
            println("🔐 Configuring Release Signing")
            println("════════════════════════════════════════════════════════")
            
            // Environment variables veya key.properties'den oku
            val alias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            
            // ❌ Null kontrolü - Eksik varsa DURDUR
            if (alias == null || keyPass == null || storePass == null) {
                val missing = buildList {
                    if (alias == null) add("KEY_ALIAS")
                    if (keyPass == null) add("KEY_PASSWORD")
                    if (storePass == null) add("KEYSTORE_PASSWORD")
                }
                
                throw GradleException("""
                    ════════════════════════════════════════════════════════
                    ❌ MISSING SIGNING CREDENTIALS!
                    ════════════════════════════════════════════════════════
                    Missing: ${missing.joinToString(", ")}
                    
                    GitHub Actions: Add these secrets to repository settings
                    Local build: Create key.properties in android/ folder
                    ════════════════════════════════════════════════════════
                """.trimIndent())
            }
            
            // Keystore dosyası - build.gradle.kts zaten app/ dizininde
            // Bu yüzden sadece filename yeterli
            val keystoreName = keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"
            val keystoreFile = file(keystoreName)
            
            println("📄 Keystore:")
            println("   Name: $keystoreName")
            println("   Path: ${keystoreFile.absolutePath}")
            println("   Exists: ${keystoreFile.exists()}")
            
            // ❌ Dosya yoksa DURDUR
            if (!keystoreFile.exists()) {
                throw GradleException("""
                    ════════════════════════════════════════════════════════
                    ❌ KEYSTORE FILE NOT FOUND!
                    ════════════════════════════════════════════════════════
                    Expected: ${keystoreFile.absolutePath}
                    
                    build.gradle.kts location: ${project.projectDir.absolutePath}
                    
                    GitHub Actions: Keystore should be at:
                      frontend/android/app/upload-keystore.jks
                    
                    Local build: Place keystore in android/app/ folder
                    ════════════════════════════════════════════════════════
                """.trimIndent())
            }
            
            // ❌ Dosya boş mu kontrol et
            if (keystoreFile.length() == 0L) {
                throw GradleException("❌ Keystore file is EMPTY (0 bytes): ${keystoreFile.absolutePath}")
            }
            
            // ✅ Tüm kontroller geçti - Config ayarla
            keyAlias = alias
            keyPassword = keyPass
            storeFile = keystoreFile
            storePassword = storePass
            
            println("✅ Signing configured!")
            println("   Alias: $alias")
            println("   File: ${keystoreFile.absolutePath}")
            println("   Size: ${keystoreFile.length()} bytes")
            println("════════════════════════════════════════════════════════")
        }
    }

    defaultConfig {
        applicationId = "com.friendapp.frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        
        // ✅ Flutter'dan gelen dinamik versiyon değerleri
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        
        multiDexEnabled = true
        
        println("📱 DefaultConfig:")
        println("   versionCode: $versionCode")
        println("   versionName: $versionName")
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