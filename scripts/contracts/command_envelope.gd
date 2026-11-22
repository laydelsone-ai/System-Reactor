class_name CommandEnvelope
extends RefCounted

const SCHEMA_VERSION := 1

static func create_register_entity(
	command_id: String,
	actor_id: String,
	world_tick: int,
	entity_record: Dictionary,
	source: String = "system"
) -> Dictionary:
	return {
		"command_id": command_id,
		"schema_version": SCHEMA_VERSION,
		"actor_id": actor_id,
		"target_ids": [],
		"domain": "identity",
		"scope": "world_local",
		"action_type": "RegisterEntity",
		"preconditions": {"entity_id_absent": true},
		"resource_requirements": [],
		"state_version": 0,
		"created_at_world_tick": world_tick,
		"source": source,
		"payload": {"entity": entity_record.duplicate(true)}
	}
