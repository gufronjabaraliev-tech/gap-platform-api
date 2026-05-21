import { IconBell, IconSearch } from './Icons.jsx';

export function Header({ greeting, subtitle, search, onSearchChange, notifCount }) {
  return (
    <header className="top-header">
      <div className="header-greeting">
        <h1>{greeting}</h1>
        <p>{subtitle}</p>
      </div>
      <div className="header-search">
        <span className="search-icon">
          <IconSearch />
        </span>
        <input
          type="search"
          placeholder="Qidirish..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
        />
      </div>
      <div className="header-actions">
        <button type="button" className="icon-btn" title="Bildirishnomalar">
          <IconBell />
          {notifCount > 0 && <span className="notif-dot" />}
        </button>
      </div>
    </header>
  );
}
