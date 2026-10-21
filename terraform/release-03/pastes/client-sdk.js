// ─────────────────────────────────────────────────────────────────────────
// LaunchDarkly client SDK paste block
// ─────────────────────────────────────────────────────────────────────────
let ottoEnabled = false;
let ldClient = null;
let refresh = () => {};

async function initLaunchDarkly() {
  const cfg = await (await fetch('/config')).json();
  ldClient = LDClient.createClient(cfg.clientKey, {
    kind: 'user',
    key: getSessionId(),
  });
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
  // Re-identify with LaunchDarkly when the visitor's tier changes.
}
// ─── End LaunchDarkly client SDK paste block ──────────────────────────────
