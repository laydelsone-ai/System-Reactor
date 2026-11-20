extends Node3D

const KernelScript = preload("res://scripts/core/world_kernel.gd")
const SceneBuilderScript = preload("res://scripts/presentation/isometric_scene_builder.gd")
const ObservatoryScript = preload("res://scripts/observatory/observatory_service.gd")
const AUTOSAVE_INTERVAL_SECONDS: float = 20.0

var kernel = KernelScript.new()
var scene_builder = SceneBuilderScript.new()
var observatory = ObservatoryScript.new()
var model_nodes: Dictionary = {}
var status_label: Label
var events_label: Label
var pause_button: Button
var refresh_accumulator: float = 0.0
var autosave_accumulator: float = 0.0

func _ready() -> void:
	var now_epoch := int(Time.get_unix_time_from_system())
	var recovery: Dictionary = kernel.initialize(now_epoch)
	model_nodes = scene_builder.build(self, kernel.state)
	_build_overlay()
	_refresh_overlay(recovery)

func _process(delta: float) -> void:
	kernel.advance_real_time(delta)
	refresh_accumulator += delta
	autosave_accumulator += delta
	if refresh_accumulator >= 1.0:
		refresh_accumulator = 0.0
		_refresh_overlay({})
	if autosave_accumulator >= AUTOSAVE_INTERVAL_SECONDS:
		autosave_accumulator = 0.0
		kernel.save_now()

func _exit_tree() -> void:
	if kernel.is_ready:
		kernel.save_now()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and kernel.is_ready:
		kernel.save_now()

func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.size = Vector2(420.0, 245.0)
	canvas.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "WORLD LABORATORY · ANDROID"
	layout.add_child(title)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)
	pause_button = Button.new()
	pause_button.pressed.connect(_on_pause_pressed)
	layout.add_child(pause_button)
	var save_button := Button.new()
	save_button.text = "Guardar mundo"
	save_button.pressed.connect(_on_save_pressed)
	layout.add_child(save_button)
	events_label = Label.new()
	events_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(events_label)
	var footer := Label.new()
	footer.text = "Proxies visuales · simulación inicial limitada · offline"
	layout.add_child(footer)

func _refresh_overlay(recovery: Dictionary = {}) -> void:
	if status_label == null or kernel.state.is_empty():
		return
	var summary: Dictionary = observatory.summarize(kernel.state)
	var days := float(summary.get("world_tick", 0)) / 86400.0
	status_label.text = "Día simulado: %.2f\nEntidades: %d · Vivas: %d · Criaturas: %d\nModo: %s" % [
		days,
		int(summary.get("entities", 0)),
		int(summary.get("alive", 0)),
		int(summary.get("creatures", 0)),
		"PAUSADO" if bool(summary.get("paused", false)) else "AUTÓNOMO"
	]
	pause_button.text = "Reanudar mundo" if bool(summary.get("paused", false)) else "Pausar mundo"
	var recent: Array = observatory.filter_recent_events(kernel.state, 4)
	var lines: Array[String] = ["Acontecimientos recientes:"]
	for event in recent:
		lines.append("• %s — %s" % [str(event.get("event_type", "Evento")), str(event.get("actor_id", "Sistema"))])
	if recent.is_empty():
		lines.append("Sin acontecimientos confirmados todavía.")
	if not recovery.is_empty() and int(recovery.get("catchup_seconds", 0)) > 0:
		lines.append("Catchup procesado: %d s" % int(recovery.get("catchup_seconds", 0)))
	if not recovery.is_empty() and not str(recovery.get("clock_anomaly", "")).is_empty():
		lines.append("Aviso temporal: %s" % str(recovery.get("clock_anomaly", "")))
	events_label.text = "\n".join(lines)
	_sync_model_positions()

func _sync_model_positions() -> void:
	var agents: Dictionary = kernel.state.get("agents", {})
	for agent_id in model_nodes.keys():
		if not agents.has(agent_id):
			continue
		var agent: Dictionary = agents[agent_id]
		var position_data: Array = agent.get("position", [0.0, 0.0, 0.0])
		var node: Node3D = model_nodes[agent_id]
		node.position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))

func _on_pause_pressed() -> void:
	kernel.set_paused(not bool(kernel.state.get("paused", false)))
	_refresh_overlay()

func _on_save_pressed() -> void:
	var saved := kernel.save_now()
	if saved:
		status_label.text += "\nGuardado local correcto."
