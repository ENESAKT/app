// android/build.gradle.kts (Root - Kotlin DSL)

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build directory ayarı (Kotlin DSL)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get().asFile}/${project.name}"))
}

// Clean task (Kotlin DSL)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Namespace Fixer (Gradle Lifecycle Safe Version)
subprojects {
    plugins.withId("com.android.library") {
        val extension = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (extension != null && extension.namespace == null) {
            val safeName = project.name.replace("-", "_").replace(".", "_")
            extension.namespace = "com.example.fixed.$safeName"
        }
    }
}