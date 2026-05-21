export function AppsPage({ apps, onOpenApp }) {
  if (!apps.length) {
    return (
      <div className="empty-state">
        <p>Hali ilova qo&apos;shilmagan</p>
      </div>
    );
  }

  return (
    <>
      <h2 className="section-title">Ilovalar</h2>
      <p style={{ color: 'var(--text-muted)', marginTop: -8, marginBottom: 20 }}>
        Har bir ilovani boshqaring — onboarding, reklama, murojaat va statistika.
      </p>
      <div className="apps-grid">
        {apps.map((a) => (
          <article
            key={a.id}
            className="app-card"
            role="button"
            tabIndex={0}
            onClick={() => onOpenApp(a.id)}
            onKeyDown={(e) => e.key === 'Enter' && onOpenApp(a.id)}
          >
            <h3>{a.name}</h3>
            <p>{a.description || a.id}</p>
            <span className={`app-status ${a.isActive ? '' : 'inactive'}`}>
              <span className="status-dot" />
              {a.isActive ? 'Faol' : 'Nofaol'}
            </span>
          </article>
        ))}
      </div>
    </>
  );
}
