extends Node3D
## WLA master-map blockout 0.2.0.
## All visible exterior geography is built under one world root.
## Dungeon interior is a separate spatial domain instantiated under the same root.

const WORLD_HALF := 1200.0
const TOWN_CENTER := Vector3(-220.0, 0.0, 120.0)
const TOWER_CENTER := Vector3(-220.0, 0.0, 120.0)
const WALL_X := 430.0
const DUNGEON_ORIGIN := Vector3(0.0, -1800.0, 0.0)

var exterior_root: Node3D
var dungeon_root: Node3D
var camera: Camera3D
var hud_label: Label
var mode_label: Label
var interior_visible := false
var mats: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 20261120
	_make_materials()
	_make_environment()
	_build_exterior()
	_build_dungeon_floor_01()
	_build_camera()
	_build_hud()
	_set_view(false)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_set_view(not interior_visible)
	if Input.is_action_just_pressed("ui_cancel"):
		_set_view(false)

func _make_materials() -> void:
	mats = {
		"grass": _mat(Color("#526e55")),
		"grass_light": _mat(Color("#66805d")),
		"road": _mat(Color("#9b896d")),
		"road_dark": _mat(Color("#756b5b")),
		"stone": _mat(Color("#777d83")),
		"stone_light": _mat(Color("#a7a69a")),
		"roof": _mat(Color("#665064")),
		"roof_warm": _mat(Color("#87624f")),
		"wood": _mat(Color("#78543b")),
		"water": _mat(Color("#477e91")),
		"forest": _mat(Color("#294b38")),
		"forest_2": _mat(Color("#385c40")),
		"tower": _mat(Color("#b7b5a9")),
		"tower_dark": _mat(Color("#555d69")),
		"rock": _mat(Color("#686b68")),
		"rock_dark": _mat(Color("#454a4a")),
		"ore_blue": _mat(Color("#48a9c7"), 0.25, true),
		"ore_gold": _mat(Color("#d0a44f"), 0.25, true),
		"ruin": _mat(Color("#99958a")),
		"safe": _mat(Color("#c9b77c"), 0.35, true),
		"crystal": _mat(Color("#72c9db"), 0.2, true)
	}

func _mat(color: Color, roughness: float = 0.9, emission: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if emission:
		m.emission_enabled = true
		m.emission = color * 0.25
	return m

func _make_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101923")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c5d0d7")
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _build_exterior() -> void:
	exterior_root = Node3D.new()
	exterior_root.name = "Continuous_Exterior_Realm"
	add_child(exterior_root)
	_box(exterior_root, "RealmGround", Vector3(0, -4, 0), Vector3(2400, 8, 2400), "grass")
	# Soft rolling terrain masses: visual blockout, not final sculpted terrain.
	for p in [Vector3(-850,-1,-760), Vector3(-720,2,700), Vector3(50,1,-900), Vector3(650,0,-650), Vector3(850,3,400)]:
		_cylinder(exterior_root, "HillMass", p, 170, 18, "grass_light")
	_build_roads_and_water()
	_build_town()
	_build_wall_and_forest()
	_build_tower_exterior()
	_build_fields_and_outskirts()

func _build_roads_and_water() -> void:
	# Main roads are deliberately varied in width and length.
	_box(exterior_root, "RoyalRoad_WestEast", Vector3(-150,0.15,120), Vector3(1050,0.3,24), "road")
	_box(exterior_root, "RoyalRoad_SouthNorth", Vector3(-220,0.16,510), Vector3(22,0.32,780), "road")
	_box(exterior_root, "MarketStreet", Vector3(-400,0.18,160), Vector3(500,0.36,12), "road_dark")
	_box(exterior_root, "GuildAvenue", Vector3(-110,0.18,-80), Vector3(14,0.36,430), "road")
	_box(exterior_root, "OuterRoad", Vector3(140,0.16,500), Vector3(420,0.32,16), "road")
	_box(exterior_root, "River", Vector3(-780,-0.4,240), Vector3(42,0.8,1180), "water")
	# Stone bridges across the river.
	for z in [-180, 300, 720]:
		_box(exterior_root, "StoneBridge", Vector3(-780,0.15,z), Vector3(72,0.5,18), "stone")

