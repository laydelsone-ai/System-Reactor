class_name WorldClock
extends RefCounted

## WLA-0A conserva un contador monotónico. No fija todavía calendario,
## velocidad temporal ni frecuencia de simulación; pertenecen a etapas posteriores.
var world_tick: int = 0

func restore(value: int) -> Error:
	if value < 0:
		return ERR_INVALID_DATA
	world_tick = value
	return OK

func advance_to(value: int) -> Error:
	if value < world_tick:
		return ERR_INVALID_PARAMETER
	world_tick = value
	return OK

func to_snapshot() -> Dictionary:
	return {"world_tick": world_tick}

func load_snapshot(data: Dictionary) -> Error:
	if not data.has("world_tick"):
		return ERR_INVALID_DATA
	return restore(int(data.get("world_tick", -1)))
