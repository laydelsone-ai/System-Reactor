class_name PersistenceEngine
extends RefCounted

const DEFAULT_ROOT := "user://world_laboratory"
const SNAPSHOT_SCHEMA_VERSION := 1

var storage_root: String

func _init(root_path: String = "") -> void:
	storage_root = DEFAULT_ROOT if root_path.is_empty() else root_path

func ensure_world_directory(world_id: String) -> Error:
	if world_id.is_empty() or not world_id.is_valid_filename():
		return ERR_INVALID_PARAMETER
	var world_path := _world_dir(world_id)
	var absolute_path := ProjectSettings.globalize_path(world_path)
	var err := DirAccess.make_dir_recursive_absolute(absolute_path)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return err
	return OK

func journal_path(world_id: String) -> String:
	return "%s/events.ndjson" % _world_dir(world_id)

func snapshot_path(world_id: String) -> String:
	return "%s/snapshot.json" % _world_dir(world_id)

func snapshot_backup_path(world_id: String) -> String:
	return "%s/snapshot.bak" % _world_dir(world_id)

func append_event(world_id: String, event: Dictionary) -> Dictionary:
	var ensure_error := ensure_world_directory(world_id)
	if ensure_error != OK:
		return {"ok": false, "error": ensure_error, "message": "No se pudo preparar el almacenamiento del mundo."}
	var journal := EventJournal.new()
	return journal.append_event(journal_path(world_id), event)

func read_journal(world_id: String) -> Dictionary:
	var journal := EventJournal.new()
	return journal.read_all(journal_path(world_id))

func save_snapshot(snapshot: Dictionary) -> Dictionary:
	var world_id := String(snapshot.get("world_id", ""))
	var ensure_error := ensure_world_directory(world_id)
	if ensure_error != OK:
		return {"ok": false, "error": ensure_error, "message": "world_id o directorio inválido."}

	var payload_text := JSON.stringify(snapshot)
	var wrapper := {
		"envelope_version": 1,
		"payload_json": payload_text,
		"sha256": payload_text.sha256_text()
	}
	var final_path := snapshot_path(world_id)
	var temp_path := "%s.tmp" % final_path
	var backup_path := snapshot_backup_path(world_id)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": FileAccess.get_open_error(), "message": "No se pudo crear snapshot temporal."}
	file.store_string(JSON.stringify(wrapper))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {"ok": false, "error": write_error, "message": "Falló la escritura del snapshot temporal."}

	var verification := _read_snapshot_file(temp_path)
	if not verification.get("ok", false):
		return {"ok": false, "error": ERR_FILE_CORRUPT, "message": "El snapshot temporal no superó la verificación."}

	if FileAccess.file_exists(final_path):
		var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(final_path), ProjectSettings.globalize_path(backup_path))
		if copy_error != OK:
			return {"ok": false, "error": copy_error, "message": "No se pudo proteger el snapshot anterior."}

	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(final_path))
	if rename_error != OK:
		return {"ok": false, "error": rename_error, "message": "No se pudo publicar el snapshot verificado."}
	return {"ok": true, "error": OK, "message": "Snapshot guardado y verificado."}

func load_snapshot(world_id: String) -> Dictionary:
	var main_path := snapshot_path(world_id)
	var backup_path := snapshot_backup_path(world_id)
	if FileAccess.file_exists(main_path):
		var main_result := _read_snapshot_file(main_path)
		if main_result.get("ok", false):
			main_result["source"] = "snapshot"
			return main_result
		var main_diagnostic := String(main_result.get("message", "Snapshot principal inválido."))
		if FileAccess.file_exists(backup_path):
			var backup_result := _read_snapshot_file(backup_path)
			if backup_result.get("ok", false):
				backup_result["source"] = "backup"
				backup_result["diagnostics"] = [main_diagnostic, "Se recuperó desde el snapshot de respaldo."]
				return backup_result
		return {"ok": false, "error": ERR_FILE_CORRUPT, "message": main_diagnostic + " El respaldo también es inválido o no existe."}
	if FileAccess.file_exists(backup_path):
		var backup_only := _read_snapshot_file(backup_path)
		if backup_only.get("ok", false):
			backup_only["source"] = "backup"
			backup_only["diagnostics"] = ["Se recuperó usando únicamente el snapshot de respaldo."]
			return backup_only
	return {"ok": false, "error": ERR_FILE_NOT_FOUND, "message": "No existe snapshot para este mundo."}

func save_last_world_id(world_id: String) -> Error:
	if world_id.is_empty() or not world_id.is_valid_filename():
		return ERR_INVALID_PARAMETER
	var parent := storage_root
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent))
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return mkdir_error
	var final_path := "%s/last_world.json" % storage_root
	var temp_path := "%s.tmp" % final_path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema_version": 1, "world_id": world_id}))
	file.flush()
	var err := file.get_error()
	file.close()
	if err != OK:
		return err
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(final_path))

func load_last_world_id() -> Dictionary:
	var path := "%s/last_world.json" % storage_root
	if not FileAccess.file_exists(path):
		return {"ok": true, "world_id": "", "message": "No existe mundo previo."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "world_id": "", "error": FileAccess.get_open_error(), "message": "No se pudo leer el índice del mundo."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schema_version", -1)) != 1:
		return {"ok": false, "world_id": "", "error": ERR_FILE_CORRUPT, "message": "El índice del mundo está corrupto."}
	var world_id := String(parsed.get("world_id", ""))
	if world_id.is_empty() or not world_id.is_valid_filename():
		return {"ok": false, "world_id": "", "error": ERR_INVALID_DATA, "message": "El índice contiene un world_id inválido."}
	return {"ok": true, "world_id": world_id, "message": "Índice recuperado."}

func _read_snapshot_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": FileAccess.get_open_error(), "message": "No se pudo abrir %s." % path}
	var wrapper: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(wrapper) != TYPE_DICTIONARY or int(wrapper.get("envelope_version", -1)) != 1:
		return {"ok": false, "error": ERR_FILE_CORRUPT, "message": "Envelope de snapshot inválido: %s." % path}
	var payload_text := String(wrapper.get("payload_json", ""))
	var expected_hash := String(wrapper.get("sha256", ""))
	if payload_text.is_empty() or expected_hash.is_empty() or payload_text.sha256_text() != expected_hash:
		return {"ok": false, "error": ERR_FILE_CORRUPT, "message": "Checksum del snapshot inválido: %s." % path}
	var payload: Variant = JSON.parse_string(payload_text)
	if typeof(payload) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_FILE_CORRUPT, "message": "Contenido de snapshot inválido: %s." % path}
	if int(payload.get("snapshot_schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
		return {"ok": false, "error": ERR_INVALID_DATA, "message": "Versión de snapshot no compatible."}
	return {"ok": true, "snapshot": payload, "error": OK, "message": "Snapshot válido."}

func _world_dir(world_id: String) -> String:
	return "%s/worlds/%s" % [storage_root, world_id]
