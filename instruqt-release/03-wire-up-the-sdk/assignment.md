---
slug: wire-up-the-sdk
type: challenge
title: Wire Up the SDK
teaser: Connect ToggleWear to LaunchDarkly and bring Otto to the page.
notes:
- type: text
  contents: A flag on its own doesn't do anything. In this challenge you'll
    wire the LaunchDarkly SDKs into ToggleWear so your new flag actually
    controls whether Otto appears.
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

# From flag to feature

You created `release-otto`, but the app has never heard of it. That's the **SDK**'s job: a small library that connects your code to LaunchDarkly, keeps flag values up to date in real time, and answers one question: "for this visitor, is this flag on?" LaunchDarkly calls that visitor a **context**, a description of who's using your app right now. Our contexts start as just a key; they get smarter in the next lab.

ToggleWear uses two SDKs, and you'll wire both:

- The **server-side SDK** (Python) decides whether Otto answers chat requests.
- The **client-side SDK** (JavaScript, in the browser) decides whether the Otto widget appears on the page at all.

All the code is copy-paste. The app's files have clearly marked stub blocks; each paste replaces one stub, markers included. Your SDK keys were already placed in the app's environment when the lab started — the pasted code just reads them.

# Wire the server

Open the [Code Editor](#tab-2) tab and open `server.py`.

1. Find the stub near the top that ends with `ld_client = None` (look for the comment `LaunchDarkly SDK setup paste block`). Replace the whole block, markers and all, with:

   ```python
   # ─────────────────────────────────────────────────────────────────────────
   # LaunchDarkly SDK setup paste block
   # ─────────────────────────────────────────────────────────────────────────
   import ldclient
   from ldclient import Context
   from ldclient.config import Config

   ldclient.set_config(Config(os.environ["LD_SDK_KEY"]))
   ld_client = ldclient.get()
   # ─── End LaunchDarkly SDK setup paste block ───────────────────────────────
   ```

2. Find the `build_context` function and its stub (`LaunchDarkly context paste block`) and replace the block with:

   ```python
       # ─────────────────────────────────────────────────────────────────────
       # LaunchDarkly context paste block
       # ─────────────────────────────────────────────────────────────────────
       return Context.builder(user_key).kind("user").build()
       # ─── End LaunchDarkly context paste block ─────────────────────────────
   ```

3. Find the stub inside the `/chat` handler (`LaunchDarkly Otto flag paste block`) and replace it with the actual flag evaluation:

   ```python
       # ─────────────────────────────────────────────────────────────────────
       # LaunchDarkly Otto flag paste block
       # ─────────────────────────────────────────────────────────────────────
       context = build_context(req.session_id, req.user_tier)
       otto_enabled = ld_client.variation("release-otto", context, False)
       # ─── End LaunchDarkly Otto flag paste block ───────────────────────────
   ```

4. Save the file. The server reloads automatically on save.

That last paste is the heart of it: `variation()` asks LaunchDarkly "is `release-otto` on for this context?" and falls back to `False` if anything goes wrong. Off by default is what makes flags safe.

# Wire the browser

Still in the [Code Editor](#tab-2), open `static/app.js`.

1. Find the stub near the top (`LaunchDarkly client SDK paste block`) and replace the whole block with:

   ```js
   // ─────────────────────────────────────────────────────────────────────────
   // LaunchDarkly client SDK paste block
   // ─────────────────────────────────────────────────────────────────────────
   let ottoEnabled = false;
   let ldClient = null;

   async function initLaunchDarkly() {
     const cfg = await (await fetch('/config')).json();
     ldClient = LDClient.createClient(cfg.clientKey, {
       kind: 'user',
       key: getSessionId(),
     });
     const refresh = () => {
       ottoEnabled = ldClient.boolVariation('release-otto', false);
       applyOttoVisibility();
     };
     ldClient.on('ready', refresh);
     ldClient.on('change', refresh);
     await ldClient.start();
   }

   function onTierChanged() {
     // Re-identify with LaunchDarkly when the visitor's tier changes.
   }
   // ─── End LaunchDarkly client SDK paste block ──────────────────────────────
   ```

2. Save the file.

Note the `change` listener: when the flag changes in LaunchDarkly, every open browser finds out in seconds. No refresh, no redeploy. You're about to see that live.

# Turn Otto on

1. Open the [ToggleWear](#tab-1) tab and refresh it. No Otto: the flag is off, and off means hidden.
2. Go to the [LaunchDarkly](#tab-0) tab and open the **release-otto** flag.
3. Flip the flag's toggle to **On** and click **Review and save**.
   <!-- VERIFY: current save flow — "Review and save" vs "Save changes", and any confirmation dialog -->
4. Go back to the [ToggleWear](#tab-1) tab and watch the bottom-right corner. Within a few seconds, **Chat with Otto** appears, no page refresh needed.

![Otto appears on the storefront](../assets/rel-03-otto-appears.png)

Say hi to him. He answers, because the server-side evaluation now returns `true` too.

You just shipped a feature by clicking a toggle. Flip it **Off** and back **On** and watch Otto blink out and back in. That's the loop you'll build everything else on.

Leave the flag **On**, click **Check**, and head to the next lab. Right now Otto is on for *everyone*, and that's a little braver than we'd like.
