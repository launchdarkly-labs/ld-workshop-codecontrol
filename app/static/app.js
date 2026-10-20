'use strict';

// ---------- Session state ----------

const SESSION_KEY = 'togglewear.sessionId';

function getSessionId() {
  let id = localStorage.getItem(SESSION_KEY);
  if (!id) {
    id = (crypto?.randomUUID?.() ?? `s-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`);
    localStorage.setItem(SESSION_KEY, id);
  }
  return id;
}

let userTier = 'free';
let lastViewedId = null;

// ─────────────────────────────────────────────────────────────────────────
// LaunchDarkly client SDK paste block — the SDK-wiring lab replaces this
// stub with real client initialization (the LDClient global comes from the
// script tag in index.html). Until then, Otto stays hidden.
// ─────────────────────────────────────────────────────────────────────────
let ottoEnabled = false;

function initLaunchDarkly() {
  applyOttoVisibility();
}

function onTierChanged() {
  // Re-identify with LaunchDarkly when the visitor's tier changes.
}
// ─── End LaunchDarkly client SDK paste block ──────────────────────────────

function applyOttoVisibility() {
  document.querySelector('aside.otto').hidden = !ottoEnabled;
}

// ---------- Product grid ----------

let catalog = [];

async function loadProducts() {
  const res = await fetch('/products');
  const data = await res.json();
  catalog = data.items;
  renderProducts();
}

function productCard(p) {
  return `
    <article class="product${p.id === lastViewedId ? ' viewing' : ''}" data-product-id="${p.id}">
      <img class="product-image" src="${p.img}" alt="${p.name}" loading="lazy">
      <div class="product-body">
        <h2 class="product-name">${p.name}</h2>
        <p class="product-price">$${p.price}</p>
        <p class="product-desc">${p.desc}</p>
      </div>
    </article>
  `;
}

function renderProducts() {
  const grid = document.getElementById('shop');
  grid.innerHTML = catalog.map(productCard).join('');
}

function initProductClicks() {
  // Clicking a product marks it as "viewed" — the signal the personalized
  // recommendations strategy uses.
  document.getElementById('shop').addEventListener('click', (ev) => {
    const card = ev.target.closest('.product');
    if (!card) return;
    lastViewedId = card.dataset.productId;
    renderProducts();
    loadRecommendations();
  });
}

// ---------- Recommended for You ----------

async function loadRecommendations() {
  const box = document.getElementById('recs');
  const track = document.getElementById('recs-track');
  const params = new URLSearchParams({
    user_key: getSessionId(),
    user_tier: userTier,
  });
  if (lastViewedId) params.set('viewed', lastViewedId);

  try {
    const res = await fetch(`/recommendations?${params}`);
    if (!res.ok) {
      // A failing recommendations service shouldn't take the page down.
      box.hidden = true;
      return;
    }
    const data = await res.json();
    if (!data.items || data.items.length === 0) {
      // The show-recommendations flag is off for this visitor (or there is
      // nothing to recommend): no carousel.
      box.hidden = true;
      return;
    }
    track.innerHTML = data.items.map((p) => `
      <article class="rec" data-product-id="${p.id}">
        <img class="rec-image" src="${p.img}" alt="${p.name}" loading="lazy">
        <div class="rec-body">
          <span class="rec-name">${p.name}</span>
          <span class="rec-price">$${p.price}</span>
        </div>
      </article>
    `).join('');
    box.hidden = false;
  } catch {
    box.hidden = true;
  }
}

function initRecClicks() {
  // Clicking a recommended item is the engagement signal the Iterate track
  // measures. Plain app behavior: the server decides whether to report it to
  // LaunchDarkly.
  document.getElementById('recs-track').addEventListener('click', (ev) => {
    const card = ev.target.closest('.rec');
    if (!card) return;
    card.classList.add('clicked');
    fetch('/recommendations/click', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_key: getSessionId(),
        user_tier: userTier,
        product_id: card.dataset.productId,
      }),
    }).catch(() => {});
  });
}

