plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Let Mapbox plugin handle its own repository configuration
    }
}

// Use standard build directory for Flutter compatibility

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}