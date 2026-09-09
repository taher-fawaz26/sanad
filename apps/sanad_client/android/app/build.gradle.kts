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

// The Maps key has two consumers and they read it from different places, so a
// build can satisfy one and silently starve the other:
//
//   1. the native Google Maps SDK — reads the MAPS_API_KEY manifest placeholder
//      set from local.properties in defaultConfig below (renders tiles/pin).
//   2. the Dart Maps REST calls — read the MAPS_API_KEY *dart-define* through
//      String.fromEnvironment in lib/src/di/app_di.dart. That is what resolves
//      a Google place_id for a picked request location and powers Places
//      autocomplete.
//
// Deriving the dart-define here makes local.properties the single source of
// truth for both, so a bare `flutter run` behaves like the melos build scripts.
// An explicit MAPS_API_KEY dart-define on the command line always wins.
// Mirrors apps/sanad_provider (SAN-823).
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
                "a request location can never be resolved to a place. " +
                "See docs/CONFIGURATION.md."
        )
    } else {
        val encoded = Base64.getEncoder()
            .encodeToString("MAPS_API_KEY=$mapsApiKey".toByteArray(Charsets.UTF_8))
        project.extra.set(
            "dart-defines",
            if (existing.isBlank()) encoded else "$existing,$encoded"
        )
    }
}

android {
    namespace = "com.sanad.client"
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
        applicationId = "com.sanad.client"
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
