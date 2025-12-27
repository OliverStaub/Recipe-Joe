# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

-keep,includedescriptorclasses class com.recipejoe.**$$serializer { *; }
-keepclassmembers class com.recipejoe.** {
    *** Companion;
}
-keepclasseswithmembers class com.recipejoe.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep Supabase models
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }

# Keep Room entities
-keep class com.recipejoe.data.local.entity.** { *; }

# Keep data classes for serialization
-keep class com.recipejoe.data.remote.dto.** { *; }
-keep class com.recipejoe.domain.model.** { *; }

# Keep Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Keep Google Play Billing
-keep class com.android.vending.billing.** { *; }
