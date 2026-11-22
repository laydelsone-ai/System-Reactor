extends SceneTree

const SystemCoreScript = preload("res://scripts/core/system_core.gd")

var _passes := 0
var _failures := 0
var _test_root := ""
var _autonomy_runtime_script: Script

func _initialize() -> void:
	_test_root = "user://wla0b_autonomy_tests_%d" % Time.get_ticks_usec()
	call_deferred("_run")

func _run() -> void:
	_autonomy_runtime_script = load("res://scripts/simulation/autonomy_runtime.gd") as Script
	if _autonomy_runtime_script == null:
		push_error("WLA-0B: runtime no cargable: res://scripts/simulation/autonomy_runtime.gd. El mensaje previo de Godot debe indicar el error interno del parser.")
		quit(1)
		return
	var social := _load_json("res://data/social/social_registry_v0.2.json")
	var bestiary := _load_json("res://data/bestiary/floor01_species.json")
	_test_agent_and_ecology_initialization(social, bestiary)
	_test_sensory_limits(social, bestiary)
	_test_conditioned_environmental_response(social, bestiary)
	_test_observer_intervention_persistence(social, bestiary)
	_test_memory_and_individual_cognition(social, bestiary)
	_test_autonomous_decisions_and_species_behavior(social, bestiary)
	_test_reproducibility(social, bestiary)
	_test_durable_checkpoint_and_replay(social, bestiary)
	print("WLA-0B AUTONOMY TESTS: %d passed, %d failed" % [_passes, _failures])
	quit(1 if _failures > 0 else 0)

func _test_agent_and_ecology_initialization(social: Dictionary, bestiary: Dictionary) -> void:
	var runtime: Variant = _autonomy_runtime_script.new()
	var initialized: Dictionary = runtime.initialize_experiment(social, bestiary, 20261120)
	_check(initialized.get("ok", false), "autonomy runtime initializes without a player")
	var state: Dictionary = runtime.get_state_copy()
	_check(state.get("agents", {}).size() == 180, "all 180 source NPC records become autonomous agents")
	_check(state.get("trial_creatures", {}).size() == 4, "four biological trial subjects are instantiated separately from canon")
	_check(state.get("ecological_processes", {}).has("trial_fungus_01"), "fungus is represented as an environmental process")
	_check(not state.get("trial_creatures", {}).has("trial_fungus_01"), "fungus is not misclassified as a cognitive creature")
	_check(String(state.get("branch_scope", "")).contains("experimental"), "the trial ecology remains outside canonical world content")
	var rat: Dictionary = runtime.get_creature("trial_rat_01")
	_check(String(rat.get("species_id", "")) == "MON-F1-001", "rat trial subject uses the source bestiary identity")
	_check(String(rat.get("trial_scope", "")).contains("not_canonical_spawn"), "trial creature is explicitly not a canonical spawn")
	var fungus: Dictionary = state.get("ecological_processes", {}).get("trial_fungus_01", {})
	_check(String(fungus.get("nature", "")).contains("not_cognitive_agent"), "fungus response is physiological, not cognitive")
	var perception: Dictionary = runtime.inspect_perception("npc_0001")
	_check(perception.get("visible_peers", []).is_empty(), "shared work-area labels do not fabricate physical co-presence")
	_check(not bool(perception.get("omniscient_world_access", true)), "human agents do not receive omniscient world access")
	var authored: Dictionary = runtime.get_agent("npc_0001")
	var source_people: Array = social.get("people", [])
	var source_named: Dictionary = source_people[0]
	var background_source: Dictionary = source_people[60]
	var background_agent: Dictionary = runtime.get_agent(String(background_source.get("person_id", "")))
	var imported_motivations := 0
	var imported_tensions := 0
	var imported_routines := 0
	for source_person_value in source_people:
		var source_person: Dictionary = source_person_value
		var imported_agent: Dictionary = runtime.get_agent(String(source_person.get("person_id", "")))
		if not String(source_person.get("motivation_summary", "")).is_empty() and String(imported_agent.get("motivation", "")) == String(source_person.get("motivation_summary", "")):
			imported_motivations += 1
		if not String(source_person.get("current_tension_summary", "")).is_empty() and String(imported_agent.get("current_tension", "")) == String(source_person.get("current_tension_summary", "")):
			imported_tensions += 1
		if not String(source_person.get("routine_summary", "")).is_empty() and String(imported_agent.get("routine_summary", "")) == String(source_person.get("routine_summary", "")):
			imported_routines += 1
	_check(imported_motivations == 180, "all 180 declared motivation summaries map from the source schema into autonomous goals")
	_check(imported_tensions == 60, "the 60 authored tension summaries are preserved as decision inputs")
	_check(imported_routines == 120, "the 120 source routines are preserved as individual action inputs")
	_check(String(authored.get("motivation", "")) == String(source_named.get("motivation_summary", "")), "authored main-cast motivation uses the exact source field")
	_check(String(authored.get("current_tension", "")) == String(source_named.get("current_tension_summary", "")), "authored main-cast tension uses the exact source field")
	_check(String(background_agent.get("motivation", "")) == String(background_source.get("motivation_summary", "")), "background population motivation uses the exact source field")
	_check(authored.get("personality_traits", []).is_empty(), "missing traits on authored NPC remain unknown rather than invented")
	_check(authored.get("cognitive_profile", {}).is_empty(), "missing cognitive aptitudes on authored NPC remain unknown")
	_check(authored.get("household_id", null) == null, "missing household assignment remains null")
	_check(String(authored.get("universal_identity_id", "")).is_empty(), "a null source identity remains unknown instead of being upgraded to a universal identity")
	_check(String(authored.get("location_basis", "")).contains("not_physical_coordinate"), "source work-area text is never upgraded into a physical spawn")
	_check(String(authored.get("validated_current_location_id", "")).is_empty(), "unvalidated presence remains unknown")

