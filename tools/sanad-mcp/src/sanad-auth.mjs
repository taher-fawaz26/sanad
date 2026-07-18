/**
 * SanadAuthProvider — development-only authenticated provider for SANAD API.
 *
 * Lifecycle:
 *   getAuthHeaders() → login if no token, refresh if expired → return Bearer header
 *   handleAuthError(401) → refresh, if fails → re-login → return true (retry)
 *
 * Security:
 *   - Reads credentials from environment variables only
 *   - Tokens stored in process memory only (never persisted)
 *   - Credentials and full tokens never logged
 */

const BASE_URL = 'https://dev-api.trysanad.us/api/v1';
const LOGIN_PATH = `${BASE_URL}/auth/login`;
const REFRESH_PATH = `${BASE_URL}/auth/refresh`;

// Refresh 60 seconds before the JWT exp to avoid races
const EXPIRY_BUFFER_MS = 60_000;

export class SanadAuthProvider {
  #accessToken = null;
  #refreshToken = null;
  #expiresAt = null;
  #loginInFlight = null;

  async getAuthHeaders() {
    await this.#ensureValidToken();
    return { Authorization: `Bearer ${this.#accessToken}` };
  }

  async handleAuthError(error) {
    if (error.response?.status !== 401 && error.response?.status !== 403) {
      return false;
    }
    try {
      if (this.#refreshToken) {
        await this.#doRefresh();
      } else {
        await this.#doLogin();
      }
      return true;
    } catch {
      try {
        await this.#doLogin();
        return true;
      } catch {
        return false;
      }
    }
  }

  // ── internals ──────────────────────────────────────────────────────────────

  async #ensureValidToken() {
    if (this.#accessToken && !this.#isExpired()) return;

    if (this.#loginInFlight) {
      await this.#loginInFlight;
      return;
    }

    if (this.#accessToken && this.#isExpired() && this.#refreshToken) {
      try {
        await this.#doRefresh();
        return;
      } catch {
        // fall through to login
      }
    }

    await this.#doLogin();
  }

  async #doLogin() {
    const email = process.env.SANAD_DEV_EMAIL;
    const password = process.env.SANAD_DEV_PASSWORD;
    if (!email || !password) {
      throw new Error(
        '[SanadAuth] SANAD_DEV_EMAIL and SANAD_DEV_PASSWORD must be set. ' +
        'Copy tools/sanad-mcp/.env.example to tools/sanad-mcp/.env and fill in values.',
      );
    }

    process.stderr.write('[SanadAuth] Logging in...\n');
    const promise = fetch(LOGIN_PATH, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier: email, password }),
    });

    this.#loginInFlight = promise.then(async (res) => {
      const body = await res.json();
      if (!res.ok) {
        throw new Error(`[SanadAuth] Login failed ${res.status}: ${JSON.stringify(body)}`);
      }
      this.#storeTokens(body.accessToken, body.refreshToken);
      process.stderr.write('[SanadAuth] Login successful. Token cached in memory.\n');
    }).finally(() => {
      this.#loginInFlight = null;
    });

    await this.#loginInFlight;
  }

  async #doRefresh() {
    process.stderr.write('[SanadAuth] Refreshing token...\n');
    const res = await fetch(REFRESH_PATH, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: this.#refreshToken }),
    });
    const body = await res.json();
    if (!res.ok) {
      throw new Error(`[SanadAuth] Refresh failed ${res.status}: ${JSON.stringify(body)}`);
    }
    this.#storeTokens(body.accessToken, body.refreshToken);
    process.stderr.write('[SanadAuth] Token refreshed.\n');
  }

  #storeTokens(accessToken, refreshToken) {
    this.#accessToken = accessToken;
    this.#refreshToken = refreshToken;
    this.#expiresAt = this.#decodeExpiry(accessToken);
  }

  #decodeExpiry(token) {
    try {
      const payload = JSON.parse(
        Buffer.from(token.split('.')[1], 'base64url').toString('utf8'),
      );
      if (payload.exp) return payload.exp * 1000 - EXPIRY_BUFFER_MS;
    } catch {
      // ignore malformed JWT — fall back to 50-minute window
    }
    return Date.now() + 50 * 60 * 1000;
  }

  #isExpired() {
    return this.#expiresAt !== null && Date.now() >= this.#expiresAt;
  }
}
