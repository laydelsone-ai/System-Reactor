class_name SystemCore
extends RefCounted

const IdFactoryScript = preload("res://scripts/core/id_factory.gd")
const WorldClockScript = preload("res://scripts/core/world_clock.gd")
const EntityRegistryScript = preload("res://scripts/domain/entity_registry.gd")
const CommandValidatorScript = preload("res://scripts/validation/command_validator.gd")
const CommandEnvelopeScript = preload("res://scripts/contracts/command_envelope.gd")
const EventEnvelopeScript = preload("res://scripts/contracts/event_envelope.gd")
const PersistenceEngineScript = preload("res://scripts/persistence/persistence_engine.gd")

const APP_VERSION := "0.3.0-wla0b-autonomy"
const CONTENT_VERSION := "0.2.0"
const GENERATOR_VERSION := "wla0b-autonomy-1"

var persistence: PersistenceEngine
var clock: WorldClock
var registry: EntityRegistry
var validator: CommandValidator
var world_id: String = ""
var world_metadata: Dictionary = {}
var last_event_sequence: int = 0
var event_count: int = 0
var processed_command_ids: Dictionary = {}
var diagnostics: Array[String] = []
var ready: bool = false
var recovery_required: bool = false

func _init(storage_root: String = "") -> void:
	persistence = PersistenceEngineScript.new(storage_root)
	clock = WorldClockScript.new()
	registry = EntityRegistryScript.new()
	validator = CommandValidatorScript.new()

func open_last_or_create() -> Dictionary:
	var index_result: Dictionary = persistence.load_last_world_id()
	if not index_result.get("ok", false):
		return {"ok": false, "message": index_result.get("message", "No se pudo leer el índice."), "error": index_result.get("error", ERR_FILE_CORRUPT)}
	var existing_id := String(index_result.get("world_id", ""))
	if existing_id.is_empty():
		return create_new_world()
	# Nunca se crea silenciosamente un mundo nuevo si el anterior no se puede abrir.
	return open_world(existing_id)

func create_new_world() -> Dictionary:
	var new_world_id := IdFactoryScript.new_id("wld")
	var ensure_error := persistence.ensure_world_directory(new_world_id)
	if ensure_error != OK:
		return {"ok": false, "error": ensure_error, "message": "No se pudo crear el directorio del mundo."}

	_clear_runtime()
	world_id = new_world_id
	var seed_value := int(Time.get_ticks_usec()) ^ int(OS.get_process_id()) ^ int(randi())
	world_metadata = {
		"world_id": world_id,
		"world_schema_version": 1,
		"rules_version": "SR-01..SR-15@2026-11-20",
		"application_version": APP_VERSION,
		"content_version": CONTENT_VERSION,
		"generator_version": GENERATOR_VERSION,
		"seed": seed_value,
		"created_at_utc": Time.get_datetime_string_from_system(true),
		"scope": "world_local"
	}

	var init_command_id := IdFactoryScript.new_id("cmd")
	var init_event := EventEnvelopeScript.create(
		IdFactoryScript.new_id("evt"), world_id, "WorldInitialized", 1, clock.world_tick,
		init_command_id, "system", {"world_metadata": world_metadata.duplicate(true)}, "system_bootstrap"
	)
	var append_result: Dictionary = persistence.append_event(world_id, init_event)
	if not append_result.get("ok", false):
		_clear_runtime()
		return {"ok": false, "error": append_result.get("error", ERR_CANT_CREATE), "message": append_result.get("message", "No se pudo registrar WorldInitialized.")}

	last_event_sequence = 1
	event_count = 1
	processed_command_ids[init_command_id] = true
	var snapshot_result := save_checkpoint("world_created")
	if not snapshot_result.get("ok", false):
		return snapshot_result
	var index_error := persistence.save_last_world_id(world_id)
	if index_error != OK:
		return {"ok": false, "error": index_error, "message": "El mundo existe y está guardado, pero no se pudo actualizar el índice de último mundo."}
	ready = true
	return {"ok": true, "world_id": world_id, "message": "Mundo local inicializado.", "diagnostics": diagnostics.duplicate()}

func open_world(target_world_id: String) -> Dictionary:
	if target_world_id.is_empty() or not target_world_id.is_valid_filename():
		return {"ok": false, "error": ERR_INVALID_PARAMETER, "message": "world_id inválido."}
	_clear_runtime()
	world_id = target_world_id

	var snapshot_result: Dictionary = persistence.load_snapshot(world_id)
	if not snapshot_result.get("ok", false):
		return {"ok": false, "error": snapshot_result.get("error", ERR_FILE_CORRUPT), "message": snapshot_result.get("message", "No se pudo cargar snapshot.")}
	for diagnostic in snapshot_result.get("diagnostics", []):
		diagnostics.append(String(diagnostic))

	var snapshot: Dictionary = snapshot_result.get("snapshot", {})
	if String(snapshot.get("world_id", "")) != world_id:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "El snapshot pertenece a otro world_id."}
	if int(snapshot.get("world_schema_version", -1)) != 1:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "Versión de mundo no compatible."}

	var clock_value: Variant = snapshot.get("world_clock", null)
	if typeof(clock_value) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "WorldClock del snapshot inválido."}
	var clock_dictionary: Dictionary = clock_value
	var clock_error := clock.load_snapshot(clock_dictionary)
	if clock_error != OK:
		return {"ok": false, "error": clock_error, "message": "WorldClock del snapshot inválido."}
	var registry_value: Variant = snapshot.get("entity_registry", null)
	if typeof(registry_value) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "Entity Registry del snapshot inválido."}
	var registry_dictionary: Dictionary = registry_value
	var registry_error := registry.load_snapshot(registry_dictionary)
	if registry_error != OK:
		return {"ok": false, "error": registry_error, "message": "Entity Registry del snapshot inválido."}
	var metadata_value: Variant = snapshot.get("world_metadata", null)
	if typeof(metadata_value) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "Metadata del mundo inválida."}
	var metadata_dictionary: Dictionary = metadata_value
	world_metadata = metadata_dictionary.duplicate(true)
	last_event_sequence = int(snapshot.get("last_event_sequence", -1))
	if last_event_sequence < 1:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "Cursor de eventos del snapshot inválido."}

	var journal_result: Dictionary = persistence.read_journal(world_id)
	if not journal_result.get("ok", false):
		for diagnostic in journal_result.get("diagnostics", []):
			diagnostics.append(String(diagnostic))
		return {"ok": false, "error": journal_result.get("error", ERR_FILE_CORRUPT), "message": "El journal no permite una recuperación segura."}
	for diagnostic in journal_result.get("diagnostics", []):
		diagnostics.append(String(diagnostic))

	var events: Array = journal_result.get("events", [])
	var journal_last_sequence := int(journal_result.get("last_sequence", 0))
	if journal_last_sequence < last_event_sequence:
		return {"ok": false, "error": ERR_FILE_CORRUPT, "message": "El journal termina antes del cursor del snapshot; no se continuará con historia incompleta."}

	for event_value in events:
		var event: Dictionary = event_value
		if String(event.get("world_id", "")) != world_id:
			return {"ok": false, "error": ERR_FILE_CORRUPT, "message": "El journal contiene un evento de otro mundo."}
		var command_id := String(event.get("command_id", ""))
		if not command_id.is_empty():
			processed_command_ids[command_id] = true
		var sequence := int(event.get("sequence", 0))
		if sequence <= last_event_sequence:
			continue
		var projection_result := _project_confirmed_event(event)
		if not projection_result.get("ok", false):
			return {"ok": false, "error": projection_result.get("error", ERR_INVALID_DATA), "message": projection_result.get("message", "Proyección de evento fallida.")}
		last_event_sequence = sequence

	last_event_sequence = max(last_event_sequence, journal_last_sequence)
	event_count = events.size()
	ready = true
	return {
		"ok": true,
		"world_id": world_id,
		"message": "Mundo recuperado.",
		"snapshot_source": snapshot_result.get("source", "snapshot"),
		"replayed_events": max(0, journal_last_sequence - int(snapshot.get("last_event_sequence", 0))),
		"diagnostics": diagnostics.duplicate()
	}

