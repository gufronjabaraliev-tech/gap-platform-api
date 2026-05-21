import pg from 'pg';

const { Pool } = pg;

let pool;
let schemaReady;

function getPool() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error(
        'DATABASE_URL muhit o\'zgarishi belgilanmagan (Railway PostgreSQL URL)',
      );
    }

    const isLocal =
      connectionString.includes('localhost') ||
      connectionString.includes('127.0.0.1');

    pool = new Pool({
      connectionString,
      ssl: isLocal ? false : { rejectUnauthorized: false },
    });
  }
  return pool;
}

function toIso(value) {
  if (!value) return value;
  return value instanceof Date ? value.toISOString() : String(value);
}

async function ensureSchema() {
  if (schemaReady) return;
  const db = getPool();

  await db.query(`
    CREATE TABLE IF NOT EXISTS admins (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'admin',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS apps (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      package_name TEXT NOT NULL DEFAULT '',
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      config JSONB NOT NULL DEFAULT '{}'::jsonb,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS support_requests (
      id TEXT PRIMARY KEY,
      app_id TEXT NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      phone TEXT,
      email TEXT,
      subject TEXT NOT NULL,
      message TEXT NOT NULL,
      user_id TEXT,
      status TEXT NOT NULL DEFAULT 'open',
      admin_note TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS analytics_events (
      id TEXT PRIMARY KEY,
      app_id TEXT NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
      event TEXT NOT NULL,
      metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
      device_id TEXT,
      user_id TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_support_requests_app_id
      ON support_requests(app_id);
    CREATE INDEX IF NOT EXISTS idx_support_requests_created_at
      ON support_requests(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_analytics_events_app_id
      ON analytics_events(app_id);
    CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at
      ON analytics_events(created_at DESC);
  `);

  schemaReady = true;
}

function mapAdmin(row) {
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    passwordHash: row.password_hash,
    role: row.role,
    createdAt: toIso(row.created_at),
  };
}

function mapApp(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description ?? '',
    packageName: row.package_name ?? '',
    isActive: row.is_active,
    config: row.config ?? {},
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
  };
}

function mapSupportRequest(row) {
  return {
    id: row.id,
    appId: row.app_id,
    name: row.name,
    phone: row.phone,
    email: row.email,
    subject: row.subject,
    message: row.message,
    userId: row.user_id,
    status: row.status,
    adminNote: row.admin_note ?? '',
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
  };
}

function mapAnalyticsEvent(row) {
  return {
    id: row.id,
    appId: row.app_id,
    event: row.event,
    metadata: row.metadata ?? {},
    deviceId: row.device_id,
    userId: row.user_id,
    createdAt: toIso(row.created_at),
  };
}

/** Barcha jadvallarni store.json shaklida yuklaydi. */
export async function loadStore() {
  await ensureSchema();
  const db = getPool();

  const [adminsRes, appsRes, supportRes, analyticsRes] = await Promise.all([
    db.query(
      'SELECT id, email, name, password_hash, role, created_at FROM admins ORDER BY created_at',
    ),
    db.query(
      `SELECT id, name, description, package_name, is_active, config, created_at, updated_at
       FROM apps ORDER BY created_at`,
    ),
    db.query(
      `SELECT id, app_id, name, phone, email, subject, message, user_id, status, admin_note,
              created_at, updated_at
       FROM support_requests ORDER BY created_at DESC`,
    ),
    db.query(
      `SELECT id, app_id, event, metadata, device_id, user_id, created_at
       FROM analytics_events ORDER BY created_at`,
    ),
  ]);

  return {
    admins: adminsRes.rows.map(mapAdmin),
    apps: appsRes.rows.map(mapApp),
    supportRequests: supportRes.rows.map(mapSupportRequest),
    analyticsEvents: analyticsRes.rows.map(mapAnalyticsEvent),
  };
}

async function upsertAdmins(client, admins) {
  for (const a of admins) {
    await client.query(
      `INSERT INTO admins (id, email, name, password_hash, role, created_at)
       VALUES ($1, $2, $3, $4, $5, $6::timestamptz)
       ON CONFLICT (id) DO UPDATE SET
         email = EXCLUDED.email,
         name = EXCLUDED.name,
         password_hash = EXCLUDED.password_hash,
         role = EXCLUDED.role`,
      [a.id, a.email, a.name, a.passwordHash, a.role, a.createdAt],
    );
  }
  const ids = admins.map((a) => a.id);
  if (ids.length === 0) {
    await client.query('DELETE FROM admins');
  } else {
    await client.query('DELETE FROM admins WHERE NOT (id = ANY($1::text[]))', [ids]);
  }
}

