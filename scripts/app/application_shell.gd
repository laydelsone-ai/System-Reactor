extends Control

const SystemCoreScript = preload("res://scripts/core/system_core.gd")

var _core: SystemCore
var _status_label: Label
var _diagnostics_label: RichTextLabel
var _fixture_input: LineEdit
var _message_label: Label

func _ready() -> void:
	_core = SystemCoreScript.new()
	_build_interface()
	var boot_result: Dictionary = _core.open_last_or_create()
	if not boot_result.get("ok", false):
		_set_message("ERROR DE ARRANQUE: %s" % boot_result.get("message", "desconocido"))
	else:
		_set_message(String(boot_result.get("message", "Núcleo iniciado.")))
	_refresh()

func _notification(what: int) -> void:
	if _core == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		var pause_save: Dictionary = _core.save_checkpoint("android_application_paused")
		if not pause_save.get("ok", false):
			push_error("WLA-0A: no se pudo guardar al pausar: %s" % pause_save.get("message", "error"))
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		var close_result: Dictionary = _core.close_world()
		if not close_result.get("ok", false):
			push_error("WLA-0A: no se pudo guardar al cerrar: %s" % close_result.get("message", "error"))
		get_tree().quit()

func _exit_tree() -> void:
	if _core != null and _core.ready:
		_core.close_world()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#101720")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)

	var title := Label.new()
	title.text = "WORLD LABORATORY  /  SISTEMA REACTOR"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#e8f0f7"))
	outer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "WLA-0A · Núcleo y persistencia · Implementación nueva basada en SR-01 a SR-15"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#9fb0c0"))
	outer.add_child(subtitle)

	var separator := HSeparator.new()
	outer.add_child(separator)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color("#d5e2ee"))
	outer.add_child(_status_label)

	var fixture_row := HBoxContainer.new()
	fixture_row.add_theme_constant_override("separation", 8)
	outer.add_child(fixture_row)
	_fixture_input = LineEdit.new()
	_fixture_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fixture_input.placeholder_text = "Etiqueta de prueba (no es contenido canónico)"
	fixture_row.add_child(_fixture_input)
	var fixture_button := Button.new()
	fixture_button.text = "Registrar prueba"
	fixture_button.pressed.connect(_on_register_fixture)
	fixture_row.add_child(fixture_button)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	outer.add_child(button_row)
	var save_button := Button.new()
	save_button.text = "Guardar checkpoint"
	save_button.pressed.connect(_on_save_checkpoint)
	button_row.add_child(save_button)
	var reload_button := Button.new()
	reload_button.text = "Reabrir desde disco"
	reload_button.pressed.connect(_on_reload)
	button_row.add_child(reload_button)

	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.add_theme_color_override("font_color", Color("#9fd6b2"))
	outer.add_child(_message_label)

	var diagnostic_title := Label.new()
	diagnostic_title.text = "DIAGNÓSTICO DEL NÚCLEO"
	diagnostic_title.add_theme_font_size_override("font_size", 16)
	diagnostic_title.add_theme_color_override("font_color", Color("#e8f0f7"))
	outer.add_child(diagnostic_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_diagnostics_label = RichTextLabel.new()
	_diagnostics_label.fit_content = true
	_diagnostics_label.scroll_active = false
	_diagnostics_label.bbcode_enabled = false
	_diagnostics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_diagnostics_label.add_theme_color_override("default_color", Color("#c0ccd8"))
	scroll.add_child(_diagnostics_label)

func _on_register_fixture() -> void:
	if _core == null or not _core.ready:
		_set_message("El núcleo no está listo.")
		return
	var result: Dictionary = _core.register_diagnostic_fixture(_fixture_input.text)
	_set_message(String(result.get("message", "Sin respuesta.")))
	if result.get("accepted", false):
		_fixture_input.clear()
	_refresh()

func _on_save_checkpoint() -> void:
	var result: Dictionary = _core.save_checkpoint("manual_ui")
	_set_message(String(result.get("message", "Sin respuesta.")))
	_refresh()

func _on_reload() -> void:
	var result: Dictionary = _core.reload_from_disk()
	_set_message(String(result.get("message", "Sin respuesta.")))
	_refresh()

func _set_message(message: String) -> void:
	if _message_label != null:
		_message_label.text = message

func _refresh() -> void:
	if _core == null:
		return
	var report: Dictionary = _core.diagnostics_report()
	_status_label.text = "Estado: %s   |   Requiere recuperación: %s\nMundo: %s\nworld_tick: %d   |   Entidades: %d   |   Eventos: %d\nÚltima secuencia de evento: %d" % [
		"LISTO" if report.get("ready", false) else "NO DISPONIBLE",
		"SÍ" if report.get("recovery_required", false) else "no",
		report.get("world_id", "—"),
		int(report.get("world_tick", 0)),
		int(report.get("entity_count", 0)),
		int(report.get("event_count", 0)),
		int(report.get("last_event_sequence", 0))
	]
	var lines: Array[String] = []
	lines.append("Reglas: %s" % report.get("rules_version", "—"))
	lines.append("Aplicación: %s" % report.get("application_version", "—"))
	lines.append("Almacenamiento: %s" % report.get("storage_root", "—"))
	lines.append("\nAlcance actual: identidad, reloj monotónico, comandos, validación, eventos confirmados, journal, snapshots y recuperación.")
	lines.append("Todavía no hay scheduler, agentes autónomos, simulación biológica, economía, combate, Arcana ni representación de mundo. Esos sistemas no pertenecen a WLA-0A.")
	var diagnostic_items: Array = report.get("diagnostics", [])
	if not diagnostic_items.is_empty():
		lines.append("\nDiagnósticos:")
		for item in diagnostic_items:
			lines.append("• %s" % String(item))
	_diagnostics_label.text = "\n".join(lines)
