# ═══════════════════════════════════════════════════════════════════
# REGLAS PROGUARD PARA GOTACONTROL
# Evita que R8 elimine clases usadas por reflexión
# ═══════════════════════════════════════════════════════════════════

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# sqflite
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# printing / pdf
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# Kotlin metadata
-keep class kotlin.Metadata { *; }

# Modelos serializables (por si usas reflexión en el futuro)
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Preservar line numbers para stack traces legibles
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile