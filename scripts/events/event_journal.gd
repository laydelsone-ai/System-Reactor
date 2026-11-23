class_name EventJournal
extends RefCounted

func append_event(path: String, event: Dictionary) -> Dictionary:
	var parent_dir := path.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent_dir))
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": mkdir_error, "message": "No se pudo crear el directorio del journal."}

	var file: FileAccess
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": FileAccess.get_open_error(), "message": "No se pudo abrir el journal."}

	file.seek_end()
	# JSON remains human-readable, while the binary Variant sidecar preserves every
	# numeric bit pattern and the original Variant types for deterministic replay.
	var stored_event := event.duplicate(true)
	var payload_value: Variant = stored_event.get("payload", {})
	stored_event["payload_variant_encoding"] = "godot_variant_base64_v1"
	stored_event["payload_variant_base64"] = Marshalls.raw_to_base64(var_to_bytes(payload_value))
	file.store_line(JSON.stringify(stored_event, "", true, true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {"ok": false, "error": write_error, "message": "No se pudo confirmar la escritura del evento."}
	return {"ok": true, "error": OK, "message": "Evento añadido al journal."}

func read_all(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": true,
			"events": [],
			"diagnostics": ["El journal todavía no existe; se tratará como vacío."],
			"last_sequence": 0
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "events": [], "diagnostics": ["No se pudo leer el journal."], "error": FileAccess.get_open_error(), "last_sequence": 0}
	var raw_text := file.get_as_text()
	file.close()

	var lines := raw_text.split("\n", false)
	var events: Array = []
	var diagnostics: Array[String] = []
	var seen_event_ids: Dictionary = {}
	var previous_sequence := 0
	var non_empty_indexes: Array[int] = []
	for i in range(lines.size()):
		if not String(lines[i]).strip_edges().is_empty():
			non_empty_indexes.append(i)
	var final_non_empty_index := -1
	if not non_empty_indexes.is_empty():
		final_non_empty_index = non_empty_indexes[non_empty_indexes.size() - 1]

	for i in range(lines.size()):
		var line := String(lines[i]).strip_edges()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			if i == final_non_empty_index:
				diagnostics.append("Se descartó una última línea incompleta del journal; los eventos completos se conservaron.")
				continue
			return {
				"ok": false,
				"events": events,
				"diagnostics": diagnostics + ["Corrupción en una línea intermedia del journal; se detuvo la recuperación segura."],
				"error": ERR_FILE_CORRUPT,
				"last_sequence": previous_sequence
			}

		var event: Dictionary = parsed
		var payload_encoding := String(event.get("payload_variant_encoding", ""))
		if not payload_encoding.is_empty():
			if payload_encoding != "godot_variant_base64_v1":
				return {
					"ok": false,
					"events": events,
					"diagnostics": diagnostics + ["Codificación binaria de payload desconocida en el journal."],
					"error": ERR_INVALID_DATA,
					"last_sequence": previous_sequence
				}
			var payload_bytes := Marshalls.base64_to_raw(String(event.get("payload_variant_base64", "")))
			if payload_bytes.is_empty():
				return {
					"ok": false,
					"events": events,
					"diagnostics": diagnostics + ["Payload binario ausente o inválido en el journal."],
					"error": ERR_FILE_CORRUPT,
					"last_sequence": previous_sequence
				}
			var exact_payload: Variant = bytes_to_var(payload_bytes)
			if typeof(exact_payload) != TYPE_DICTIONARY:
				return {
					"ok": false,
					"events": events,
					"diagnostics": diagnostics + ["Payload binario no contiene un Dictionary válido."],
					"error": ERR_FILE_CORRUPT,
					"last_sequence": previous_sequence
				}
			event["payload"] = exact_payload
		var event_id := String(event.get("event_id", ""))
		var sequence := int(event.get("sequence", -1))
		var world_tick := int(event.get("world_tick", -1))
		if event_id.is_empty() or sequence < 1 or world_tick < 0 or seen_event_ids.has(event_id):
			return {
				"ok": false,
				"events": events,
				"diagnostics": diagnostics + ["Evento con ID/secuencia inválidos o event_id duplicado."],
				"error": ERR_FILE_CORRUPT,
				"last_sequence": previous_sequence
			}
		if sequence != previous_sequence + 1:
			return {
				"ok": false,
				"events": events,
				"diagnostics": diagnostics + ["La secuencia del journal no es continua; se detuvo la recuperación."],
				"error": ERR_FILE_CORRUPT,
				"last_sequence": previous_sequence
			}
		if int(event.get("schema_version", -1)) != 1 or String(event.get("confirmation_status", "")) != "confirmed":
			return {
				"ok": false,
				"events": events,
				"diagnostics": diagnostics + ["El journal contiene un evento no confirmado o con esquema desconocido."],
				"error": ERR_INVALID_DATA,
				"last_sequence": previous_sequence
			}
		if String(event.get("world_id", "")).is_empty() or String(event.get("event_type", "")).is_empty():
			return {
				"ok": false,
				"events": events,
				"diagnostics": diagnostics + ["Evento sin world_id o event_type."],
				"error": ERR_FILE_CORRUPT,
				"last_sequence": previous_sequence
			}
		if typeof(event.get("payload", null)) != TYPE_DICTIONARY or String(event.get("authority", "")).is_empty() or String(event.get("origin", "")).is_empty():
			return {
				"ok": false,
				"events": events,
				"diagnostics": diagnostics + ["Evento sin payload, autoridad o procedencia válida."],
				"error": ERR_FILE_CORRUPT,
				"last_sequence": previous_sequence
			}

		seen_event_ids[event_id] = true
		previous_sequence = sequence
		events.append(event.duplicate(true))

	return {"ok": true, "events": events, "diagnostics": diagnostics, "last_sequence": previous_sequence, "error": OK}
