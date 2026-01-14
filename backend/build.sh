#!/usr/bin/env bash
# exit on error
set -o errexit

echo "🚀 Build başlıyor..."

# Pip upgrade
pip install --upgrade pip

# Install dependencies
echo "📦 Bağımlılıklar yükleniyor..."
pip install -r requirements.txt

# Collect static files
echo "📁 Statik dosyalar toplanıyor..."
python manage.py collectstatic --no-input

# Run migrations
echo "🗃️ Migrations çalıştırılıyor..."
python manage.py migrate

echo "✅ Build tamamlandı!"
