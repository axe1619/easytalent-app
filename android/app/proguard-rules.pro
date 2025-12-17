# Reglas para ignorar idiomas de ML Kit Text Recognition que no se utilizan
# Estos idiomas (chino, devanagari, japonés, coreano) no se necesitan en la app

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Mantener las clases de ML Kit que sí se usan (si las hay)
-keep class com.google.mlkit.vision.text.** { *; }
-keep interface com.google.mlkit.vision.text.** { *; }