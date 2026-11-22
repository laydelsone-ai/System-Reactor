class_name EntityRegistry
extends RefCounted

## Registro de identidad lógica. La representación visual es opcional y nunca
## constituye la identidad. Las dimensiones de identidad permanecen separadas.
var _entities: Dictionary = {}

func register_entity(record: Dictionary) -> Error:
	var validation_error := validate_record(record)
	if validation_error != OK:
		return validation_error
	var entity_id := String(record.get("entity_id", ""))
	if _entities.has(entity_id):
		return ERR_ALREADY_EXISTS
	_entities[entity_id] = record.duplicate(true)
	return OK

func validate_record(record: Dictionary) -> Error:
	var entity_id := String(record.get("entity_id", ""))
	if entity_id.is_empty():
		return ERR_INVALID_DATA
	if String(record.get("entity_kind", "")).is_empty():
		return ERR_INVALID_DATA
	if String(record.get("scope", "")) != "world_local":
		return ERR_INVALID_DATA
	if int(record.get("schema_version", -1)) != 1:
		return ERR_INVALID_DATA
	if int(record.get("state_version", -1)) < 1:
		return ERR_INVALID_DATA
	if int(record.get("created_at_world_tick", -1)) < 0:
		return ERR_INVALID_DATA
	if typeof(record.get("origin", null)) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA
	for field_name in ["universal_identity_id", "life_episode_id", "body_id", "cognitive_profile_id", "social_identity_id", "species_definition_id", "template_id"]:
		if record.has(field_name) and record[field_name] != null and String(record[field_name]).is_empty():
			return ERR_INVALID_DATA
	return OK

func has_entity(entity_id: String) -> bool:
	return _entities.has(entity_id)

func get_entity(entity_id: String) -> Dictionary:
	if not _entities.has(entity_id):
		return {}
	var stored_record: Dictionary = _entities[entity_id]
	return stored_record.duplicate(true)

func entity_count() -> int:
	return _entities.size()

func all_entities() -> Array:
	var result: Array = []
	for value in _entities.values():
		var stored_record: Dictionary = value
		result.append(stored_record.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("entity_id", "")) < String(b.get("entity_id", ""))
	)
	return result

func clear() -> void:
	_entities.clear()

func to_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"entities": all_entities()
	}

func load_snapshot(data: Dictionary) -> Error:
	if int(data.get("schema_version", -1)) != 1:
		return ERR_INVALID_DATA
	var incoming: Variant = data.get("entities", null)
	if typeof(incoming) != TYPE_ARRAY:
		return ERR_INVALID_DATA
	var rebuilt: Dictionary = {}
	for item in incoming:
		if typeof(item) != TYPE_DICTIONARY:
			return ERR_INVALID_DATA
		var record: Dictionary = item
		var entity_id := String(record.get("entity_id", ""))
		if entity_id.is_empty() or rebuilt.has(entity_id):
			return ERR_INVALID_DATA
		if validate_record(record) != OK:
			return ERR_INVALID_DATA
		rebuilt[entity_id] = record.duplicate(true)
	_entities = rebuilt
	return OK
