// Top-level Gradle configuration for the Flutter Android app

import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for Flutter multi-module layout
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val subBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(subBuildDir)
}

// Required for some plugins such as WorkManager
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
