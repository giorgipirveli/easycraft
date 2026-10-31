class_name SyncPace
extends RefCounted
## How often bodies sync over the network (M4 Wave 1 A, spec §17.0: player and creature sync stays
## small and paced). A MultiplayerSynchronizer sends every frame by default: a host at 60 FPS sent a
## guest 234 kbit/s of positions while they played together, 371 kbit/s while the guest flew (animals
## spawn around every player), all on the relay's one reliable stream. Players sync PLAYER_HZ times a
## second (the people you play with), everything else OTHER_HZ (animals, monsters, buddies, bots,
## coins), and only when a value changed (a resting animal sends nothing). Session applies it to every
## synchronizer that enters the tree.

const PLAYER_HZ := 20.0
const OTHER_HZ := 10.0
const SMOOTHING_SLACK := 0.05


## Seconds between syncs of `body` (the synchronizer's parent). Owner #109: a car carries its riders at up to 14 m/s:
## it syncs as often as a player (only what changed, like every creature: a parked car sends nothing). By its group, so
## the autoloads that pace every synchronizer never compile the cars at startup.
const FAST_GROUP := &"vehicles"


static func interval_for(body: Node) -> float:
	return 1.0 / (PLAYER_HZ if body is Player or (body != null and body.is_in_group(FAST_GROUP)) else OTHER_HZ)


## How far behind its newest sync a remote body is shown (RemoteSmoother, M4 Wave 2 A2): one sync
## interval plus SMOOTHING_SLACK for syncs that arrive late (100 ms for players, 150 ms for others).
static func smoothing_delay(body: Node) -> float:
	return interval_for(body) + SMOOTHING_SLACK


## Everything but players syncs a property only when it changed (REPLICATION_MODE_ON_CHANGE).
static func only_on_change(body: Node) -> bool:
	return not (body is Player)


## Makes every always-synced property of `cfg` sync on change instead.
static func to_on_change(cfg: SceneReplicationConfig) -> void:
	if cfg == null:
		return
	for path: NodePath in cfg.get_properties():
		if cfg.property_get_replication_mode(path) == SceneReplicationConfig.REPLICATION_MODE_ALWAYS:
			cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
