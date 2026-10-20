# Vendored browser bundles

Everything the browser needs from LaunchDarkly is served from this directory
so labs never depend on a CDN at run time.

| File | Package | Global exposed |
|---|---|---|
| `ldclient-v4.9.1.min.js` | `@launchdarkly/js-client-sdk@4.9.1` (self-built IIFE) | `LDClient` (`LDClient.createClient`, `LDClient.basicLogger`) |
| `ld-observability-v1.2.1.umd.js` | `@launchdarkly/observability@1.2.1` (published UMD) | `Observability` (`.default` = plugin class, `.LDObserve` = record API) |
| `ld-session-replay-v1.2.1.umd.js` | `@launchdarkly/session-replay@1.2.1` (published UMD) | `SessionReplay` (`.default` = plugin class, `.LDRecord` = recording API) |

## Client SDK (self-built)

The published `@launchdarkly/js-client-sdk` ships only CJS/ESM — no
browser-global build — so we bundle one (decision recorded in `DECISIONS.md`).
To rebuild (e.g. for an SDK upgrade):

```bash
mkdir /tmp/ld-bundle && cd /tmp/ld-bundle
npm init -y
npm install @launchdarkly/js-client-sdk@<version> esbuild
echo "export * from '@launchdarkly/js-client-sdk';" > entry.js
npx esbuild entry.js --bundle --format=iife --global-name=LDClient \
  --minify --outfile=ldclient-v<version>.min.js
```

## Observability plugins (published UMD builds)

The observability and session-replay plugins DO publish UMD builds, so these
are straight copies of `dist/index.umd.js` from the npm package (fetched via
jsDelivr on 2026-10-19). To upgrade:

```bash
curl -fsSL https://cdn.jsdelivr.net/npm/@launchdarkly/observability@<version>/dist/index.umd.js \
  -o ld-observability-v<version>.umd.js
curl -fsSL https://cdn.jsdelivr.net/npm/@launchdarkly/session-replay@<version>/dist/index.umd.js \
  -o ld-session-replay-v<version>.umd.js
```

They are used by the Observability track's instrumentation lab, which passes
`new Observability.default({...})` and `new SessionReplay.default({...})` in
the `plugins` option of `LDClient.createClient`. Loading them on every track
is harmless: until a plugin instance is passed to the client they only define
globals.

After any change, update the `<script>` tags in `app/static/index.html`.