func execute_register_entity(record: Dictionary, command_id: String = "", source: String = "diagnostics") -> Dictionary:
	if not ready or recovery_required:
		return {"accepted": false, "code": "core_not_ready", "message": "El núcleo no está listo o requiere recuperación."}
	var final_command_id := command_id if not command_id.is_empty() else IdFactoryScript.new_id("cmd")
	var command := CommandEnvelopeScript.create_register_entity(
		final_command_id, "system", clock.world_tick, record, source
	)
	var validation: Dictionary = validator.validate_register_entity(command, registry, processed_command_ids, clock.world_tick)
	if not validation.get("ok", false):
		return {"accepted": false, "code": validation.get("code", "rejected"), "message": validation.get("message", "Comando rechazado."), "command_id": final_command_id}

	var next_sequence := last_event_sequence + 1
	var event := EventEnvelopeScript.create(
		IdFactoryScript.new_id("evt"), world_id, "EntityRegistered", next_sequence,
		clock.world_tick, final_command_id, "system", {"entity": record.duplicate(true)}, source, "EntityRegistry"
	)
	var append_result: Dictionary = persistence.append_event(world_id, event)
	if not append_result.get("ok", false):
		return {"accepted": false, "code": "journal_write_failed", "message": append_result.get("message", "No se pudo persistir el evento."), "command_id": final_command_id}

	# El journal es la confirmación durable. Si la proyección falla después de
	# escribir, se bloquean nuevas escrituras y se exige reabrir/reproyectar.
	var projection_result := _project_confirmed_event(event)
	if not projection_result.get("ok", false):
		recovery_required = true
		diagnostics.append("Evento confirmado pero proyección pendiente; se requiere recuperación antes de escribir más.")
		return {"accepted": false, "code": "projection_requires_recovery", "message": "El evento quedó en el journal; reabre el mundo para recuperar la proyección.", "command_id": final_command_id}

	last_event_sequence = next_sequence
	event_count += 1
	processed_command_ids[final_command_id] = true
	return {"accepted": true, "code": "confirmed", "message": "Entidad registrada mediante comando validado.", "command_id": final_command_id, "event_id": event["event_id"], "entity_id": record.get("entity_id", "")}

func commit_domain_event(
	event_type: String,
	actor_id: String,
	payload: Dictionary,
	authority: String,
	origin: String,
	tick_override: int = -1
) -> Dictionary:
	## Confirma un evento producido por un dominio después de validar su comando.
	## No concede autoridad al presentador: el dominio debe validar precondiciones
	## y pasar aquí únicamente el resultado ya resuelto.
	if not ready or recovery_required:
		return {"accepted": false, "code": "core_not_ready", "message": "El núcleo no está listo o requiere recuperación."}
	if event_type.strip_edges().is_empty() or authority.strip_edges().is_empty() or origin.strip_edges().is_empty():
		return {"accepted": false, "code": "invalid_event_contract", "message": "El evento necesita tipo, autoridad y procedencia."}
	var commit_tick := clock.world_tick if tick_override < 0 else tick_override
	if commit_tick < clock.world_tick:
		return {"accepted": false, "code": "time_regression", "message": "El evento no puede retroceder el reloj del mundo."}
	if actor_id.is_empty():
		return {"accepted": false, "code": "missing_actor", "message": "El evento necesita actor o system."}
	var command_id := IdFactoryScript.new_id("cmd")
	var next_sequence := last_event_sequence + 1
	var event := EventEnvelopeScript.create(
		IdFactoryScript.new_id("evt"), world_id, event_type, next_sequence,
		commit_tick, command_id, actor_id, payload, origin, authority
	)
	var extra_participants: Variant = payload.get("participants", [])
	if typeof(extra_participants) == TYPE_ARRAY:
		for participant_value in extra_participants:
			var participant_id := String(participant_value)
			if not participant_id.is_empty() and not event["participants"].has(participant_id):
				event["participants"].append(participant_id)
	var append_result: Dictionary = persistence.append_event(world_id, event)
	if not append_result.get("ok", false):
		return {"accepted": false, "code": "journal_write_failed", "message": append_result.get("message", "No se pudo confirmar el evento.")}
	var clock_error := clock.advance_to(commit_tick)
	if clock_error != OK:
		recovery_required = true
		diagnostics.append("Evento confirmado con avance temporal pendiente; se requiere recuperación.")
		return {"accepted": false, "code": "clock_projection_failed", "message": "El evento quedó en journal, pero el reloj requiere recuperación."}
	last_event_sequence = next_sequence
	event_count += 1
	processed_command_ids[command_id] = true
	return {
		"accepted": true, "code": "confirmed", "message": "Evento de dominio confirmado.",
		"event_id": event["event_id"], "command_id": command_id, "sequence": next_sequence,
		"world_tick": commit_tick
	}

func register_diagnostic_fixture(label: String) -> Dictionary:
	var safe_label := label.strip_edges()
	if safe_label.is_empty():
		safe_label = "WLA-0A persistence probe"
	var record := {
		"entity_id": IdFactoryScript.new_id("ent"),
		"entity_kind": "diagnostic_fixture",
		"scope": "world_local",
		"schema_version": 1,
		"state_version": 1,
		"created_at_world_tick": clock.world_tick,
		"origin": {"type": "technical_test", "stage": "WLA-0A"},
		"display_label": safe_label,
		"asset_key": null
	}
	return execute_register_entity(record, "", "diagnostics_fixture")