async function upsertApps(client, apps) {
  for (const a of apps) {
    await client.query(
      `INSERT INTO apps (id, name, description, package_name, is_active, config, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::timestamptz, $8::timestamptz)
       ON CONFLICT (id) DO UPDATE SET
         name = EXCLUDED.name,
         description = EXCLUDED.description,
         package_name = EXCLUDED.package_name,
         is_active = EXCLUDED.is_active,
         config = EXCLUDED.config,
         updated_at = EXCLUDED.updated_at`,
      [
        a.id,
        a.name,
        a.description ?? '',
        a.packageName ?? '',
        a.isActive !== false,
        JSON.stringify(a.config ?? {}),
        a.createdAt,
        a.updatedAt,
      ],
    );
  }
  const ids = apps.map((a) => a.id);
  if (ids.length === 0) {
    await client.query('DELETE FROM apps');
  } else {
    await client.query('DELETE FROM apps WHERE NOT (id = ANY($1::text[]))', [ids]);
  }
}

async function upsertSupportRequests(client, tickets) {
  for (const t of tickets) {
    await client.query(
      `INSERT INTO support_requests (
         id, app_id, name, phone, email, subject, message, user_id, status, admin_note,
         created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::timestamptz, $12::timestamptz)
       ON CONFLICT (id) DO UPDATE SET
         app_id = EXCLUDED.app_id,
         name = EXCLUDED.name,
         phone = EXCLUDED.phone,
         email = EXCLUDED.email,
         subject = EXCLUDED.subject,
         message = EXCLUDED.message,
         user_id = EXCLUDED.user_id,
         status = EXCLUDED.status,
         admin_note = EXCLUDED.admin_note,
         updated_at = EXCLUDED.updated_at`,
      [
        t.id,
        t.appId,
        t.name,
        t.phone,
        t.email,
        t.subject,
        t.message,
        t.userId,
        t.status,
        t.adminNote ?? '',
        t.createdAt,
        t.updatedAt,
      ],
    );
  }
  const ids = tickets.map((t) => t.id);
  if (ids.length === 0) {
    await client.query('DELETE FROM support_requests');
  } else {
    await client.query(
      'DELETE FROM support_requests WHERE NOT (id = ANY($1::text[]))',
      [ids],
    );
  }
}

async function upsertAnalyticsEvents(client, events) {
  for (const e of events) {
    await client.query(
      `INSERT INTO analytics_events (id, app_id, event, metadata, device_id, user_id, created_at)
       VALUES ($1, $2, $3, $4::jsonb, $5, $6, $7::timestamptz)
       ON CONFLICT (id) DO UPDATE SET
         app_id = EXCLUDED.app_id,
         event = EXCLUDED.event,
         metadata = EXCLUDED.metadata,
         device_id = EXCLUDED.device_id,
         user_id = EXCLUDED.user_id`,
      [
        e.id,
        e.appId,
        e.event,
        JSON.stringify(e.metadata ?? {}),
        e.deviceId,
        e.userId,
        e.createdAt,
      ],
    );
  }
  const ids = events.map((e) => e.id);
  if (ids.length === 0) {
    await client.query('DELETE FROM analytics_events');
  } else {
    await client.query(
      'DELETE FROM analytics_events WHERE NOT (id = ANY($1::text[]))',
      [ids],
    );
  }
}

/** Butun store obyektini PostgreSQL ga yozadi. */
export async function saveStore(store) {
  await ensureSchema();
  const client = await getPool().connect();
  try {
    await client.query('BEGIN');
    await upsertAdmins(client, store.admins ?? []);
    await upsertApps(client, store.apps ?? []);
    await upsertSupportRequests(client, store.supportRequests ?? []);
    await upsertAnalyticsEvents(client, store.analyticsEvents ?? []);
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Yuklab → mutator → saqlash (tranzaksiya ichida).
 * @param {(store: object) => void} mutator
 */
export async function updateStore(mutator) {
  await ensureSchema();
  const client = await getPool().connect();
  try {
    await client.query('BEGIN');

    const [adminsRes, appsRes, supportRes, analyticsRes] = await Promise.all([
      client.query(
        'SELECT id, email, name, password_hash, role, created_at FROM admins ORDER BY created_at',
      ),
      client.query(
        `SELECT id, name, description, package_name, is_active, config, created_at, updated_at
         FROM apps ORDER BY created_at`,
      ),
      client.query(
        `SELECT id, app_id, name, phone, email, subject, message, user_id, status, admin_note,
                created_at, updated_at
         FROM support_requests ORDER BY created_at DESC`,
      ),
      client.query(
        `SELECT id, app_id, event, metadata, device_id, user_id, created_at
         FROM analytics_events ORDER BY created_at`,
      ),
    ]);

    const store = {
      admins: adminsRes.rows.map(mapAdmin),
      apps: appsRes.rows.map(mapApp),
      supportRequests: supportRes.rows.map(mapSupportRequest),
      analyticsEvents: analyticsRes.rows.map(mapAnalyticsEvent),
    };

    mutator(store);

    await upsertAdmins(client, store.admins);
    await upsertApps(client, store.apps);
    await upsertSupportRequests(client, store.supportRequests);
    await upsertAnalyticsEvents(client, store.analyticsEvents);

    await client.query('COMMIT');
    return store;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/** Server yopilishida pool ni yopish (ixtiyoriy). */
export async function closeDb() {
  if (pool) {
    await pool.end();
    pool = undefined;
    schemaReady = false;
  }
}