func _test_sensory_limits(social: Dictionary, bestiary: Dictionary) -> void:
	var runtime: Variant = _autonomy_runtime_script.new()
	runtime.initialize_experiment(social, bestiary, 1337)
	var state: Dictionary = runtime.get_state_copy()
	var creatures: Dictionary = state.get("trial_creatures", {})
	var bat: Dictionary = creatures.get("trial_bat_01", {})
	var beetle: Dictionary = creatures.get("trial_beetle_01", {})
	var crawler: Dictionary = creatures.get("trial_crawler_01", {})
	beetle["location"] = "R10"
	crawler["location"] = "R05"
	creatures["trial_beetle_01"] = beetle
	creatures["trial_crawler_01"] = crawler
	state["trial_creatures"] = creatures
	var rooms: Dictionary = state.get("environment", {}).get("rooms", {})
	var bat_room: Dictionary = rooms.get("R04", {})
	bat_room["noise"] = 0.9
	rooms["R04"] = bat_room
	state["environment"]["rooms"] = rooms
	var blocked: Dictionary = runtime._perceive_creature(state, bat)
	_check(blocked.get("visible_entities", []).is_empty(), "bat echolocation loses a nearby target in a high-noise chamber")
	bat_room["noise"] = 0.0
	rooms["R04"] = bat_room
	state["environment"]["rooms"] = rooms
	var detectable: Dictionary = runtime._perceive_creature(state, bat)
	_check(detectable.get("visible_entities", []).size() == 1, "bat echolocation detects a nearby target when acoustic conditions permit")
	_check(not bool(detectable.get("omniscient_world_access", true)), "creature perception explicitly excludes omniscient world access")

func _test_conditioned_environmental_response(social: Dictionary, bestiary: Dictionary) -> void:
	var runtime: Variant = _autonomy_runtime_script.new()
	runtime.initialize_experiment(social, bestiary, 9871)
	var state: Dictionary = runtime.get_state_copy()
	var creatures: Dictionary = state.get("trial_creatures", {})
	var rat: Dictionary = creatures.get("trial_rat_01", {})
	for other_id in ["trial_beetle_01", "trial_bat_01", "trial_crawler_01"]:
		var other: Dictionary = creatures.get(other_id, {})
		other["location"] = "R10"
		creatures[other_id] = other
	creatures["trial_rat_01"] = rat
	state["trial_creatures"] = creatures
	var rooms: Dictionary = state.get("environment", {}).get("rooms", {})
	var room: Dictionary = rooms.get("R07", {})
	room["noise"] = 0.8
	rooms["R07"] = room
	state["environment"]["rooms"] = rooms
	var perception: Dictionary = runtime._perceive_creature(state, rat)
	var decision: Dictionary = runtime._decide_creature(state, rat, perception, 1)
	_check(String(decision.get("action", "")) == "flee_to_narrow_refuge", "rat flees from strong environmental vibration even without a detected predator")
	_check(String(decision.get("reason", "")).contains("vibración intensa"), "rat decision records the actual detected cause rather than a scripted enemy target")

