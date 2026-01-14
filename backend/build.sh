#!/usr/bin/env bash
# Hata olursa durdur
set -o errexit

# Paket yükleyicisini güncelle
pip install --upgrade pip

# Gerekli kütüphaneleri yükle
pip install -r requirements.txt