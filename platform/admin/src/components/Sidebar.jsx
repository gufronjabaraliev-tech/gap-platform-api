import {
  IconApps,
  IconDashboard,
  IconLogout,
  IconReport,
  IconSupport,
} from './Icons.jsx';

const NAV = [
  { id: 'dashboard', label: 'Dashboard', Icon: IconDashboard },
  { id: 'apps', label: 'Ilovalar', Icon: IconApps },
  { id: 'reporting', label: 'Hisobotlar', Icon: IconReport },
  { id: 'support', label: 'Murojaat', Icon: IconSupport },
];

export function Sidebar({ page, admin, onNavigate, onLogout }) {
  const initials = (admin?.name || 'A')
    .split(' ')
    .map((w) => w[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <span>Platform</span>
        <h2>Invest Group</h2>
      </div>

      <div className="sidebar-profile">
        <div className="avatar">{initials}</div>
        <div>
          <div className="profile-name">{admin?.name || 'Administrator'}</div>
          <div className="profile-email">{admin?.email || ''}</div>
        </div>
      </div>

      <nav className="sidebar-nav">
        {NAV.map(({ id, label, Icon }) => (
          <button
            key={id}
            type="button"
            className={`nav-link ${page === id ? 'active' : ''}`}
            onClick={() => onNavigate(id)}
          >
            <Icon />
            {label}
          </button>
        ))}
      </nav>

      <div className="sidebar-footer">
        <button type="button" className="btn-logout" onClick={onLogout}>
          <IconLogout />
          Chiqish
        </button>
      </div>
    </aside>
  );
}
