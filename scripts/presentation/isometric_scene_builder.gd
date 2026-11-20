extends RefCounted

func build(root: Node3D, state: Dictionary) -> Dictionary:
	_build_environment(root)
	var model_nodes: Dictionary = {}
	var agents: Dictionary = state.get("agents", {})
	var ids: Array = agents.keys()
	ids.sort()
	for agent_id in ids:
		var agent: Dictionary = agents[agent_id]
		var node := _make_proxy_model(agent)
		root.add_child(node)
		model_nodes[agent_id] = node
	return model_nodes

func _build_environment(root: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.68, 0.82)
	environment.ambient_light_energy = 0.65
	world_environment.environment = environment
	root.add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.15
	root.add_child(light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 30.0
	camera.position = Vector3(22.0, 26.0, 22.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	root.add_child(camera)

	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(48.0, 48.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.20, 0.28, 0.24)
	floor_material.roughness = 1.0
	floor.material_override = floor_material
	root.add_child(floor)

	for x in range(-8, 9):
		for z in range(-8, 9):
			var tile := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.0, 0.08, 1.0)
			tile.mesh = box
			tile.position = Vector3(float(x), 0.05, float(z))
			var material := StandardMaterial3D.new()
			var alternate := (x + z) % 2 == 0
			material.albedo_color = Color(0.28, 0.37, 0.29) if alternate else Color(0.25, 0.33, 0.27)
			material.roughness = 1.0
			tile.material_override = material
			root.add_child(tile)

func _make_proxy_model(agent: Dictionary) -> Node3D:
	var container := Node3D.new()
	container.name = str(agent.get("agent_id", "agent"))
	var position_data: Array = agent.get("position", [0.0, 0.0, 0.0])
	container.position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	var is_creature := agent.get("entity_kind", "person") == "creature"
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.28 if not is_creature else 0.38
	mesh.height = 1.35 if not is_creature else 0.9
	body.mesh = mesh
	body.position.y = 0.68 if not is_creature else 0.48
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.62, 0.88) if not is_creature else Color(0.76, 0.42, 0.24)
	mat.roughness = 0.8
	body.material_override = mat
	container.add_child(body)
	var label := Label3D.new()
	label.text = str(agent.get("display_name", "Entidad"))
	label.position.y = 1.65 if not is_creature else 1.15
	label.font_size = 36
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	container.add_child(label)
	return container
