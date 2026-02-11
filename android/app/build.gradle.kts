import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.quietcheck.app"
    compileSdk = 36


    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.quietcheck.app"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }



    // Build flavors for debug/staging/release (TEMPORARILY COMMENTED OUT)
    // flavorDimensions += "environment"
    // productFlavors {
    //     create("dev") {
    //         dimension = "environment"
    //         applicationIdSuffix = ".dev"
    //         versionNameSuffix = "-dev"
    //         resValue("string", "app_name", "QuietCheck Dev")
    //         buildConfigField("boolean", "ENABLE_DEBUG_FEATURES", "true")
    //         buildConfigField("boolean", "ENABLE_CRASH_DIAGNOSTICS", "true")
    //     }
    //     create("staging") {
    //         dimension = "environment"
    //         applicationIdSuffix = ".staging"
    //         versionNameSuffix = "-staging"
    //         resValue("string", "app_name", "QuietCheck Staging")
    //         buildConfigField("boolean", "ENABLE_DEBUG_FEATURES", "true")
    //         buildConfigField("boolean", "ENABLE_CRASH_DIAGNOSTICS", "true")
    //     }
    //     create("prod") {
    //         dimension = "environment"
    //         resValue("string", "app_name", "QuietCheck")
    //         buildConfigField("boolean", "ENABLE_DEBUG_FEATURES", "false")
    //         buildConfigField("boolean", "ENABLE_CRASH_DIAGNOSTICS", "false")
    //     }
    // }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
        release {
            ndk {
                debugSymbolLevel = "FULL"
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

// Stronger hack to disable strip task
tasks.all {
    if (name.contains("strip")) {
        enabled = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.concurrent:concurrent-futures:1.2.0")
    // WorkManager for background tasks (BootCompletedReceiver/DataCollectionWorker)
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
