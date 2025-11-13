# Juan Heart Mobile - ProGuard Rules
# Enable aggressive optimizations while preserving functionality

## Flutter Core
# Keep all Flutter framework classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Keep Flutter plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Flutter JNI
-keepclasseswithmembers class * {
    native <methods>;
}

# Don't warn about missing Play Core classes (optional dynamic feature delivery)
-dontwarn com.google.android.play.core.**
-dontnote com.google.android.play.core.**

## Drift Database
# Keep Drift database classes and methods
-keep class drift.** { *; }
-keep class com.simolus.drift.** { *; }
-keep class moor.** { *; }

# Keep database-related classes
-keepclassmembers class * extends drift.GeneratedDatabase {
    *;
}

## Dio HTTP Client
# Keep Dio classes for network operations
-keep class dio.** { *; }
-keep class com.dio.** { *; }

# Preserve Dio interceptors
-keep class * implements dio.Interceptor { *; }

## Hive Storage
# Keep Hive classes for local storage
-keep class hive.** { *; }
-keep class hive_flutter.** { *; }

# Keep generated Hive adapters
-keep class **$HiveFieldAdapter { *; }

## Firebase
# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }

## JSON Serialization
# Keep JSON serialization annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep classes with JSON annotations
-keep @interface com.google.gson.annotations.SerializedName
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

## PDF Generation
# Keep PDF library classes if using
-keep class com.pdf.** { *; }

## Geolocation
# Keep location services
-keep class com.google.android.gms.location.** { *; }

## Connectivity
# Keep connectivity classes
-keep class androidx.core.content.** { *; }

## Notifications
# Keep notification classes
-keep class androidx.core.app.NotificationCompat** { *; }

## WebView
# Keep WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

## Kotlin
# Keep Kotlin metadata
-keepattributes *Annotation*, InnerClasses
-dontnote kotlin.internal.PlatformImplementationsKt

# Keep Kotlin reflect (if used)
-keep class kotlin.reflect.** { *; }

# Keep Kotlin coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

## General Android
# Keep Android framework classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## Optimization Configuration
# Enable all optimizations except those that can cause issues
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Repackage classes to reduce APK size
-repackageclasses ''
-flattenpackagehierarchy

## Debugging (remove in production)
# Preserve line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Rename source file attribute to hide original file names
-renamesourcefileattribute SourceFile

## R8 Compatibility
# Don't warn about missing classes from optional dependencies
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

## Logging (optional - remove debug logs in production)
# Remove Log.d, Log.v calls to reduce APK size
# Uncomment the following lines to strip debug/verbose logs:
# -assumenosideeffects class android.util.Log {
#     public static int d(...);
#     public static int v(...);
# }

## Custom Application Classes
# Add your custom model classes here if they use reflection
# Example:
# -keep class com.example.juan_heart.models.** { *; }

# Keep all data models used in JSON serialization
-keep class com.example.juan_heart.models.** { *; }

## End of ProGuard Rules
