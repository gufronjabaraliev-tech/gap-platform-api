import { useEffect, useState } from 'react';
import { api } from '../api.js';
import { IconTrend } from '../components/Icons.jsx';

export function DashboardPage() {
  const [data, setData] = useState(null);

  useEffect(() => {
    async function load() {
      const apps = await api.apps();
      const statsList = await Promise.all(
        apps.map(async (a) => {
          try {
            const s = await api.stats(a.id);
            return { app: a, stats: s };
          } catch {
            return { app: a, stats: null };
          }
        }),
      );
      const totalEvents = statsList.reduce((n, x) => n + (x.stats?.totalEvents || 0), 0);
      const events7 = statsList.reduce((n, x) => n + (x.stats?.eventsLast7Days || 0), 0);
      const supportOpen = statsList.reduce((n, x) => n + (x.stats?.supportOpen || 0), 0);
      const activeApps = apps.filter((a) => a.isActive).length;
      setData({ apps, statsList, totalEvents, events7, supportOpen, activeApps });
    }
    load().catch(console.error);
  }, []);

  if (!data) {
    return <p style={{ color: 'var(--text-muted)' }}>Yuklanmoqda...</p>;
  }

  const maxEvents = Math.max(
    ...data.statsList.map((x) => x.stats?.totalEvents || 0),
    1,
  );

  const months = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn'];
  const barHeights = [45, 62, 55, 78, 68, data.events7 > 0 ? Math.min(95, 40 + data.events7 * 3) : 50];

  return (
    <>
      <h2 className="section-title">Overview</h2>
      <div className="overview-grid">
        <div className="stat-card">
          <div>
            <div className="stat-label">Ilovalar</div>
            <div className="stat-value">{data.apps.length}</div>
          </div>
          <div className="stat-icon">📱</div>
        </div>
        <div className="stat-card">
          <div>
            <div className="stat-label">Faol ilovalar</div>
            <div className="stat-value">{data.activeApps}</div>
          </div>
          <div className="stat-icon">✓</div>
        </div>
        <div className="stat-card">
          <div>
            <div className="stat-label">Hodisalar (jami)</div>
            <div className="stat-value">{data.totalEvents.toLocaleString()}</div>
          </div>
          <IconTrend />
        </div>
        <div className="stat-card alert">
          <div>
            <div className="stat-label">Ochiq murojaat</div>
            <div className="stat-value">{data.supportOpen}</div>
          </div>
          <div className="stat-icon">!</div>
        </div>
      </div>

      <div className="dashboard-row">
        <div className="panel-card">
          <h3>Foydalanuvchi faolligi</h3>
          <div className="users-highlight">
            <div className="stat-icon" style={{ width: 56, height: 56, fontSize: '1.5rem' }}>
              👥
            </div>
            <div>
              <div className="big-num">
                {data.events7} <span>7 kun</span>
              </div>
              <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                Ilova ochilishlari
              </div>
            </div>
          </div>
        </div>

        <div className="panel-card">
          <h3>Hodisalar taqsimoti</h3>
          <div className="pie-wrap">
            <div
              className="pie-chart"
              style={{
                background: `conic-gradient(
                  var(--accent) 0deg ${Math.min(320, (data.events7 / Math.max(data.totalEvents, 1)) * 360)}deg,
                  #334155 ${Math.min(320, (data.events7 / Math.max(data.totalEvents, 1)) * 360)}deg 360deg
                )`,
              }}
            />
            <ul className="pie-legend">
              <li>
                <span className="dot" style={{ background: 'var(--accent)' }} />
                So&apos;nggi 7 kun
              </li>
              <li>
                <span className="dot" style={{ background: '#334155' }} />
                Jami bazadan
              </li>
            </ul>
          </div>
        </div>

        <div className="panel-card">
          <h3>Ilovalar bo&apos;yicha</h3>
          <ul className="rank-list">
            {data.statsList.map(({ app, stats }) => (
              <li key={app.id} className="rank-item">
                <div className="rank-header">
                  <span>{app.name}</span>
                  <span>{stats?.totalEvents ?? 0}</span>
                </div>
                <div className="rank-bar">
                  <div
                    className="rank-fill"
                    style={{
                      width: `${((stats?.totalEvents || 0) / maxEvents) * 100}%`,
                    }}
                  />
                </div>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="panel-card chart-panel">
        <h3>Faollik (so&apos;nggi oylar)</h3>
        <div className="chart-area">
          {months.map((m, i) => (
            <div key={m} className="chart-bar-wrap">
              <div className="chart-bar" style={{ height: `${barHeights[i]}%` }} />
              <span className="chart-label">{m}</span>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
