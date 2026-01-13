#!/usr/bin/env python3
"""
Keystore dosyasını GitHub Secrets için Base64'e çevirir.
Windows certutil sorunlarını çözer.
"""

import base64
import os

# Input ve output dosyaları
KEYSTORE_FILE = "upload-keystore.jks"
OUTPUT_FILE = "keystore_fixed.txt"

def encode_keystore_to_base64():
    """Keystore'u okuyup tek satırlık Base64 stringine çevirir."""
    
    # Keystore dosyasını kontrol et
    if not os.path.exists(KEYSTORE_FILE):
        print(f"❌ HATA: '{KEYSTORE_FILE}' dosyası bulunamadı!")
        print(f"   Lütfen bu scripti keystore dosyasıyla aynı klasörde çalıştırın.")
        return False
    
    try:
        # Keystore dosyasını binary modda oku
        with open(KEYSTORE_FILE, 'rb') as f:
            keystore_bytes = f.read()
        
        print(f"✅ Keystore okundu: {len(keystore_bytes)} bytes")
        
        # Base64'e çevir (tek satır, boşluksuz)
        base64_string = base64.b64encode(keystore_bytes).decode('utf-8')
        
        print(f"✅ Base64 encode tamamlandı: {len(base64_string)} karakterlik string")
        
        # Output dosyasına yaz
        with open(OUTPUT_FILE, 'w') as f:
            f.write(base64_string)
        
        print(f"✅ '{OUTPUT_FILE}' dosyası oluşturuldu!")
        print()
        print("═" * 60)
        print("🎯 BAŞARILI! Şimdi yapmanız gerekenler:")
        print("═" * 60)
        print(f"1. '{OUTPUT_FILE}' dosyasını bir text editör ile açın")
        print("2. TÜM içeriği kopyalayın (Ctrl+A, Ctrl+C)")
        print("3. GitHub → Repository → Settings → Secrets → Actions")
        print("4. 'New repository secret' → Name: KEYSTORE_BASE64")
        print("5. Value alanına yapıştırın")
        print("═" * 60)
        print()
        print(f"📊 Base64 string uzunluğu: {len(base64_string)} karakter")
        print(f"📦 Orijinal dosya boyutu: {len(keystore_bytes)} bytes")
        print()
        
        return True
        
    except Exception as e:
        print(f"❌ HATA: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("🔐 Android Keystore → Base64 Converter")
    print("=" * 60)
    print()
    
    success = encode_keystore_to_base64()
    
    if success:
        print("✅ İşlem tamamlandı!")
    else:
        print("❌ İşlem başarısız!")
