extends RefCounted

func filter_recent_events(state: Dictionary, limit: int = 12) -> Array:
	var events: Array = state.get("recent_events", []).duplicate(true)
	events.reverse()
	if events.size() > limit:
		events.resize(limit)
	return events

func summarize(state: Dictionary) -> Dictionary:
	var agents: Dictionary = state.get("agents", {})
	var alive := 0
	var creatures := 0
	for agent_value in agents.values():
		var agent: Dictionary = agent_value
		if agent.get("life_state", "alive") == "alive":
			alive += 1
		if agent.get("entity_kind", "person") == "creature":
			creatures += 1
	return {
		"world_tick": int(state.get("world_tick", 0)),
		"entities": agents.size(),
		"alive": alive,
		"creatures": creatures,
		"recent_event_count": state.get("recent_events", []).size(),
		"paused": bool(state.get("paused", false))
	}
