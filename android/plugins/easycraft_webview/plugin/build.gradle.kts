plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val pluginName = "EasyCraftWebView"
val pluginPackageName = "com.giorgi.easycraft.webview"
// Where Godot's export plugin (addons/easycraft_webview/plugin.gd) picks the libraries up.
val addonBin = rootDir.resolve("../../../addons/easycraft_webview/bin")

android {
    namespace = pluginPackageName
    compileSdk = 35
    buildToolsVersion = "35.0.0"

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = pluginName
        manifestPlaceholders["godotPluginPackageName"] = pluginPackageName
        buildConfigField("String", "GODOT_PLUGIN_NAME", "\"$pluginName\"")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // The game's APK already contains the Godot library; the plugin only compiles against it.
    compileOnly("org.godotengine:godot:4.7.2.stable")
}

// ./gradlew assemble builds both AARs and copies them into the Godot addon.
val copyDebugAar by tasks.registering(Copy::class) {
    from(layout.buildDirectory.dir("outputs/aar"))
    include("plugin-debug.aar")
    rename { "$pluginName-debug.aar" }
    into(addonBin.resolve("debug"))
}
val copyReleaseAar by tasks.registering(Copy::class) {
    from(layout.buildDirectory.dir("outputs/aar"))
    include("plugin-release.aar")
    rename { "$pluginName-release.aar" }
    into(addonBin.resolve("release"))
}
tasks.named("assemble").configure {
    finalizedBy(copyDebugAar, copyReleaseAar)
}
