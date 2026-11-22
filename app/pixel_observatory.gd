extends Control

const SystemCoreScript = preload("res://scripts/core/system_core.gd")
const AutonomyRuntimeScript = preload("res://scripts/simulation/autonomy_runtime.gd")
const FONT_ATLAS: Texture2D = preload("res://assets/ui/font_5x7.png")
const FONT_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,:;-/+%#?!()[]<>"
const TILE_STONE: Texture2D = preload("res://assets/tiles/stone.png")
const TILE_MINERAL: Texture2D = preload("res://assets/tiles/mineral.png")
const TILE_WATER: Texture2D = preload("res://assets/tiles/water.png")
const TILE_RUBBLE: Texture2D = preload("res://assets/tiles/rubble.png")
const TILE_RUIN: Texture2D = preload("res://assets/tiles/ruin.png")
const TILE_TIMBER: Texture2D = preload("res://assets/tiles/timber.png")
const SPRITE_RAT: Texture2D = preload("res://assets/sprites/rat_filon.png")
const SPRITE_BEETLE: Texture2D = preload("res://assets/sprites/escarabajo_ferrante.png")
const SPRITE_FUNGUS: Texture2D = preload("res://assets/sprites/hongo_farolero.png")
const SPRITE_BAT: Texture2D = preload("res://assets/sprites/murcielago_eco.png")
const SPRITE_CRAWLER: Texture2D = preload("res://assets/sprites/rastrero_escombro.png")
const SPRITE_PICKAXE: Texture2D = preload("res://assets/sprites/pickaxe.png")
const SPRITE_LAMP: Texture2D = preload("res://assets/sprites/lamp.png")
const SPRITE_CRYSTAL: Texture2D = preload("res://assets/sprites/crystal.png")

const COLORS := {
	"bg": Color("#0b1215"),
	"panel": Color("#172226"),
	"panel_alt": Color("#1d2b2e"),
	"panel_dark": Color("#10191c"),
	"line": Color("#53676a"),
	"line_soft": Color("#314448"),
	"text": Color("#e8e0c9"),
	"muted": Color("#8fa3a0"),
	"muted_dark": Color("#607574"),
	"gold": Color("#e1b76c"),
	"gold_dark": Color("#9a7040"),
	"teal": Color("#5bb8be"),
	"blue": Color("#5798b1"),
	"green": Color("#82b58c"),
	"red": Color("#c87864"),
	"white": Color("#ffffff")
}

# The chamber diagram is a presentation reference, not final canonical geography.
const ROOMS: Array[Dictionary] = [
	{"id":"R01", "x":4, "y":0, "w":4, "h":4, "type":"stone", "label":"EXTRACCION"},
	{"id":"R02", "x":10, "y":0, "w":4, "h":4, "type":"stone", "label":"GALERIA"},
	{"id":"R03", "x":16, "y":0, "w":5, "h":4, "type":"timber", "label":"VIA MINERA"},
	{"id":"R04", "x":23, "y":0, "w":4, "h":4, "type":"stone", "label":"UMBRAL"},
	{"id":"R08", "x":2, "y":7, "w":5, "h":4, "type":"rubble", "label":"DERRUMBE"},
	{"id":"R07", "x":9, "y":7, "w":4, "h":4, "type":"stone", "label":"CRUCE"},
	{"id":"R06", "x":16, "y":7, "w":5, "h":4, "type":"mineral", "label":"VETA"},
	{"id":"R05", "x":23, "y":7, "w":5, "h":4, "type":"water", "label":"BOMBEO"},
	{"id":"R09", "x":4, "y":14, "w":4, "h":4, "type":"water", "label":"CISTERNA"},
	{"id":"R10", "x":11, "y":14, "w":4, "h":4, "type":"timber", "label":"SOPORTES"},
	{"id":"R11", "x":18, "y":14, "w":5, "h":4, "type":"ruin", "label":"RUINAS"},
	{"id":"R12", "x":25, "y":14, "w":5, "h":4, "type":"rubble", "label":"ESCOMBROS"}
]
const CORRIDORS: Array[Array] = [
	[[8,2],[9,2]], [[14,2],[15,2]], [[21,2],[22,2]],
	[[11,4],[11,5],[11,6]],
	[[18,4],[17,5],[16,6],[15,7]],
	[[25,4],[25,5],[25,6]],
	[[22,9]], [[13,9],[14,9],[15,9]], [[7,9],[8,9]],
	[[4,11],[4,12],[4,13]],
	[[8,16],[9,16],[10,16]], [[15,16],[16,16],[17,16]], [[23,16],[24,16]],
	[[25,11],[25,12],[25,13]]
]
var _core: SystemCore
var _autonomy: AutonomyRuntime
var _autonomy_auto_run := true
var _autonomy_was_running_before_os_pause := true
var _autonomy_accumulator := 0.0
var _autonomy_tick_interval := 1.25
var _tab := 0
var _selected_room := "R06"
var _bestiary_index := 0
var _message := "MUNDO LOCAL INICIALIZADO"
var _bestiary: Array = []
var _social: Dictionary = {}
var _social_people: Array = []
var _bestiary_data: Dictionary = {}
var _autonomy_status := "AUTONOMIA NO INICIALIZADA"
var _tab_rects: Array[Rect2] = []
var _action_rects: Dictionary = {}
var _bestiary_prev_rect := Rect2()
var _bestiary_next_rect := Rect2()
var _map_rect := Rect2()
var _map_screen_origin := Vector2.ZERO
var _map_scale := 1.0
var _pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
	_core = SystemCoreScript.new()
	_load_content()
	var boot_result: Dictionary = _core.open_last_or_create()
	var boot_ok := bool(boot_result.get("ok", false))
	if boot_ok:
		_message = String(boot_result.get("message", "MUNDO LOCAL INICIALIZADO"))
		_open_autonomy()
	else:
		_message = "ERROR DE ARRANQUE: " + String(boot_result.get("message", "SIN DETALLE"))
		_autonomy_status = _message
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	if _pulse > 1000.0:
		_pulse = 0.0
	if _autonomy_auto_run and _autonomy != null and _autonomy.is_ready():
		_autonomy_accumulator += delta
		if _autonomy_accumulator >= _autonomy_tick_interval:
			_autonomy_accumulator = 0.0
			var tick_result: Dictionary = _autonomy.step()
			if not tick_result.get("ok", false):
				_autonomy_status = String(tick_result.get("message", "ERROR DE SIMULACION"))
			else:
				_autonomy_status = "CICLO %d / %d DECISIONES" % [int(tick_result.get("tick", 0)), int(tick_result.get("decisions", 0))]
	queue_redraw()

func _notification(what: int) -> void:
	if _core == null or not _core.ready:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_autonomy_was_running_before_os_pause = _autonomy_auto_run
		_autonomy_auto_run = false
		_autonomy_accumulator = 0.0
		if _autonomy != null:
			var autonomy_save: Dictionary = _autonomy.save_checkpoint()
			if not autonomy_save.get("ok", false):
				push_error("WLA: guardado autónomo al pausar fallido: %s" % autonomy_save.get("message", "error"))
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_autonomy_auto_run = _autonomy_was_running_before_os_pause
		_autonomy_accumulator = 0.0
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autonomy_auto_run = false
		if _autonomy != null:
			_autonomy.save_checkpoint()
		var close_result: Dictionary = _core.close_world()
		if not close_result.get("ok", false):
			push_error("WLA: guardado al cerrar fallido: %s" % close_result.get("message", "error"))
		get_tree().quit()

func _exit_tree() -> void:
	if _autonomy != null and _autonomy.is_ready():
		_autonomy.save_checkpoint()
	if _core != null and _core.ready:
		_core.close_world()

