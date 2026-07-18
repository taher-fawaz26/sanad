/**
 * Loads the SANAD OpenAPI spec from the live backend.
 *
 * Strategy (tried in order):
 *   1. GET /api/docs-json with Referer header (avoids hotlink protection)
 *   2. GET /api/docs-json with Bearer token (in case endpoint requires auth)
 *
 * Never falls back to a local file — the live spec is the source of truth.
 */

const SPEC_URL = 'https://dev-api.trysanad.us/api/docs-json';
const SWAGGER_UI_URL = 'https://dev-api.trysanad.us/api/docs';

export async function loadLiveSpec(authProvider) {
  // Attempt 1: no auth, just Referer (mimics browser Swagger UI XHR)
  process.stderr.write(`[SpecLoader] Fetching ${SPEC_URL} (attempt 1: Referer only)...\n`);
  const r1 = await fetch(SPEC_URL, {
    headers: {
      Accept: 'application/json',
      Referer: SWAGGER_UI_URL,
      'User-Agent': 'Mozilla/5.0 (compatible; SanadMCP/1.0)',
    },
  });

  if (r1.ok) {
    process.stderr.write('[SpecLoader] Spec loaded without authentication.\n');
    return await r1.text();
  }

  process.stderr.write(
    `[SpecLoader] Attempt 1 failed (${r1.status}). Trying with Bearer token...\n`,
  );

  // Attempt 2: with Bearer token
  const authHeaders = await authProvider.getAuthHeaders();
  const r2 = await fetch(SPEC_URL, {
    headers: {
      Accept: 'application/json',
      Referer: SWAGGER_UI_URL,
      'User-Agent': 'Mozilla/5.0 (compatible; SanadMCP/1.0)',
      ...authHeaders,
    },
  });

  if (r2.ok) {
    process.stderr.write('[SpecLoader] Spec loaded with Bearer token.\n');
    return await r2.text();
  }

  throw new Error(
    `[SpecLoader] Cannot fetch OpenAPI spec from ${SPEC_URL}.\n` +
    `  Attempt 1 (Referer): ${r1.status}\n` +
    `  Attempt 2 (Bearer):  ${r2.status}\n\n` +
    `  Ask the backend team to expose ${SPEC_URL} without IP restrictions, ` +
    `or make it accessible with a valid Bearer token.`,
  );
}
