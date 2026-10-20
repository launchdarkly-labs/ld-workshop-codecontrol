"""ToggleWear storefront server.

One FastAPI process serves the static frontend and the app's API endpoints:
/chat (Otto, the mock shopping assistant), /products (the catalog), and
/recommendations (the "Recommended for You" carousel).

Otto is a mock: replies come from a small canned set below, picked by
keyword. There is no language model behind him.

LaunchDarkly integration points are the marked paste blocks. The labs tell
you exactly what to put between the markers; until then the stubs keep the
app running unwired.
"""
import logging
import os
import re
import sys
import threading
import time
from collections import defaultdict
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
from fastapi.staticfiles import StaticFiles

# override=True so .env wins over stale LD_* values from a previous shell
# session.
load_dotenv(override=True)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("togglewear")

STATIC_DIR = Path(__file__).parent / "static"
TURN_LIMIT = int(os.getenv("LD_CHAT_TURN_LIMIT", "30"))

# ─────────────────────────────────────────────────────────────────────────
# LaunchDarkly SDK setup paste block — the SDK-wiring lab replaces this
# stub with real client initialization. Until then, ld_client stays None
# and the app runs unwired.
# ─────────────────────────────────────────────────────────────────────────
ld_client = None
# ─── End LaunchDarkly SDK setup paste block ───────────────────────────────


def build_context(user_key: str, user_tier: str):
    """Build the LaunchDarkly evaluation context for this visitor."""
    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly context paste block — the SDK-wiring and targeting labs
    # replace this stub with a real Context built from the visitor's key
    # and tier.
    # ─────────────────────────────────────────────────────────────────────
    return None
    # ─── End LaunchDarkly context paste block ─────────────────────────────


# ─────────────────────────────────────────────────────────────────────────
# Catalog. Also rendered by the frontend via /products. Product ids are
# lowercase-hyphenated and used by the recommendations feature.
#
# NOTE: "rollout-tote" has no "category" field. DO NOT add one. The
# Observability track's production-error story depends on this gap — the
# personalized recommendations strategy throws when the viewed product has
# no category.
# ─────────────────────────────────────────────────────────────────────────
CATALOG = [
    {"id": "rocket-tee", "name": "Rocket Tee", "price": 28, "category": "apparel",
     "desc": "Classic crew-neck t-shirt with the LaunchDarkly rocket. Heather grey.",
     "img": "/static/images/rocket-tee.svg"},
    {"id": "feature-flag-hoodie", "name": "Feature Flag Hoodie", "price": 58, "category": "apparel",
     "desc": "Pullover hoodie. Embroidered flag logo. Midnight navy.",
     "img": "/static/images/feature-flag-hoodie.svg"},
    {"id": "dark-mode-cap", "name": "Dark Mode Cap", "price": 24, "category": "accessories",
     "desc": "Six-panel dad cap. Tone-on-tone black logo.",
     "img": "/static/images/dark-mode-cap.svg"},
    {"id": "ship-it-mug", "name": "Ship It Mug", "price": 16, "category": "drinkware",
     "desc": '12oz ceramic. "Ship it" in the LaunchDarkly font.',
     "img": "/static/images/ship-it-mug.svg"},
    {"id": "toggle-socks", "name": "Toggle Socks", "price": 14, "category": "apparel",
     "desc": "Crew socks with a tiny rocket on the ankle.",
     "img": "/static/images/toggle-socks.svg"},
    {"id": "release-notes-notebook", "name": "Release Notes Notebook", "price": 18, "category": "stationery",
     "desc": "A5 hardcover. Dot grid. For your actual release notes.",
     "img": "/static/images/release-notes-notebook.svg"},
    # No "category" on purpose — see the note above this list.
    {"id": "rollout-tote", "name": "Rollout Tote", "price": 22,
     "desc": "12oz canvas. Reinforced handles.",
     "img": "/static/images/rollout-tote.svg"},
    {"id": "feature-branch-crewneck", "name": "Feature Branch Crewneck", "price": 52, "category": "apparel",
     "desc": "Heavyweight crewneck sweatshirt. Sage green.",
     "img": "/static/images/feature-branch-crewneck.svg"},
]