func _load_content() -> void:
	_bestiary_data = _read_json("res://data/bestiary/floor01_species.json")
	_bestiary = _bestiary_data.get("species", [])
	var social_value: Variant = _read_json("res://data/social/social_registry_v0.2.json")
	if typeof(social_value) == TYPE_DICTIONARY:
		_social = social_value
		_social_people = _social.get("people", [])

func _open_autonomy() -> void:
	if _core == null or not _core.ready:
		_autonomy_status = "NUCLEO NO DISPONIBLE"
		return
	_autonomy = AutonomyRuntimeScript.new()
	var result: Dictionary = _autonomy.open(_core, _social, _bestiary_data)
	if result.get("ok", false):
		_autonomy_status = "WLA-0B LISTO / %d NPC / %d CRIATURAS DE PRUEBA" % [int(result.get("agents", 0)), int(result.get("trial_creatures", 0))]
	else:
		_autonomy_status = String(result.get("message", "NO SE PUDO INICIAR LA AUTONOMIA"))
		_autonomy = null

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("WLA: falta archivo de contenido %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("WLA: no se pudo abrir %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("WLA: JSON invalido en %s" % path)
		return {}
	return parsed

func _draw() -> void:
	var view_size := get_viewport_rect().size
	if view_size.x < 100.0 or view_size.y < 100.0:
		return
	_action_rects.clear()
	_tab_rects.clear()
	_bestiary_prev_rect = Rect2()
	_bestiary_next_rect = Rect2()
	_draw_background(view_size)
	_draw_header(view_size)
	_draw_tabs(view_size)
	var footer_h := 74.0
	var body_top := 132.0
	var body_bottom := view_size.y - footer_h - 14.0
	var body_h := maxf(300.0, body_bottom - body_top)
	var gap := 12.0
	if _tab == 4:
		_draw_autonomy_panel(Rect2(18.0, body_top, view_size.x - 36.0, body_h))
		_draw_footer(view_size)
		return
	var map_rect: Rect2
	var info_rect: Rect2
	if view_size.x >= view_size.y:
		var map_w := floorf((view_size.x - 48.0 - gap) * 0.615)
		map_rect = Rect2(18.0, body_top, map_w, body_h)
		info_rect = Rect2(map_rect.end.x + gap, body_top, view_size.x - map_rect.end.x - 18.0, body_h)
	else:
		var map_h := minf(540.0, body_h * 0.58)
		map_rect = Rect2(16.0, body_top, view_size.x - 32.0, map_h)
		info_rect = Rect2(16.0, map_rect.end.y + gap, view_size.x - 32.0, body_bottom - map_rect.end.y - gap)
	_draw_map_panel(map_rect)
	_draw_info_panel(info_rect)
	_draw_footer(view_size)

func _draw_background(view_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), COLORS.bg)
	# Quiet pixel-grid texture and scattered mineral glints.
	for x in range(12, int(view_size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, view_size.y), Color(0.13, 0.20, 0.21, 0.12), 1.0)
	for y in range(12, int(view_size.y), 32):
		draw_line(Vector2(0, y), Vector2(view_size.x, y), Color(0.13, 0.20, 0.21, 0.12), 1.0)
	for i in range(34):
		var px := float((i * 173 + 41) % maxi(1, int(view_size.x)))
		var py := float((i * 97 + 23) % maxi(1, int(view_size.y)))
		draw_rect(Rect2(px, py, 2.0, 2.0), Color(0.36, 0.60, 0.59, 0.16))
	# Thin frame and corner registration marks.
	draw_rect(Rect2(8, 8, view_size.x - 16, view_size.y - 16), COLORS.line_soft, false, 1.0)

func _draw_header(view_size: Vector2) -> void:
	var r := Rect2(18, 16, view_size.x - 36, 58)
	_panel(r, COLORS.panel_dark, COLORS.line)
	# Reactor mark, deliberately geometric and pixel-aligned.
	draw_rect(Rect2(32, 31, 8, 8), COLORS.gold)
	draw_rect(Rect2(42, 21, 8, 8), COLORS.teal)
	draw_rect(Rect2(42, 41, 8, 8), COLORS.blue)
	draw_rect(Rect2(52, 31, 8, 8), COLORS.gold_dark)
	_text("WORLD LABORATORY", Vector2(72, 27), 2.2, COLORS.text)
	_text("SISTEMA REACTOR / SIMULACION AUTONOMA", Vector2(74, 53), 0.95, COLORS.muted)
	var pill_w := 164.0
	var pill_x := view_size.x - pill_w - 210.0
	_chip(Rect2(pill_x, 31, pill_w, 27), "LOCAL / OFFLINE", COLORS.green)
	_text("WLA-0B  /  TRIAL", Vector2(view_size.x - 190, 39), 1.0, COLORS.gold)

func _draw_tabs(view_size: Vector2) -> void:
	var names := ["OBSERVATORIO", "BESTIARIO", "POBLACION", "EVENTOS", "AUTONOMIA"]
	var x := 18.0
	var y := 88.0
	var widths := [145.0, 105.0, 112.0, 82.0, 118.0]
	for i in range(names.size()):
		var r := Rect2(x, y, widths[i], 32.0)
		_tab_rects.append(r)
		var selected := i == _tab
		var bg := COLORS.gold if selected else COLORS.panel
		var fg := COLORS.bg if selected else COLORS.muted
		draw_rect(r, bg)
		draw_rect(r, COLORS.line if not selected else COLORS.gold_dark, false, 1.0)
		_text(names[i], Vector2(r.position.x + 8, r.position.y + 12), 0.82, fg)
		x += widths[i] + 7.0
	if view_size.x > 1050.0:
		var right_label := "OBSERVADOR PASIVO / SIMULACION SIN JUGADOR"
		var right_w := _text_width(right_label, 0.85)
		_text(right_label, Vector2(view_size.x - right_w - 24.0, y + 12), 0.85, COLORS.muted_dark)

func _draw_map_panel(rect: Rect2) -> void:
	_map_rect = rect
	_panel(rect, COLORS.panel, COLORS.line)
	_text("MAZMORRA  /  PISO 01", rect.position + Vector2(18, 24), 1.5, COLORS.text)
	_text("MINA DE LOS APUNTALAMIENTOS", rect.position + Vector2(18, 46), 1.0, COLORS.gold)
	_text("12 CAMARAS DE REFERENCIA  /  14 CONEXIONES", Vector2(rect.end.x - 230, rect.position.y + 28), 0.8, COLORS.muted)
	draw_line(Vector2(rect.position.x + 14, rect.position.y + 62), Vector2(rect.end.x - 14, rect.position.y + 62), COLORS.line_soft, 1.0)
	var content := Rect2(rect.position + Vector2(10, 70), Vector2(rect.size.x - 20, rect.size.y - 112))
	_draw_iso_map(content)
	var hint_y := rect.end.y - 22.0
	_text("TOCA UNA CAMARA PARA INSPECCIONAR", Vector2(rect.position.x + 17, hint_y), 0.85, COLORS.muted)
	_text("REFERENCIA VISUAL", Vector2(rect.end.x - 146, hint_y), 0.85, COLORS.gold)

