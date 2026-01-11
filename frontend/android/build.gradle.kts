allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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

// Kotlin DSL: Fix namespace for third-party plugins (r_upgrade, etc.)
subprojects {
    plugins.withId("com.android.library") {
        val extension = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (extension != null && extension.namespace == null) {
            extension.namespace = project.group.toString()
        }
    }
}
