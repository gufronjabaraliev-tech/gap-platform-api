import { Router } from 'express';
import { v4 as uuid } from 'uuid';
import { loadStore, updateStore } from '../db.js';
import { hashPassword, requireAdmin, signAdminToken, verifyPassword } from '../auth.js';

const router = Router();

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body ?? {};
    if (!email || !password) {
      return res.status(400).json({ error: 'Email va parol kerak' });
    }

    const store = await loadStore();
    const admin = store.admins.find(
      (a) => a.email.toLowerCase() === String(email).toLowerCase(),
    );
    if (!admin || !verifyPassword(password, admin.passwordHash)) {
      return res.status(401).json({ error: 'Email yoki parol noto\'g\'ri' });
    }

    res.json({
      token: signAdminToken(admin),
      admin: { id: admin.id, email: admin.email, name: admin.name, role: admin.role },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.get('/me', requireAdmin, async (req, res) => {
  try {
    const store = await loadStore();
    const admin = store.admins.find((a) => a.id === req.admin.sub);
    if (!admin) return res.status(404).json({ error: 'Admin topilmadi' });
    res.json({
      id: admin.id,
      email: admin.email,
      name: admin.name,
      role: admin.role,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.get('/apps', requireAdmin, async (_req, res) => {
  try {
    const store = await loadStore();
    res.json(
      store.apps.map((a) => ({
        id: a.id,
        name: a.name,
        description: a.description,
        packageName: a.packageName,
        isActive: a.isActive,
        updatedAt: a.updatedAt,
      })),
    );
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.get('/apps/:appId', requireAdmin, async (req, res) => {
  try {
    const store = await loadStore();
    const app = store.apps.find((a) => a.id === req.params.appId);
    if (!app) return res.status(404).json({ error: 'Ilova topilmadi' });
    res.json(app);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.patch('/apps/:appId', requireAdmin, async (req, res) => {
  try {
    const { name, description, isActive, config } = req.body ?? {};
    let updated = null;

    await updateStore((s) => {
      const app = s.apps.find((a) => a.id === req.params.appId);
      if (!app) return;
      if (name !== undefined) app.name = name;
      if (description !== undefined) app.description = description;
      if (isActive !== undefined) app.isActive = isActive;
      if (config !== undefined) app.config = config;
      app.updatedAt = new Date().toISOString();
      updated = app;
    });

    if (!updated) return res.status(404).json({ error: 'Ilova topilmadi' });
    res.json(updated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.post('/apps', requireAdmin, async (req, res) => {
  try {
    const { id, name, description, packageName } = req.body ?? {};
    if (!id?.trim() || !name?.trim()) {
      return res.status(400).json({ error: 'id va name majburiy' });
    }

    const appId = id.trim().toLowerCase().replace(/\s+/g, '-');
    const store = await loadStore();
    if (store.apps.some((a) => a.id === appId)) {
      return res.status(409).json({ error: 'Bu id band' });
    }

    const app = {
      id: appId,
      name: name.trim(),
      description: description?.trim() || '',
      packageName: packageName?.trim() || '',
      isActive: true,
      config: {
        maintenance: { enabled: false, message: '' },
        onboarding: { pages: [] },
        ads: { enabled: false, placements: {} },
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await updateStore((s) => {
      s.apps.push(app);
    });

    res.status(201).json(app);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.get('/apps/:appId/stats', requireAdmin, async (req, res) => {
  try {
    const store = await loadStore();
    const appId = req.params.appId;
    const events = store.analyticsEvents.filter((e) => e.appId === appId);
    const tickets = store.supportRequests.filter((t) => t.appId === appId);

    const byEvent = {};
    for (const e of events) {
      byEvent[e.event] = (byEvent[e.event] || 0) + 1;
    }

    const last7 = events.filter((e) => {
      const d = new Date(e.createdAt);
      return Date.now() - d.getTime() < 7 * 24 * 60 * 60 * 1000;
    }).length;

    res.json({
      totalEvents: events.length,
      eventsLast7Days: last7,
      eventsByType: byEvent,
      supportOpen: tickets.filter((t) => t.status === 'open').length,
      supportTotal: tickets.length,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.get('/apps/:appId/support', requireAdmin, async (req, res) => {
  try {
    const store = await loadStore();
    const list = store.supportRequests
      .filter((t) => t.appId === req.params.appId)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json(list);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.patch('/support/:ticketId', requireAdmin, async (req, res) => {
  try {
    const { status, adminNote } = req.body ?? {};
    let ticket = null;

    await updateStore((s) => {
      const t = s.supportRequests.find((x) => x.id === req.params.ticketId);
      if (!t) return;
      if (status) t.status = status;
      if (adminNote !== undefined) t.adminNote = adminNote;
      t.updatedAt = new Date().toISOString();
      ticket = t;
    });

    if (!ticket) return res.status(404).json({ error: 'Murojaat topilmadi' });
    res.json(ticket);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

router.get('/analytics', requireAdmin, async (req, res) => {
  try {
    const { appId, limit = '100' } = req.query;
    const store = await loadStore();
    let list = store.analyticsEvents;
    if (appId) list = list.filter((e) => e.appId === appId);
    list = list
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, Math.min(parseInt(limit, 10) || 100, 500));
    res.json(list);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

export default router;