func _draw_iso_map(area: Rect2) -> void:
	const TILE_W := 32.0
	const TILE_H := 20.0
	var min_x := -208.0
	var max_x := 480.0
	var min_y := 0.0
	var max_y := 500.0
	var fit_x := (area.size.x - 26.0) / (max_x - min_x)
	var fit_y := (area.size.y - 20.0) / (max_y - min_y)
	_map_scale = clampf(minf(fit_x, fit_y), 0.54, 1.05)
	var map_w := (max_x - min_x) * _map_scale
	var map_h := (max_y - min_y) * _map_scale
	_map_screen_origin = Vector2(area.position.x + (area.size.x - map_w) * 0.5 - min_x * _map_scale, area.position.y + (area.size.y - map_h) * 0.5 - min_y * _map_scale)
	# The dark void below the mine gives the chambers a floating cutaway feel.
	draw_rect(area, Color("#111a1e"))
	for x in range(int(area.position.x) + 8, int(area.end.x) - 8, 24):
		draw_line(Vector2(x, area.position.y + 8), Vector2(x, area.end.y - 8), Color(0.22, 0.33, 0.34, 0.12), 1.0)
	for y in range(int(area.position.y) + 8, int(area.end.y) - 8, 24):
		draw_line(Vector2(area.position.x + 8, y), Vector2(area.end.x - 8, y), Color(0.22, 0.33, 0.34, 0.12), 1.0)
	var cell_types: Dictionary = {}
	var cell_room: Dictionary = {}
	for room in ROOMS:
		for gy in range(int(room.y), int(room.y) + int(room.h)):
			for gx in range(int(room.x), int(room.x) + int(room.w)):
				var room_cell_key := "%d:%d" % [gx, gy]
				cell_types[room_cell_key] = String(room.type)
				cell_room[room_cell_key] = String(room.id)
	for path in CORRIDORS:
		for cell in path:
			var corridor_cell_key := "%d:%d" % [int(cell[0]), int(cell[1])]
			if not cell_types.has(corridor_cell_key):
				cell_types[corridor_cell_key] = "stone"
	# Back-to-front order is essential for the isometric overlaps.
	var cell_keys: Array = cell_types.keys()
	cell_keys.sort_custom(func(a: String, b: String) -> bool:
		var aa := a.split(":")
		var bb := b.split(":")
		return int(aa[0]) + int(aa[1]) < int(bb[0]) + int(bb[1])
	)
	draw_set_transform(_map_screen_origin, 0.0, Vector2(_map_scale, _map_scale))
	# Room plinth faces first, then the top surface. No tile is a collision or a final world coordinate.
	for key in cell_keys:
		var face_parts := String(key).split(":")
		var face_grid_x := int(face_parts[0])
		var face_grid_y := int(face_parts[1])
		var room_id := String(cell_room.get(key, ""))
		if room_id.is_empty():
			continue
		var room := _room_by_id(room_id)
		var face_cx := (float(face_grid_x - face_grid_y) * TILE_W * 0.5)
		var face_cy := (float(face_grid_x + face_grid_y) * TILE_H * 0.5)
		var color := _room_base_color(String(room.type))
		var bottom_left := Vector2(face_cx, face_cy + TILE_H * 0.5)
		var right_mid := Vector2(face_cx + TILE_W * 0.5, face_cy)
		var depth := 5.0
		if face_grid_y == int(room.y) + int(room.h) - 1:
			draw_colored_polygon(PackedVector2Array([right_mid, bottom_left, bottom_left + Vector2(0, depth), right_mid + Vector2(0, depth)]), color.darkened(0.42))
		if face_grid_x == int(room.x) + int(room.w) - 1:
			var bottom_right := Vector2(face_cx + TILE_W * 0.5, face_cy)
			draw_colored_polygon(PackedVector2Array([bottom_right, bottom_left, bottom_left + Vector2(0, depth), bottom_right + Vector2(0, depth)]), color.darkened(0.28))
	for key in cell_keys:
		var tile_parts := String(key).split(":")
		var tile_grid_x := int(tile_parts[0])
		var tile_grid_y := int(tile_parts[1])
		var type := String(cell_types[key])
		var tex: Texture2D = _texture_for_type(type)
		var tile_cx := (float(tile_grid_x - tile_grid_y) * TILE_W * 0.5)
		var tile_cy := (float(tile_grid_x + tile_grid_y) * TILE_H * 0.5)
		draw_texture(tex, Vector2(tile_cx - TILE_W * 0.5, tile_cy - TILE_H * 0.5))
	# Timber rails, crystal deposits and mining fixtures are decorative only.
	_draw_map_props()
	for room in ROOMS:
		var room_cx := float(room.x) + float(room.w) * 0.5
		var room_cy := float(room.y) + float(room.h) * 0.5
		var px := (room_cx - room_cy) * TILE_W * 0.5
		var py := (room_cx + room_cy) * TILE_H * 0.5
		var label := String(room.id)
		var selected := String(room.id) == _selected_room
		var label_rect := Rect2(px - 17, py - 10, 34, 16)
		draw_rect(label_rect, Color("#142126", 0.92))
		draw_rect(label_rect, COLORS.gold if selected else COLORS.line, false, 1.0)
		_text(label, Vector2(px - 12, py - 5), 1.0, COLORS.gold if selected else COLORS.text)
		if selected:
			var pulse_color := Color(0.94, 0.73, 0.39, 0.25 + 0.16 * sin(_pulse * 2.6))
			draw_rect(Rect2(px - 22, py - 15, 44, 26), pulse_color, false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_map_props() -> void:
	# Mine rails in R03.
	_draw_iso_line(Vector2(17.0, 1.8), Vector2(20.5, 1.8), Color("#c7a16b"), 2.0)
	_draw_iso_line(Vector2(17.0, 2.35), Vector2(20.5, 2.35), Color("#73563d"), 2.0)
	for gx in [17.5, 19.0, 20.0]:
		var rail_support_pos := _grid_to_iso(Vector2(gx, 2.05))
		draw_rect(Rect2(rail_support_pos.x - 1, rail_support_pos.y - 3, 2, 8), Color("#b58b53"))
	var tool_pos := _grid_to_iso(Vector2(20.0, 3.2))
	draw_texture_rect(SPRITE_PICKAXE, Rect2(tool_pos.x - 7, tool_pos.y - 11, 14, 14), false)
	# Mineral spikes in R06.
	for spot in [Vector2(17.4,8.1), Vector2(19.4,8.7), Vector2(18.2,9.6), Vector2(20.0,10.0)]:
		var crystal_pos := _grid_to_iso(spot)
		var size := 18.0 if spot.x < 19.0 else 15.0
		draw_texture_rect(SPRITE_CRYSTAL, Rect2(crystal_pos.x - size * 0.5, crystal_pos.y - size + 2, size, size), false)
	# Lamps and timber support hints.
	for spot in [Vector2(5.0,1.0), Vector2(12.0,1.0), Vector2(24.8,1.0), Vector2(3.0,8.0), Vector2(12.0,8.0), Vector2(21.5,15.0)]:
		var lamp_pos := _grid_to_iso(spot)
		draw_texture_rect(SPRITE_LAMP, Rect2(lamp_pos.x - 7, lamp_pos.y - 15, 14, 14), false)
	# A dim fungus cluster in the support chamber, no agent behavior implied.
	var fungus_pos := _grid_to_iso(Vector2(13.0, 15.8))
	draw_texture_rect(SPRITE_FUNGUS, Rect2(fungus_pos.x - 13, fungus_pos.y - 21, 26, 26), false, Color(0.72, 1.0, 0.86, 0.9))
	# Rock piles in two collapse rooms.
	for spot in [Vector2(3.0,8.0), Vector2(5.0,9.0), Vector2(27.5,15.2), Vector2(28.5,17.0)]:
		var rubble_pos := _grid_to_iso(spot)
		draw_rect(Rect2(rubble_pos.x - 3, rubble_pos.y - 3, 8, 5), Color("#8e7355"))
		draw_rect(Rect2(rubble_pos.x - 1, rubble_pos.y - 6, 5, 4), Color("#b0906c"))

func _draw_iso_line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var pa := _grid_to_iso(a)
	var pb := _grid_to_iso(b)
	draw_line(pa, pb, color, width)

func _grid_to_iso(grid: Vector2) -> Vector2:
	return Vector2((grid.x - grid.y) * 16.0, (grid.x + grid.y) * 10.0)

func _draw_info_panel(rect: Rect2) -> void:
	_panel(rect, COLORS.panel, COLORS.line)
	match _tab:
		0:
			_draw_overview(rect)
		1:
			_draw_bestiary(rect)
		2:
			_draw_population(rect)
		3:
			_draw_events(rect)

func _draw_overview(rect: Rect2) -> void:
	_text("CAMARA SELECCIONADA", rect.position + Vector2(18, 26), 1.0, COLORS.muted)
	var room := _room_by_id(_selected_room)
	_text(_selected_room, rect.position + Vector2(18, 64), 3.0, COLORS.gold)
	_text(String(room.get("label", "REFERENCIA")), rect.position + Vector2(22, 91), 1.0, COLORS.text)
	var room_type := _type_description(String(room.get("type", "stone")))
	_text(room_type, rect.position + Vector2(18, 121), 0.9, COLORS.muted)
	draw_line(Vector2(rect.position.x + 16, rect.position.y + 142), Vector2(rect.end.x - 16, rect.position.y + 142), COLORS.line_soft, 1.0)
	_text("PISO 01 / MINA DE LOS", rect.position + Vector2(18, 166), 1.0, COLORS.text)
	_text("APUNTALAMIENTOS", rect.position + Vector2(18, 185), 1.0, COLORS.text)
	_text("SUBBIOMA: GALERIAS SECAS,", rect.position + Vector2(18, 218), 0.85, COLORS.muted)
	_text("ESCOMBRERAS Y CAMARAS DE", rect.position + Vector2(18, 235), 0.85, COLORS.muted)
	_text("EXTRACCION ABANDONADAS.", rect.position + Vector2(18, 252), 0.85, COLORS.muted)
	var stats_y := rect.position.y + 286.0
	_draw_stat_card(Rect2(rect.position.x + 16, stats_y, rect.size.x - 32, 108))
	_text("ESTADO DE SIMULACION", rect.position + Vector2(18, stats_y + 126), 0.9, COLORS.gold)
	_text("WLA-0B / CICLO DE AUTONOMIA", rect.position + Vector2(18, stats_y + 148), 0.85, COLORS.text)
	_text("180 REGISTROS / 24 DECISIONES POR TICK", rect.position + Vector2(18, stats_y + 165), 0.72, COLORS.text)
	_text("ABRE AUTONOMIA PARA VER DECISIONES", rect.position + Vector2(18, stats_y + 188), 0.72, COLORS.teal)
	_text("Y CONSECUENCIAS DEL EXPERIMENTO.", rect.position + Vector2(18, stats_y + 205), 0.72, COLORS.teal)

func _draw_stat_card(rect: Rect2) -> void:
	_panel(rect, COLORS.panel_dark, COLORS.line_soft)
	var report := _core.diagnostics_report() if _core != null else {}
	var values := [
		["TICK", "%04d" % int(report.get("world_tick", 0))],
		["ENTIDADES", str(int(report.get("entity_count", 0)))],
		["EVENTOS", str(int(report.get("event_count", 0)))]
	]
	var col_w := (rect.size.x - 24.0) / 3.0
	for i in range(values.size()):
		var x := rect.position.x + 12 + i * col_w
		_text(String(values[i][0]), Vector2(x, rect.position.y + 26), 0.8, COLORS.muted)
		_text(String(values[i][1]), Vector2(x, rect.position.y + 58), 2.0, COLORS.gold if i == 0 else COLORS.text)
		if i < 2:
			draw_line(Vector2(x + col_w - 8, rect.position.y + 15), Vector2(x + col_w - 8, rect.end.y - 15), COLORS.line_soft, 1.0)

func _draw_bestiary(rect: Rect2) -> void:
	_text("BESTIARIO / PISO 01", rect.position + Vector2(18, 26), 1.25, COLORS.text)
	_text("CATALOGO PROPUESTO V0.1", rect.position + Vector2(18, 48), 0.8, COLORS.gold)
	if _bestiary.is_empty():
		_text("NO SE PUDO CARGAR EL CATALOGO.", rect.position + Vector2(18, 100), 0.9, COLORS.red)
		return
	_bestiary_index = clampi(_bestiary_index, 0, _bestiary.size() - 1)
	var item: Dictionary = _bestiary[_bestiary_index]
	var sprite := _sprite_for_species(String(item.get("id", "")))
	var sprite_rect := Rect2(rect.position.x + 18, rect.position.y + 72, 86, 86)
	_panel(sprite_rect, COLORS.panel_dark, COLORS.line_soft)
	draw_texture_rect(sprite, Rect2(sprite_rect.position + Vector2(8, 8), Vector2(70, 70)), false)
	var title_x := rect.position.x + 118
	_text(String(item.get("id", "")), Vector2(title_x, rect.position.y + 91), 0.8, COLORS.muted)
	var name_lines := _wrap(String(item.get("name", "SIN NOMBRE")), 20)
	for i in range(mini(name_lines.size(), 2)):
		_text(name_lines[i], Vector2(title_x, rect.position.y + 115 + i * 18), 1.0, COLORS.text)
	_text("PELIGRO %d/5" % int(item.get("danger", 1)), Vector2(title_x, rect.position.y + 151), 1.0, COLORS.red if int(item.get("danger", 1)) >= 3 else COLORS.gold)
	var controls_y := rect.position.y + 174
	_bestiary_prev_rect = Rect2(rect.end.x - 94, controls_y - 14, 28, 24)
	_bestiary_next_rect = Rect2(rect.end.x - 54, controls_y - 14, 28, 24)
	_chip(Rect2(rect.position.x + 18, controls_y - 14, 82, 24), "%d / %d" % [_bestiary_index + 1, _bestiary.size()], COLORS.teal)
	_button(_bestiary_prev_rect, "<", false)
	_button(_bestiary_next_rect, ">", false)
	draw_line(Vector2(rect.position.x + 16, rect.position.y + 207), Vector2(rect.end.x - 16, rect.position.y + 207), COLORS.line_soft, 1.0)
	var summary := String(item.get("summary", ""))
	var summary_lines := _wrap(summary, int((rect.size.x - 36) / 7.2))
	var sy := rect.position.y + 230
	for i in range(mini(summary_lines.size(), 4)):
		_text(summary_lines[i], Vector2(rect.position.x + 18, sy + i * 15), 0.75, COLORS.muted)
	var stats: Dictionary = item.get("stats", {})
	var stat_names := ["FUE", "POT", "AGI", "COO", "RES", "PER"]
	var stat_keys := ["fuerza", "potencia", "agilidad", "coordinacion", "resistencia_fisica", "percepcion"]
	var stat_top := rect.position.y + 304
	var half_w := (rect.size.x - 52.0) * 0.5
	for i in range(6):
		var col := i % 2
		var row := int(i / 2)
		var x := rect.position.x + 18 + col * (half_w + 16)
		var y := stat_top + row * 40
		var value := int(stats.get(stat_keys[i], 0))
		_text(stat_names[i], Vector2(x, y), 0.75, COLORS.muted)
		_text(str(value), Vector2(x + half_w - 28, y), 0.85, COLORS.text)
		draw_rect(Rect2(x, y + 11, half_w - 2, 5), Color("#26383a"))
		var bar_color := COLORS.teal if value < 55 else COLORS.gold
		draw_rect(Rect2(x, y + 11, (half_w - 2) * float(value) / 100.0, 5), bar_color)
	var bottom_y := rect.end.y - 94
	_text("CAPACIDAD", Vector2(rect.position.x + 18, bottom_y), 0.8, COLORS.gold)
	var abilities: Array = item.get("abilities", [])
	if not abilities.is_empty():
		var ability_lines := _wrap(String(abilities[0]), int((rect.size.x - 40) / 7.2))
		for i in range(mini(ability_lines.size(), 2)):
			_text(ability_lines[i], Vector2(rect.position.x + 18, bottom_y + 18 + i * 14), 0.72, COLORS.text)
	_text("ESCALA 0-100 = APTITUD, NO HP.", Vector2(rect.position.x + 18, rect.end.y - 18), 0.7, COLORS.muted_dark)

func _draw_population(rect: Rect2) -> void:
	_text("REGISTRO SOCIAL", rect.position + Vector2(18, 27), 1.4, COLORS.text)
	_text("IMPORTACION V0.2.0 / FUENTE", rect.position + Vector2(18, 49), 0.8, COLORS.gold)
	var people_count := _social_people.size()
	var population_audit: Dictionary = _social.get("population_import_audit", {})
	var named_count := int(population_audit.get("named_count", 60))
	var background_count := int(population_audit.get("background_count", 120))
	var households: Array = _social.get("households", [])
	var relationships: Array = _social.get("relationships", [])
	var same_household := 0
	var unconfirmed_family := 0
	for relation in relationships:
		if String(relation.get("relationship_type", "")) == "same_household_member":
			same_household += 1
		if String(relation.get("status", "")).contains("pending_author_confirmation"):
			unconfirmed_family += 1
	var hero := Rect2(rect.position.x + 16, rect.position.y + 76, rect.size.x - 32, 100)
	_panel(hero, COLORS.panel_dark, COLORS.line_soft)
	_text(str(people_count), hero.position + Vector2(16, 50), 3.0, COLORS.gold)
	_text("PERSONAS EN EL REGISTRO", hero.position + Vector2(120, 42), 0.95, COLORS.text)
	_text("NO TODAS ESTAN INSTANCIADAS EN EL MUNDO", hero.position + Vector2(120, 62), 0.65, COLORS.muted)
	var cards_y := rect.position.y + 194
	var card_w := (rect.size.x - 42.0) / 2.0
	_draw_count_card(Rect2(rect.position.x + 16, cards_y, card_w, 76), "NOMBRADOS", named_count, COLORS.teal)
	_draw_count_card(Rect2(rect.position.x + 26 + card_w, cards_y, card_w, 76), "FONDO", background_count, COLORS.blue)
	_draw_count_card(Rect2(rect.position.x + 16, cards_y + 90, card_w, 76), "HOGARES", households.size(), COLORS.gold)
	_draw_count_card(Rect2(rect.position.x + 26 + card_w, cards_y + 90, card_w, 76), "ENLACES HOGAR", same_household, COLORS.green)
	var note_y := cards_y + 198
	_text("PRECAUCIONES DE PROCEDENCIA", Vector2(rect.position.x + 18, note_y), 0.85, COLORS.gold)
	_text("HOGAR COMPARTIDO NO SIGNIFICA PARENTESCO", Vector2(rect.position.x + 18, note_y + 22), 0.72, COLORS.text)
	_text("NI AMISTAD. LAS 40 AGRUPACIONES NO TIENEN", Vector2(rect.position.x + 18, note_y + 38), 0.72, COLORS.text)
	_text("DOMICILIOS FISICOS ASIGNADOS.", Vector2(rect.position.x + 18, note_y + 54), 0.72, COLORS.text)
	_text("%d VINCULO KALL PROVISIONAL / 4 DECLARACIONES" % unconfirmed_family, Vector2(rect.position.x + 18, note_y + 78), 0.62, COLORS.muted)
	_text("SOCIALES PENDIENTES DE RESOLUCION.", Vector2(rect.position.x + 18, note_y + 93), 0.68, COLORS.muted)

func _draw_count_card(rect: Rect2, label: String, value: int, color: Color) -> void:
	_panel(rect, COLORS.panel_dark, COLORS.line_soft)
	_text(label, rect.position + Vector2(10, 20), 0.7, COLORS.muted)
	_text(str(value), rect.position + Vector2(10, 51), 1.8, color)

func _draw_events(rect: Rect2) -> void:
	_text("JOURNAL / EVENTOS", rect.position + Vector2(18, 27), 1.3, COLORS.text)
	_text("REGISTRO APPEND-ONLY / ESTADO LOCAL", rect.position + Vector2(18, 49), 0.72, COLORS.gold)
	var report := _core.diagnostics_report() if _core != null else {}
	var values := [
		["WORLD ID", _short_id(String(report.get("world_id", "NO DISPONIBLE")))],
		["ULTIMA SECUENCIA", str(int(report.get("last_event_sequence", 0)))],
		["EVENTOS", str(int(report.get("event_count", 0)))],
		["ENTIDADES", str(int(report.get("entity_count", 0)))],
		["WORLD TICK", str(int(report.get("world_tick", 0)))]
	]
	var y := rect.position.y + 83
	for entry in values:
		_text(String(entry[0]), Vector2(rect.position.x + 18, y), 0.7, COLORS.muted)
		_text(String(entry[1]), Vector2(rect.end.x - 162, y), 0.9, COLORS.text)
		y += 29
	draw_line(Vector2(rect.position.x + 16, y + 5), Vector2(rect.end.x - 16, y + 5), COLORS.line_soft, 1.0)
	_text("ULTIMOS REGISTROS", Vector2(rect.position.x + 18, y + 29), 0.8, COLORS.gold)
	y += 50
	var events: Array = _journal_events()
	if events.is_empty():
		_text("NO HAY EVENTOS PARA MOSTRAR.", Vector2(rect.position.x + 18, y), 0.75, COLORS.muted)
	else:
		var start := maxi(0, events.size() - 4)
		for i in range(events.size() - 1, start - 1, -1):
			var ev: Dictionary = events[i]
			var line_text := "#%03d  %s" % [int(ev.get("sequence", 0)), String(ev.get("event_type", "EVENT"))]
			_text(line_text, Vector2(rect.position.x + 18, y), 0.85, COLORS.text)
			y += 22
	var qa_y := rect.end.y - 78
	_text("PRUEBA QA: CREA UN MARCADOR TECNICO", Vector2(rect.position.x + 18, qa_y - 14), 0.68, COLORS.muted)
	var marker_rect := Rect2(rect.position.x + 16, qa_y + 4, rect.size.x - 32, 34)
	_button(marker_rect, "REGISTRAR MARCADOR QA", false)
	_action_rects["marker"] = marker_rect

func _draw_autonomy_panel(rect: Rect2) -> void:
	_panel(rect, COLORS.panel, COLORS.line)
	var compact := rect.size.x < 650.0
	var report: Dictionary = _autonomy.get_report() if _autonomy != null and _autonomy.is_ready() else {}
	var metrics: Dictionary = report.get("metrics", {})
	_text("WLA-0B / LABORATORIO DE AUTONOMIA", rect.position + Vector2(18, 24), 0.86 if compact else 1.25, COLORS.text)
	_text("AGENTES SIN ORDEN DEL JUGADOR / CICLOS AUTONOMOS", rect.position + Vector2(18, 43), 0.57 if compact else 0.72, COLORS.muted)
	var status_color: Color = COLORS.green if _autonomy_auto_run else COLORS.gold
	var chip_w := 92.0 if compact else 148.0
	_chip(Rect2(rect.end.x - chip_w - 16, rect.position.y + 14, chip_w, 24), "AUTO ON" if _autonomy_auto_run else "PAUSADO", status_color)

	var card_labels: Array[String] = ["TICK", "AGENTES", "CRIATURAS", "DECISIONES", "MEMORIAS"]
	var card_values: Array[String] = [
		str(int(report.get("tick", 0))),
		"%d/%d" % [int(report.get("npc_active", 0)), int(report.get("npc_total", 0))],
		str(int(report.get("trial_creatures", 0))),
		str(int(metrics.get("decisions_processed", 0))),
		str(int(metrics.get("memories_written", 0)))
	]
	var card_colors: Array[Color] = [COLORS.gold, COLORS.teal, COLORS.blue, COLORS.text, COLORS.green]
	var card_y := rect.position.y + 58.0
	if compact:
		var compact_card_gap := 6.0
		var compact_card_w := (rect.size.x - 36.0 - compact_card_gap * 2.0) / 3.0
		for i in range(card_labels.size()):
			var compact_card_column := i % 3
			var compact_card_row := floori(float(i) / 3.0)
			var compact_card_rect := Rect2(rect.position.x + 16 + compact_card_column * (compact_card_w + compact_card_gap), card_y + compact_card_row * 48.0, compact_card_w, 43.0)
			_panel(compact_card_rect, COLORS.panel_dark, COLORS.line_soft)
			_text(card_labels[i], compact_card_rect.position + Vector2(6, 14), 0.53, COLORS.muted)
			_text(card_values[i], compact_card_rect.position + Vector2(6, 34), 0.92, card_colors[i])
	else:
		var wide_card_gap := 8.0
		var wide_card_w := (rect.size.x - 36.0 - wide_card_gap * 4.0) / 5.0
		for i in range(card_labels.size()):
			var wide_card_rect := Rect2(rect.position.x + 16 + i * (wide_card_w + wide_card_gap), card_y, wide_card_w, 58.0)
			_panel(wide_card_rect, COLORS.panel_dark, COLORS.line_soft)
			_text(card_labels[i], wide_card_rect.position + Vector2(8, 17), 0.66, COLORS.muted)
			_text(card_values[i], wide_card_rect.position + Vector2(8, 43), 1.25, card_colors[i])

	var control_y := card_y + (102.0 if compact else 70.0)
	var labels: Array[String] = ["PASO +1", "PAUSAR" if _autonomy_auto_run else "REANUDAR", "RUIDO R07", "DANAR HONGO", "GUARDAR"]
	var keys: Array[String] = ["sim_step", "sim_toggle", "sim_vibration", "sim_fungus", "sim_save"]
	if compact:
		var compact_button_gap := 6.0
		var compact_button_w := (rect.size.x - 36.0 - compact_button_gap * 2.0) / 3.0
		for i in range(keys.size()):
			var compact_button_column := i % 3
			var compact_button_row := floori(float(i) / 3.0)
			var compact_action_rect := Rect2(rect.position.x + 16 + compact_button_column * (compact_button_w + compact_button_gap), control_y + compact_button_row * 36.0, compact_button_w, 31.0)
			_button(compact_action_rect, labels[i], i == 1 and _autonomy_auto_run)
			_action_rects[keys[i]] = compact_action_rect
	else:
		var wide_button_gap := 8.0
		var wide_button_w := (rect.size.x - 36.0 - wide_button_gap * 4.0) / 5.0
		for i in range(keys.size()):
			var wide_action_rect := Rect2(rect.position.x + 16 + i * (wide_button_w + wide_button_gap), control_y, wide_button_w, 36.0)
			_button(wide_action_rect, labels[i], i == 1 and _autonomy_auto_run)
			_action_rects[keys[i]] = wide_action_rect

	var content_y := control_y + (76.0 if compact else 48.0)
	var content_h := maxf(108.0, rect.end.y - content_y - 16.0)
	var recent: Array = _autonomy.get_recent_events(10) if _autonomy != null else []
	if compact:
		var events_h := maxf(82.0, content_h * 0.43)
		var compact_events_rect := Rect2(rect.position.x + 16, content_y, rect.size.x - 32.0, events_h)
		var compact_detail_rect := Rect2(rect.position.x + 16, compact_events_rect.end.y + 8.0, rect.size.x - 32.0, maxf(70.0, rect.end.y - compact_events_rect.end.y - 24.0))
		_draw_autonomy_trace(compact_events_rect, recent, 2, true)
		_draw_autonomy_subjects(compact_detail_rect, true)
	else:
		var split_gap := 12.0
		var left_w := (rect.size.x - 36.0 - split_gap) * 0.54
		var wide_events_rect := Rect2(rect.position.x + 16, content_y, left_w, content_h)
		var wide_detail_rect := Rect2(wide_events_rect.end.x + split_gap, content_y, rect.end.x - 16 - wide_events_rect.end.x - split_gap, content_h)
		_draw_autonomy_trace(wide_events_rect, recent, 7, false)
		_draw_autonomy_subjects(wide_detail_rect, false)
	var footer_y := rect.end.y - 10.0
	_text(_autonomy_status.substr(0, mini(_autonomy_status.length(), maxi(10, int((rect.size.x - 40.0) / (4.0 if compact else 5.3))))), Vector2(rect.position.x + 18, footer_y), 0.55 if compact else 0.62, COLORS.muted_dark)

func _draw_autonomy_trace(events_rect: Rect2, recent: Array, max_rows: int, compact: bool) -> void:
	_panel(events_rect, COLORS.panel_dark, COLORS.line_soft)
	_text("TRAZA DE DECISIONES", events_rect.position + Vector2(12, 19), 0.72 if compact else 0.9, COLORS.gold)
	_text("DECISIONES Y CONSECUENCIAS", events_rect.position + Vector2(12, 35), 0.50 if compact else 0.62, COLORS.muted)
	var row_y := events_rect.position.y + (54.0 if compact else 62.0)
	var max_visible := mini(max_rows, maxi(0, int((events_rect.size.y - (58.0 if compact else 76.0)) / (22.0 if compact else 27.0))))
	var shown := 0
	for idx in range(recent.size() - 1, -1, -1):
		if shown >= max_visible:
			break
		var item: Dictionary = recent[idx]
		var success := bool(item.get("success", false))
		var label := "%s / %s" % [String(item.get("display_name", item.get("agent_id", "AGENTE"))), String(item.get("action", "ACCION"))]
		var detail := String(item.get("reason", item.get("cause", "")))
		var chars := maxi(10, int((events_rect.size.x - 44.0) / (5.0 if compact else 5.8)))
		_draw_status_dot(Vector2(events_rect.position.x + 14, row_y - 3), COLORS.green if success else COLORS.gold)
		_text(label.substr(0, mini(label.length(), chars)), Vector2(events_rect.position.x + 25, row_y), 0.59 if compact else 0.72, COLORS.text)
		if not compact:
			_text(detail.substr(0, mini(detail.length(), maxi(12, int((events_rect.size.x - 46.0) / 6.4)))), Vector2(events_rect.position.x + 27, row_y + 13), 0.58, COLORS.muted)
		row_y += 22.0 if compact else 27.0
		shown += 1
	if shown == 0:
		_text("ESPERANDO EL PRIMER CICLO", events_rect.position + Vector2(14, 68), 0.62, COLORS.muted)

func _draw_autonomy_subjects(detail_rect: Rect2, compact: bool) -> void:
	_panel(detail_rect, COLORS.panel_dark, COLORS.line_soft)
	_text("INSPECTOR / ESTADO DEL MUNDO", detail_rect.position + Vector2(12, 19), 0.72 if compact else 0.9, COLORS.gold)
	_text("CRIATURAS DE PRUEBA / UBICACION EXPERIMENTAL", detail_rect.position + Vector2(12, 35), 0.50 if compact else 0.58, COLORS.muted)
	var report: Dictionary = _autonomy.get_report() if _autonomy != null else {}
	var presence_note := "NPC SIN COORD. %d / COG %d" % [int(report.get("npc_without_validated_presence", 0)), int(report.get("npc_with_cognitive_profile", 0))]
	_text(presence_note, detail_rect.position + Vector2(12, 48), 0.48 if compact else 0.56, COLORS.muted_dark)
	var state: Dictionary = _autonomy.get_state_copy() if _autonomy != null else {}
	var creatures: Dictionary = state.get("trial_creatures", {})
	var creature_y := detail_rect.position.y + (61.0 if compact else 77.0)
	var row_step := 22.0 if compact else 38.0
	var sprite_size := 18.0 if compact else 28.0
	for creature_id in ["trial_rat_01", "trial_beetle_01", "trial_bat_01", "trial_crawler_01"]:
		if not creatures.has(creature_id) or creature_y + row_step > detail_rect.end.y - 6.0:
			continue
		var creature: Dictionary = creatures[creature_id]
		var sprite: Texture2D = _sprite_for_species(String(creature.get("species_id", "")))
		draw_texture_rect(sprite, Rect2(detail_rect.position.x + 10, creature_y - (14.0 if compact else 8.0), sprite_size, sprite_size), false)
		var name_size := 0.58 if compact else 0.7
		var detail_size := 0.50 if compact else 0.58
		var text_x := detail_rect.position.x + (34.0 if compact else 49.0)
		_text(String(creature.get("species_name", creature_id)).substr(0, 22), Vector2(text_x, creature_y), name_size, COLORS.text)
		_text("%s H%02d%%" % [String(creature.get("location", "?")), int(float(creature.get("hunger", 0.0)) * 100.0)], Vector2(text_x, creature_y + (10.0 if compact else 13.0)), detail_size, COLORS.muted)
		creature_y += row_step
	var fungus: Dictionary = state.get("ecological_processes", {}).get("trial_fungus_01", {})
	if not fungus.is_empty() and creature_y + 14.0 < detail_rect.end.y:
		_text("HONGO / %s / ESP %.2f" % [String(fungus.get("last_response", "quiet")), float(fungus.get("spore_cloud", 0.0))], Vector2(detail_rect.position.x + 12, creature_y + 4), 0.54 if compact else 0.58, COLORS.teal)

func _draw_footer(view_size: Vector2) -> void:
	var r := Rect2(18, view_size.y - 74, view_size.x - 36, 56)
	_panel(r, COLORS.panel_dark, COLORS.line)
	var report := _core.diagnostics_report() if _core != null else {}
	var ready := bool(report.get("ready", false))
	var ready_text := "NUCLEO LISTO" if ready else "NUCLEO NO DISPONIBLE"
	var status_color: Color = COLORS.green if ready else COLORS.red
	_draw_status_dot(Vector2(r.position.x + 16, r.position.y + 28), status_color)
	if view_size.x < 840.0:
		_text("CORE" if ready else "ERROR", Vector2(r.position.x + 27, r.position.y + 31), 0.68, status_color)
		_text("T%d" % int(report.get("world_tick", 0)), Vector2(r.position.x + 70, r.position.y + 31), 0.68, COLORS.muted)
		var compact_buttons_x := r.end.x - 224.0
		var compact_button_gap := 4.0
		var compact_button_w := (r.end.x - compact_buttons_x - 4.0) / 3.0
		var compact_save_rect := Rect2(compact_buttons_x, r.position.y + 11, compact_button_w, 34)
		var compact_reload_rect := Rect2(compact_buttons_x + compact_button_w + compact_button_gap, r.position.y + 11, compact_button_w, 34)
		var compact_probe_rect := Rect2(compact_buttons_x + (compact_button_w + compact_button_gap) * 2.0, r.position.y + 11, compact_button_w, 34)
		_button(compact_save_rect, "GUARDAR", false)
		_button(compact_reload_rect, "CARGAR", false)
		_button(compact_probe_rect, "QA", false)
		_action_rects["save"] = compact_save_rect
		_action_rects["reload"] = compact_reload_rect
		_action_rects["probe"] = compact_probe_rect
		return
	_text(ready_text, Vector2(r.position.x + 30, r.position.y + 31), 0.85, status_color)
	_text("ID " + _short_id(String(report.get("world_id", "SIN MUNDO"))), Vector2(r.position.x + 178, r.position.y + 31), 0.8, COLORS.muted)
	_text("TICK %d" % int(report.get("world_tick", 0)), Vector2(r.position.x + 328, r.position.y + 31), 0.8, COLORS.muted)
	_text("ENT %d" % int(report.get("entity_count", 0)), Vector2(r.position.x + 430, r.position.y + 31), 0.8, COLORS.muted)
	_text("EVT %d" % int(report.get("event_count", 0)), Vector2(r.position.x + 520, r.position.y + 31), 0.8, COLORS.muted)
	_text(_message.substr(0, 25), Vector2(r.position.x + 610, r.position.y + 31), 0.7, COLORS.muted_dark)
	var wide_buttons_x := r.end.x - 334
	var wide_save_rect := Rect2(wide_buttons_x, r.position.y + 11, 98, 34)
	var wide_reload_rect := Rect2(wide_buttons_x + 106, r.position.y + 11, 104, 34)
	var wide_probe_rect := Rect2(wide_buttons_x + 218, r.position.y + 11, 102, 34)
	_button(wide_save_rect, "GUARDAR", false)
	_button(wide_reload_rect, "RECUPERAR", false)
	_button(wide_probe_rect, "MARCADOR", false)
	_action_rects["save"] = wide_save_rect
	_action_rects["reload"] = wide_reload_rect
	_action_rects["probe"] = wide_probe_rect

func _panel(rect: Rect2, fill: Color, border: Color) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 1.0)
	# Cut-corner pixels create the technical-console frame.
	for point in [rect.position, Vector2(rect.end.x - 3, rect.position.y), Vector2(rect.position.x, rect.end.y - 3), rect.end - Vector2(3, 3)]:
		draw_rect(Rect2(point, Vector2(3, 3)), COLORS.bg)

