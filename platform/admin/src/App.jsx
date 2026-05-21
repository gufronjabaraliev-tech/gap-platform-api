import { useEffect, useMemo, useState } from 'react';
import { api, clearToken, getToken } from './api.js';
import { Layout } from './components/Layout.jsx';
import { LoginPage } from './pages/LoginPage.jsx';
import { DashboardPage } from './pages/DashboardPage.jsx';
import { AppsPage } from './pages/AppsPage.jsx';
import { AppManagePage } from './pages/AppManagePage.jsx';
import { SupportPage } from './pages/SupportPage.jsx';
import { ReportingPage } from './pages/ReportingPage.jsx';

export default function App() {
  const [authed, setAuthed] = useState(!!getToken());
  const [admin, setAdmin] = useState(null);
  const [page, setPage] = useState('dashboard');
  const [selectedApp, setSelectedApp] = useState(null);
  const [apps, setApps] = useState([]);
  const [search, setSearch] = useState('');
  const [notifCount, setNotifCount] = useState(0);

  useEffect(() => {
    if (!getToken()) return;
    api
      .me()
      .then((a) => {
        setAdmin(a);
        setAuthed(true);
      })
      .catch(() => {
        clearToken();
        setAuthed(false);
      });
  }, []);

  useEffect(() => {
    if (!authed) return;
    api.apps().then(setApps).catch(console.error);
  }, [authed, page, selectedApp]);

  useEffect(() => {
    if (!authed || !apps.length) return;
    (async () => {
      let open = 0;
      for (const a of apps) {
        try {
          const s = await api.stats(a.id);
          open += s.supportOpen || 0;
        } catch {
          /* ignore */
        }
      }
      setNotifCount(open);
    })();
  }, [authed, apps]);

  const filteredApps = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return apps;
    return apps.filter(
      (a) =>
        a.name.toLowerCase().includes(q) ||
        a.id.toLowerCase().includes(q) ||
        (a.description || '').toLowerCase().includes(q),
    );
  }, [apps, search]);

  function logout() {
    clearToken();
    setAuthed(false);
    setAdmin(null);
    setSelectedApp(null);
    setPage('dashboard');
  }

  function navigate(p) {
    setPage(p);
    setSelectedApp(null);
  }

  if (!authed) {
    return (
      <LoginPage
        onLogin={() => {
          api.me().then((a) => {
            setAdmin(a);
            setAuthed(true);
          });
        }}
      />
    );
  }

  let content;
  if (selectedApp) {
    content = (
      <AppManagePage appId={selectedApp} onBack={() => setSelectedApp(null)} />
    );
  } else if (page === 'dashboard') {
    content = <DashboardPage />;
  } else if (page === 'apps') {
    content = <AppsPage apps={filteredApps} onOpenApp={setSelectedApp} />;
  } else if (page === 'reporting') {
    content = <ReportingPage apps={apps} />;
  } else if (page === 'support') {
    content = <SupportPage apps={apps} />;
  } else {
    content = <DashboardPage />;
  }

  return (
    <Layout
      admin={admin}
      page={selectedApp ? 'apps' : page}
      onNavigate={navigate}
      onLogout={logout}
      search={search}
      onSearchChange={setSearch}
      notifCount={notifCount}
    >
      {content}
    </Layout>
  );
}