BESTSELLER_IDS = ["feature-flag-hoodie", "rocket-tee", "ship-it-mug", "dark-mode-cap"]

# ─────────────────────────────────────────────────────────────────────────
# Otto's canned replies, in two styles. Keyword-matched, first match wins.
#
# "concise" is Otto's normal voice: warm, helpful, a little playful, brief.
# "chatty" is the new variation the guarded-release lab ships: noticeably
# longer and prone to wandering off-topic. Because Otto "types" his reply
# (see OTTO_TYPING_SECONDS_PER_CHAR below), chatty replies are organically
# slower — that latency difference is the regression the guarded release
# catches. Keep chatty plausibly bad, not comical.
# ─────────────────────────────────────────────────────────────────────────
CANNED_REPLIES = [
    (("hi", "hello", "hey", "howdy"), {
        "concise": "Hey! I'm Otto. Ask me about products, sizing, or shipping — I know this shop inside out.",
        "chatty": "Well hey there, welcome to ToggleWear! I'm Otto — resident shopping assistant, sizing consultant, shipping tracker, and unofficial shop historian. Did you know our first product was the Rocket Tee? Still a classic. Anyway, I can help with products, sizing, shipping, returns, gift ideas, care instructions... honestly, just start typing and we'll figure it out together.",
    }),
    (("size", "sizing", "fit", "large", "small", "medium"), {
        "concise": "Our tees and crewnecks run true to size. Between sizes? Go up one — the fabric relaxes a little after the first wash.",
        "chatty": "Great question — sizing is honestly one of my favorite topics. So, our tees and crewnecks run true to size, generally speaking, though 'true to size' means different things to different people, doesn't it? Fit is so personal. If you're between sizes I'd usually say go up one, because the fabric relaxes after the first wash — we use a pre-shrunk cotton but there's always a little give. The hoodie runs slightly roomy. The socks, of course, stretch.",
    }),
    (("ship", "shipping", "deliver", "delivery", "arrive"), {
        "concise": "Orders go out within 2 business days, and shipping is free over $50. Tracking lands in your inbox the moment it's on the way.",
        "chatty": "Ah, shipping — the eternal question! So here's the full picture: orders leave the warehouse within 2 business days, usually faster if you order before noon, though I probably shouldn't promise that. Shipping is free over $50, which — between us — is a great excuse to add the socks. Tracking lands in your inbox the moment the label prints. Fun fact: our warehouse team names the forklifts. The fast one is called Rollout.",
    }),
    (("return", "refund", "exchange"), {
        "concise": "Returns are easy: 30 days, no questions asked. Keep the tags on and we'll cover the label.",
        "chatty": "Returns! Nobody loves doing them, but ours are genuinely painless, I promise. You've got 30 days, no questions asked — though people do sometimes tell me why anyway, and honestly I appreciate the context. Keep the tags on, we cover the label, refunds land in a few business days depending on your bank. Exchanges work the same way, just tell us the new size. Speaking of sizes, did I mention things relax a little after the first wash?",
    }),
    (("hoodie", "sweatshirt", "crewneck", "warm"), {
        "concise": "The Feature Flag Hoodie is our bestseller — midnight navy, embroidered logo, warm without being bulky. The Feature Branch Crewneck is the heavyweight option.",
        "chatty": "Oh, you want warm? Let me walk you through the whole lineup. The Feature Flag Hoodie is our bestseller — midnight navy, embroidered logo, warm without being bulky, and I could go on about the embroidery quality because we changed suppliers last year and it really shows. Then there's the Feature Branch Crewneck, the heavyweight option, sage green, very 'cabin in October.' Layer the two? Now you're unstoppable. There's also the cap, which is not warm, but looks great.",
    }),
    (("price", "discount", "coupon", "sale", "deal"), {
        "concise": "We keep pricing simple — no coupon games. Free shipping kicks in over $50, though, if that helps.",
        "chatty": "So, pricing philosophy — and we do have a philosophy. We keep prices simple on purpose: no coupon games, no fake markdowns, no 'act now' timers. What you see is what it costs. I realize that's a slightly unusual stance for a shop assistant to lecture you about, but I feel strongly! The one lever we do have is free shipping over $50, which, if you're at $44, is basically the universe telling you to get the Toggle Socks.",
    }),
    (("mug", "sock", "tote", "cap", "notebook", "gift"), {
        "concise": "For gifts, the Ship It Mug and Toggle Socks are the crowd-pleasers. The Release Notes Notebook is for the person who actually writes release notes.",
        "chatty": "Gift mode, engaged! Okay: the Ship It Mug and Toggle Socks are the reliable crowd-pleasers — I've never heard a complaint about either, and believe me, I hear things. The Release Notes Notebook is for the person in your life who actually writes release notes, which is a rarer and more precious person than most people realize. The Rollout Tote is the sleeper pick; people underestimate a good tote until they own one, and then it's their whole personality.",
    }),
]

