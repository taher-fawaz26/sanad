import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties for release signing (optional — only if file exists)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// Load Google Maps API key from local.properties (gitignored — never commit keys)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

// SAN-823: the Maps key has TWO consumers, and they used to read it from two
// different places, so a build could satisfy one and silently starve the other:
//
//   1. the native Google Maps SDK — reads the MAPS_API_KEY manifest placeholder
//      set from local.properties in defaultConfig below (renders tiles/pin).
//   2. the Dart Maps REST calls — read the MAPS_API_KEY *dart-define* via
//      String.fromEnvironment in lib/src/di/app_di.dart. This is what obtains
//      the Google place_id for a picked branch location, and what powers Places
//      autocomplete.
//
// Only `.vscode/launch.json` and the `build:provider:*` melos scripts pass that
// dart-define. A bare `flutter build apk --release` passes neither, producing an
// APK where the map renders and the pin still reverse-geocodes (via the keyless
// native Android Geocoder) but no place_id can EVER be resolved — leaving Branch
// Location permanently unconfirmable and Places search silently inert.
//
// Deriving the dart-define here makes local.properties the single source of
// truth for both consumers, so every build command and build type behaves the
// same. A MAPS_API_KEY dart-define passed on the command line always wins, so
// the melos scripts and the CI workflow are unaffected.
run {
    val mapsApiKey = localProperties.getProperty("MAPS_API_KEY", "")
    val existing = project.findProperty("dart-defines")?.toString().orEmpty()
    val alreadyProvided = existing
        .split(",")
        .filter { it.isNotBlank() }
        .any {
            runCatching {
                String(Base64.getDecoder().decode(it), Charsets.UTF_8)
            }.getOrDefault("").startsWith("MAPS_API_KEY=")
        }

    if (alreadyProvided) {
        // Explicit --dart-define(-from-file) on the command line: leave it be.
    } else if (mapsApiKey.isBlank()) {
        logger.warn(
            "WARNING: MAPS_API_KEY is not set in android/local.properties and no " +
                "MAPS_API_KEY dart-define was passed. The map will render blank and " +
                "a branch location can never be confirmed (no Google place_id). " +
                "See docs/CONFIGURATION.md."
        )
    } else {
        val encoded = Base64.getEncoder()
            .encodeToString("MAPS_API_KEY=$mapsApiKey".toByteArray(Charsets.UTF_8))
        // -P properties land in the project's extra properties, so setting the
        // key here overrides/extends what the Flutter tool passed. Read back by
        // the Flutter Gradle plugin in afterEvaluate, i.e. after this script.
        project.extra.set(
            "dart-defines",
            if (existing.isBlank()) encoded else "$existing,$encoded"
        )
    }
}

android {
    namespace = "com.sanad.provider"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // `flutter_local_notifications` (which draws the foreground push
        // banner the OS suppresses) uses java.time, so its build fails outright
        // without desugaring on the minSdk this app targets.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.sanad.provider"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] =
            localProperties.getProperty("MAPS_API_KEY", "")
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// `document_camera_frame` still pulls the legacy `firebase-iid` artifact
// transitively. Its classes (notably FirebaseInstanceIdReceiver) were folded
// into `firebase-messaging` 22+, so having both on the classpath fails the
// build with a duplicate-class error the moment firebase_messaging is added.
// Excluding the legacy module is the documented resolution — nothing needs it.
configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}

dependencies {
    // Required by the AppCompat launch/normal themes (see res/values/styles.xml).
    // `local_auth` hosts BiometricPrompt in a FragmentActivity, and on API 24-27
    // androidx.biometric falls back to an AppCompat AlertDialog, which resolves
    // only under a Theme.AppCompat descendant. androidx.biometric pulls appcompat
    // in transitively; it is declared here explicitly so the theme's requirement
    // is not silently dependent on a transitive dependency.
    implementation("androidx.appcompat:appcompat:1.7.0")

    // Backports java.time and friends for `isCoreLibraryDesugaringEnabled`
    // above. Required by flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