func _build_town() -> void:
	var town := Node3D.new()
	town.name = "Fantasy_Capital_Town"
	exterior_root.add_child(town)
	# District footprints, with plazas and connected street corridors.
	_box(town, "CentralSquare", Vector3(-220,0.22,120), Vector3(150,0.44,130), "stone_light")
	_box(town, "GuildSquare", Vector3(-80,0.2,-110), Vector3(120,0.4,90), "stone")
	# Guild hall: large landmark north-west of tower.
	_build_building(town, "AdventurersGuild", Vector3(-420,0,-110), Vector3(86,34,64), "roof_warm", true)
	_build_building(town, "GrandTavern", Vector3(-510,0,170), Vector3(58,20,42), "roof")
	_build_building(town, "WayfarerInn", Vector3(-360,0,300), Vector3(48,18,38), "roof_warm")
	_build_building(town, "Blacksmith", Vector3(-80,0,310), Vector3(42,17,34), "roof_dark" if mats.has("roof_dark") else "roof")
	_build_building(town, "MarketHall", Vector3(-610,0,-20), Vector3(68,22,42), "roof_warm")
	_build_building(town, "Temple", Vector3(-60,0,-300), Vector3(72,34,62), "stone_light", true)
	_build_building(town, "PlayerHome_Allocation_A", Vector3(-670,0,360), Vector3(30,14,26), "roof")
	_build_building(town, "PlayerHome_Allocation_B", Vector3(-600,0,420), Vector3(30,14,26), "roof")
	_build_building(town, "PlayerHome_Allocation_C", Vector3(-520,0,430), Vector3(30,14,26), "roof")
	_build_building(town, "PlayerHome_Allocation_D", Vector3(-440,0,430), Vector3(30,14,26), "roof")
	# Residential blocks, workshops, stables, warehouse and guard barracks.
	for row in range(3):
		for col in range(4):
			var p := Vector3(-700.0 + col * 92.0, 0, -360.0 + row * 88.0)
			_build_building(town, "Residential_%d_%d" % [row,col], p, Vector3(34,15,28), "roof" if (row+col)%2==0 else "roof_warm")
	_build_building(town, "Carpenter", Vector3(80,0,300), Vector3(42,16,34), "roof")
	_build_building(town, "Alchemist", Vector3(90,0,210), Vector3(34,16,28), "roof_warm")
	_build_building(town, "Stables", Vector3(180,0,350), Vector3(62,18,40), "roof")
	_build_building(town, "Warehouse", Vector3(180,0,220), Vector3(70,20,46), "roof_warm")
	_build_building(town, "GuardBarracks", Vector3(210,0,-80), Vector3(56,22,42), "roof")
	# Decorative street lamps and square well.
	_cylinder(town, "SquareWell", Vector3(-220,1,120), 5, 2, "stone")
	for p in [Vector3(-290,0,-30),Vector3(-150,0,-30),Vector3(-290,0,270),Vector3(-150,0,270)]:
		_cylinder(town, "StreetLamp", p + Vector3(0,5,0), 0.6, 10, "tower_dark")

func _build_building(parent: Node3D, label: String, pos: Vector3, size: Vector3, roof_key: String, landmark: bool = false) -> void:
	var group := Node3D.new()
	group.name = label
	group.position = pos
	parent.add_child(group)
	_box(group, "Foundation", Vector3(0,1,0), Vector3(size.x+3,2,size.z+3), "stone")
	_box(group, "Walls", Vector3(0,size.y*0.5+2,0), size, "stone_light")
	var roof := _box(group, "Roof", Vector3(0,size.y+5,0), Vector3(size.x+8,5,size.z+8), roof_key)
	roof.rotation_degrees.z = -4 if landmark else 0
	if landmark:
		_box(group, "FrontPortico", Vector3(0,5,size.z*0.5+4), Vector3(size.x*0.55,10,5), "wood")
		for x in [-size.x*0.22,0,size.x*0.22]:
			_cylinder(group, "PorticoColumn", Vector3(x,6,size.z*0.5+4), 1.1, 12, "stone")