func _chip(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, color.darkened(0.78))
	draw_rect(rect, color.darkened(0.2), false, 1.0)
	_text(label, rect.position + Vector2(8, 16), 0.8, color)

func _button(rect: Rect2, label: String, selected: bool) -> void:
	var fill := COLORS.gold if selected else COLORS.panel_alt
	var fg := COLORS.bg if selected else COLORS.text
	draw_rect(rect, fill)
	draw_rect(rect, COLORS.gold_dark if selected else COLORS.line, false, 1.0)
	var text_w := _text_width(label, 0.8)
	_text(label, Vector2(rect.position.x + maxf(5.0, (rect.size.x - text_w) * 0.5), rect.position.y + 21), 0.8, fg)

func _draw_status_dot(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center - Vector2(4, 4), Vector2(8, 8)), color)
	draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), color.lightened(0.35))

func _text(value: String, position: Vector2, scale: float = 1.0, color: Color = Color.WHITE) -> void:
	var text_value := value.to_upper()
	var cursor := position
	for i in range(text_value.length()):
		var character := text_value.substr(i, 1)
		var index := FONT_CHARS.find(character)
		if index < 0:
			index = FONT_CHARS.find(" ")
		var sx := float(index % 10) * 6.0
		var sy := float(floori(float(index) / 10.0)) * 8.0
		draw_texture_rect_region(FONT_ATLAS, Rect2(cursor, Vector2(5.0 * scale, 7.0 * scale)), Rect2(sx, sy, 5.0, 7.0), color)
		cursor.x += 6.0 * scale

