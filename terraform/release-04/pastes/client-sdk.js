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
  ldClient = LDClient.createClient(cfg.clientKey, ldContext());
  const refresh = () => {
    ottoEnabled = ldClient.boolVariation('release-otto', false);
    applyOttoVisibility();
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
    });
  }
}
// ─── End LaunchDarkly client SDK paste block ──────────────────────────────
