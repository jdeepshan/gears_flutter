plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gears.gearserp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("gearsRelease") {
            storeFile = file(
                "/Users/osos/Documents/Nipun_Projects/cmp/CmpRnD/androidApp/keystore/gears_keystore.jks",
            )
            storePassword = "Gears@123"
            keyAlias = "key_gears_gearserp"
            keyPassword = "Gears@123"
        }
    }

    defaultConfig {
        applicationId = "com.gears.gearserp"
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Must match the redirect URI hash registered in Azure AD for osos-qa.
        manifestPlaceholders["signing_key_hash"] = "TGBOUBcsIFWTTNYPXwfVjmPiw4w="
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("gearsRelease")
        }
        release {
            signingConfig = signingConfigs.getByName("gearsRelease")
        }
    }
}

flutter {
    source = "../.."
}
