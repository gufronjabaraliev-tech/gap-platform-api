const TOKEN_KEY = 'gap_platform_token';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

async function request(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(path, { ...options, headers });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `HTTP ${res.status}`);
  }
  return data;
}

export const api = {
  login: (email, password) =>
    request('/api/admin/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),
  me: () => request('/api/admin/me'),
  apps: () => request('/api/admin/apps'),
  app: (id) => request(`/api/admin/apps/${id}`),
  updateApp: (id, body) =>
    request(`/api/admin/apps/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  stats: (id) => request(`/api/admin/apps/${id}/stats`),
  support: (id) => request(`/api/admin/apps/${id}/support`),
  updateSupport: (ticketId, body) =>
    request(`/api/admin/support/${ticketId}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
};