func _test_observer_intervention_persistence(social: Dictionary, bestiary: Dictionary) -> void:
	var runtime: Variant = _autonomy_runtime_script.new()
	var initialized: Dictionary = runtime.initialize_experiment(social, bestiary, 77231)
	_check(initialized.get("ok", false), "observer intervention test initializes an isolated runtime")
	var intervention: Dictionary = runtime.emit_vibration("R07", 0.73)
	_check(intervention.get("ok", false), "observer vibration intervention is accepted only for an existing trial room")
	var state: Dictionary = runtime.get_state_copy()
	var environment: Dictionary = state.get("environment", {})
	var rooms: Dictionary = environment.get("rooms", {})
	var room: Dictionary = rooms.get("R07", {})
	_check(float(room.get("noise", 0.0)) >= 0.73, "observer vibration updates and persists the target room state")
	var stimuli: Array = environment.get("stimuli", [])
	var found_observer_stimulus := false
	for stimulus_value in stimuli:
		var stimulus: Dictionary = stimulus_value
		if String(stimulus.get("type", "")) == "vibration" and String(stimulus.get("room_id", "")) == "R07" and String(stimulus.get("source", "")) == "observer_intervention":
			found_observer_stimulus = true
			break
	_check(found_observer_stimulus, "observer vibration retains explicit intervention provenance")
	var metrics: Dictionary = state.get("metrics", {})
	_check(int(metrics.get("observer_interventions", 0)) == 1, "observer intervention is counted separately from autonomous actions")


func _test_memory_and_individual_cognition(social: Dictionary, bestiary: Dictionary) -> void:
	var runtime: Variant = _autonomy_runtime_script.new()
	runtime.initialize_experiment(social, bestiary, 481516)
	var strong_reasoner := {"cognitive_profile":{"reasoning":90}}
	var weak_reasoner := {"cognitive_profile":{"reasoning":10}}
	var strong_bias: float = float(runtime._aptitude_bias(strong_reasoner, "reasoning", 0.10))
	var weak_bias: float = float(runtime._aptitude_bias(weak_reasoner, "reasoning", 0.10))
	_check(strong_bias > weak_bias, "declared cognitive aptitude changes utility weights")
	var missing_aptitude: float = float(runtime._aptitude_bias({"cognitive_profile":{}}, "reasoning", 0.10))
	_check(is_zero_approx(missing_aptitude), "unknown aptitude contributes no fabricated personal bonus")
	_check(runtime._trait_bias(["disciplinado"], "routine") > runtime._trait_bias(["reservado"], "routine"), "declared personality traits alter relevant decision preferences")
	var successful_memory := {"cognitive_profile":{"memory":90}, "memory":[{"type":"action_outcome", "action":"advance_motivation", "tick":8, "success":true, "confidence":0.9, "importance":0.6}]}
	var failed_memory := {"cognitive_profile":{"memory":90}, "memory":[{"type":"action_outcome", "action":"advance_motivation", "tick":8, "success":false, "confidence":0.9, "importance":0.6}]}
	var positive_memory_bias: float = float(runtime._memory_bias(successful_memory, "advance_motivation", 9))
	var negative_memory_bias: float = float(runtime._memory_bias(failed_memory, "advance_motivation", 9))
	_check(positive_memory_bias > 0.0, "remembered success slightly reinforces a future action")
	_check(negative_memory_bias < 0.0, "remembered failure reduces the future utility of repeating an action")
	var unknown_memory_profile := {"cognitive_profile":{}, "memory":[{"type":"action_outcome", "action":"advance_motivation", "tick":8, "success":true, "confidence":0.9, "importance":0.6}]}
	var known_memory_profile := {"cognitive_profile":{"memory":90}, "memory":[{"type":"action_outcome", "action":"advance_motivation", "tick":8, "success":true, "confidence":0.9, "importance":0.6}]}
	_check(runtime._memory_bias(unknown_memory_profile, "advance_motivation", 9) > 0.0, "generic memory mechanism remains active without inventing a memory aptitude")
	_check(runtime._memory_bias(known_memory_profile, "advance_motivation", 9) > runtime._memory_bias(unknown_memory_profile, "advance_motivation", 9), "a supplied memory aptitude modifies recall influence only when present")
	var source_people: Array = social.get("people", [])
	var background_id := String(source_people[60].get("person_id", ""))
	var agent: Dictionary = runtime.get_agent(background_id)
	var perception := {"visible_peers":[], "pending_offers":[], "recalled_memories":[]}
	var without_memory: Dictionary = runtime._decide_human(agent, perception, 9)
	var remembered_agent := agent.duplicate(true)
	remembered_agent["memory"] = [{"memory_id":"test_failure", "type":"action_outcome", "action":"advance_motivation", "tick":8, "success":false, "confidence":0.95, "importance":0.9}]
	var with_memory: Dictionary = runtime._decide_human(remembered_agent, perception, 9)
	var baseline_goal_score := _candidate_score(without_memory, "advance_motivation")
	var recalled_goal_score := _candidate_score(with_memory, "advance_motivation")
	_check(recalled_goal_score < baseline_goal_score, "recalled personal experience changes the next decision score")

