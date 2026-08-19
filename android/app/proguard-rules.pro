# Flutter Wrapper & Deferred Components
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**

# Google Play Services & Maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Geolocator / Location
-dontwarn com.baseflow.geolocator.**
-keep class com.baseflow.geolocator.** { *; }

# Local Notifications & Foreground Task
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.pravera.flutter_foreground_task.** { *; }

# Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