func _text_width(value: String, scale: float = 1.0) -> float:
	return float(value.length()) * 6.0 * scale

func _wrap(value: String, max_chars: int) -> Array[String]:
	var output: Array[String] = []
	var safe_limit := maxi(8, max_chars)
	var words := value.replace("\n", " ").split(" ", false)
	var line := ""
	for word in words:
		var candidate := word if line.is_empty() else line + " " + word
		if candidate.length() <= safe_limit:
			line = candidate
		else:
			if not line.is_empty():
				output.append(line)
			line = word
	if not line.is_empty():
		output.append(line)
	return output

func _room_by_id(room_id: String) -> Dictionary:
	for room in ROOMS:
		if String(room.id) == room_id:
			return room
	return ROOMS[0]

func _texture_for_type(room_type: String) -> Texture2D:
	match room_type:
		"timber": return TILE_TIMBER
		"mineral": return TILE_MINERAL
		"water": return TILE_WATER
		"rubble": return TILE_RUBBLE
		"ruin": return TILE_RUIN
		_: return TILE_STONE

func _room_base_color(room_type: String) -> Color:
	match room_type:
		"timber": return Color("#526554")
		"mineral": return Color("#285c70")
		"water": return Color("#214f62")
		"rubble": return Color("#594638")
		"ruin": return Color("#6a5a41")
		_: return Color("#535e58")

