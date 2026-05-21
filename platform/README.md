# Invest Group — Platform API va Admin

**Invest Group** — ko‘p ilovali boshqaruv platformasi. Hozir **GAP** ilovasi ulangan, kelajakda boshqa ilovalar ham qo‘shiladi.

## Tuzilma

```
platform/
├── api/          # Node.js REST API (port 3847)
└── admin/        # React admin panel (port 5174)
```

## Tez ishga tushirish

### 1. API server

```bash
cd platform/api
npm install
npm run seed
npm run dev
```

- API: http://localhost:3847
- Admin login: `admin@gap.uz` / `admin123` (Invest Group panel)

### 2. Admin panel

```bash
cd platform/admin
npm install
npm run dev
```

Brauzer: http://localhost:5174 — **Invest Group** admin panel

### 3. GAP mobil ilova

Telefon **USB** orqali ulangan bo‘lsa, kompyuteringizning mahalliy IP manzilini ishlating:

```bash
cd gap_app
flutter pub get
flutter run -d <qurilma_id> --dart-define=PLATFORM_API_URL=http://192.168.X.X:3847
```

`192.168.X.X` — `ipconfig` (Windows) dagi IPv4 manzil.

Emulyatorda odatda qo‘shimcha parametr kerak emas (`10.0.2.2` ishlatiladi).

## Admin imkoniyatlari

| Bo‘lim | Vazifa |
|--------|--------|
| **Ilovalar** | Har bir ilova alohida (GAP, keyinchalik boshqalar) |
| **Onboarding** | Kirishdagi 4 ta sahifa matni va ikonkasi |
| **Reklama** | Banner (masalan, jamg‘armalar ro‘yxati) |
| **Murojaatlar** | Foydalanuvchi xabarlari, holatni yopish |
| **Statistika** | `app_open` va boshqa hodisalar |
| **Texnik holat** | Ilovani vaqtincha o‘chirish |

## Yangi ilova qo‘shish

Admin panel → kelajakda «Ilova qo‘shish» yoki API:

`POST /api/admin/apps` — `{ "id": "myapp", "name": "..." }`

Mobil ilovada `PlatformConfig.appId` ni shu `id` ga o‘rnating.

## API (qisqa)

| Endpoint | Kim uchun |
|----------|-----------|
| `GET /api/public/apps/gap/config` | Mobil ilova |
| `POST /api/public/apps/gap/events` | Analitika |
| `POST /api/public/apps/gap/support` | Murojaat |
| `POST /api/admin/login` | Admin panel |

Ma’lumotlar: `platform/api/data/store.json` (keyin PostgreSQL ga ko‘chirish mumkin).