func _candidate_score(decision: Dictionary, action: String) -> float:
	for candidate_value in decision.get("candidate_scores", []):
		var candidate: Dictionary = candidate_value
		if String(candidate.get("action", "")) == action:
			return float(candidate.get("score", -999.0))
	return -999.0

func _test_autonomous_decisions_and_species_behavior(social: Dictionary, bestiary: Dictionary) -> void:
	var runtime: Variant = _autonomy_runtime_script.new()
	runtime.initialize_experiment(social, bestiary, 20261120)
	var first_step: Dictionary = runtime.step()
	_check(first_step.get("ok", false), "world advances without player input")
	_check(int(first_step.get("npc_decisions", 0)) == 24, "scheduler evaluates a bounded batch of 24 NPCs per abstract tick")
	_check(int(first_step.get("creature_decisions", 0)) == 4, "each trial creature evaluates its own species behavior every tick")
	_check(int(first_step.get("decisions", 0)) == 28, "NPC and creature decisions are counted separately from environmental processes")
	var first_metrics: Dictionary = first_step.get("metrics", {})
	_check(int(first_metrics.get("decisions_processed", 0)) == 28, "decision attempts are measured separately from successful actions")
	_check(int(first_metrics.get("actions_committed", 0)) <= int(first_metrics.get("decisions_processed", 0)), "committed actions never exceed decision attempts")
	var first_named_agent: Dictionary = runtime.get_agent("npc_0001")
	_check(String(first_named_agent.get("last_action", "")) == "advance_motivation", "a named NPC independently acts on its documented motivation in the first cycle")
	_check(not first_named_agent.get("goal_steps", {}).is_empty(), "human autonomous action creates a persistent effort consequence without claiming goal completion")
	var rat_after_first: Dictionary = runtime.get_creature("trial_rat_01")
	var crawler_after_first: Dictionary = runtime.get_creature("trial_crawler_01")
	_check(String(rat_after_first.get("location", "")) == "R08", "rat flees into a narrow refuge when a crawler closes in")
	_check(String(crawler_after_first.get("location", "")) == "R07", "crawler stalks toward prey it can sense and physically reach")
	var beetle: Dictionary = runtime.get_creature("trial_beetle_01")
	var bat: Dictionary = runtime.get_creature("trial_bat_01")
	_check(String(beetle.get("last_action", "")) == "consume_detritus", "ferrante beetle feeds on available detritus")
	_check(String(bat.get("last_action", "")) == "forage_insects", "echo bat forages for insects using its sensory profile")
	var second_step: Dictionary = runtime.step()
	_check(second_step.get("ok", false), "second autonomous cycle commits")
	var crawler_second: Dictionary = runtime.get_creature("trial_crawler_01")
	var rat_second: Dictionary = runtime.get_creature("trial_rat_01")
	_check(String(crawler_second.get("last_action", "")) == "abandon_narrow_pursuit", "crawler abandons prey that enters an inaccessible narrow crack")
	_check(String(rat_second.get("location", "")) == "R09", "rat continues seeking a narrow refuge after the predator gives chase")
	var fungus_damage: Dictionary = runtime.damage_fungus(0.55)
	_check(fungus_damage.get("ok", false), "observer disturbance is recorded as a separate intervention")
	var third_step: Dictionary = runtime.step()
	_check(third_step.get("ok", false), "ecological process advances on its own after the intervention")
	var current_state: Dictionary = runtime.get_state_copy()
	var fungus_state: Dictionary = current_state.get("ecological_processes", {}).get("trial_fungus_01", {})
	_check(int(current_state.get("metrics", {}).get("spore_releases", 0)) == 1, "fungus releases spores only after its humidity, maturity and tissue conditions are met")
	_check(float(fungus_state.get("spore_cloud", 0.0)) > 0.0, "physiological consequence changes the colony state")
	_check(String(fungus_state.get("last_response", "")).contains("spore_release"), "fungus records a causal physiological response")
	for tick in range(5):
		var result: Dictionary = runtime.step()
		_check(result.get("ok", false), "scheduler continues autonomous simulation through cycle %d" % (tick + 4))
	var report: Dictionary = runtime.get_report()
	_check(int(report.get("npc_with_memory", 0)) > 0, "agents accumulate individual memories from their own actions")
	_check(int(report.get("metrics", {}).get("memories_written", 0)) > 0, "memory-write metric counts actual memory records")
	var rat_memory: Array = runtime.get_creature("trial_rat_01").get("memory", [])
	_check(not rat_memory.is_empty(), "creature stores a first-person record of its own sensory action outcomes")
	_check(int(report.get("metrics", {}).get("movement_steps", 0)) > 0, "movement consequences are counted separately from decisions")
	_check(int(report.get("metrics", {}).get("resources_consumed", 0)) > 0, "ecological resource consumption changes measurable world state")
	var all_agents: Dictionary = runtime.get_state_copy().get("agents", {})
	var evaluated := 0
	for agent_value in all_agents.values():
		if int(agent_value.get("last_decision_tick", -1)) >= 1:
			evaluated += 1
	_check(evaluated == 180, "round-robin scheduler evaluates the complete population over successive ticks")