func _type_description(room_type: String) -> String:
	match room_type:
		"timber": return "PIEDRA / APUNTALAMIENTOS DE MADERA"
		"mineral": return "VETA MINERAL / CRISTALES DECORATIVOS"
		"water": return "AGUA / INFRAESTRUCTURA DE BOMBEO"
		"rubble": return "DERRUMBE / ESCOMBROS"
		"ruin": return "RUINAS / ESTRUCTURA ANTIGUA"
		_: return "PIEDRA / ZONA DE EXTRACCION"

func _sprite_for_species(species_id: String) -> Texture2D:
	match species_id:
		"MON-F1-001": return SPRITE_RAT
		"MON-F1-002": return SPRITE_BEETLE
		"MON-F1-003": return SPRITE_FUNGUS
		"MON-F1-004": return SPRITE_BAT
		"MON-F1-005": return SPRITE_CRAWLER
		_: return SPRITE_RAT

func _short_id(value: String) -> String:
	if value.length() <= 18:
		return value
	return value.substr(0, 8) + "..." + value.substr(value.length() - 5)

func _journal_events() -> Array:
	if _core == null or _core.world_id.is_empty():
		return []
	var result: Dictionary = _core.persistence.read_journal(_core.world_id)
	if result.get("ok", false):
		return result.get("events", [])
	return []

