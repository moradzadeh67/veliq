import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties when it exists. That file is
// git-ignored and must never be committed; without it the release build falls
// back to the debug signing config so a fresh clone still builds.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.moradzadeh67.veliq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.moradzadeh67.veliq"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Signed with the upload key when android/key.properties is present,
            // otherwise with the debug key so `flutter build apk --release` still works.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // ML Kit is loaded reflectively and needs to survive R8 (full mode is
            // the AGP 8+ default), otherwise the release APK crashes on launch
            // while MainActivity creates the OCR recognizer. Rules live in
            // proguard-rules.pro.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
    // Bundled (on-device) Latin OCR for Android (T-136, D-016). "Bundled" means
    // the model ships inside the APK (~4MB per ABI) and runs offline; the
    // alternative play-services variant downloads the model at first run.
    implementation("com.google.mlkit:text-recognition:16.0.1")

    // Tesseract (T-163) reads the scripts ML Kit does not ship: Persian/Arabic,
    // Cyrillic, CJK. The traineddata files are bundled as assets, so it runs
    // offline like ML Kit and never uploads the image.
    implementation("com.github.adaptech-cz:tesseract4android:4.9.0") {
        // JitPack's POM pulls the OpenMP variant as well, which duplicates every
        // class and native library. One engine is enough.
        exclude(
            group = "com.github.adaptech-cz.tesseract4android",
            module = "tesseract4android-openmp",
        )
    }

    testImplementation("junit:junit:4.13.2")
}
