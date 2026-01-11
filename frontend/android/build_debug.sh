# ============================================================================
# LOCAL APK BUILD - Hızlı Test Komutları
# ============================================================================
# Bu dosyayı frontend/android/ klasörüne kaydedin
# PowerShell veya Git Bash'te çalıştırın
# ============================================================================

echo "🧹 Gradle Cache Temizleniyor..."
./gradlew clean

echo ""
echo "🔧 Debug APK Oluşturuluyor..."
./gradlew assembleDebug --stacktrace --info

echo ""
echo "✅ Build tamamlandı!"
echo "📦 APK Konumu: app/build/outputs/apk/debug/app-debug.apk"
