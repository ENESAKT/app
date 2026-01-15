plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Plugin'i
    id("dev.flutter.flutter-gradle-plugin")
    // 👇 FIREBASE İÇİN GEREKLİ OLAN KISIM BURASI
    id("com.google.gms.google-services")
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace = "com.enes.vibe"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId = "com.enes.vibe"
        
        // 🔥 TABLET HATASINI ÇÖZEN AYAR (21 yaptık)
        minSdk = 21
        
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
    }

    // İMZALAMA AYARLARI (GitHub Actions ve Release için)
    signingConfigs {
        release {
            // Eğer GitHub Secret'larında tanımlıysa oradan alır, yoksa hata vermez
            def keystoreFile = file("upload-keystore.jks")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // İmza ayarlarını uygula (dosya varsa)
            signingConfig = signingConfigs.release
            
            // Kod sıkıştırma (APK boyutunu küçültür)
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