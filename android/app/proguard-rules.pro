# Guardians AI ProGuard Rules
# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Google Play Core (optional deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Supabase
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }

# Record package
-keep class com.llfbandit.record.** { *; }

# Speech to text
-keep class com.csdcorp.speech_to_text.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Flutter local notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# General Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
