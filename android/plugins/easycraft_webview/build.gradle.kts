// The same Android Gradle plugin and Kotlin versions as Godot 4.7.2's Gradle build template
// (android_source.zip, config.gradle), so the game's Gradle export reuses the downloaded tools.
plugins {
    id("com.android.library") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.21" apply false
}