func _handle_tap(position: Vector2) -> void:
	for i in range(_tab_rects.size()):
		if _tab_rects[i].has_point(position):
			_tab = i
			queue_redraw()
			return
	if _action_rects.has("sim_step") and _action_rects["sim_step"].has_point(position):
		if _autonomy != null:
			var result: Dictionary = _autonomy.step()
			_autonomy_status = "CICLO MANUAL %d" % int(result.get("tick", 0)) if result.get("ok", false) else String(result.get("message", "ERROR"))
		queue_redraw()
		return
	if _action_rects.has("sim_toggle") and _action_rects["sim_toggle"].has_point(position):
		_autonomy_auto_run = not _autonomy_auto_run
		_autonomy_accumulator = 0.0
		queue_redraw()
		return
	if _action_rects.has("sim_vibration") and _action_rects["sim_vibration"].has_point(position):
		if _autonomy != null:
			var stimulus: Dictionary = _autonomy.emit_vibration("R07", 0.95)
			_autonomy_status = String(stimulus.get("message", "ESTIMULO REGISTRADO"))
		queue_redraw()
		return
	if _action_rects.has("sim_fungus") and _action_rects["sim_fungus"].has_point(position):
		if _autonomy != null:
			var disturbance: Dictionary = _autonomy.damage_fungus(0.55)
			_autonomy_status = String(disturbance.get("message", "PERTURBACION REGISTRADA"))
		queue_redraw()
		return
	if _action_rects.has("sim_save") and _action_rects["sim_save"].has_point(position):
		if _autonomy != null:
			var checkpoint: Dictionary = _autonomy.save_checkpoint()
			_autonomy_status = String(checkpoint.get("message", "GUARDADO"))
		queue_redraw()
		return
	if _action_rects.has("save"):
		var save_rect: Rect2 = _action_rects["save"]
		if save_rect.has_point(position):
			var save_result: Dictionary = _autonomy.save_checkpoint() if _autonomy != null else _core.save_checkpoint("pixel_observatory_manual")
			_message = String(save_result.get("message", "GUARDADO"))
			queue_redraw()
			return
	if _action_rects.has("reload"):
		var reload_rect: Rect2 = _action_rects["reload"]
		if reload_rect.has_point(position):
			var reload_result: Dictionary = _core.reload_from_disk() if _core != null else {"ok": false, "message": "NUCLEO NO DISPONIBLE"}
			if reload_result.get("ok", false):
				_open_autonomy()
			_message = String(reload_result.get("message", "RECUPERACION"))
			queue_redraw()
			return
	if _action_rects.has("probe"):
		var probe_rect: Rect2 = _action_rects["probe"]
		if probe_rect.has_point(position):
			_register_qa_marker()
			return
	if _action_rects.has("marker"):
		var marker_rect: Rect2 = _action_rects["marker"]
		if marker_rect.has_point(position):
			_register_qa_marker()
			return
	if _bestiary_prev_rect.has_point(position):
		_bestiary_index = posmod(_bestiary_index - 1, maxi(1, _bestiary.size()))
		queue_redraw()
		return
	if _bestiary_next_rect.has_point(position):
		_bestiary_index = posmod(_bestiary_index + 1, maxi(1, _bestiary.size()))
		queue_redraw()
		return
	if _map_rect.has_point(position):
		_select_room_at(position)
		return