// ---------- Tier switch ----------

function initTierSwitch() {
  const sel = document.getElementById('user-tier');
  userTier = sel.value;
  sel.addEventListener('change', () => {
    userTier = sel.value;
    const label = { free: 'Free', premium: 'Premium', beta: 'Beta' }[userTier] ?? userTier;
    appendBubble('system', `Switched to ${label} user.`);
    onTierChanged();
    loadRecommendations();
  });
}

// ---------- Otto widget ----------

const transcript = () => document.getElementById('otto-transcript');
const meta = () => document.getElementById('otto-meta');

function appendBubble(kind, text) {
  const div = document.createElement('div');
  div.className = `bubble ${kind}`;
  div.textContent = text;
  const t = transcript();
  t.appendChild(div);
  t.scrollTop = t.scrollHeight;
}

function setMeta(text) {
  meta().textContent = text;
}

function initOttoPanel() {
  const toggle = document.getElementById('otto-toggle');
  const panel = document.getElementById('otto-panel');
  const close = document.getElementById('otto-close');
  const reset = document.getElementById('otto-reset');
  const input = document.getElementById('otto-input');

  const open = () => {
    panel.hidden = false;
    toggle.setAttribute('aria-expanded', 'true');
    toggle.style.display = 'none';
    setTimeout(() => input.focus(), 30);
  };
  const shut = () => {
    panel.hidden = true;
    toggle.setAttribute('aria-expanded', 'false');
    toggle.style.display = '';
  };

  toggle.addEventListener('click', open);
  close.addEventListener('click', shut);
  reset.addEventListener('click', resetChat);
}

async function resetChat() {
  const reset = document.getElementById('otto-reset');
  reset.disabled = true;
  try {
    const res = await fetch('/chat/reset', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: getSessionId() }),
    });
    if (!res.ok) {
      appendBubble('system', `Reset failed (${res.status}).`);
      return;
    }
    transcript().innerHTML = '';
    setMeta('');
    appendBubble('system', "Chat reset. Ask me anything about ToggleWear.");
    document.getElementById('otto-input').focus();
  } catch (err) {
    appendBubble('system', `Reset error: ${err.message}`);
  } finally {
    reset.disabled = false;
  }
}

async function sendMessage(message) {
  const sendBtn = document.querySelector('.otto-send');
  const input = document.getElementById('otto-input');
  input.disabled = true;
  sendBtn.disabled = true;

  try {
    const res = await fetch('/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message,
        user_tier: userTier,
        session_id: getSessionId(),
      }),
    });

    const data = await res.json();

    if (!res.ok) {
      // Turn cap (429) returns a friendly response we still want to show.
      if (res.status === 429 && data?.response) {
        appendBubble('system', data.response);
      } else {
        appendBubble('system', `Error ${res.status}: ${data?.detail || 'request failed'}`);
      }
      return;
    }

    appendBubble('otto', data.response);
    setMeta(`turn ${data.turn} / ${data.turn_limit} · tier: ${userTier}`);
  } catch (err) {
    appendBubble('system', `Network error: ${err.message}`);
  } finally {
    input.disabled = false;
    sendBtn.disabled = false;
    input.focus();
  }
}

function initChatForm() {
  const form = document.getElementById('otto-form');
  const input = document.getElementById('otto-input');

  form.addEventListener('submit', (ev) => {
    ev.preventDefault();
    const msg = input.value.trim();
    if (!msg) return;
    appendBubble('user', msg);
    input.value = '';
    sendMessage(msg);
  });
}

// ---------- Boot ----------

document.addEventListener('DOMContentLoaded', () => {
  loadProducts();
  loadRecommendations();
  initProductClicks();
  initRecClicks();
  initTierSwitch();
  initOttoPanel();
  initChatForm();
  initLaunchDarkly();
  appendBubble('system', "Hi — I'm Otto. Ask me anything about ToggleWear.");
});