DEFAULT_REPLY = {
    "concise": "I'm not sure about that one — the product page has the details, or our team can help.",
    "chatty": "Hmm, you know what, I'm genuinely not sure about that one — and I'd rather admit it than make something up, that's kind of my whole thing. The product pages have the full details, and our human team can dig into anything I can't. While you're here though: have you seen the Feature Flag Hoodie? Not related to your question at all, I just think it deserves the attention.",
}

# Otto "types" his reply, so longer replies take proportionally longer to
# arrive. This is what makes Chatty Otto organically slower on the
# otto-response-latency metric — do not remove.
OTTO_TYPING_SECONDS_PER_CHAR = float(os.getenv("OTTO_TYPING_SECONDS_PER_CHAR", "0.0015"))


def pick_reply(message: str, style: str = "concise") -> str:
    """Pick a plausible canned reply by keyword, in the requested style.

    Keywords match at word starts ("size" matches "sizes") but not inside
    words ("hi" must not match "shipping").
    """
    lowered = message.lower()
    for keywords, variants in CANNED_REPLIES:
        if any(re.search(rf"\b{re.escape(k)}", lowered) for k in keywords):
            return variants.get(style, variants["concise"])
    return DEFAULT_REPLY.get(style, DEFAULT_REPLY["concise"])


def _recommend_bestsellers() -> list[dict]:
    """The safe, boring control: the same popular items for everyone."""
    by_id = {p["id"]: p for p in CATALOG}
    return [by_id[i] for i in BESTSELLER_IDS]


def _recommend_personalized(viewed_id: Optional[str]) -> list[dict]:
    """Pick items in the same category as the product the shopper viewed."""
    viewed = next((p for p in CATALOG if p["id"] == viewed_id), None)
    if viewed is None:
        return _recommend_bestsellers()
    viewed_category = viewed["category"]
    same = [p for p in CATALOG
            if p.get("category") == viewed_category and p["id"] != viewed["id"]]
    filler = [p for p in _recommend_bestsellers() if p not in same and p["id"] != viewed["id"]]
    return (same + filler)[:4]


_turns: dict[str, int] = defaultdict(int)
_state_lock = threading.Lock()

app = FastAPI(title="ToggleWear")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


class ChatRequest(BaseModel):
    message: str
    user_tier: str = "free"
    session_id: str


class ChatResponse(BaseModel):
    response: str
    turn: int
    turn_limit: int


class ChatResetRequest(BaseModel):
    session_id: str


class RecClickRequest(BaseModel):
    user_key: str
    user_tier: str = "free"
    product_id: str


@app.get("/")
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/healthz")
def healthz():
    # "observability" flips to true once the Observability track's paste
    # initializes the ldobserve plugin. Checked via sys.modules so an
    # unwired app never imports the (heavy) plugin just to answer this.
    observe = sys.modules.get("ldobserve.observe")
    return {
        "ok": True,
        "ld_wired": ld_client is not None,
        "observability": bool(observe is not None and observe.is_initialized()),
    }