func _build_wall_and_forest() -> void:
	var wall := Node3D.new()
	wall.name = "Kingdom_Forest_Boundary_Wall"
	exterior_root.add_child(wall)
	# Main north-south wall with a monumental gate opening around z=110.
	_box(wall, "WallWest", Vector3(WALL_X,22,-500), Vector3(22,44,1220), "stone")
	_box(wall, "WallNorth", Vector3(0,22,-1110), Vector3(860,44,22), "stone")
	_box(wall, "WallSouth", Vector3(0,22,720), Vector3(860,44,22), "stone")
	_box(wall, "GateLeft", Vector3(WALL_X,22,40), Vector3(22,44,70), "stone")
	_box(wall, "GateRight", Vector3(WALL_X,22,190), Vector3(22,44,70), "stone")
	_box(wall, "GateArch", Vector3(WALL_X,42,115), Vector3(26,8,80), "stone_light")
	for z in range(-1050, 701, 90):
		if z > 0 and z < 230: continue
		_box(wall, "WallMerlon", Vector3(WALL_X,48,z), Vector3(28,10,18), "stone_light")
	# Watch towers.
	for z in [-1040, -500, 600]:
		_build_building(wall, "WatchTower_%d" % z, Vector3(WALL_X,0,z), Vector3(34,62,34), "tower_dark", true)
	# Forest is inside the playable world, beyond the wall. Nothing is authored outside the wall boundary.
	var forest := Node3D.new()
	forest.name = "Forest_Inside_Playable_Realm"
	exterior_root.add_child(forest)
	for i in range(115):
		var x := rng.randf_range(500, 1110)
		var z := rng.randf_range(-1000, 1030)
		if absf(z-115.0) < 95.0 and x < 650.0: continue
		_tree(forest, Vector3(x,0,z), rng.randf_range(0.8,1.5))
	# Forest clearings and a long, narrow path.
	_box(forest, "HunterTrail", Vector3(780,0.12,130), Vector3(620,0.24,7), "road_dark")
	_box(forest, "ForestClearing", Vector3(850,0.08,-430), Vector3(180,0.16,150), "grass_light")

func _tree(parent: Node3D, p: Vector3, scale: float) -> void:
	_cylinder(parent, "TreeTrunk", p + Vector3(0,5*scale,0), 1.2*scale, 10*scale, "wood")
	_cone(parent, "TreeCanopy", p + Vector3(0,14*scale,0), 7*scale, 20*scale, "forest")

func _build_tower_exterior() -> void:
	var tower := Node3D.new()
	tower.name = "Babel_Tower_Exterior"
	tower.position = TOWER_CENTER
	exterior_root.add_child(tower)
	_cylinder(tower, "TowerFootprint", Vector3(0,3,0), 72, 6, "tower_dark")
	_cylinder(tower, "TowerBase", Vector3(0,52,0), 54, 100, "tower")
	_cylinder(tower, "TowerShaft", Vector3(0,270,0), 42, 340, "tower")
	_cylinder(tower, "TowerUpperShaft", Vector3(0,570,0), 32, 260, "stone_light")
	_cone(tower, "TowerCrown", Vector3(0,735,0), 44, 80, "tower_dark")
	for y in [100,220,340,460,580,700]:
		_cylinder(tower, "TowerRing", Vector3(0,y,0), 57 if y < 400 else 44, 8, "tower_dark")
	# Buttresses and entry arch make the entrance legible from the town.
	for a in range(8):
		var angle := TAU * float(a) / 8.0
		var p := Vector3(cos(angle)*66,28,sin(angle)*66)
		var buttress := _box(tower, "TowerButtress", p, Vector3(13,55,18), "stone")
		buttress.rotation.y = angle
	_box(tower, "DungeonEntrance", Vector3(0,18,55), Vector3(26,34,7), "tower_dark")
	_box(tower, "EntranceDoorVoid", Vector3(0,10,59), Vector3(13,19,2), "rock_dark")

func _build_fields_and_outskirts() -> void:
	for i in range(16):
		var x := -950.0 + float(i%4)*95.0
		var z := 520.0 + float(i/4)*85.0
		_box(exterior_root, "FarmPlot_%02d" % i, Vector3(x,0.12,z), Vector3(68,0.24,48), "road")
		for row in range(4):
			_box(exterior_root, "CropFurrow", Vector3(x-24+row*16,0.28,z), Vector3(2,0.1,42), "grass_light")

