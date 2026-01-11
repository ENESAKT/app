-- ============================================
-- Supabase: Manuel Güncelleme Sistemi Tablosu
-- ============================================

-- App Config tablosunu oluştur
CREATE TABLE IF NOT EXISTS app_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_version TEXT NOT NULL,
  download_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Güncelleme trigger'ı ekle (updated_at otomatik güncellensin)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_app_config_updated_at
  BEFORE UPDATE ON app_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- İlk test verisi ekle
INSERT INTO app_config (current_version, download_url)
VALUES ('1.0.1', 'https://github.com/KULLANICI_ADI/PROJE_ADI/releases/download/v1.0.1/app-release.apk')
ON CONFLICT DO NOTHING;

-- ============================================
-- KULLANIM TALİMATLARI
-- ============================================

-- 1. Supabase Dashboard'da SQL Editor'ü açın
-- 2. Bu scripti yapıştırın ve çalıştırın
-- 3. Yeni sürüm yayınladığınızda şu komutu çalıştırın:

/*
UPDATE app_config
SET 
  current_version = '1.0.2',
  download_url = 'https://github.com/KULLANICI_ADI/PROJE_ADI/releases/download/v1.0.2/app-release.apk'
WHERE id = (SELECT id FROM app_config LIMIT 1);
*/

-- 4. Mevcut versiyonu kontrol etmek için:
-- SELECT * FROM app_config;
