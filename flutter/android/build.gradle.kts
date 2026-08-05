allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force google_sign_in_android ke versi lama agar kompatibel dengan firebase_auth ^4.x
    configurations.all {
        resolutionStrategy {
            force("io.flutter.plugins.googlesignin:google_sign_in_android:6.1.30")
        }
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
