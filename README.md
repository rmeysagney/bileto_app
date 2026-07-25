# 🎟️ Etkinlik App - Etkinlik Takip ve Yönetim Platformu

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Django](https://img.shields.io/badge/Django_REST-4.x-092E20?style=for-the-badge&logo=django&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.style=for-the-badge)

**Etkinlik App**, kullanıcıların şehirlerindeki konser, tiyatro, atölye, spor ve teknoloji gibi çeşitli etkinlikleri keşfetmelerini, takvim üzerinde takip etmelerini, favorilerine eklemelerini ve katılım sağlamalarını kolaylaştıran modern bir etkinlik yönetim platformudur.

Proje, tam teşekküllü bir **Django REST Framework** arka planı (Backend) ve modern **Flutter** mobil uygulamasından (Frontend) oluşmaktadır.

---

## ✨ Öne Çıkan Özellikler

### 📱 Mobil Uygulama (Flutter)
- 🎨 **Modern & Şık Arayüz:** Google Fonts ve Material 3 destekli responsive tasarım.
- 🔍 **Arama ve Kategori Filtreleme:** Etkinlikleri kategoriye (Müzik, Sanat, Teknoloji vb.) veya isimle anlık filtreleme.
- 📅 **İnteraktif Takvim Görünümü:** Etkinlik günlerini takvim üzerinde kolayca takip edebilme.
- 👤 **Kullanıcı Yönetimi:** Kayıt ol, giriş yap, profil güncelleme ve geçmiş katılımları görüntüleme.
- ❤️ **Favoriler ve Katılım:** Etkinlikleri favorilere ekleme ve tek tıkla katılım sağlama.
- ➕ **Organizatör Paneli:** Yeni etkinlik oluşturma (Tarih, saat, konum, kapasite, bilet fiyatı ve görsel belirleme).
- 🛡️ **Yönetici (Admin) Paneli:** Oluşturulan etkinlikleri onaylama veya reddetme kontrolü.
- 📤 **Sosyal Paylaşım:** Etkinlik detaylarını arkadaşlarınızla paylaşma.

### ⚡ Arka Plan Servisi (Django REST API)
- 🔒 **Güvenli Kimlik Doğrulama:** Token / Session tabanlı kullanıcı oturumu yönetimi.
- 👥 **Rol Tabanlı Yetkilendirme:** Katılımcı, Organizatör ve Admin rolleri.
- 📂 **Medya ve Görsel Yönetimi:** Etkinlik afişleri ve profil fotoğrafları yönetimi.
- 📊 **RESTful API Yapısı:** Flutter mobil uygulaması ile kesintisiz ve hızlı veri iletişimi.

---

## 🛠️ Kullanılan Teknolojiler

### Backend
- **Dil:** Python 3.10+
- **Framework:** Django & Django REST Framework
- **Veritabanı:** SQLite (Geliştirme) / PostgreSQL uyumlu

### Frontend
- **Framework:** Flutter (Dart SDK ^3.5.0)
- **Durum Yönetimi (State Management):** `provider`
- **Önemli Paketler:** `http`, `table_calendar`, `google_fonts`, `shared_preferences`, `cached_network_image`, `share_plus`

---

## 📁 Proje Dizin Yapısı

```
etkinlik_app/
│
├── 🐍 etkinlik_api/             # Django REST API Projesi
│   ├── config/                 # Ana Django Yapılandırması (Settings, URLs)
│   ├── events/                 # Etkinlik Modülleri (Models, Views, Serializers)
│   ├── users/                  # Kullanıcı Modülleri ve Auth
│   ├── media/                  # Yüklenen Görseller
│   └── manage.py
│
├── 📱 etkinlik_flutter/         # Flutter Mobil Uygulaması
│   ├── lib/
│   │   ├── models/             # Veri Modelleri (Event, User, Category)
│   │   ├── providers/          # State Management (AuthProvider, EventProvider)
│   │   ├── services/           # HTTP API Servisi (ApiService)
│   │   └── views/              # Ekranlar (Home, Calendar, Detail, Admin, Profile)
│   └── pubspec.yaml
│
└── 📄 README.md
```

---

## 🚀 Kurulum ve Çalıştırma

### 1. Depoyu Klonlayın
```bash
git clone https://github.com/rmeysagney/etkinlik_app.git
cd etkinlik_app
```

---

### 2. Backend (Django REST API) Kurulumu

```bash
# API klasörüne gidin
cd etkinlik_api

# Sanal ortam oluşturun ve aktif edin
python -m venv venv
# macOS / Linux için:
source venv/bin/activate
# Windows için:
# venv\Scripts\activate

# Gerekli kütüphaneleri yükleyin
pip install django djangorestframework django-cors-headers pillow

# Veritabanı göçlerini uygulayın
python manage.py migrate

# (Opsiyonel) Örnek verileri yükleyin veya Süper Kullanıcı oluşturun
python manage.py createsuperuser

# Sunucuyu başlatın (varsayılan: http://127.0.0.1:8000)
python manage.py runserver
```

---

### 3. Frontend (Flutter Uygulaması) Kurulumu

Yeni bir terminal penceresi açın ve:

```bash
# Flutter projesi klasörüne gidin
cd etkinlik_flutter

# Bağımlılıkları yükleyin
flutter pub get

# Uygulamayı başlatın (Simülatör, Emülatör veya Chrome üzerinde)
flutter run
```

> 💡 **Not:** Android Emülatör kullanıyorsanız `lib/services/api_service.dart` dosyasındaki API adresinin `http://10.0.2.2:8000/api` olarak ayarlandığından emin olun. iOS Simülatör veya Chrome için `http://127.0.0.1:8000/api` kullanılır.

---

## 🔗 Önemli API Uç Noktaları (Endpoints)

| Yöntem | Endpoint | Açıklama |
| :--- | :--- | :--- |
| `POST` | `/api/users/register/` | Yeni kullanıcı kaydı |
| `POST` | `/api/users/login/` | Kullanıcı girişi ve token alma |
| `GET` | `/api/events/` | Onaylanmış etkinlikleri listeleme |
| `POST` | `/api/events/` | Yeni etkinlik oluşturma (Organizatör) |
| `GET` | `/api/events/<id>/` | Etkinlik detaylarını getirme |
| `POST` | `/api/events/<id>/join/` | Etkinliğe katılma / kaydolma |
| `POST` | `/api/events/<id>/favorite/` | Etkinliği favorilere ekleme/çıkarma |
| `GET` | `/api/events/pending/` | Onay bekleyen etkinlikler (Admin) |
| `POST` | `/api/events/<id>/approve/` | Etkinliği onaylama (Admin) |

---

## 🤝 Katkıda Bulunma

1. Bu depoyu çatallayın (Fork).
2. Yeni bir özellik dalı oluşturun (`git checkout -b feature/YeniOzellik`).
3. Değişikliklerinizi işleyin (`git commit -m 'feat: Yeni özellik eklendi'`).
4. Dalınıza itin (`git push origin feature/YeniOzellik`).
5. Bir Çekme İsteği (Pull Request) açın.

---

## 📜 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.