func _build_dungeon_floor_01() -> void:
	dungeon_root = Node3D.new()
	dungeon_root.name = "Dungeon_Floor_01_NonEuclidean_Interior"
	dungeon_root.position = DUNGEON_ORIGIN
	add_child(dungeon_root)
	# Large spatial domain: 12 unique chambers connected by corridors of different widths.
	_box(dungeon_root, "MineBedrock", Vector3(0,-3,0), Vector3(1500,6,1250), "rock_dark")
	_box(dungeon_root, "MineCeiling", Vector3(0,90,0), Vector3(1500,8,1250), "rock_dark")
	# Each chamber has a unique footprint and distinct landmark arrangement.
	var rooms := [
		{"n":"01_EntryGallery","p":Vector3(-500,0,0),"s":Vector3(150,2,90),"kind":0},
		{"n":"02_PillarCourt","p":Vector3(-260,0,-190),"s":Vector3(190,2,150),"kind":1},
		{"n":"03_CrystalSeam","p":Vector3(20,0,-330),"s":Vector3(125,2,210),"kind":2},
		{"n":"04_CollapsedNave","p":Vector3(300,0,-170),"s":Vector3(220,2,120),"kind":3},
		{"n":"05_DeepWell","p":Vector3(540,0,60),"s":Vector3(150,2,150),"kind":4},
		{"n":"06_MinersCamp","p":Vector3(300,0,320),"s":Vector3(180,2,110),"kind":5},
		{"n":"07_BrokenAqueduct","p":Vector3(10,0,420),"s":Vector3(240,2,90),"kind":6},
		{"n":"08_ObeliskHall","p":Vector3(-300,0,360),"s":Vector3(170,2,190),"kind":7},
		{"n":"09_NarrowFault","p":Vector3(-600,0,280),"s":Vector3(100,2,220),"kind":8},
		{"n":"10_StalactiteVault","p":Vector3(-760,0,-120),"s":Vector3(180,2,120),"kind":9},
		{"n":"11_RuinedFoundry","p":Vector3(-250,0,-470),"s":Vector3(230,2,100),"kind":10},
		{"n":"12_DeepSanctum","p":Vector3(570,0,-390),"s":Vector3(190,2,170),"kind":11}
	]
	for room in rooms:
		_make_room(room)
	# Connect every chamber with long/narrow/wide corridors. Corridors are traversable combat spaces.
	_corridor(Vector3(-425,0,-95),Vector3(-335,0,-125),18)
	_corridor(Vector3(-170,0,-220),Vector3(-45,0,-280),12)
	_corridor(Vector3(82,0,-300),Vector3(190,0,-230),34)
	_corridor(Vector3(410,0,-145),Vector3(470,0,-30),9)
	_corridor(Vector3(500,0,140),Vector3(400,0,265),22)
	_corridor(Vector3(210,0,350),Vector3(130,0,390),8)
	_corridor(Vector3(-110,0,420),Vector3(-210,0,385),28)
	_corridor(Vector3(-390,0,340),Vector3(-520,0,300),10)
	_corridor(Vector3(-640,0,170),Vector3(-700,0,40),7)
	_corridor(Vector3(-680,0,-180),Vector3(-500,0,-430),24)
	_corridor(Vector3(-135,0,-470),Vector3(420,0,-400),14)
	# Two loops create alternate routes; no room is a mandatory combat arena.
	_corridor(Vector3(-300,0,-100),Vector3(10,0,120),16)
	_corridor(Vector3(300,0,-170),Vector3(300,0,320),11)
	_corridor(Vector3(-600,0,280),Vector3(-500,0,0),9)
	# Small safe zone near the entrance. Monsters are not forbidden from entering.
	_box(dungeon_root, "SafeZoneFloor", Vector3(-650,0,560), Vector3(170,2,110), "safe")
	_box(dungeon_root, "SafeZoneMarker", Vector3(-650,2,560), Vector3(80,0.5,2), "tower_dark")
	# Entrance tunnel links spatially to tower threshold.
	_corridor(Vector3(-650,0,620),Vector3(-500,0,0),20)
	# Mine rails and visible mineral veins; decorative/resource markers only.
	for i in range(18):
		var p := Vector3(rng.randf_range(-700,650),rng.randf_range(2,22),rng.randf_range(-420,450))
		_ore_vein(dungeon_root,p, "ore_blue" if i%3 else "ore_gold")
	# Broken pillars, ruins, old arches, and varied ceiling supports.
	for p in [Vector3(-300,0,-210),Vector3(-220,0,-210),Vector3(-300,0,-150),Vector3(-220,0,-150),
		Vector3(270,0,-200),Vector3(350,0,-200),Vector3(-280,0,330),Vector3(-330,0,390),
		Vector3(560,0,-440),Vector3(630,0,-440)]:
		_box(dungeon_root, "AncientPillar", p+Vector3(0,18,0), Vector3(8,36,8), "ruin")
	# Cracked mine supports and occasional rock masses.
	for p in [Vector3(-480,0,30),Vector3(20,0,-360),Vector3(320,0,350),Vector3(-740,0,-120)]:
		_box(dungeon_root, "TimberSupport", p+Vector3(0,16,0), Vector3(3,32,3), "wood")
	# Domain metadata for future persistence and floor progression.
	dungeon_root.set_meta("floor_id","tower_floor_01")
	dungeon_root.set_meta("room_count",12)
	dungeon_root.set_meta("safe_zone_policy","low_spawn_weight_not_exclusion")

