# ─────────────────────────────────────────────────────────────────────────
# LaunchDarkly SDK setup paste block
# ─────────────────────────────────────────────────────────────────────────
import ldclient
from ldclient import Context
from ldclient.config import Config
from ldobserve import ObservabilityConfig, ObservabilityPlugin, observe

ldclient.set_config(Config(
    os.environ["LD_SDK_KEY"],
    plugins=[
        ObservabilityPlugin(ObservabilityConfig(
            service_name="togglewear",
            service_version="workshop",
        )),
    ],
))
ld_client = ldclient.get()
ld_client.flag_tracker.add_listener(
    lambda change: log.info("flag changed: %s", change.key)
)
# ─── End LaunchDarkly SDK setup paste block ───────────────────────────────