func save_checkpoint(reason: String = "manual") -> Dictionary:
	if world_id.is_empty():
		return {"ok": false, "error": ERR_UNCONFIGURED, "message": "No hay mundo activo."}
	var snapshot := {
		"snapshot_schema_version": 1,
		"world_schema_version": 1,
		"world_id": world_id,
		"world_metadata": world_metadata.duplicate(true),
		"world_clock": clock.to_snapshot(),
		"entity_registry": registry.to_snapshot(),
		"last_event_sequence": last_event_sequence,
		"event_count_at_checkpoint": event_count,
		"checkpoint_reason": reason,
		"checkpointed_at_utc": Time.get_datetime_string_from_system(true)
	}
	return persistence.save_snapshot(snapshot)

func reload_from_disk() -> Dictionary:
	if world_id.is_empty():
		return {"ok": false, "error": ERR_UNCONFIGURED, "message": "No hay mundo activo."}
	var target := world_id
	return open_world(target)

func close_world() -> Dictionary:
	if not ready or world_id.is_empty():
		return {"ok": true, "message": "No había mundo activo."}
	return save_checkpoint("application_close")

func diagnostics_report() -> Dictionary:
	return {
		"ready": ready,
		"recovery_required": recovery_required,
		"world_id": world_id,
		"world_tick": clock.world_tick,
		"entity_count": registry.entity_count(),
		"event_count": event_count,
		"last_event_sequence": last_event_sequence,
		"rules_version": world_metadata.get("rules_version", ""),
		"application_version": APP_VERSION,
		"storage_root": persistence.storage_root,
		"diagnostics": diagnostics.duplicate()
	}

func _project_confirmed_event(event: Dictionary) -> Dictionary:
	if String(event.get("confirmation_status", "")) != "confirmed":
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "No se proyectan eventos que no estén confirmados."}
	var event_tick := int(event.get("world_tick", -1))
	if event_tick < 0 or event_tick < clock.world_tick:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "El evento usa un tick inválido o regresivo."}
	if event_tick > clock.world_tick:
		var clock_error := clock.advance_to(event_tick)
		if clock_error != OK:
			return {"ok": false, "error": clock_error, "message": "No se pudo proyectar el tiempo del evento."}
	var event_payload: Variant = event.get("payload", null)
	if typeof(event_payload) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "El evento no contiene un payload de objeto."}
	var payload_dictionary: Dictionary = event_payload
	match String(event.get("event_type", "")):
		"WorldInitialized":
			var metadata: Variant = payload_dictionary.get("world_metadata", null)
			if typeof(metadata) != TYPE_DICTIONARY:
				return {"ok": false, "error": ERR_INVALID_DATA, "message": "WorldInitialized no contiene metadata válida."}
			var metadata_dictionary: Dictionary = metadata
			if String(metadata_dictionary.get("world_id", "")) != world_id:
				return {"ok": false, "error": ERR_INVALID_DATA, "message": "WorldInitialized no coincide con el mundo activo."}
			return {"ok": true}
		"EntityRegistered":
			var entity: Variant = payload_dictionary.get("entity", null)
			if typeof(entity) != TYPE_DICTIONARY:
				return {"ok": false, "error": ERR_INVALID_DATA, "message": "EntityRegistered no contiene entidad."}
			var entity_dictionary: Dictionary = entity
			var register_error: Error = registry.register_entity(entity_dictionary)
			if register_error != OK:
				return {"ok": false, "error": register_error, "message": "La proyección de entidad falló."}
			return {"ok": true}
		"SimulationStepCommitted", "ObserverInterventionCommitted":
			# El Kernel conserva el evento. AutonomyRuntime proyecta su state_delta
			# después de restaurar el snapshot de dominio correspondiente.
			return {"ok": true}
		_:
			diagnostics.append("Evento %s (seq %d) confirmado pero sin proyección de recuperación en WLA-0A; se conservó en el journal." % [event.get("event_type", "?"), int(event.get("sequence", 0))])
			return {"ok": true}

func _clear_runtime() -> void:
	clock = WorldClockScript.new()
	registry = EntityRegistryScript.new()
	validator = CommandValidatorScript.new()
	world_id = ""
	world_metadata = {}
	last_event_sequence = 0
	event_count = 0
	processed_command_ids.clear()
	diagnostics.clear()
	ready = false
	recovery_required = false
