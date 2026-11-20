extends RefCounted

const GIVEN_NAMES: Array[String] = ["Aren", "Mira", "Kael", "Liora", "Soren", "Nara", "Eren", "Veya", "Darin", "Ilya", "Taren", "Selka"]
const FAMILY_NAMES: Array[String] = ["Valen", "Oris", "Thorne", "Merrow", "Aster", "Rook", "Neris", "Voss"]

func generate(seed_value: int, humanoid_count: int = 64, creature_count: int = 24) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var agents: Dictionary = {}
	var total := humanoid_count + creature_count
	for index in range(total):
		var is_creature := index >= humanoid_count
		var agent_id := "agent_%04d" % (index + 1)
		var display_name := ""
		var species_id := ""
		if is_creature:
			display_name = "Criatura %02d" % (index - humanoid_count + 1)
			species_id = "wild_creature_seed"
		else:
			var first := GIVEN_NAMES[rng.randi_range(0, GIVEN_NAMES.size() - 1)]
			var family := FAMILY_NAMES[rng.randi_range(0, FAMILY_NAMES.size() - 1)]
			display_name = "%s %s" % [first, family]
			species_id = "human_seed"
		var x := rng.randf_range(-9.0, 9.0)
		var z := rng.randf_range(-9.0, 9.0)
		var agent := {
			"agent_id": agent_id,
			"universal_identity_id": "uid_%04d" % (index + 1),
			"life_episode_id": "life_%04d_01" % (index + 1),
			"body_id": "body_%04d_01" % (index + 1),
			"cognitive_profile_id": "cog_%04d" % (index + 1),
			"display_name": display_name,
			"entity_kind": "creature" if is_creature else "person",
			"species_definition_id": species_id,
			"region_id": "region_origin",
			"position": [x, 0.0, z],
			"asset_key": "models/proxy_creature" if is_creature else "models/proxy_humanoid",
			"life_state": "alive",
			"needs": {
				"hunger": rng.randf_range(5.0, 55.0),
				"fatigue": rng.randf_range(5.0, 55.0),
				"safety": rng.randf_range(55.0, 100.0)
			},
			"personality": {
				"caution": rng.randf(),
				"curiosity": rng.randf(),
				"persistence": rng.randf()
			},
			"capabilities": {"move": true, "forage": true, "eat": true, "rest": true},
			"inventory": {"food": rng.randi_range(0, 2)},
			"memories": [],
			"beliefs": [],
			"relationships": [],
			"goals": ["survive", "maintain_condition"],
			"last_decision_tick": 0,
			"next_decision_tick": rng.randi_range(60, 900),
			"last_decision_trace": {}
		}
		agents[agent_id] = agent

	return {
		"save_schema_version": 1,
		"world_id": "world_local_%s" % str(seed_value),
		"seed": seed_value,
		"rng_state": rng.state,
		"rules_version": "WLA-0.1.0",
		"generator_version": "seed_generator-0.1.0",
		"world_tick": 0,
		"last_wall_epoch": 0,
		"paused": false,
		"next_ecology_tick": 3600,
		"agents": agents,
		"regions": {
			"region_origin": {
				"region_id": "region_origin",
				"display_name": "Región de prueba",
				"food_units": 900,
				"population_pressure": 0.25,
				"resource_version": 1
			}
		},
		"processed_command_ids": {},
		"recent_events": [],
		"last_event_id": "",
		"clock_anomalies": []
	}
