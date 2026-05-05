# ProGuard rules for FreshVeggie app

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.firebase.** { *; }

# Keep Google Play Core library (for split install/deferred components)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keepnames class com.google.android.play.core.** { *; }

# Keep Flutter/Dart interop
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keepclassmembers class io.flutter.embedding.engine.FlutterEngine { *; }

# Keep HTTP/Network classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class com.squareup.okhttp3.** { *; }
-keepnames class com.squareup.okhttp3.internal.** { *; }

# Keep classes needed for image loading (cached_network_image)
-keep class com.bumptech.glide.** { *; }
-keep interface com.bumptech.glide.** { *; }
-keep class * extends com.bumptech.glide.module.AppGlideModule
-keep enum com.bumptech.glide.load.resource.bitmap.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

# Keep Retrofit/Gson
-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep parameter names for debugging
-keepattributes LocalVariableTable,LocalVariableTypeTable,SourceFile,LineNumberTable,*Annotation*,Signature,Exceptions,InnerClasses

# Suppress some warnings
-dontnote android.net.http.*
-dontnote org.apache.commons.codec.**
-dontnote org.apache.http.**
-dontwarn android.net.http.**
-dontwarn org.apache.commons.**
-dontwarn org.apache.http.**
-dontwarn com.google.android.play.core.**
-dontwarn java.lang.invoke.LambdaMetafactory
