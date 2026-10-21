// ─────────────────────────────────────────────────────────────────────────
// LaunchDarkly client SDK paste block
// ─────────────────────────────────────────────────────────────────────────
let ottoEnabled = false;
let ldClient = null;
let refresh = () => {};

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
  // Runs once flags are ready and again on EVERY flag change LaunchDarkly
  // streams down: re-evaluate and re-render everything flag-driven.
  refresh = () => {
    ottoEnabled = ldClient.boolVariation('release-otto', false);
    applyOttoVisibility();
    // Evaluate the strategy flag in the browser too: LaunchDarkly attributes
    // this session's errors and replay to the variation it evaluated.
    ldClient.variation('recommendations-strategy', 'bestsellers');
    loadRecommendations();
  };
  ldClient.on('ready', refresh);
  ldClient.on('change', refresh);
  await ldClient.start();
}

function onTierChanged() {
  if (ldClient) {
    ldClient.identify(ldContext()).then(refresh);
  }
}
// ─── End LaunchDarkly client SDK paste block ──────────────────────────────
