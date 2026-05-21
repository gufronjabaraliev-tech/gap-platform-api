import { useEffect, useState } from 'react';
import { api } from '../api.js';

export function SupportPage({ apps }) {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const all = [];
      for (const a of apps) {
        const list = await api.support(a.id);
        all.push(...list.map((t) => ({ ...t, appName: a.name })));
      }
      all.sort((x, y) => new Date(y.createdAt) - new Date(x.createdAt));
      setTickets(all);
      setLoading(false);
    }
    if (apps.length) load().catch(console.error);
    else setLoading(false);
  }, [apps]);

  async function closeTicket(id) {
    await api.updateSupport(id, { status: 'closed' });
    setTickets((prev) =>
      prev.map((t) => (t.id === id ? { ...t, status: 'closed' } : t)),
    );
  }

  if (loading) return <p style={{ color: 'var(--text-muted)' }}>Yuklanmoqda...</p>;

  return (
    <>
      <h2 className="section-title">Murojaatlar</h2>
      <div className="panel-card">
        {tickets.length === 0 ? (
          <p style={{ color: 'var(--text-muted)' }}>Hali murojaat yo&apos;q</p>
        ) : (
          tickets.map((t) => (
            <div key={t.id} className="ticket">
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
                <strong>{t.subject}</strong>
                <span className={`badge badge-${t.status === 'open' ? 'open' : 'closed'}`}>
                  {t.status}
                </span>
              </div>
              <p style={{ margin: '6px 0', fontSize: '0.82rem', color: 'var(--accent)' }}>
                {t.appName}
              </p>
              <p style={{ margin: '6px 0', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                {t.name} · {new Date(t.createdAt).toLocaleString('uz')}
              </p>
              <p>{t.message}</p>
              {t.status === 'open' && (
                <button type="button" className="btn-secondary" onClick={() => closeTicket(t.id)}>
                  Yopildi
                </button>
              )}
            </div>
          ))
        )}
      </div>
    </>
  );
}
