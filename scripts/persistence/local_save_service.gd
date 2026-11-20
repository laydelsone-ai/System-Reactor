extends RefCounted

const ROOT_DIR := "user://world_lab"
const SNAPSHOT_PATH := "user://world_lab/snapshot.json"
const TEMP_PATH := "user://world_lab/snapshot.json.tmp"
const BACKUP_PATH := "user://world_lab/snapshot.json.bak"

func load_snapshot() -> Dictionary:
	var current := _read_json_dictionary(SNAPSHOT_PATH)
	if not current.is_empty():
		return current
	return _read_json_dictionary(BACKUP_PATH)

func save_snapshot(snapshot: Dictionary) -> bool:
	var absolute_root := ProjectSettings.globalize_path(ROOT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var temp_file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if temp_file == null:
		push_error("No se pudo crear snapshot temporal: %s" % error_string(FileAccess.get_open_error()))
		return false
	temp_file.store_string(JSON.stringify(snapshot))
	temp_file.flush()
	temp_file.close()

	var target_abs := ProjectSettings.globalize_path(SNAPSHOT_PATH)
	var temp_abs := ProjectSettings.globalize_path(TEMP_PATH)
	var backup_abs := ProjectSettings.globalize_path(BACKUP_PATH)
	if FileAccess.file_exists(SNAPSHOT_PATH):
		DirAccess.copy_absolute(target_abs, backup_abs)
		DirAccess.remove_absolute(target_abs)
	var rename_error := DirAccess.rename_absolute(temp_abs, target_abs)
	if rename_error != OK:
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.copy_absolute(backup_abs, target_abs)
		push_error("No se pudo reemplazar snapshot: %s" % error_string(rename_error))
		return false
	return true

func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}
