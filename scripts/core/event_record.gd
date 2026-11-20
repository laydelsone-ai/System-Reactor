extends RefCounted

static func create_event(
		event_type: String,
		world_tick: int,
		actor_id: String,
		command_id: String,
		payload: Dictionary,
		provenance: String = "agent_decision") -> Dictionary:
	var event_id := "evt_%s_%s" % [str(world_tick), command_id]
	return {
		"event_id": event_id,
		"schema_version": 1,
		"event_type": event_type,
		"world_tick": world_tick,
		"recorded_at_epoch": int(Time.get_unix_time_from_system()),
		"actor_id": actor_id,
		"target_ids": [],
		"cause_ids": [],
		"command_id": command_id,
		"scope": "world_local",
		"visibility": "restricted",
		"confirmation_status": "confirmed",
		"dissemination_status": "not_disseminated",
		"disposition": "normal",
		"authority": "local_domain_validator",
		"rules_version": "WLA-0.1.0",
		"provenance": provenance,
		"payload": payload.duplicate(true)
	}
