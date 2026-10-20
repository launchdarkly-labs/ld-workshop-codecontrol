# ---- Demo app: dependencies + systemd unit -----------------------------------
# Keys arrive at track start: track_scripts/setup-workstation writes /opt/ld/ld.env
# and runs `systemctl restart ld-app`. Until then the app serves a "not configured"
# page, so enabling the unit at image-build time is safe.
cd "$APP_DIR"
python3 -m venv .venv
.venv/bin/pip install --no-cache-dir --upgrade pip
.venv/bin/pip install --no-cache-dir -r requirements.txt

# Vendored JS client SDK (optional, for client-side flag demos; avoids a CDN
# dependency inside the sandbox). Served at /static/ldclient.min.js.
mkdir -p "$APP_DIR/static"
curl -fsSL https://unpkg.com/launchdarkly-js-client-sdk@3/dist/ldclient.min.js -o "$APP_DIR/static/ldclient.min.js"

cat > /etc/systemd/system/ld-app.service <<UNIT
[Unit]
Description=LaunchDarkly demo app
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=-/opt/ld/ld.env
Environment=PORT=8000
ExecStart=$APP_DIR/.venv/bin/python $APP_DIR/app.py
Restart=always
RestartSec=2
User=root

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable ld-app
systemctl start ld-app || true
