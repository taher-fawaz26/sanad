/**
 * SanadAuthProvider — development-only authenticated provider for SANAD API.
 *
 * Lifecycle:
 *   getAuthHeaders() → login if no token, refresh if expired → return Bearer header
 *   handleAuthError(401) → refresh, if fails → re-login → return true (retry)
 *
 * Login mechanism (backend contract as of the login/verify auth refactor):
 *   #doLogin() → #doRequestOtp() → #doVerifyOtp() → #doStoreSession()
 *   1. POST REQUEST_OTP_PATH  { email }         — triggers OTP issuance server-side
 *   2. POST VERIFY_OTP_PATH   { email, otp }    — returns
 *      { accessToken, refreshToken, status } where `status` is one of
 *      "ACTIVE" | "SUSPENDED" | "INCOMPLETE". Tokens are only populated when
 *      `status === "ACTIVE"`; any other status is treated as a login failure.
 *
 * Security:
 *   - Reads credentials from environment variables only
 *   - Tokens stored in process memory only (never persisted)
 *   - Credentials and full tokens never logged
 */

const BASE_URL = 'https://dev-api.trysanad.us/api/v1';
const REQUEST_OTP_PATH = `${BASE_URL}/auth/login`;
const VERIFY_OTP_PATH = `${BASE_URL}/auth/login/verify`;
const REFRESH_PATH = `${BASE_URL}/auth/refresh`;

// Dev-only OTP fallback — overridable so CI can inject its own value.
const DEFAULT_DEV_OTP = '055555';

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

  /**
   * Full login sequence: request an OTP, verify it, cache the returned
   * session. Split into small steps so each HTTP call has its own
   * failure message and can be reasoned about independently.
   */
  async #doLogin() {
    const email = process.env.SANAD_DEV_EMAIL;
    if (!email) {
      throw new Error(
        '[SanadAuth] SANAD_DEV_EMAIL must be set. ' +
        'Copy tools/sanad-mcp/.env.example to tools/sanad-mcp/.env and fill in values.',
      );
    }

    process.stderr.write('[SanadAuth] Logging in...\n');

    const promise = (async () => {
      await this.#doRequestOtp(email);
      const { accessToken, refreshToken } = await this.#doVerifyOtp(email);
      this.#doStoreSession(accessToken, refreshToken);
    })();

    this.#loginInFlight = promise.finally(() => {
      this.#loginInFlight = null;
    });

    await this.#loginInFlight;
  }

  /** Step 1 — POST REQUEST_OTP_PATH { email }. Response carries no tokens. */
  async #doRequestOtp(email) {
    process.stderr.write('[SanadAuth] Requesting OTP...\n');

    const res = await fetch(REQUEST_OTP_PATH, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(
        `[SanadAuth] OTP request failed ${res.status}: ${JSON.stringify(body)}`,
      );
    }

    process.stderr.write('[SanadAuth] OTP requested.\n');
  }

  /**
   * Step 2 — POST VERIFY_OTP_PATH { email, otp }. Returns
   * { accessToken, refreshToken, status }. `SANAD_DEV_OTP` lets CI override
   * the fixed dev OTP. Tokens are only meaningful when `status === "ACTIVE"`;
   * "SUSPENDED"/"INCOMPLETE" accounts have no usable session.
   */
  async #doVerifyOtp(email) {
    process.stderr.write('[SanadAuth] Verifying OTP...\n');

    const otp = process.env.SANAD_DEV_OTP || DEFAULT_DEV_OTP;
    const res = await fetch(VERIFY_OTP_PATH, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, otp }),
    });

    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(
        `[SanadAuth] OTP verification failed ${res.status}: ${JSON.stringify(body)}`,
      );
    }

    if (body.status !== 'ACTIVE') {
      throw new Error(
        `[SanadAuth] Login did not complete: account status is "${body.status}" (expected "ACTIVE").`,
      );
    }

    process.stderr.write('[SanadAuth] Authentication successful.\n');
    return { accessToken: body.accessToken, refreshToken: body.refreshToken };
  }

  /** Step 3 — cache the session (unchanged token-cache mechanism). */
  #doStoreSession(accessToken, refreshToken) {
    this.#storeTokens(accessToken, refreshToken);
    process.stderr.write('[SanadAuth] Login successful. Token cached in memory.\n');
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
