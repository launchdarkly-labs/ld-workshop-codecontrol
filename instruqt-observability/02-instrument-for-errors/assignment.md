---
slug: instrument-for-errors
type: challenge
title: Instrument for Errors
teaser: Wire the observability plugins so runtime errors and shopper sessions land in LaunchDarkly.
notes:
- type: text
  contents: The personalized recommendations strategy has a bug nobody has noticed yet. Before you ship it, you'll give the app a way to tell you when something goes wrong.
tabs:
- title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- title: Shell
  type: terminal
  hostname: workstation
  workdir: /opt/ld/codecontrol/app
difficulty: basic
timelimit: 1200
enhanced_loading: null
---

# A feature nobody is watching

While you were shipping Otto, ToggleWear shipped something else: the **Recommended for You** carousel under the product grid. Have a look at it in the [ToggleWear](#tab-1) tab. It's live, it's behind two flags (`show-recommendations` turns it on; `recommendations-strategy` picks what fills it), and right now it serves the **Bestsellers** strategy: the same four popular items for everyone. Safe. Boring.

The team built a second strategy, **Personalized**, which recommends items in the same category as whatever the shopper just viewed. It works great in demos. It also has a bug nobody has found yet, and in two minutes you're going to ship it to production anyway. On purpose. Because the point of this track is what happens next.

**Observability** is the ability to see what your running application is actually doing: the errors it throws, the requests it serves, the sessions people have in it. LaunchDarkly's observability plugins collect those signals and, crucially, tag each one with the flag variations that were active when it happened. An error isn't just "an error"; it's "an error that happened to shoppers on *Personalized*." That tagging is what the rest of this track is built on.

The plugins come in two halves, and all the code is copy-paste:

- The **server plugin** (Python) records exceptions, request traces, and logs from `server.py`.
- The **browser plugins** (JavaScript) record errors and **session replays** from the shopper's browser, so you can watch exactly what a shopper saw.

# Instrument the server

Open the [Code Editor](#tab-2) tab and open `server.py`.

1. Find the `LaunchDarkly SDK setup paste block` near the top (you pasted it in the Release track) and replace the whole block, markers and all, with this version. The only change: the SDK is configured with the observability plugin.

   ```python
   # ─────────────────────────────────────────────────────────────────────────
   # LaunchDarkly SDK setup paste block
   # ─────────────────────────────────────────────────────────────────────────
   import ldclient
   from ldclient import Context
   from ldclient.config import Config
   from ldobserve import ObservabilityConfig, ObservabilityPlugin, observe

   ldclient.set_config(Config(
       os.environ["LD_SDK_KEY"],
       plugins=[
           ObservabilityPlugin(ObservabilityConfig(
               service_name="togglewear",
               service_version="workshop",
           )),
       ],
   ))
   ld_client = ldclient.get()
   # ─── End LaunchDarkly SDK setup paste block ───────────────────────────────
   ```

2. Save the file. The server reloads; give it a few seconds, since the plugin has some OpenTelemetry machinery to start.

That one plugin does a lot. It instruments the web framework so every request becomes a trace, it records any exception that escapes a request handler, and every `variation()` call you already make stamps the current trace with the flag and the variation served. You didn't add a single `try`/`except`. (If you ever want to report an error you caught yourself, that's `observe.record_exception(e)`.)

# Instrument the browser

Still in the [Code Editor](#tab-2), open `static/app.js`.

1. Find the `LaunchDarkly client SDK paste block` and replace the whole block with this version. Two changes: the client is created with the **Observability** and **SessionReplay** plugins, and the browser now evaluates `recommendations-strategy` too, so each shopper's session is tagged with the strategy they saw.

   ```js
   // ─────────────────────────────────────────────────────────────────────────
   // LaunchDarkly client SDK paste block
   // ─────────────────────────────────────────────────────────────────────────
   let ottoEnabled = false;
   let ldClient = null;

   function ldContext() {
     return {
       kind: 'user',
       key: getSessionId(),
       tier: userTier,
     };
   }

   async function initLaunchDarkly() {
     const cfg = await (await fetch('/config')).json();
     ldClient = LDClient.createClient(cfg.clientKey, ldContext(), {
       plugins: [
         new Observability.default({
           serviceName: 'togglewear-web',
           tracingOrigins: true,
         }),
         new SessionReplay.default({
           // The storefront has no personal data, so record everything. In a
           // real app leave this at the default ('strict') or use 'default'.
           privacySetting: 'none',
         }),
       ],
     });
     const refresh = () => {
       ottoEnabled = ldClient.boolVariation('release-otto', false);
       applyOttoVisibility();
       // Evaluate the strategy flag in the browser too: LaunchDarkly attributes
       // this session's errors and replay to the variation it evaluated.
       ldClient.variation('recommendations-strategy', 'bestsellers');
     };
     ldClient.on('ready', refresh);
     ldClient.on('change', refresh);
     await ldClient.start();
   }

   function onTierChanged() {
     if (ldClient) {
       ldClient.identify(ldContext()).then(() => {
         ottoEnabled = ldClient.boolVariation('release-otto', false);
         applyOttoVisibility();
         ldClient.variation('recommendations-strategy', 'bestsellers');
       });
     }
   }
   // ─── End LaunchDarkly client SDK paste block ──────────────────────────────
   ```

   <!-- VERIFY: the browser plugin accepts `serviceName` and `tracingOrigins` under these option names (docs show tracingOrigins; serviceName is inferred from the "Versioning sessions and errors" doc) -->

2. Save the file, then refresh the [ToggleWear](#tab-1) tab so the new code loads. Nothing visible changes. Your session is now being recorded.

The `privacySetting` line deserves a second look. Session replay defaults to `strict`, which blanks out all text and images in the recording so no personal data leaves the browser. ToggleWear's storefront has nothing personal on it, so we record everything and the replay will be legible. Real apps should start strict and loosen deliberately.

# Ship Personalized

Now the release. Go to the [LaunchDarkly](#tab-0) tab and open the **recommendations-strategy** flag.

1. Edit the **default rule**, which serves **Bestsellers**.
2. Change it to serve **Personalized** and click **Review and save**.
   <!-- VERIFY: save flow label; whether the Serve menu offers a plain variation alongside the rollout options on the default rule -->

That's a plain variation change: no ramp, no guard, everyone at once. It's exactly how you shipped things before this workshop, and that's deliberate. Hold the thought.

# Break it

Switch to the [ToggleWear](#tab-1) tab.

1. Click any product card. The carousel re-renders with items from that product's category. Personalized is working.
2. Now click the **Rollout Tote**.
3. The carousel disappears.

Here's why: the tote is the one product in the catalog with no `category` field, and the Personalized strategy reads that field without checking. The server throws, the request fails with a 500, and the frontend quietly hides the carousel rather than crash the page. A shopper would never know anything went wrong. They'd just... not see recommendations. Click a few other products, then the tote again, to collect a couple of occurrences.

You're not alone in there, either: the synthetic shoppers from the Release track are browsing the carousel too, and about a third of them view the tote. The bug is firing steadily in the background.

# See it

Back in the [LaunchDarkly](#tab-0) tab, open the **Telemetry** section in the left sidebar and click **Errors**.
<!-- VERIFY: sidebar section name ("Telemetry") and the Errors list location in the current navigation -->

Within a minute or so, a new error appears: a `KeyError: 'category'` from the `togglewear` service. Click it. You'll see how many times it has occurred, how many users it affected, the first and last time it was seen, and under **Instances**, the Python stack trace pointing at the exact line in `_recommend_personalized`.

![The first error arrives](../assets/obs-02-first-error.png)

That error has been happening to real shoppers since the moment you saved the flag. The difference now is that you can see it. In the next lab you'll see who it happened to, and watch it happen.

Click **Check**, then **Next**.