func _register_qa_marker() -> void:
	if _core == null or not _core.ready:
		_message = "EL NUCLEO NO ESTA DISPONIBLE"
		queue_redraw()
		return
	var result: Dictionary = _core.register_diagnostic_fixture("Marcador QA / pixel observatory")
	_message = String(result.get("message", "SIN RESPUESTA"))
	if result.get("accepted", false):
		_message = "MARCADOR QA CONFIRMADO / EVT " + _short_id(String(result.get("event_id", "")))
	queue_redraw()

func _select_room_at(position: Vector2) -> void:
	if _map_scale <= 0.0:
		return
	var p := (position - _map_screen_origin) / _map_scale
	var gx := p.x / 32.0 + p.y / 20.0
	var gy := p.y / 20.0 - p.x / 32.0
	for room in ROOMS:
		if gx >= float(room.x) - 0.35 and gx <= float(room.x + room.w) - 0.1 and gy >= float(room.y) - 0.35 and gy <= float(room.y + room.h) - 0.1:
			_selected_room = String(room.id)
			queue_redraw()
			return

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed:
		return
	if key_event.keycode == KEY_1:
		_tab = 0
	elif key_event.keycode == KEY_2:
		_tab = 1
	elif key_event.keycode == KEY_3:
		_tab = 2
	elif key_event.keycode == KEY_4:
		_tab = 3
	elif key_event.keycode == KEY_5:
		_tab = 4
	elif key_event.keycode == KEY_SPACE and _tab == 4:
		_autonomy_auto_run = not _autonomy_auto_run
		_autonomy_accumulator = 0.0
	elif key_event.keycode == KEY_ENTER and _tab == 4 and _autonomy != null:
		_autonomy.step()
	elif key_event.keycode == KEY_LEFT and _tab == 1:
		_bestiary_index = posmod(_bestiary_index - 1, maxi(1, _bestiary.size()))
	elif key_event.keycode == KEY_RIGHT and _tab == 1:
		_bestiary_index = posmod(_bestiary_index + 1, maxi(1, _bestiary.size()))
	else:
		return
	queue_redraw()
