import express from 'express';
import cors from 'cors';
import publicRoutes from './routes/public.js';
import adminRoutes from './routes/admin.js';

const PORT = process.env.PORT || 3847;

if (!process.env.DATABASE_URL?.trim()) {
  console.warn('');
  console.warn('DATABASE_URL topilmadi. .env faylini tekshiring.');
  console.warn(
    'Ma\'lumotlar bazasiga ulanish ishlamaydi, lekin server ishga tushadi (local test).',
  );
  console.warn('');
}

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'gap-platform-api' });
});

app.use('/api/public', publicRoutes);
app.use('/api/admin', adminRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Server xatoligi' });
});

app.listen(PORT, () => {
  console.log(`Platform API: http://localhost:${PORT}`);
  console.log(`Admin API:    http://localhost:${PORT}/api/admin`);
  console.log(`Public API:   http://localhost:${PORT}/api/public`);
});
