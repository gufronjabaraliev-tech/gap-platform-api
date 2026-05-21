import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { hashPassword } from './auth.js';
import { loadStore, saveStore } from './db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const STORE_JSON_PATH = path.join(__dirname, '..', 'data', 'store.json');

function readStoreJson() {
  if (!fs.existsSync(STORE_JSON_PATH)) {
    return null;
  }
  const raw = JSON.parse(fs.readFileSync(STORE_JSON_PATH, 'utf8'));
  return {
    admins: Array.isArray(raw.admins) ? raw.admins : [],
    apps: Array.isArray(raw.apps) ? raw.apps : [],
    supportRequests: Array.isArray(raw.supportRequests) ? raw.supportRequests : [],
    analyticsEvents: Array.isArray(raw.analyticsEvents) ? raw.analyticsEvents : [],
  };
}

function defaultGapApp() {
  const now = new Date().toISOString();
  return {
    id: 'gap',
    name: 'GAP',
    description: 'Navbatli jamg\'arma ilovasi',
    packageName: 'uz.gap.gap_app',
    isActive: true,
    config: {
      maintenance: { enabled: false, message: '' },
      onboarding: {
        pages: [
          {
            title: "Oson va ishonchli jamg'arma",
            description:
              'Guruhingiz bilan oson boshqarish, shaffof va xavfsiz tizim.',
            icon: 'groups',
          },
          {
            title: 'Shaffoflik va ishonch ustuvor',
            description:
              "Har bir operatsiya aniq, hisobotlar to'liq va tushunarli.",
            icon: 'visibility',
          },
          {
            title: 'Maqsadlar sari birgalikda',
            description:
              'Kichik hissa – katta natija. Birgalikda orzularimizga erishamiz.',
            icon: 'people',
          },
          {
            title: 'Hisobot',
            description:
              "Guruh a'zolarining to'lovlari va tizim faoliyati sizning qo'lingizda.",
            icon: 'bar_chart',
            isLast: true,
          },
        ],
      },
      ads: {
        enabled: false,
        placements: {
          my_groups_banner: {
            enabled: false,
            title: '',
            subtitle: '',
            imageUrl: '',
            linkUrl: '',
            backgroundColor: '#047857',
          },
          login_footer: {
            enabled: false,
            title: '',
            subtitle: '',
            imageUrl: '',
            linkUrl: '',
            backgroundColor: '#065F46',
          },
        },
      },
    },
    createdAt: now,
    updatedAt: now,
  };
}

function createDefaultAdmin() {
  return {
    id: 'admin-1',
    email: 'admin@gap.uz',
    name: 'Super Admin',
    passwordHash: hashPassword('admin123'),
    role: 'superadmin',
    createdAt: new Date().toISOString(),
  };
}

function printSeedHint(message, detail) {
  console.error('');
  console.error(message);
  if (detail) {
    console.error(`  ${detail}`);
  }
  console.error('');
}

function isDbConfigOrConnectionError(err) {
  const msg = String(err?.message ?? err).toLowerCase();
  return (
    msg.includes('database_url') ||
    msg.includes('econnrefused') ||
    msg.includes('enotfound') ||
    msg.includes('connect') ||
    msg.includes('timeout') ||
    msg.includes('password authentication') ||
    msg.includes('does not exist') ||
    msg.includes('getaddrinfo')
  );
}

try {
  if (!process.env.DATABASE_URL?.trim()) {
    printSeedHint('DATABASE_URL topilmadi. .env faylini tekshiring.');
  } else {
    const fromJson = readStoreJson();
    let store;
    let source;

    if (fromJson) {
      store = fromJson;
      source = 'data/store.json';
    } else {
      store = await loadStore();
      source = 'PostgreSQL (mavjud yoki bo\'sh)';
    }

    let addedAdmin = false;
    let addedGapApp = false;

    if (store.admins.length === 0) {
      store.admins.push(createDefaultAdmin());
      addedAdmin = true;
    }

    if (!store.apps.some((a) => a.id === 'gap')) {
      store.apps.push(defaultGapApp());
      addedGapApp = true;
    }

    await saveStore(store);

    console.log('');
    console.log('═══════════════════════════════════════');
    console.log('  GAP Platform API — Seed muvaffaqiyatli');
    console.log('═══════════════════════════════════════');
    console.log(`  Manba:              ${source}`);
    console.log(`  Adminlar:           ${store.admins.length}`);
    console.log(`  Ilovalar:           ${store.apps.length}`);
    console.log(`  Murojaatlar:        ${store.supportRequests.length}`);
    console.log(`  Analitika hodisalar: ${store.analyticsEvents.length}`);
    if (addedAdmin) {
      console.log('');
      console.log('  Yangi admin yaratildi:');
      console.log('    Email:    admin@gap.uz');
      console.log('    Parol:    admin123');
      console.log('    Ism:      Super Admin');
      console.log('    Rol:      superadmin');
    }
    if (addedGapApp) {
      console.log('  GAP ilovasi (id: gap) qo\'shildi.');
    }
    if (fromJson) {
      console.log('');
      console.log('  store.json ma\'lumotlari PostgreSQL ga ko\'chirildi.');
    }
    console.log('═══════════════════════════════════════');
    console.log('');
  }
} catch (err) {
  if (
    !process.env.DATABASE_URL?.trim() ||
    String(err?.message ?? '').includes('DATABASE_URL')
  ) {
    printSeedHint('DATABASE_URL topilmadi. .env faylini tekshiring.');
  } else if (isDbConfigOrConnectionError(err)) {
    printSeedHint(
      'PostgreSQL ga ulanib bo\'lmadi. DATABASE_URL va serverni tekshiring.',
      err.message,
    );
  } else {
    printSeedHint(`Seed bajarilmadi: ${err.message}`);
  }
}
