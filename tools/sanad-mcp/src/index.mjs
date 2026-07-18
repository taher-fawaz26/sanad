/**
 * SANAD MCP Server — development tool.
 *
 * Provides Claude Code with authenticated access to the SANAD backend:
 *   - Live OpenAPI specification discovery
 *   - Authenticated API request execution
 *   - Automatic token lifecycle (login → cache → refresh → re-login)
 *
 * NOT part of the Flutter application. Never import this from Dart packages.
 *
 * Usage:
 *   node tools/sanad-mcp/src/index.mjs
 *
 * Required environment variables:
 *   SANAD_DEV_EMAIL     — dev account email/phone identifier
 *   SANAD_DEV_PASSWORD  — dev account password
 *
 * Optional:
 *   SANAD_MCP_ALLOW_MUTATIONS=true   — also expose POST/PUT/PATCH/DELETE tools
 *                                       (default: GET only for safety)
 */

import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import path from 'path';

// Load .env from tools/sanad-mcp/.env if present
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const envPath = path.resolve(__dirname, '..', '.env');

// Dynamically load dotenv (it's a CJS module)
const require = createRequire(import.meta.url);
try {
  const dotenv = require('dotenv');
  dotenv.config({ path: envPath });
} catch {
  // dotenv not critical — env vars may already be set externally
}

import { OpenAPIServer } from '@ivotoby/openapi-mcp-server';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

import { SanadAuthProvider } from './sanad-auth.mjs';
import { loadLiveSpec } from './spec-loader.mjs';

// ── Safety: default to read-only ────────────────────────────────────────────

const allowMutations = process.env.SANAD_MCP_ALLOW_MUTATIONS === 'true';
const includeOperations = allowMutations
  ? ['get', 'post', 'put', 'patch', 'delete']
  : ['get'];

if (allowMutations) {
  process.stderr.write(
    '[SanadMCP] SANAD_MCP_ALLOW_MUTATIONS=true — POST/PUT/PATCH/DELETE exposed.\n',
  );
} else {
  process.stderr.write(
    '[SanadMCP] Read-only mode (GET only). ' +
    'Set SANAD_MCP_ALLOW_MUTATIONS=true to expose mutating endpoints.\n',
  );
}

// ── Bootstrap ────────────────────────────────────────────────────────────────

process.stderr.write('[SanadMCP] Starting SANAD MCP server...\n');

const authProvider = new SanadAuthProvider();

let specContent;
try {
  specContent = await loadLiveSpec(authProvider);
} catch (err) {
  process.stderr.write(`${err.message}\n`);
  process.exit(1);
}

const server = new OpenAPIServer({
  name: 'sanad-api',
  version: '1.0.0',
  apiBaseUrl: 'https://dev-api.trysanad.us/api/v1',
  openApiSpec: 'inline',
  specInputMethod: 'inline',
  inlineSpecContent: specContent,
  authProvider,
  transportType: 'stdio',
  toolsMode: 'all',
  includeOperations,
  verbose: false,
});

const transport = new StdioServerTransport();
await server.start(transport);

process.stderr.write('[SanadMCP] Server running on stdio. Ready for Claude Code.\n');
