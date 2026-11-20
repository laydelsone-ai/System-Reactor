extends Node3D

const STARTING_AGENTS := 18
const STARTING_CREATURES := 6
const SAVE_PATH := "user://wla_state.json"

@onready var boot_label: Label = $HUD/Panel/Content/Boot
@onready var status_label: Label = $HUD/Panel/Content/Status
@onready var runtime_label: Label = $HUD/Panel/Content/Runtime

var rng := RandomNumberGenerator.new()
var agents: Array = []
var sim_seconds: float = 0.0
var save_accumulator: float = 0.0
var decision_accumulator: float = 0.0
var boot_errors: Array[String] = []

func _ready() -> void:
	print("WLA_BOOT_OK: scene _ready entered")
	rng.seed = 20261120
	_boot()

func _boot() -> void:
	boot_label.text = "ESCENA CARGADA · CREANDO ENTIDADES"
	_build_ground_markers()
	_spawn_agents()
	_load_local_clock()
	boot_label.text = "MUNDO LOCAL INICIADO"
	status_label.text = "Agentes: %d · Criaturas: %d\nModo: offline · Simulación local" % [STARTING_AGENTS, STARTING_CREATURES]
	runtime_label.text = "Observatorio inicial · Catchup completo pendiente"
	print("WLA_BOOT_OK: entities=%d" % agents.size())

func _process(delta: float) -> void:
	sim_seconds += delta
	decision_accumulator += delta
	save_accumulator += delta
	if decision_accumulator >= 2.0:
		decision_accumulator = 0.0
		_process_agent_decisions()
	if save_accumulator >= 15.0:
		save_accumulator = 0.0
		_save_local_state()
	if runtime_label != null:
		runtime_label.text = "Observatorio inicial · Tiempo simulado: %d s" % int(sim_seconds)

func _build_ground_markers() -> void:
	# 42 líneas simples en lugar de cientos de nodos de mosaico.
	# Mantiene legibilidad isométrica y reduce llamadas de dibujo en Android.
	for i in range(-10, 11):
		var x_line := MeshInstance3D.new()
		var x_mesh := BoxMesh.new()
		x_mesh.size = Vector3(0.025, 0.02, 20.0)
		x_line.mesh = x_mesh
		x_line.position = Vector3(float(i), -0.025, 0.0)
		var x_material := StandardMaterial3D.new()
		x_material.albedo_color = Color(0.36, 0.45, 0.35, 1)
		x_line.material_override = x_material
		add_child(x_line)

		var z_line := MeshInstance3D.new()
		var z_mesh := BoxMesh.new()
		z_mesh.size = Vector3(20.0, 0.02, 0.025)
		z_line.mesh = z_mesh
		z_line.position = Vector3(0.0, -0.024, float(i))
		var z_material := StandardMaterial3D.new()
		z_material.albedo_color = Color(0.36, 0.45, 0.35, 1)
		z_line.material_override = z_material
		add_child(z_line)

func _spawn_agents() -> void:
	for i in range(STARTING_AGENTS + STARTING_CREATURES):
		var creature := i >= STARTING_AGENTS
		var entity := Node3D.new()
		entity.name = "Creature_%02d" % (i - STARTING_AGENTS + 1) if creature else "Agent_%02d" % (i + 1)
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.35 if creature else 0.25
		capsule.height = 0.85 if creature else 1.35
		body.mesh = capsule
		body.position.y = 0.48 if creature else 0.68
		var body_material := StandardMaterial3D.new()
		body_material.albedo_color = Color(0.82, 0.34, 0.22, 1) if creature else Color(0.24, 0.62, 0.9, 1)
		body_material.roughness = 0.7
		body.material_override = body_material
		entity.add_child(body)
		var head := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.20 if not creature else 0.24
		sphere.height = 0.4 if not creature else 0.48
		head.mesh = sphere
		head.position.y = 1.48 if not creature else 1.0
		head.material_override = body_material
		entity.add_child(head)
		var label := Label3D.new()
		label.text = "Criatura %d" % (i - STARTING_AGENTS + 1) if creature else "Agente %d" % (i + 1)
		label.position.y = 1.85 if not creature else 1.28
		label.font_size = 30
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		entity.add_child(label)
		entity.position = Vector3(rng.randf_range(-8.0, 8.0), 0.0, rng.randf_range(-8.0, 8.0))
		add_child(entity)
		agents.append({
			"node": entity,
			"kind": "creature" if creature else "person",
			"hunger": rng.randf_range(10.0, 60.0),
			"fatigue": rng.randf_range(5.0, 40.0),
			"decision_count": 0,
			"last_action": "spawned"
		})

func _process_agent_decisions() -> void:
	var decision_count := 0
	for agent_value in agents:
		var agent: Dictionary = agent_value
		var node: Node3D = agent["node"]
		agent["hunger"] = minf(100.0, float(agent["hunger"]) + rng.randf_range(0.4, 1.2))
		agent["fatigue"] = minf(100.0, float(agent["fatigue"]) + rng.randf_range(0.15, 0.5))
		var action := "patrol"
		if float(agent["hunger"]) > 72.0:
			action = "forage"
			agent["hunger"] = maxf(15.0, float(agent["hunger"]) - 28.0)
		elif float(agent["fatigue"]) > 78.0:
			action = "rest"
			agent["fatigue"] = maxf(10.0, float(agent["fatigue"]) - 32.0)
		else:
			action = "patrol"
		var target := node.position + Vector3(rng.randf_range(-1.2, 1.2), 0.0, rng.randf_range(-1.2, 1.2))
		target.x = clampf(target.x, -10.0, 10.0)
		target.z = clampf(target.z, -10.0, 10.0)
		if action == "patrol" or action == "forage":
			node.position = target
		agent["decision_count"] = int(agent["decision_count"]) + 1
		agent["last_action"] = action
		decision_count += 1
		print("WLA_DECISION: %s -> %s" % [node.name, action])
	if runtime_label != null:
		runtime_label.text = "Tiempo: %d s · Evaluaciones recientes: %d" % [int(sim_seconds), decision_count]

func _load_local_clock() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir el estado local.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var previous_epoch := int(parsed.get("last_epoch", 0))
		var current_epoch := int(Time.get_unix_time_from_system())
		var gap := maxi(0, current_epoch - previous_epoch)
		print("WLA_CATCHUP_CANDIDATE: %d seconds" % gap)

func _save_local_state() -> void:
	var payload := {
		"schema_version": 1,
		"last_epoch": int(Time.get_unix_time_from_system()),
		"sim_seconds": sim_seconds,
		"agent_count": agents.size()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("WLA_RUNTIME_ERROR: cannot open local save")
		return
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
