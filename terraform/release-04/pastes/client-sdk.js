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
  ldClient = LDClient.createClient(cfg.clientKey, ldContext());
  // Runs once flags are ready and again on EVERY flag change LaunchDarkly
  // streams down: re-evaluate and re-render everything flag-driven, so a
  // toggle in LaunchDarkly shows up here within seconds, no refresh.
  refresh = () => {
    ottoEnabled = ldClient.boolVariation('release-otto', false);
    applyOttoVisibility();
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
