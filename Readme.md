# 🚀 Polibatam Ride

Sistem P2P Jastip & Pengantaran Antar Mahasiswa Politeknik Negeri Batam.

## 📁 Struktur Project

```
polibatam-ride/
├── backend/       → Laravel API
├── frontend/      → Flutter App
└── README.md
```

## 🛠️ Tech Stack

- **Backend**: Laravel 11 + MySQL + Sanctum + Gmail SMTP
- **Frontend**: Flutter + Dio + SharedPreferences

## ⚙️ Cara Setup

### 1. Clone Repo

```bash
git clone https://github.com/username/polibatam-ride.git
cd polibatam-ride
```

### 2. Setup Backend

```bash
cd backend

# Install dependencies
composer install

# Copy .env.example ke .env
cp .env.example .env

# Generate key
php artisan key:generate

# Bikin database di MySQL dulu, namanya: polibatam_ride
# Terus edit .env, sesuaikan:
#   DB_DATABASE=polibatam_ride
#   DB_USERNAME=root
#   DB_PASSWORD=
#   MAIL_USERNAME & MAIL_PASSWORD (isi Gmail + App Password)

# Migrate database
php artisan migrate

# Bikin symlink storage
php artisan storage:link

# Jalanin server
php artisan serve --host=0.0.0.0 --port=8000
```

### 3. Setup Frontend

Buka terminal **baru** (jangan tutup yang Laravel):

```bash
cd frontend

# Install dependencies
flutter pub get

# Cek IP laptop :
# Windows: ipconfig  → liat IPv4 Address
# Mac/Linux: ifconfig → liat inet

# Edit file lib/services/api_service.dart
# Ganti baseUrl jadi salah satu:
# - Emulator Android: http://10.0.2.2:8000/api
# - Emulator iOS: http://localhost:8000/api
# - Web (Edge/Chrome): http://127.0.0.1:8000/api
# - HP Fisik: http://<IP_LAPTOP>:8000/api

# Jalanin
flutter run -d edge         # Web
flutter run                 # Emulator/HP
```

## 📝 Catatan Penting

- File `.env` **TIDAK di-push** ke GitHub karena berisi kredensial
- Setiap developer harus bikin `.env` sendiri dengan copy dari `.env.example`
- Untuk Gmail SMTP, WAJIB pakai **App Password** (bukan password Gmail biasa)
  - Bikin di: https://myaccount.google.com/apppasswords
- KTM user disimpen di `backend/storage/app/public/ktm/` (di-ignore juga)

## 🎯 Fitur

- ✅ Auth dengan verifikasi OTP email
- ✅ Upload KTM untuk verifikasi mahasiswa  
- ✅ Verifikasi admin (approve/reject)
- ⏳ Tebengan (ride sharing)
- ⏳ Jastip (jasa titip)

## 👥 Contributors

- Muhammad Farrel Azzikry
- Vikram Al Hakim