import { useCallback, useEffect, useState } from 'react';
import { api } from '../api.js';

const ICONS = [
  'groups',
  'visibility',
  'people',
  'bar_chart',
  'savings',
  'wallet',
  'security',
  'star',
];

export function AppManagePage({ appId, onBack }) {
  const [app, setApp] = useState(null);
  const [stats, setStats] = useState(null);
  const [tickets, setTickets] = useState([]);
  const [tab, setTab] = useState('onboarding');
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');

  const load = useCallback(async () => {
    const [a, s, t] = await Promise.all([
      api.app(appId),
      api.stats(appId),
      api.support(appId),
    ]);
    setApp(a);
    setStats(s);
    setTickets(t);
  }, [appId]);

  useEffect(() => {
    load().catch(console.error);
  }, [load]);

  function updateConfig(mutator) {
    setApp((prev) => {
      const next = structuredClone(prev);
      mutator(next.config);
      return next;
    });
  }

  async function save() {
    setSaving(true);
    setMsg('');
    try {
      await api.updateApp(appId, { config: app.config });
      setMsg('Saqlandi');
      await load();
    } catch (e) {
      setMsg(e.message);
    } finally {
      setSaving(false);
    }
  }

  async function ticketStatus(id, status) {
    await api.updateSupport(id, { status });
    await load();
  }

  if (!app) return <p style={{ color: 'var(--text-muted)' }}>Yuklanmoqda...</p>;

  const pages = app.config?.onboarding?.pages ?? [];
  const ads = app.config?.ads ?? { enabled: false, placements: {} };
  const banner = ads.placements?.my_groups_banner ?? {};

  return (
  <>
      <nav className="breadcrumb">
        <button type="button" onClick={onBack}>
          Ilovalar
        </button>
        <span>/</span>
        <strong>{app.name}</strong>
      </nav>

      <p style={{ color: 'var(--text-muted)', marginTop: -12, marginBottom: 20 }}>
        {app.description}
      </p>

      {stats && (
        <div className="overview-grid" style={{ marginBottom: 24 }}>
          <div className="stat-card">
            <div>
              <div className="stat-label">Hodisalar</div>
              <div className="stat-value">{stats.totalEvents}</div>
            </div>
          </div>
          <div className="stat-card">
            <div>
              <div className="stat-label">7 kun</div>
              <div className="stat-value">{stats.eventsLast7Days}</div>
            </div>
          </div>
          <div className="stat-card alert">
            <div>
              <div className="stat-label">Ochiq murojaat</div>
              <div className="stat-value">{stats.supportOpen}</div>
            </div>
          </div>
          <div className="stat-card">
            <div>
              <div className="stat-label">Reklama</div>
              <div className="stat-value" style={{ fontSize: '1.1rem' }}>
                {ads.enabled ? 'Yoniq' : "O'chiq"}
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="tabs">
        {[
          ['onboarding', 'Onboarding (4 sahifa)'],
          ['ads', 'Reklama'],
          ['support', 'Murojaatlar'],
          ['maintenance', 'Texnik holat'],
        ].map(([id, label]) => (
          <button
            key={id}
            type="button"
            className={`tab ${tab === id ? 'active' : ''}`}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'onboarding' && (
        <div className="panel-card">
          <h3>Kirishdagi 4 ta sahifa</h3>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>
            Ilova ochilganda ko&apos;rinadigan onboarding matnlari.
          </p>
          {pages.map((p, i) => (
            <div key={i} className="page-row">
              <strong>Sahifa {i + 1}</strong>
              <label>Sarlavha</label>
              <input
                value={p.title}
                onChange={(e) =>
                  updateConfig((c) => {
                    c.onboarding.pages[i].title = e.target.value;
                  })
                }
              />
              <label>Matn</label>
              <textarea
                value={p.description}
                onChange={(e) =>
                  updateConfig((c) => {
                    c.onboarding.pages[i].description = e.target.value;
                  })
                }
              />
              <label>Ikonka</label>
              <select
                value={p.icon}
                onChange={(e) =>
                  updateConfig((c) => {
                    c.onboarding.pages[i].icon = e.target.value;
                  })
                }
              >
                {ICONS.map((ic) => (
                  <option key={ic} value={ic}>
                    {ic}
                  </option>
                ))}
              </select>
            </div>
          ))}
        </div>
      )}

      {tab === 'ads' && (
        <div className="panel-card">
          <h3>Reklama sozlamalari</h3>
          <div className="toggle">
            <input
              type="checkbox"
              checked={!!ads.enabled}
              onChange={(e) =>
                updateConfig((c) => {
                  c.ads.enabled = e.target.checked;
                })
              }
            />
            <span>Reklama yoqilgan</span>
          </div>
          <h4 style={{ marginTop: 16 }}>Jamg&apos;armalar ro&apos;yxati banner</h4>
          <div className="toggle">
            <input
              type="checkbox"
              checked={!!banner.enabled}
              onChange={(e) =>
                updateConfig((c) => {
                  if (!c.ads.placements.my_groups_banner) {
                    c.ads.placements.my_groups_banner = {};
                  }
                  c.ads.placements.my_groups_banner.enabled = e.target.checked;
                })
              }
            />
            <span>Banner ko&apos;rsatish</span>
          </div>
          <label>Sarlavha</label>
          <input
            value={banner.title || ''}
            onChange={(e) =>
              updateConfig((c) => {
                c.ads.placements.my_groups_banner.title = e.target.value;
              })
            }
          />
          <label>Qisqa matn</label>
          <input
            value={banner.subtitle || ''}
            onChange={(e) =>
              updateConfig((c) => {
                c.ads.placements.my_groups_banner.subtitle = e.target.value;
              })
            }
          />
          <label>Rasm URL</label>
          <input
            value={banner.imageUrl || ''}
            onChange={(e) =>
              updateConfig((c) => {
                c.ads.placements.my_groups_banner.imageUrl = e.target.value;
              })
            }
          />
          <label>Havola URL</label>
          <input
            value={banner.linkUrl || ''}
            onChange={(e) =>
              updateConfig((c) => {
                c.ads.placements.my_groups_banner.linkUrl = e.target.value;
              })
            }
          />
          <label>Fon rangi (#hex)</label>
          <input
            value={banner.backgroundColor || '#047857'}
            onChange={(e) =>
              updateConfig((c) => {
                c.ads.placements.my_groups_banner.backgroundColor = e.target.value;
              })
            }
          />
        </div>
      )}

      {tab === 'support' && (
        <div className="panel-card">
          <h3>Murojaatlar (shu ilova)</h3>
          {tickets.length === 0 && (
            <p style={{ color: 'var(--text-muted)' }}>Hali murojaat yo&apos;q</p>
          )}
          {tickets.map((t) => (
            <div key={t.id} className="ticket">
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <strong>{t.subject}</strong>
                <span className={`badge badge-${t.status === 'open' ? 'open' : 'closed'}`}>
                  {t.status}
                </span>
              </div>
              <p style={{ margin: '8px 0', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                {t.name} · {new Date(t.createdAt).toLocaleString('uz')}
              </p>
              <p>{t.message}</p>
              {t.status === 'open' && (
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => ticketStatus(t.id, 'closed')}
                >
                  Yopildi deb belgilash
                </button>
              )}
            </div>
          ))}
        </div>
      )}

      {tab === 'maintenance' && (
        <div className="panel-card">
          <h3>Texnik ishlar rejimi</h3>
          <div className="toggle">
            <input
              type="checkbox"
              checked={!!app.config?.maintenance?.enabled}
              onChange={(e) =>
                updateConfig((c) => {
                  c.maintenance.enabled = e.target.checked;
                })
              }
            />
            <span>Ilovani vaqtincha o&apos;chirish</span>
          </div>
          <label>Xabar</label>
          <textarea
            value={app.config?.maintenance?.message || ''}
            onChange={(e) =>
              updateConfig((c) => {
                c.maintenance.message = e.target.value;
              })
            }
          />
        </div>
      )}

      {tab !== 'support' && (
        <div style={{ marginTop: 16, display: 'flex', gap: 12, alignItems: 'center' }}>
          <button type="button" className="btn-primary" onClick={save} disabled={saving}>
            {saving ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
          {msg && (
            <span className={msg === 'Saqlandi' ? 'success-msg' : 'error-msg'}>{msg}</span>
          )}
        </div>
      )}
    </>
  );
}