func _test_reproducibility(social: Dictionary, bestiary: Dictionary) -> void:
	var left: Variant = _autonomy_runtime_script.new()
	var right: Variant = _autonomy_runtime_script.new()
	left.initialize_experiment(social, bestiary, 73119)
	right.initialize_experiment(social, bestiary, 73119)
	for tick in range(10):
		var left_result: Dictionary = left.step()
		var right_result: Dictionary = right.step()
		_check(left_result.get("ok", false) and right_result.get("ok", false), "fixed-seed replicas complete tick %d" % (tick + 1))
	_check(left.get_state_copy() == right.get_state_copy(), "fixed seed and identical input reproduce the same autonomous state")
	_check(left.get_recent_events(80) == right.get_recent_events(80), "fixed seed reproduces the same decision and consequence trace")

func _test_durable_checkpoint_and_replay(social: Dictionary, bestiary: Dictionary) -> void:
	var core: Variant = SystemCoreScript.new(_test_root)
	var opened: Dictionary = core.open_last_or_create()
	_check(opened.get("ok", false), "test world opens for autonomous persistence")
	var runtime: Variant = _autonomy_runtime_script.new()
	var runtime_open: Dictionary = runtime.open(core, social, bestiary)
	_check(runtime_open.get("ok", false), "autonomy binds to the event-sourced world core")
	var step_result: Dictionary = runtime.step()
	_check(step_result.get("ok", false), "autonomous tick is committed to the world journal")
	var saved: Dictionary = runtime.save_checkpoint()
	_check(saved.get("ok", false), "autonomy snapshot and core snapshot are committed")
	var post_snapshot_step: Dictionary = runtime.step()
	_check(post_snapshot_step.get("ok", false), "a later autonomous tick is appended after the saved snapshot")
	var expected_tick: int = int(runtime.current_tick())
	var restored_core: Variant = SystemCoreScript.new(_test_root)
	var restored_open: Dictionary = restored_core.open_last_or_create()
	_check(restored_open.get("ok", false), "world core recovers after autonomous checkpoint")
	var restored_runtime: Variant = _autonomy_runtime_script.new()
	var restored_runtime_open: Dictionary = restored_runtime.open(restored_core, social, bestiary)
	_check(restored_runtime_open.get("ok", false), "autonomous domain restores its snapshot")
	_check(restored_runtime.current_tick() == expected_tick, "autonomous snapshot and post-snapshot journal replay restore the latest tick")
	_check(restored_runtime.get_creature("trial_rat_01") == runtime.get_creature("trial_rat_01"), "creature state and decisions survive snapshot restoration")
	_check(restored_runtime.get_agent("npc_0001") == runtime.get_agent("npc_0001"), "NPC memory and individual progress survive snapshot restoration")

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_check(false, "file opens: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_check(false, "JSON root is a dictionary: " + path)
		return {}
	return parsed

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
