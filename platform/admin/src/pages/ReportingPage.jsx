import { useEffect, useState } from 'react';
import { api } from '../api.js';

export function ReportingPage({ apps }) {
  const [rows, setRows] = useState([]);

  useEffect(() => {
    async function load() {
      const list = [];
      for (const a of apps) {
        try {
          const s = await api.stats(a.id);
          list.push({ app: a, stats: s });
        } catch {
          list.push({ app: a, stats: null });
        }
      }
      setRows(list);
    }
    if (apps.length) load().catch(console.error);
  }, [apps]);

  return (
    <>
      <h2 className="section-title">Hisobotlar</h2>
      <div className="panel-card">
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
          <thead>
            <tr style={{ textAlign: 'left', color: 'var(--text-muted)' }}>
              <th style={{ padding: '10px 8px' }}>Ilova</th>
              <th style={{ padding: '10px 8px' }}>Hodisalar</th>
              <th style={{ padding: '10px 8px' }}>7 kun</th>
              <th style={{ padding: '10px 8px' }}>Murojaat</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(({ app, stats }) => (
              <tr key={app.id} style={{ borderTop: '1px solid var(--border)' }}>
                <td style={{ padding: '12px 8px', fontWeight: 600 }}>{app.name}</td>
                <td style={{ padding: '12px 8px' }}>{stats?.totalEvents ?? '—'}</td>
                <td style={{ padding: '12px 8px' }}>{stats?.eventsLast7Days ?? '—'}</td>
                <td style={{ padding: '12px 8px' }}>{stats?.supportOpen ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {rows.length === 0 && (
          <p style={{ color: 'var(--text-muted)', padding: 16 }}>Ma&apos;lumot yo&apos;q</p>
        )}
      </div>
    </>
  );
}
