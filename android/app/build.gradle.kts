import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Fail-closed Play upload signing. Copy android/key.properties.example →
// android/key.properties on Mohammed's machine. Release never falls back to
// debug unless the local escape hatch is set:
//   -PallowDebugReleaseSigning=true
// Store / Play scripts (tool/release.sh) must never pass that property.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val allowDebugReleaseSigning =
    (findProperty("allowDebugReleaseSigning") as String?)
        ?.equals("true", ignoreCase = true) == true

val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

fun keystorePropertyOrEmpty(name: String): String =
    keystoreProperties.getProperty(name)?.trim().orEmpty()

fun resolveStoreFile(path: String): java.io.File {
    val given = java.io.File(path)
    if (given.isAbsolute) return given
    val fromAndroid = rootProject.file(path)
    if (fromAndroid.isFile) return fromAndroid
    return file(path)
}

fun releaseSigningProblem(): String? {
    val hint =
        "Copy android/key.properties.example to android/key.properties and " +
            "set storeFile, storePassword, keyAlias, and keyPassword. " +
            "See STORE.md Signing. " +
            "Local flutter run --release only: -PallowDebugReleaseSigning=true"

    if (!keystorePropertiesFile.exists()) {
        return "android/key.properties is missing. $hint"
    }

    val missing = requiredSigningKeys.filter { keystorePropertyOrEmpty(it).isEmpty() }
    if (missing.isNotEmpty()) {
        return "android/key.properties has empty required keys: " +
            "${missing.joinToString(", ")}. $hint"
    }

    val store = resolveStoreFile(keystorePropertyOrEmpty("storeFile"))
    if (!store.isFile) {
        return "android/key.properties storeFile does not exist: ${store.path}. $hint"
    }
    return null
}

val releaseSigningError = releaseSigningProblem()
val hasReleaseSigning = releaseSigningError == null

fun isAndroidReleasePackageTask(name: String): Boolean {
    val n = name.lowercase()
    if (!n.contains("release")) return false
    return (n.startsWith("assemble") || n.startsWith("bundle")) && n.endsWith("release")
}

android {
    namespace = "com.dahr.dahr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Org com.dahr + project name dahr. Do not change without Play Console + STORE.md.
        applicationId = "com.dahr.dahr"
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
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystorePropertyOrEmpty("keyAlias")
                keyPassword = keystorePropertyOrEmpty("keyPassword")
                storePassword = keystorePropertyOrEmpty("storePassword")
                storeFile = resolveStoreFile(keystorePropertyOrEmpty("storeFile"))
            }
        }
    }

    buildTypes {
        release {
            // Do not assign debug signing when the upload keystore is missing.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (allowDebugReleaseSigning) {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

tasks.configureEach {
    if (!isAndroidReleasePackageTask(name)) return@configureEach
    doFirst {
        if (!hasReleaseSigning && !allowDebugReleaseSigning) {
            throw GradleException(
                releaseSigningError
                    ?: "Android release signing is not configured. See android/key.properties.example and STORE.md Signing.",
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
