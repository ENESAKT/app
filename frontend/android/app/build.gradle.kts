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

// 🔍 DEBUG TASK (Build sırasında imza yapılandırmasını kontrol eder)
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
        println("   KEY_ALIAS