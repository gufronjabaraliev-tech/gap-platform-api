import { Router } from 'express';
import { v4 as uuid } from 'uuid';
import { loadStore, updateStore } from '../db.js';

const router = Router();

/** Ilova uchun remote config (onboarding, reklama, maintenance). */
router.get('/apps/:appId/config', async (req, res) => {
  try {
    const store = await loadStore();
    const app = store.apps.find(
      (a) => a.id === req.params.appId && a.isActive,
    );
    if (!app) {
      return res.status(404).json({ error: 'Ilova topilmadi' });
    }
    res.json({
      appId: app.id,
      appName: app.name,
      updatedAt: app.updatedAt,
      config: app.config,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

/** Analitika hodisasi (ilovadan). */
router.post('/apps/:appId/events', async (req, res) => {
  try {
    const { event, metadata, deviceId, userId } = req.body ?? {};
    if (!event || typeof event !== 'string') {
      return res.status(400).json({ error: 'event majburiy' });
    }

    const store = await loadStore();
    const app = store.apps.find((a) => a.id === req.params.appId);
    if (!app) {
      return res.status(404).json({ error: 'Ilova topilmadi' });
    }

    const row = {
      id: uuid(),
      appId: req.params.appId,
      event,
      metadata: metadata ?? {},
      deviceId: deviceId ?? null,
      userId: userId ?? null,
      createdAt: new Date().toISOString(),
    };

    await updateStore((s) => {
      s.analyticsEvents.push(row);
      if (s.analyticsEvents.length > 50000) {
        s.analyticsEvents = s.analyticsEvents.slice(-40000);
      }
    });

    res.status(201).json({ ok: true, id: row.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

/** Foydalanuvchi murojaati. */
router.post('/apps/:appId/support', async (req, res) => {
  try {
    const { name, phone, email, subject, message, userId } = req.body ?? {};
    if (!subject?.trim() || !message?.trim()) {
      return res.status(400).json({ error: 'Mavzu va xabar majburiy' });
    }

    const store = await loadStore();
    const app = store.apps.find((a) => a.id === req.params.appId);
    if (!app) {
      return res.status(404).json({ error: 'Ilova topilmadi' });
    }

    const ticket = {
      id: uuid(),
      appId: req.params.appId,
      name: name?.trim() || 'Noma\'lum',
      phone: phone?.trim() || null,
      email: email?.trim() || null,
      subject: subject.trim(),
      message: message.trim(),
      userId: userId ?? null,
      status: 'open',
      adminNote: '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await updateStore((s) => {
      s.supportRequests.unshift(ticket);
    });

    res.status(201).json({ ok: true, id: ticket.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server xatoligi' });
  }
});

export default router;
