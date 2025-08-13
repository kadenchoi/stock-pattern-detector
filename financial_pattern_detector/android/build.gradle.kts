allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://developer.huawei.com/repo/")
        }
        maven {
            url = uri("https://jitpack.io")
        }
        // Try GitHub packages for transistorsoft
        maven {
            url = uri("https://maven.pkg.github.com/transistorsoft/transistor-background-fetch")
        }
        // Alternative approach - use direct package manager
        flatDir {
            dirs("libs")
        }
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
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
