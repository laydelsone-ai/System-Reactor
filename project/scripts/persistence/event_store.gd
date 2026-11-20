extends RefCounted

func append_event(world_id: String, event: Dictionary) -> bool:
	var safe_world_id := world_id.replace("/", "_").replace("\\", "_")
	var directory := "user://world_lab/%s" % safe_world_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var path := "%s/events.ndjson" % directory
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	else:
		file.seek_end()
	if file == null:
		push_error("No se pudo abrir el diario local de eventos.")
		return false
	file.store_line(JSON.stringify(event))
	file.flush()
	file.close()
	return true

func load_events_after(world_id: String, cursor_event_id: String, after_tick: int) -> Array:
	var safe_world_id := world_id.replace("/", "_").replace("\\", "_")
	var path := "user://world_lab/%s/events.ndjson" % safe_world_id
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed_events: Array = []
	var found_cursor := cursor_event_id.is_empty()
	var cursor_missing_fallback: Array = []
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if not (parsed is Dictionary):
			continue # una última línea truncada no se aplica parcialmente
		var event: Dictionary = parsed
		if str(event.get("event_id", "")) == cursor_event_id:
			found_cursor = true
			continue
		if found_cursor:
			parsed_events.append(event)
		elif int(event.get("world_tick", 0)) > after_tick:
			cursor_missing_fallback.append(event)
	file.close()
	if not found_cursor:
		push_warning("Cursor del journal no encontrado; se usa recuperación conservadora por world_tick.")
		return cursor_missing_fallback
	return parsed_events
