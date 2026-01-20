plugins {
    id("com.android.application")
    id("kotlin-android")
    // هذا السطر ضروري جداً لربط المشروع بـ Flutter
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.muhamed.wosool"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.muhamed.wosool"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- هذا هو الجزء الذي أضفناه لحل مشكلة تعليق البناء على الـ Linux/NTFS ---
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    // ------------------------------------------------------------------

    buildTypes {
        release {
            // سنستخدم مفاتيح التصحيح (Debug Keys) حالياً ليعمل البناء بدون إنشاء Keystore مخصص
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}