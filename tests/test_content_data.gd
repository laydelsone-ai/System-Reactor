extends SceneTree

var _failures := 0
var _passes := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bestiary := _load_json("res://data/bestiary/floor01_species.json")
	var social := _load_json("res://data/social/social_registry_v0.2.json")
	var missions := _load_json("res://data/missions/mission_templates_v0.1.json")
	var species: Array = bestiary.get("species", [])
	var people: Array = social.get("people", [])
	var households: Array = social.get("households", [])
	var relationships: Array = social.get("relationships", [])
	var mission_items: Array = missions.get("missions", [])

	_check(species.size() == 5, "floor 1 bestiary contains five source profiles")
	_check(people.size() == 180, "social registry contains 180 imported people")
	_check(households.size() == 40, "social registry preserves 40 source household groups")
	_check(mission_items.size() == 12, "NPC catalogue preserves 12 conditional mission templates")

	var species_ids: Dictionary = {}
	for item in species:
		var species_id := String(item.get("id", ""))
		_check(not species_id.is_empty() and not species_ids.has(species_id), "bestiary species IDs are present and unique: " + species_id)
		species_ids[species_id] = true
		_check(int(item.get("floor", 0)) == 1, "all loaded bestiary profiles belong to floor 1")
		_check(int(item.get("danger", 0)) >= 1 and int(item.get("danger", 0)) <= 5, "danger guide stays within 1-5")
		var stats: Dictionary = item.get("stats", {})
		for stat_name in ["fuerza", "potencia", "agilidad", "coordinacion", "resistencia_fisica", "percepcion"]:
			var stat_value := int(stats.get(stat_name, -1))
			_check(stat_value >= 0 and stat_value <= 100, "aptitude scale remains within 0-100: " + species_id + "/" + stat_name)

	var named_count := 0
	var background_count := 0
	for person in people:
		var layer := String(person.get("population_layer", ""))
		if layer == "authored_named_cast":
			named_count += 1
		elif layer == "background_seeded_population":
			background_count += 1
	_check(named_count == 60, "social registry preserves 60 named records")
	_check(background_count == 120, "social registry preserves 120 background records")

	var household_edges := 0
	for relation in relationships:
		if String(relation.get("relationship_type", "")) == "same_household_member":
			household_edges += 1
	_check(household_edges == 240, "social registry preserves 240 directed household co-membership links")
	_check(social.get("unresolved_social_claims", []).size() == 4, "four unresolved social claims remain unresolved")

	print("WLA CONTENT TESTS: %d passed, %d failed" % [_passes, _failures])
	quit(1 if _failures > 0 else 0)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_check(false, "file can be opened: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_check(false, "JSON root is an object: " + path)
		return {}
	_check(true, "JSON loaded: " + path.get_file())
	return parsed

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
