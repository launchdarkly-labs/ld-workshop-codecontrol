"""
LaunchDarkly demo app for Instruqt tracks.

Server-side flag evaluation with the Python server SDK. The page polls
/api/state every 2 seconds so flag changes show up without a refresh.

Environment (written to /opt/ld/ld.env by the track setup script):
  LD_SDK_KEY        server-side SDK key          (required for flags to work)
  LD_CLIENT_KEY     client-side ID               (exposed to the page for JS SDK demos)
  LD_PROJECT_KEY    project key                  (display only)
  LD_ENV_KEY        environment key, default "test"
  FEATURE_FLAG_KEY  the boolean flag that drives the featured card, default "new-feature"
  PORT              default 8000

Simulate different users with query params, e.g. /?user=alice&country=US&plan=pro
"""
import atexit
import os

import ldclient
from flask import Flask, jsonify, render_template, request
from ldclient import Context
from ldclient.config import Config

SDK_KEY = os.environ.get("LD_SDK_KEY", "")
CLIENT_SIDE_ID = os.environ.get("LD_CLIENT_KEY", "")
PROJECT_KEY = os.environ.get("LD_PROJECT_KEY", "")
ENV_KEY = os.environ.get("LD_ENV_KEY", "test")
FEATURE_FLAG_KEY = os.environ.get("FEATURE_FLAG_KEY", "new-feature")
PORT = int(os.environ.get("PORT", "8000"))

# Custom attributes the page lets you set on the user context. Targeting rules
# in the workshop can key off any of these.
CONTEXT_ATTRIBUTES = ("country", "plan", "email", "beta")

app = Flask(__name__)

client = None
if SDK_KEY:
    ldclient.set_config(Config(SDK_KEY))
    client = ldclient.get()
    atexit.register(client.close)


def build_context(args):
    key = args.get("user") or "workshop-user"
    builder = Context.builder(key).kind("user").name(args.get("name") or key.replace("-", " ").title())
    for attr in CONTEXT_ATTRIBUTES:
        value = args.get(attr)
        if value:
            builder.set(attr, value)
    return builder.build()


def ld_ready():
    return client is not None and client.is_initialized()


def snapshot(context):
    if not ld_ready():
        return {
            "configured": bool(SDK_KEY),
            "initialized": False,
            "flags": {},
            "feature_enabled": False,
        }
    state = client.all_flags_state(context)
    return {
        "configured": True,
        "initialized": True,
        "flags": state.to_values_map(),
        "feature_enabled": client.variation(FEATURE_FLAG_KEY, context, False),
    }


@app.route("/")
def index():
    context = build_context(request.args)
    return render_template(
        "index.html",
        state=snapshot(context),
        context=context.to_dict(),
        project_key=PROJECT_KEY,
        env_key=ENV_KEY,
        client_side_id=CLIENT_SIDE_ID,
        feature_flag_key=FEATURE_FLAG_KEY,
        attributes=CONTEXT_ATTRIBUTES,
    )


@app.route("/api/state")
def api_state():
    context = build_context(request.args)
    data = snapshot(context)
    data["context"] = context.to_dict()
    data["feature_flag_key"] = FEATURE_FLAG_KEY
    return jsonify(data)


@app.route("/healthz")
def healthz():
    return jsonify({"ok": True, "ld_configured": bool(SDK_KEY), "ld_initialized": ld_ready()})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT, debug=False)
