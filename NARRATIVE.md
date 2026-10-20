# NARRATIVE.md

This file is the story bible for the workshop. It holds the ToggleWear premise, the developer's arc across the three tracks, the voice for learner-facing prose, ToggleWear's brand, the product list, and the specs for the two flaggable features (Otto and the recommendations carousel). Every `assignment.md` and every prompt referenced by Terraform should be consistent with this file.

When inconsistency arises during implementation, fix the prose to match `NARRATIVE.md`, not the other way around. Updates to `NARRATIVE.md` happen deliberately, not as a side effect.

---

## The premise

ToggleWear is a fictional online retailer of LaunchDarkly-branded apparel — t-shirts, hoodies, hats, and accessories featuring LaunchDarkly's logo and brand. It's a small operation. The shop is already live. **You are a developer at ToggleWear**, and your job across this workshop is to ship changes to the live site without breaking it — using LaunchDarkly CodeControl to release safely, watch what happens, and improve.

There's no single character being "built" here (unlike the AgentControl workshop, where Otto was the star). The through-line is *you, shipping confidently*. Two features carry the story: **Otto**, a shopping-assistant chat widget you roll out in the Release track, and the **"Recommended for You"** carousel, a new feature that misbehaves in production (Observability) and that you experiment on (Iterate).

---

## The arc, by track

Each track is a chapter in shipping confidently. The arc is light-touch — it lives in welcome/recap intros and in the transition line that closes each challenge.

**Track 1 — Release, titled *Shipping Otto: From First Flag to Guarded Release*: "Ship it without holding your breath."**
The shop is live. You want to add Otto, a chat widget, but you don't want to expose him to everyone at once and hope for the best. You put Otto behind a flag, wire the SDK, target a few beta users, roll him out gradually, and finally ship a guarded release so that if a new version of Otto goes bad, LaunchDarkly rolls it back for you. You end knowing how to release anything safely.

**Track 2 — Observability, titled *The Carousel That Broke Production*: "Know the moment something breaks — and fix it before anyone notices."**
Otto's shipped. Now ToggleWear wants a "Recommended for You" carousel. You ship it — and it starts throwing errors in production on certain products. You instrument the app so errors show up attributed to the release that caused them, replay the exact session where a shopper watched the carousel vanish, watch release health per variation, guard the rollout on the real error signal you just wired, and finally set up auto-remediation so the system heals itself when the signal goes bad.

**Track 3 — Iterate, titled *Bestsellers vs. Personalized: Let the Shop Decide*: "Stop guessing which version is better. Measure it."**
The recommendations carousel works. But is the current version actually the best one? You create a metric, design an A/B experiment comparing two recommendation strategies, run it against live lab traffic, read the results, promote the winner, and then hand the decision to a multi-armed bandit that routes traffic to the best performer automatically. You end knowing how to let real data drive product decisions.

---

## Voice for assignment.md prose

**Tone:** Confident, warm, direct. Treat the learner as a peer. Light humor when it fits, never forced.

**Reference voice:** Match the public `01-release` basics track's voice — short paragraphs, imperatives ("Click the **Create flag** button…"), reasoning kept brief and in section intros rather than in steps.

**Things to do:**
- Use first-person plural when describing project moves ("We're going to put Otto behind a flag").
- Use second-person imperative for steps ("Click the **Create flag** button").
- Bold the literal text the learner sees in the UI: "click **Save changes**".
- Put text the learner types or pastes in fenced code blocks (with a language hint). All code is copy-paste — never ask the learner to write code from scratch.
- Reference tabs by index: `[LaunchDarkly](#tab-0)`, `[ToggleWear](#tab-1)`, `[Code Editor](#tab-2)`.
- The **first** time a core concept appears (flag, context, segment, metric, experiment), give a one- or two-sentence plain-language definition in the section intro. The audience is new to LD. Keep it to a couple of sentences — depth is the slides' job.
- End each challenge with a one-sentence transition pointing to what's next.

**Things to avoid:**
- Conceptual exposition mid-step. Move it to section intros or omit it.
- Cute filler ("Awesome!", "Great job!" in every paragraph). Once per challenge at most.
- Em-dashes used decoratively. Use commas or periods.
- Assuming LD familiarity. Don't reference a UI area or concept the learner hasn't been shown yet without a quick orientation.

---

## ToggleWear: brand details

**Name:** ToggleWear

