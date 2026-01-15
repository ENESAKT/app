// ═══════════════════════════════════════════════════════════════════════════
// ROOT BUILD.GRADLE.KTS (Project Level)
// ═══════════════════════════════════════════════════════════════════════════

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP ve Kotlin versiyonları (Bunlar senin projenle uyumlu olmalı)
        // Eğer hata alırsan versiyonları settings.gradle veya libs.versions.toml'dan kontrol et
        classpath("com.android.tools.build:gradle:8.2.1") 
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
classpath 'com.google.gms:google-services:4.4.1'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build dizini ayarları (Flutter standart yapısı)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 namespace HATASI DÜZELTİCİ (3. Parti Eklentiler İçin)
// AGP 8.0+ artık her modülün bir namespace'i olmasını zorunlu kılar.
// Eski paketler (r_upgrade vb.) bunu yapmadığı için build patlar.
// Bu kod, onlara otomatik geçici bir namespace atar.
// ═══════════════════════════════════════════════════════════════════════════
subprojects {
    afterEvaluate {
        // Android Library (Plugin) olup olmadığına bak
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            
            if (android != null && android.namespace == null) {
                // Güvenli namespace oluşturma mantığı
                var autoNamespace = project.group.toString()
                
                // Eğer grup adı yoksa veya "unspecified" ise, proje adından üret
                if (autoNamespace.isEmpty() || autoNamespace == "unspecified") {
                    autoNamespace = "com.example.${project.name.replace("-", "_").replace(".", "_")}"
                }
                
                println("⚠️ Namespace eklendi (${project.name}):