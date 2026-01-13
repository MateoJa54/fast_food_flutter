buildscript {
    // 1. IMPORTANTE: Debes agregar los repositorios AQUÍ también para que
    // pueda descargar el plugin de google-services.
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Esta línea es necesaria para que Flutter funcione correctamente con Android
        // (Asegúrate de que la versión coincida con la que requiere tu Flutter SDK, usualmente 7.x o 8.x)
        // Si ya tienes esto configurado en settings.gradle, puedes omitirlo, pero es común tenerlo aquí:
        classpath("com.android.tools.build:gradle:8.1.0") 
        
        // Tu plugin de Google Services (Firebase)
        classpath("com.google.gms:google-services:4.4.2")
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