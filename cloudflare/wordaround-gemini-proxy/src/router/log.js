/**
 * Tiny debug logger for the AI Provider Router.
 *
 * Everything written here lands in `wrangler tail`. We NEVER log API keys,
 * bearer tokens, Azure tokens, or full user content — only task metadata,
 * provider names, status codes, and prompt *lengths*.
 */

const PREFIX = "[AIRouter]";

export function logDebug(...args) {
  // Workers log to the platform; surfaced via `wrangler tail`.
  console.log(PREFIX, ...args);
}

export function logWarn(...args) {
  console.warn(PREFIX, ...args);
}
