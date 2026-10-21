# ─────────────────────────────────────────────────────────────────────────
# LaunchDarkly SDK setup paste block
# ─────────────────────────────────────────────────────────────────────────
import ldclient
from ldclient import Context
from ldclient.config import Config

ldclient.set_config(Config(os.environ["LD_SDK_KEY"]))
ld_client = ldclient.get()

# The SDK streams flag changes and every variation() call reads the latest
# value, so evaluations are always current. Subscribing to the change feed
# as well makes each change visible in the server log the moment it lands.
ld_client.flag_tracker.add_listener(
    lambda change: log.info("flag changed: %s", change.key)
)
# ─── End LaunchDarkly SDK setup paste block ───────────────────────────────
