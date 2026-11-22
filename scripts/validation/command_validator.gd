class_name CommandValidator
extends RefCounted

const SUPPORTED_SCHEMA_VERSION := 1

func validate_register_entity(
	command: Dictionary,
	registry: EntityRegistry,
	processed_command_ids: Dictionary,
	current_world_tick: int
) -> Dictionary:
	if int(command.get("schema_version", -1)) != SUPPORTED_SCHEMA_VERSION:
		return _reject("unsupported_schema", "Versión de comando no compatible.")

	var command_id := String(command.get("command_id", ""))
	if command_id.is_empty():
		return _reject("missing_command_id", "El comando necesita un identificador único.")
	if processed_command_ids.has(command_id):
		return _reject("duplicate_command", "Este command_id ya fue procesado.")
	if String(command.get("action_type", "")) != "RegisterEntity":
		return _reject("unsupported_action", "Acción no implementada en WLA-0A.")
	if String(command.get("domain", "")) != "identity":
		return _reject("wrong_domain", "RegisterEntity debe dirigirse al dominio identity.")
	if String(command.get("scope", "")) != "world_local":
		return _reject("wrong_scope", "WLA-0A solo registra entidades en el mundo local.")
	if int(command.get("state_version", -1)) < 0:
		return _reject("invalid_command_state_version", "state_version del comando no puede ser negativo.")
	if typeof(command.get("target_ids", null)) != TYPE_ARRAY:
		return _reject("invalid_targets", "target_ids debe ser un array.")
	if typeof(command.get("preconditions", null)) != TYPE_DICTIONARY:
		return _reject("invalid_preconditions", "preconditions debe ser un objeto.")
	var preconditions: Dictionary = command.get("preconditions", {})
	if not bool(preconditions.get("entity_id_absent", false)):
		return _reject("missing_entity_absence_precondition", "RegisterEntity requiere la precondición entity_id_absent.")
	if typeof(command.get("resource_requirements", null)) != TYPE_ARRAY:
		return _reject("invalid_resource_requirements", "resource_requirements debe ser un array.")

	var actor_id := String(command.get("actor_id", ""))
	if actor_id.is_empty():
		return _reject("missing_actor", "El comando necesita actor.")
	if actor_id != "system" and not registry.has_entity(actor_id):
		return _reject("unknown_actor", "El actor no existe en el registro de entidades.")

	var tick := int(command.get("created_at_world_tick", -1))
	if tick < 0 or tick > current_world_tick:
		return _reject("invalid_world_tick", "El comando usa un world_tick inválido o futuro.")

	var payload: Variant = command.get("payload", null)
	if typeof(payload) != TYPE_DICTIONARY:
		return _reject("invalid_payload", "El payload del comando no es un objeto.")
	var payload_dictionary: Dictionary = payload
	var entity: Variant = payload_dictionary.get("entity", null)
	if typeof(entity) != TYPE_DICTIONARY:
		return _reject("missing_entity", "El comando no contiene el registro de entidad.")

	var record: Dictionary = entity
	var entity_id := String(record.get("entity_id", ""))
	if entity_id.is_empty():
		return _reject("missing_entity_id", "La entidad necesita entity_id.")
	if registry.has_entity(entity_id):
		return _reject("entity_already_exists", "El entity_id ya está registrado y no se puede reutilizar.")
	if String(record.get("entity_kind", "")).is_empty():
		return _reject("missing_entity_kind", "La entidad necesita entity_kind.")
	if typeof(record.get("origin", null)) != TYPE_DICTIONARY:
		return _reject("missing_entity_origin", "La entidad necesita procedencia en origin.")
	if String(record.get("scope", "")) != "world_local":
		return _reject("invalid_entity_scope", "La entidad debe pertenecer al ámbito world_local.")
	if int(record.get("schema_version", -1)) != 1:
		return _reject("invalid_entity_schema", "Versión de entidad no compatible.")
	if int(record.get("state_version", -1)) < 1:
		return _reject("invalid_state_version", "state_version debe comenzar en 1 o más.")
	if int(record.get("created_at_world_tick", -1)) != tick:
		return _reject("entity_tick_mismatch", "La fecha de creación de la entidad debe coincidir con la del comando.")

	# Las identidades vital, corporal, cognitiva y social no se confunden.
	# En WLA-0A pueden omitirse cuando el tipo de entidad aún no las requiere.
	for field_name in ["universal_identity_id", "life_episode_id", "body_id", "cognitive_profile_id", "social_identity_id", "species_definition_id", "template_id"]:
		if record.has(field_name) and record[field_name] != null and String(record[field_name]).is_empty():
			return _reject("empty_identity_dimension", "%s no puede ser una cadena vacía." % field_name)

	return {"ok": true, "code": "accepted", "message": "Comando validado."}

func _reject(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
