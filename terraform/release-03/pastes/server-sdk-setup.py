# ─────────────────────────────────────────────────────────────────────────
# LaunchDarkly SDK setup paste block
# ─────────────────────────────────────────────────────────────────────────
import ldclient
from ldclient import Context
from ldclient.config import Config

ldclient.set_config(Config(os.environ["LD_SDK_KEY"]))
ld_client = ldclient.get()
# ─── End LaunchDarkly SDK setup paste block ───────────────────────────────