func _make_room(room: Dictionary) -> void:
	var p: Vector3 = room["p"]
	var s: Vector3 = room["s"]
	var kind: int = room["kind"]
	var group := Node3D.new()
	group.name = str(room["n"])
	group.position = p
	dungeon_root.add_child(group)
	_box(group, "ChamberFloor", Vector3(0,0,0), s, "rock")
	# Irregular rock perimeter is approximated with individually shaped wall blocks.
	var wall_h := 34.0 + float(kind%4)*5.0
	_box(group, "WallNorth", Vector3(0,wall_h*0.5,-s.z*0.5), Vector3(s.x,wall_h,8), "rock_dark")
	_box(group, "WallSouth", Vector3(0,wall_h*0.5,s.z*0.5), Vector3(s.x,wall_h,8), "rock_dark")
	_box(group, "WallWest", Vector3(-s.x*0.5,wall_h*0.5,0), Vector3(8,wall_h,s.z), "rock_dark")
	_box(group, "WallEast", Vector3(s.x*0.5,wall_h*0.5,0), Vector3(8,wall_h,s.z), "rock_dark")
	match kind:
		0: # Entry gallery
			for x in [-45,0,45]: _box(group,"OldSupport",Vector3(x,14,0),Vector3(5,28,s.z-12),"wood")
		1: # Pillar court
			for x in [-60,0,60]:
				for z in [-45,45]: _box(group,"Pillar",Vector3(x,22,z),Vector3(10,44,10),"ruin")
		2: # Crystal seam
			for x in [-35,0,35]: _crystal_cluster(group,Vector3(x,8,0))
		3: # Collapsed nave
			for x in [-65,-20,35,80]: _box(group,"FallenColumn",Vector3(x,5,0),Vector3(28,8,7),"ruin")
		4: # Deep well
			_cylinder(group,"WellRim",Vector3(0,3,0),28,6,"stone")
			_cylinder(group,"Abyss",Vector3(0,-12,0),20,30,"rock_dark")
		5: # Miners camp
			for x in [-55,0,55]: _box(group,"AbandonedWorkbench",Vector3(x,5,0),Vector3(24,8,9),"wood")
		6: # Aqueduct
			for x in [-80,-40,0,40,80]: _cylinder(group,"AqueductArchSupport",Vector3(x,14,0),5,28,"ruin")
			_box(group,"DryChannel",Vector3(0,3,0),Vector3(s.x-20,2,18),"stone")
		7: # Obelisk hall
			_box(group,"Obelisk",Vector3(0,26,0),Vector3(12,52,12),"tower_dark")
		8: # Narrow fault
			_box(group,"FaultRidge",Vector3(0,8,0),Vector3(12,16,s.z-18),"rock_dark")
		9: # Stalactite vault
			for x in [-60,-20,20,60]: _cone(group,"Stalactite",Vector3(x,24,0),7,26,"rock_dark")
		10: # Ruined foundry
			_box(group,"ColdFurnace",Vector3(0,10,0),Vector3(42,20,34),"stone")
			for x in [-75,75]: _cylinder(group,"Smokestack",Vector3(x,24,0),5,48,"rock_dark")
		11: # Deep sanctum
			_cylinder(group,"SanctumDais",Vector3(0,3,0),32,6,"ruin")
			for a in range(6):
				var angle := TAU*float(a)/6.0
				_box(group,"SanctumMonolith",Vector3(cos(angle)*52,20,sin(angle)*52),Vector3(9,40,9),"tower_dark")

