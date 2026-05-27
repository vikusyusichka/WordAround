# WordAround — Gemini proxy Worker

Cloudflare Worker that hides the Gemini API key from the iOS bundle.
The iOS app stores only this Worker's URL; the key lives as a Wrangler
secret on Cloudflare's side.

## Architecture

```
iOS app (GrammarQuizAIHTTPClient)
   POST { "prompt": "..." }
        │
        ▼
Cloudflare Worker  (this directory)
   reads env.GEMINI_API_KEY
        │
        ▼
Gemini API (generativelanguage.googleapis.com)
        │
        ▼
   { "text": "..." }  back to iOS
```

## One-time setup

```bash
cd cloudflare/wordaround-gemini-proxy
npm install                 # installs Wrangler locally
npx wrangler login          # opens browser to authorize
npx wrangler secret put GEMINI_API_KEY
# paste your Gemini API key when prompted — it is uploaded directly to
# Cloudflare and never written to disk.
```

## Deploy

```bash
npx wrangler deploy
```

Wrangler prints the public URL, e.g.
`https://wordaround-gemini-proxy.<your-account>.workers.dev`.

Paste it into `GrammarQuizAIConfiguration.endpointURL` in the iOS app:

```swift
static let endpointURL: URL? = URL(string:
  "https://wordaround-gemini-proxy.<your-account>.workers.dev"
)
```

## Local development

```bash
npx wrangler dev            # exposes a local URL for testing
```

You can point the iOS app at the local URL temporarily for end-to-end
testing.

## Smoke test

```bash
curl -X POST https://wordaround-gemini-proxy.<your-account>.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Return a JSON object {\"text\":\"hello\"}."}'
```

Expected response:

```json
{ "text": "..." }
```

## Security verification

In the project root:

```bash
grep -R "AIza" WordAround           # should NOT match any Gemini key
grep -R "GEMINI_API_KEY" WordAround # should NOT match a literal value
```

The only `AIza` hit allowed inside `WordAround/` is the Firebase iOS
key in `GoogleService-Info.plist`, which is by design client-side and
restricted by Firebase Auth / Firestore rules.
