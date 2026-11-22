class_name EventEnvelope
extends RefCounted

const SCHEMA_VERSION := 1
const RULES_VERSION := "SR-01..SR-15@2026-11-20"

static func create(
	event_id: String,
	world_id: String,
	event_type: String,
	sequence: int,
	world_tick: int,
	command_id: String,
	actor_id: String,
	payload: Dictionary,
	origin: String,
	authority: String = "SystemCore"
) -> Dictionary:
	var participants: Array = []
	if not actor_id.is_empty() and actor_id != "system":
		participants.append(actor_id)
	var entity_value: Variant = payload.get("entity", null)
	if typeof(entity_value) == TYPE_DICTIONARY:
		var entity_record: Dictionary = entity_value
		var entity_id := String(entity_record.get("entity_id", ""))
		if not entity_id.is_empty() and not participants.has(entity_id):
			participants.append(entity_id)
	return {
		"event_id": event_id,
		"schema_version": SCHEMA_VERSION,
		"world_id": world_id,
		"event_type": event_type,
		"sequence": sequence,
		"world_tick": world_tick,
		"participants": participants,
		"location": null,
		"causes": [{"kind": "command", "id": command_id}] if not command_id.is_empty() else [],
		"consequences": [],
		"command_id": command_id,
		"actor_id": actor_id,
		"authority": authority,
		"rule_version": RULES_VERSION,
		"origin": origin,
		"confirmation_status": "confirmed",
		"dissemination_status": "not_disseminated",
		"visibility": "world_internal",
		"disposition": "normal",
		"recorded_at_utc": Time.get_datetime_string_from_system(true),
		"payload": payload.duplicate(true)
	}
