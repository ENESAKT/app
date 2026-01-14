# PROJE DOKÜMANTASYONU VE KURALLAR

## 1. Proje Özeti
Bu proje, **Flutter** ile geliştirilmiş, backend servisi olarak tamamen **Supabase** kullanan bir sosyal medya uygulamasıdır. Kullanıcılar gönderi paylaşabilir, hikaye atabilir, yorum yapabilir, beğenebilir ve takipleşebilir.

## 2. Teknoloji Yığını (Tech Stack)
* **Frontend:** Flutter (Dart)
* **Backend & Database:** Supabase (PostgreSQL)
* **Authentication:** Supabase Native Auth (Email/Password + Google OAuth)
* **State Management:** Provider
* **Storage:** Supabase Storage (Medya dosyaları için)

## 3. Mimari ve Kurallar
* **MİMARİ:** MVVM (Model-View-ViewModel) benzeri yapı. `screens`, `models`, `services`, `widgets` klasörleri kullanılır.
* **LEGACY KOD YASAK:** Projeden **Django (Render)** ve **Firebase** tamamen kaldırılmıştır. `apiService` veya REST API çağrıları **yapılmamalıdır**. Tüm işlemler doğrudan Supabase SDK ile yapılmalıdır.
* **NULL SAFETY:** Kodlar kesinlikle Null Safety kurallarına uymalıdır.

## 4. Veritabanı Yapısı (Supabase PostgreSQL)
Tüm tablolarda **Primary Key** olarak `UUID` kullanılır. String ID kullanımı yasaktır.

* **Tablolar:**
    * `users` (id, username, avatar_url, vb.)
    * `posts` (caption, media_urls, location)
    * `stories` (24 saatlik hikayeler)
    * `comments` & `likes`
    * `followers` (takip sistemi)
    * `blocked_users` (engelleme sistemi)
    * `notifications`

## 5. Kimlik Doğrulama (Authentication)
* **Yöntem:** Supabase Native Auth.
* **Google Sign-In:** Aktif.
* **Deep Link:** `io.supabase.arkadas://login-callback`
* **Validation:** Kullanıcı ID'leri `uuid` formatında değilse (eski Firebase ID'si gibi) otomatik `signOut` yapılır.

## 6. Önemli Notlar
* **Admin Paneli:** Doğrudan Supabase `users` tablosundan veri çeker.
* **Engellenenler:** `blocked_users` tablosu üzerinden yönetilir (Join işlemleri ile).
* **Android Manifest:** Deep Link için `intent-filter` ayarlanmıştır.