@app.get("/config")
def config():
    """Public frontend config. The client-side ID is safe to expose — it
    identifies the environment but grants no API access."""
    return {"clientKey": os.getenv("LD_CLIENT_KEY", "")}


@app.get("/products")
def products():
    return {"items": CATALOG}


@app.get("/recommendations")
def recommendations(user_key: str = "anonymous", user_tier: str = "free",
                    viewed: Optional[str] = None):
    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly recommendations paste block — the Observability and
    # Iterate tracks replace this stub with a real flag evaluation that
    # picks the strategy per visitor.
    # ─────────────────────────────────────────────────────────────────────
    strategy = "bestsellers"
    # ─── End LaunchDarkly recommendations paste block ─────────────────────

    if strategy == "personalized":
        items = _recommend_personalized(viewed)
    else:
        items = _recommend_bestsellers()
    log.info("recommendations user=%s tier=%s strategy=%s viewed=%s",
             user_key, user_tier, strategy, viewed)
    return {"strategy": strategy, "items": items}


@app.post("/recommendations/click")
def recommendations_click(req: RecClickRequest):
    """A shopper clicked an item in the carousel: the engagement signal the
    Iterate track measures."""
    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly engagement tracking paste block — the Iterate track's
    # first-metric lab replaces this stub with a track() call that reports
    # the recs-engagement event for this shopper.
    # ─────────────────────────────────────────────────────────────────────
    pass
    # ─── End LaunchDarkly engagement tracking paste block ─────────────────

    log.info("recs click user=%s tier=%s product=%s", req.user_key, req.user_tier, req.product_id)
    return {"ok": True}


@app.post("/chat/reset")
def chat_reset(req: ChatResetRequest):
    """Clear the turn count for this session so the learner can start a
    fresh chat without refreshing the page."""
    with _state_lock:
        _turns.pop(req.session_id, None)
    log.info("chat reset session=%s", req.session_id)
    return {"ok": True}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    with _state_lock:
        _turns[req.session_id] += 1
        turn = _turns[req.session_id]

    if turn > TURN_LIMIT:
        return JSONResponse(
            status_code=429,
            content={
                "response": (
                    "You have reached the demo chat limit for this session. "
                    "Refresh the page to start a new session."
                ),
                "turn": turn,
                "turn_limit": TURN_LIMIT,
            },
        )

    started = time.monotonic()

    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly Otto flag paste block — the SDK-wiring lab replaces
    # this stub with a real evaluation of the release-otto flag. Until
    # then, Otto reports he isn't wired up.
    # ─────────────────────────────────────────────────────────────────────
    otto_enabled = False
    # ─── End LaunchDarkly Otto flag paste block ───────────────────────────

    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly Otto style paste block — the guarded-release lab's setup
    # wires this to the otto-style flag. Until then Otto is always concise.
    # ─────────────────────────────────────────────────────────────────────
    otto_style = "concise"
    # ─── End LaunchDarkly Otto style paste block ──────────────────────────

    if not otto_enabled:
        if ld_client is None:
            reply = "Otto isn't wired up to LaunchDarkly yet. Complete the SDK lab to bring him to life."
        else:
            reply = "Otto is turned off right now — the release-otto flag is serving false for this context."
    else:
        reply = pick_reply(req.message, otto_style)
        time.sleep(OTTO_TYPING_SECONDS_PER_CHAR * len(reply))

    elapsed_ms = (time.monotonic() - started) * 1000

    # ─────────────────────────────────────────────────────────────────────
    # LaunchDarkly event tracking paste block — the guarded-release lab
    # replaces this stub with a track() call that reports response latency
    # (the otto-response-latency metric).
    # ─────────────────────────────────────────────────────────────────────
    pass
    # ─── End LaunchDarkly event tracking paste block ──────────────────────

    log.info("chat session=%s tier=%s turn=%d elapsed_ms=%.1f",
             req.session_id, req.user_tier, turn, elapsed_ms)

    return ChatResponse(response=reply, turn=turn, turn_limit=TURN_LIMIT)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=3000)