**Tagline:** "Wear your features on your sleeve." *(carried over; revisit if a better one emerges)*

**Logo:** Placeholder — a simple wordmark is fine. The operator may supply real brand assets. If a logo is placed, it incorporates the LaunchDarkly rocket motif (a toggle switch on a rocket, etc.).

**Aesthetic:** Modern e-commerce. Clean, lots of whitespace, sans-serif type. Not "developer-tooling" looking. Somewhere between Allbirds and a band's merch site.

**Brand voice (the shop's, not Otto's):** Friendly, slightly tongue-in-cheek about the meta-reference ("LaunchDarkly-branded apparel" is a knowing wink), enthusiastic about the products without overselling.

---

## Product list

Six to eight items in the product grid. Carried over from the AgentControl workshop's catalog:

| Product | Price | One-line description |
|---|---|---|
| Rocket Tee | $28 | Classic crew-neck t-shirt with the LaunchDarkly rocket. Heather grey. |
| Feature Flag Hoodie | $58 | Pullover hoodie. Embroidered flag logo. Midnight navy. |
| Dark Mode Cap | $24 | Six-panel dad cap. Tone-on-tone black logo. |
| Ship It Mug | $16 | 12oz ceramic. "Ship it" in the LaunchDarkly font. |
| Toggle Socks | $14 | Crew socks with a tiny rocket on the ankle. |
| Release Notes Notebook | $18 | A5 hardcover. Dot grid. For your actual release notes. |
| Rollout Tote | $22 | 12oz canvas. Reinforced handles. |
| Feature Branch Crewneck | $52 | Heavyweight crewneck sweatshirt. Sage green. |

Each product needs a placeholder image (1:1, ~600px square), a name, price, short description, and an ID (lowercase-hyphenated) used by the recommendations feature.

---

## Feature 1: Otto (the mock chat widget)

**What it is:** A shopping-assistant chat widget embedded on the ToggleWear page. Otto answers customer questions about products, sizing, and store policies.

**Mock, not AI:** Otto returns **canned responses** from a small scripted set in `server.py`. There is no language model. A tiny keyword-match picks a plausible canned reply (a sizing question gets the sizing reply, a shipping question gets the shipping reply, everything else gets a friendly default). This is deliberate — see the "Otto is a mock chatbot" entry in `DECISIONS.md`. Keep the canned set small (roughly 5–8 replies) and on-brand.

**Otto's voice (in his canned replies):** Warm, helpful, a little playful, brief. Honest when he doesn't know ("I'm not sure about that one — the product page has the details, or our team can help").

**Role in the Release track:**
- Otto's *presence* is gated by the flag `release-otto` (boolean). Off by default. When the learner turns it on and wires the SDK, Otto appears on the page. This is the first-flag "aha."
- Targeting (`04`) shows Otto to beta users first. Segments (`05`) make that reusable.
- Progressive rollout (`07`) ramps Otto's boolean from a small percentage to 100%.
- The guarded release (`08`) ships a new Otto *behavior variation* — **"Chatty Otto"** — against the current **"Concise Otto."** Chatty Otto's canned replies are long-winded and drift off-topic, and because Otto "types" his replies (a per-character delay in `server.py`), chatty replies are organically slower. The guarded release watches the **`otto-response-latency`** metric and rolls back to Concise Otto automatically. The regression is organic (Chatty Otto really is worse on the metric), not a contrived flip. *(Decided 2026-07-07; see `DECISIONS.md` "Simple metric for Release 08.")*

**Flag/metric keys (decided during Phase 0/5 implementation):**
- `release-otto` — boolean, gates Otto's presence.
- `otto-style` — multivariate string, variations `concise` ("Concise Otto") / `chatty` ("Chatty Otto"). Drives the guarded release.
- `otto-response-latency` — custom numeric metric, milliseconds per Otto reply, lower is better. Fed by `client.track(..., metric_value=elapsed_ms)` in `server.py`; guards Release `08`.

---

## Feature 2: "Recommended for You" carousel

**What it is:** A horizontal recommendations strip below the product grid that suggests a few products. Two strategies exist:
- **"Bestsellers"** (control) — shows the same popular items to everyone. Safe, boring.
- **"Personalized"** (treatment) — picks items based on a simple attribute on the context (e.g. items in the same category as something the shopper viewed). More engaging in theory.

