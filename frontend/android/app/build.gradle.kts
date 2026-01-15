// ═══════════════════════════════════════════════════════════════════════════
// ROOT BUILD.GRADLE.KTS (Project Level)
// ═══════════════════════════════════════════════════════════════════════════

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Senin projenin uyumlu olduğu versiyonlar
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

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
// NAMESPACE HATASI DÜZELTİCİ (Sadeleştirilmiş Versiyon)
// Bu kod, eski paketlerin (r_upgrade vb.) build hatası vermesini engeller.
// ═══════════════════════════════════════════════════════════════════════════
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            
            if (android != null && android.namespace == null) {
                // Hata veren paketlere otomatik isim ata
                val safeName = project.name.replace("-", "_").replace(".", "_")
                android.namespace = "com.example.fixed.$safeName"
            }
        }
    }
}