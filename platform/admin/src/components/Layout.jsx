import { Sidebar } from './Sidebar.jsx';
import { Header } from './Header.jsx';

export function Layout({
  admin,
  page,
  onNavigate,
  onLogout,
  search,
  onSearchChange,
  notifCount,
  children,
}) {
  const firstName = admin?.name?.split(' ')[0] || 'Admin';

  return (
    <div className="app-shell">
      <Sidebar
        page={page}
        admin={admin}
        onNavigate={onNavigate}
        onLogout={onLogout}
      />
      <div className="main-area">
        <Header
          greeting={`Welcome ${firstName} !`}
          subtitle="Invest Group — ilovalar boshqaruvi"
          search={search}
          onSearchChange={onSearchChange}
          notifCount={notifCount}
        />
        <main className="page-content">{children}</main>
      </div>
    </div>
  );
}

