import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) releasePropertiesFile.inputStream().use { releaseProperties.load(it) }

android {
    buildFeatures { resValues = true }
    namespace = "com.alternatereality.alternate_reality"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.alternatereality.alternate_reality"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "distribution"
    productFlavors {
        create("preview") {
            dimension = "distribution"
            applicationIdSuffix = ".preview"
            versionNameSuffix = "-preview"
            resValue("string", "app_name", "Alternate Reality Preview")
        }
        create("production") {
            dimension = "distribution"
            resValue("string", "app_name", "Alternate Reality")
        }
    }
    signingConfigs {
        create("release") {
            if (releasePropertiesFile.exists()) {
                storeFile = rootProject.file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

gradle.taskGraph.whenReady {
    val ambiguousTasks = setOf("assemble", "build", "assembleDebug", "assembleProfile", "assembleRelease", "bundle", "bundleDebug", "bundleRelease", "installDebug", "installRelease")
    if (gradle.startParameter.taskNames.any { it.substringAfterLast(":") in ambiguousTasks }) {
        throw GradleException("Choose an app flavor: use the Alternate Reality - Preview run configuration, or flutter run --flavor preview. For the original app ID, use --flavor production. See docs/ANDROID_STUDIO.md.")
    }

    if (allTasks.any { it.name.contains("Release", ignoreCase = true) } && !releasePropertiesFile.exists()) {
        throw GradleException("Release signing is missing. Create android/key.properties using docs/RELEASE.md. Debug signing is never used for releases.")
    }
}