**Role in the Observability track:**
- The carousel is gated by `show-recommendations` (boolean) and its strategy is chosen by `recommendations-strategy` (multivariate: `bestsellers` / `personalized`).
- The **Personalized** strategy has a lurking bug: for a product with a missing or malformed field (there's one such product in the catalog, seeded intentionally), the recommendation code throws. In production this surfaces as an error attributed to the `personalized` variation of `recommendations-strategy`.
- `02-instrument-for-errors` wires the observability SDK so those throws become visible errors in LaunchDarkly.
- `03-errors-in-context` shows the errors attributed to the release/flag that introduced them, and the **session replay** of a shopper hitting the broken carousel — the human-visible side of the same error, scoped to the `personalized` variation.
- `04-release-monitoring` attaches an error-rate (and/or latency) metric to the release and shows health per variation.
- `06-guarded-release-real-metrics` guards a rollout of the `personalized` strategy on that real error metric; the metric goes bad, and it rolls back.
- `07-auto-remediation` configures self-healing so that when the error signal crosses a threshold in production, LaunchDarkly (or an app-side loop wired to LD's REST API, depending on what Phase 0 confirms the product supports) automatically flips `recommendations-strategy` back to `bestsellers` — or the product's auto-remediation feature suggests/opens the fix. **Phase 0 must confirm the actual shape of the auto-remediation feature** (fully-managed self-healing vs. suggested-change/PR vs. app-side loop) before this challenge is authored; see `PHASES-observability.md`.

**Role in the Iterate track:**
- The experiment compares `bestsellers` vs `personalized` (with the bug fixed) on an engagement metric, `recs-engagement`: a click on a recommended item, reported by the server from `POST /recommendations/click` as a custom conversion metric (percent of shoppers who clicked at least once, higher is better). Decided 2026-10-19.
- `07-multi-armed-bandit` converts the decision to a bandit that dynamically routes traffic to whichever strategy is winning.

**Suggested flag/metric keys (verify naming conventions during Phase 0):**
- `show-recommendations` — boolean, gates the carousel's presence.
- `recommendations-strategy` — multivariate, `bestsellers` / `personalized`.
- `recs-error-rate` — metric, error/exception signal from the carousel (Observability).
- `recs-engagement` — metric, click/engagement signal on recommended items (Iterate).

---

## The "bad" behaviors that drive rollback / remediation

These need to be organic (real regressions the metric legitimately catches), not contrived flips. Consistent across tracks:

- **Chatty Otto (Release `08`):** canned replies are noticeably longer and wander off-topic. Because Otto types at a fixed per-character rate, chatty replies take ~4x longer, degrading `otto-response-latency` enough for Release Guardian to detect. Bad enough to catch, not so bad it's comical.
- **Personalized recommendations bug (Observability):** throws on the one catalog product with a malformed field. Produces a real, attributable error spike on the `personalized` variation. The fix (handle the malformed field) is what the learner conceptually applies; in the lab the remediation is the flag flip back to `bestsellers`.

A presenter escape hatch (a `sabotage.py`-style script in `traffic-generator/`) should exist to force the bad signal on demand when organic lab traffic is too slow, mirroring the AgentControl workshop's approach.

---

## Traffic generation

Reuse the AgentControl workshop's synthetic-traffic pattern: `traffic-generator/generate_traffic.py` evaluates flags to get real contexts and emits synthetic metric/error events weighted so the intended winner/loser is visible in the dashboards and experiments converge in a presenter-friendly ~60–90s. **It does not call any model** (there isn't one). For the error story, a variant emits the exception-shaped events for the `personalized` bug; for the experiment, a variant emits `recs-engagement` events weighted so one strategy wins clearly.

---

## Things to keep consistent across all `assignment.md` files

- ToggleWear is one word, capitalized as shown.
- Otto's name — never "the bot" or "the chatbot" in narrative copy; just "Otto." ("the chat widget" is fine in technical contexts.)
- The recommendations feature is "Recommended for You" in UI copy, "the recommendations carousel" in prose.
- Flag keys are lowercase-hyphenated: `release-otto`, `otto-style`, `show-recommendations`, `recommendations-strategy`.
- Metric keys are lowercase-hyphenated: `otto-response-latency`, `recs-error-rate`, `recs-engagement`.
- Context/user-tier values in code are lowercase (`free`, `premium`, `beta`); in UI copy, "Free user," "Premium user," "Beta user."
- The developer-shipping-safely framing is the through-line. Don't retro-fit a single mascot; the story is the learner's.
