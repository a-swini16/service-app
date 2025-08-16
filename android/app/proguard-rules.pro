# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# OneSignal specific rules
-keep class com.onesignal.** { *; }
-keep interface com.onesignal.** { *; }
-dontwarn com.onesignal.**
-dontwarn com.amazon.**
-dontwarn com.google.android.gms.**

# OneSignal SDK
-keep class com.onesignal.OneSignal { *; }
-keep class com.onesignal.shortcutbadger.** { *; }
-keep class com.onesignal.NotificationBundleProcessor { *; }
-keep class com.onesignal.OSUtils { *; }

# Firebase (used by OneSignal)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# HTTP and networking
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# JSON serialization
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Prevent obfuscation of classes with native methods
-keepclasseswithmembers class * {
    native <methods>;
}