func _corridor(a: Vector3, b: Vector3, width: float) -> void:
	var mid := (a+b)*0.5
	var length := a.distance_to(b)
	var angle := atan2(b.z-a.z,b.x-a.x)
	var floor := _box(dungeon_root,"CombatCorridor",mid+Vector3(0,0.5,0),Vector3(length,1.0,width),"rock")
	floor.rotation.y = -angle
	var wall_height := 24.0
	var side_offset := Vector3(-sin(angle),0,cos(angle))*(width*0.5+3.0)
	for side in [-1.0,1.0]:
		var wall := _box(dungeon_root,"CorridorRockWall",mid+side_offset*side+Vector3(0,wall_height*0.5,0),Vector3(length,wall_height,6),"rock_dark")
		wall.rotation.y = -angle

func _ore_vein(parent: Node3D, p: Vector3, mat_key: String) -> void:
	for i in range(5):
		var shard := _cone(parent,"VisibleMineral",p+Vector3(rng.randf_range(-5,5),rng.randf_range(-2,2),rng.randf_range(-3,3)),rng.randf_range(1.4,3.2),rng.randf_range(4,9),mat_key)
		shard.rotation_degrees = Vector3(rng.randf_range(-20,20),rng.randf_range(0,360),rng.randf_range(-20,20))

func _crystal_cluster(parent: Node3D, p: Vector3) -> void:
	for i in range(9):
		_cone(parent,"CrystalShard",p+Vector3(rng.randf_range(-16,16),rng.randf_range(3,12),rng.randf_range(-16,16)),rng.randf_range(1.5,3.5),rng.randf_range(8,20),"crystal")

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1250.0
	camera.position = Vector3(900,1250,1250)
	camera.look_at(Vector3(0,0,0),Vector3.UP)
	camera.current = true
	add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,16)
	panel.custom_minimum_size = Vector2(400,0)
	layer.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "WORLD LABORATORY · MAP BLOCKOUT 0.2"
	title.add_theme_font_size_override("font_size",20)
	vbox.add_child(title)
	hud_label = Label.new()
	hud_label.text = "Reino continuo · Geografía mixta · Torre monumental"
	vbox.add_child(hud_label)
	mode_label = Label.new()
	mode_label.text = "Vista exterior | ENTER: cambiar a Mazmorra · ESC: volver"
	vbox.add_child(mode_label)
	var hint := Label.new()
	hint.text = "Blockout geométrico: sin arte final ni combate todavía."
	vbox.add_child(hint)

func _set_view(show_dungeon: bool) -> void:
	interior_visible = show_dungeon
	exterior_root.visible = not show_dungeon
	dungeon_root.visible = show_dungeon
	if show_dungeon:
		camera.position = DUNGEON_ORIGIN + Vector3(950,1150,1150)
		camera.look_at(DUNGEON_ORIGIN,Vector3.UP)
		camera.size = 1500.0
		mode_label.text = "PISO 01 · MINA DE RUINAS | ENTER: exterior · ESC: exterior"
		hud_label.text = "12 cámaras únicas · corredores estrechos y anchos · zona segura probabilística"
	else:
		camera.position = Vector3(900,1250,1250)
		camera.look_at(Vector3.ZERO,Vector3.UP)
		camera.size = 1250.0
		mode_label.text = "Vista exterior | ENTER: cambiar a Mazmorra · ESC: volver"
		hud_label.text = "Reino continuo · Geografía mixta · Torre monumental"

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, material_key: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = mats.get(material_key,mats["stone"])
	parent.add_child(node)
	return node

func _cylinder(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, material_key: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	node.mesh = mesh
	node.position = pos
	node.material_override = mats.get(material_key,mats["stone"])
	parent.add_child(node)
	return node

func _cone(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, material_key: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 7
	node.mesh = mesh
	node.position = pos
	node.material_override = mats.get(material_key,mats["stone"])
	parent.add_child(node)
	return node
