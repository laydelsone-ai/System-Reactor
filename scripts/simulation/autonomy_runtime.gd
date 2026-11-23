extends RefCounted

## WLA-0B — runtime autónomo offline.
## La rama de prueba ecológica usa fixtures explícitos y no declara geografía canónica.
## Los NPC conservan únicamente motivaciones, tensiones, roles, rasgos y vínculos declarados.

const RUNTIME_VERSION := "WLA-0B.2"
const SNAPSHOT_SCHEMA := 1
const HUMAN_DECISION_BUDGET := 24
const MAX_MEMORY_ITEMS := 28
const MAX_RECENT_EVENTS := 80
const AUTOSAVE_INTERVAL := 12

const TRIAL_EDGES: Array = [
	["R01", "R02"], ["R02", "R03"], ["R03", "R04"],
	["R02", "R07"], ["R03", "R06"], ["R04", "R05"],
	["R06", "R05"], ["R06", "R07"], ["R07", "R08"],
	["R08", "R09"], ["R09", "R10"], ["R10", "R11"],
	["R11", "R12"], ["R05", "R12"]
]

const TRAIT_BIASES := {
	"prudente": {"risk": -0.18, "rest": 0.08, "investigate": 0.12},
	"ambicioso": {"goal": 0.18, "routine": 0.04},
	"solidario": {"social": 0.14, "help": 0.20},
	"reservado": {"social": -0.18},
	"desconfiado": {"social": -0.12, "verify": 0.10},
	"curioso": {"investigate": 0.20, "study": 0.14},
	"creativo": {"investigate": 0.15, "goal": 0.04},
	"paciente": {"persistence": 0.16, "study": 0.08},
	"disciplinado": {"routine": 0.18, "goal": 0.06},
	"generoso": {"social": 0.10, "help": 0.16},
	"sociable": {"social": 0.20, "communication": 0.08},
	"sociable_extrovertido": {"social": 0.22, "communication": 0.08}
}

var _core: Variant
var _state: Dictionary = {}
var _social_source: Dictionary = {}
var _bestiary_source: Dictionary = {}
var _ready := false
var _last_error := ""
var _last_decision_batch: Array = []
var _memory_writes_this_step := 0

func open(core: Variant, social_data: Dictionary, bestiary_data: Dictionary) -> Dictionary:
	if core == null or not core.ready:
		return {"ok": false, "message": "El núcleo del mundo no está disponible."}
	_core = core
	_social_source = social_data.duplicate(true)
	_bestiary_source = bestiary_data.duplicate(true)
	var seed_value := int(core.world_metadata.get("seed", 20261120))
	_state = _create_initial_state(_social_source, _bestiary_source, seed_value)
	var population_result := _register_population_identities()
	if not population_result.get("ok", false):
		return population_result
	var restore_result := _restore_snapshot_and_replay()
	if not restore_result.get("ok", false):
		return restore_result
	_ready = true
	return {
		"ok": true,
		"message": "Runtime autónomo WLA-0B inicializado.",
		"agents": _state.get("agents", {}).size(),
		"trial_creatures": _state.get("trial_creatures", {}).size(),
		"trial_only": true,
		"restored": bool(restore_result.get("restored", false)),
		"replayed_steps": int(restore_result.get("replayed_steps", 0))
	}

func initialize_experiment(social_data: Dictionary, bestiary_data: Dictionary, seed_value: int = 20261120) -> Dictionary:
	## Modo in-memory para pruebas reproducibles. No escribe ni crea entidades canónicas.
	_core = null
	_social_source = social_data.duplicate(true)
	_bestiary_source = bestiary_data.duplicate(true)
	_state = _create_initial_state(_social_source, _bestiary_source, seed_value)
	_ready = true
	_last_error = ""
	return {"ok": true, "agents": _state.agents.size(), "trial_creatures": _state.trial_creatures.size()}

func is_ready() -> bool:
	return _ready

func current_tick() -> int:
	return int(_state.get("tick", 0))

func get_state_copy() -> Dictionary:
	return _state.duplicate(true)

func get_agent(agent_id: String) -> Dictionary:
	var agents: Dictionary = _state.get("agents", {})
	if not agents.has(agent_id):
		return {}
	return agents[agent_id].duplicate(true)

func get_creature(creature_id: String) -> Dictionary:
	var creatures: Dictionary = _state.get("trial_creatures", {})
	if not creatures.has(creature_id):
		return {}
	return creatures[creature_id].duplicate(true)

func get_recent_events(limit: int = 20) -> Array:
	var events: Array = _state.get("recent_events", [])
	var start := maxi(0, events.size() - maxi(0, limit))
	return events.slice(start, events.size())

func get_metrics() -> Dictionary:
	return _state.get("metrics", {}).duplicate(true)

func get_report() -> Dictionary:
	var agents: Dictionary = _state.get("agents", {})
	var creatures: Dictionary = _state.get("trial_creatures", {})
	var active_npc := 0
	var npc_with_memory := 0
	var npc_with_validated_presence := 0
	var npc_with_known_motivation := 0
	var npc_with_known_routine := 0
	var npc_with_cognitive_profile := 0
	var last_action_names: Dictionary = {}
	for agent_value in agents.values():
		var agent: Dictionary = agent_value
		if String(agent.get("life_state", "active")) == "active":
			active_npc += 1
		if not agent.get("memory", []).is_empty():
			npc_with_memory += 1
		if not String(agent.get("validated_current_location_id", "")).is_empty():
			npc_with_validated_presence += 1
		if not String(agent.get("motivation", "")).is_empty():
			npc_with_known_motivation += 1
		if not String(agent.get("routine_summary", "")).is_empty():
			npc_with_known_routine += 1
		if not agent.get("cognitive_profile", {}).is_empty():
			npc_with_cognitive_profile += 1
		var action_name := String(agent.get("last_action", ""))
		if not action_name.is_empty():
			last_action_names[action_name] = int(last_action_names.get(action_name, 0)) + 1
	return {
		"runtime_version": RUNTIME_VERSION,
		"branch_id": String(_state.get("branch_id", "")),
		"branch_scope": String(_state.get("branch_scope", "")),
		"tick": current_tick(),
		"npc_total": agents.size(),
		"npc_active": active_npc,
		"npc_active_semantics": "active_agent_models_not_physical_world_spawns",
		"npc_with_memory": npc_with_memory,
		"npc_with_validated_presence": npc_with_validated_presence,
		"npc_without_validated_presence": maxi(0, agents.size() - npc_with_validated_presence),
		"npc_with_known_motivation": npc_with_known_motivation,
		"npc_with_known_routine": npc_with_known_routine,
		"npc_with_cognitive_profile": npc_with_cognitive_profile,
		"npc_runtime_resolution": "individual_intent_and_memory_model_without_physical_location_unless_validated",
		"trial_creatures": creatures.size(),
		"metrics": get_metrics(),
		"last_actions": last_action_names,
		"observer_mode": "passive_unless_explicit_test_intervention",
		"human_presence_policy": "same_validated_location_only",
		"combat_resolution": "not_implemented_SR09_required",
		"last_error": _last_error
	}

func step() -> Dictionary:
	if not _ready:
		return {"ok": false, "message": "Runtime autónomo no inicializado."}
	var next_state: Dictionary = _state.duplicate(true)
	_memory_writes_this_step = 0
	var next_tick := int(next_state.get("tick", 0)) + 1
	var decisions: Array = []
	var updates: Array = []
	var agent_updates: Dictionary = {}
	var creature_updates: Dictionary = {}
	var changed_agent_ids: Dictionary = {}
	var agents: Dictionary = next_state.get("agents", {})
	var batch_ids: Array = _select_human_batch(next_state, HUMAN_DECISION_BUDGET)
	_advance_agent_pressures(next_state, batch_ids)
	# Cada agente decide usando la misma fotografía de observación del ciclo.
	# Las consecuencias se confirman en next_state después, sin ventaja por orden de ID.
	var human_observation_state: Dictionary = next_state.duplicate(true)

	for agent_id_value in batch_ids:
		var agent_id := String(agent_id_value)
		var observed_agents: Dictionary = human_observation_state.get("agents", {})
		if not observed_agents.has(agent_id) or not agents.has(agent_id):
			continue
		var agent: Dictionary = observed_agents[agent_id]
		if String(agent.get("life_state", "active")) != "active":
			continue
		var perception := _perceive_human(human_observation_state, agent)
		var decision := _decide_human(agent, perception, next_tick)
		var action_result := _execute_human_action(next_state, agent_id, decision, perception, next_tick)
		agent = agents[agent_id]
		agent["last_decision_tick"] = next_tick
		agent["last_decision"] = decision.duplicate(true)
		agent["last_action"] = String(decision.get("action", "observe"))
		agents[agent_id] = agent
		var trace := _make_trace(agent_id, agent, perception, decision, action_result, next_tick)
		decisions.append(trace)
		changed_agent_ids[agent_id] = true
		var modified_target := String(action_result.get("target_id", ""))
		if not modified_target.is_empty() and agents.has(modified_target):
			changed_agent_ids[modified_target] = true
		_append_recent_event(next_state, trace)

	var changed_ids: Array = changed_agent_ids.keys()
	changed_ids.sort()
	for changed_id_value in changed_ids:
		var changed_id := String(changed_id_value)
		var changed_state: Dictionary = agents[changed_id].duplicate(true)
		agent_updates[changed_id] = changed_state
		updates.append({"kind": "npc", "id": changed_id, "state": changed_state.duplicate(true)})

	# Las criaturas del escenario ecológico se evalúan en cada ciclo de prueba:
	# la proximidad y el riesgo inmediato tienen prioridad sobre población lejana.
	var creature_ids: Array = next_state.get("trial_creatures", {}).keys()
	creature_ids.sort()
	var creature_observation_state: Dictionary = next_state.duplicate(true)
	for creature_id_value in creature_ids:
		var creature_id := String(creature_id_value)
		var observed_creatures: Dictionary = creature_observation_state.get("trial_creatures", {})
		var creature: Dictionary = observed_creatures[creature_id]
		var creature_perception := _perceive_creature(creature_observation_state, creature)
		var creature_decision := _decide_creature(creature_observation_state, creature, creature_perception, next_tick)
		var creature_result := _execute_creature_action(next_state, creature_id, creature_decision, creature_perception, next_tick)
		creature = next_state.trial_creatures[creature_id]
		creature["last_decision"] = creature_decision.duplicate(true)
		creature["last_action"] = String(creature_decision.get("action", "hold"))
		creature["last_decision_tick"] = next_tick
		next_state.trial_creatures[creature_id] = creature
		var creature_trace := _make_trace(creature_id, creature, creature_perception, creature_decision, creature_result, next_tick)
		decisions.append(creature_trace)
		var creature_state: Dictionary = creature.duplicate(true)
		creature_updates[creature_id] = creature_state
		updates.append({"kind": "creature", "id": creature_id, "state": creature_state.duplicate(true)})
		_append_recent_event(next_state, creature_trace)

	_process_environmental_organisms(next_state, next_tick, decisions)
	_advance_creature_metabolism(next_state)
	_decay_environment(next_state)
	var scheduler: Dictionary = next_state.get("scheduler", {})
	scheduler["cursor"] = int(scheduler.get("cursor", 0)) + batch_ids.size()
	scheduler["last_batch_size"] = batch_ids.size()
	var agent_decision_count := batch_ids.size() + creature_ids.size()
	scheduler["total_decisions"] = int(scheduler.get("total_decisions", 0)) + agent_decision_count
	next_state["scheduler"] = scheduler
	next_state["tick"] = next_tick
	var metrics: Dictionary = next_state.get("metrics", {})
	metrics["npc_decisions"] = int(metrics.get("npc_decisions", 0)) + batch_ids.size()
	metrics["creature_decisions"] = int(metrics.get("creature_decisions", 0)) + creature_ids.size()
	metrics["decisions_processed"] = int(metrics.get("decisions_processed", 0)) + agent_decision_count
	var successful_action_count := 0
	for decision_index in range(mini(agent_decision_count, decisions.size())):
		if bool(decisions[decision_index].get("success", false)):
			successful_action_count += 1
	metrics["actions_committed"] = int(metrics.get("actions_committed", 0)) + successful_action_count
	metrics["observations_processed"] = int(metrics.get("observations_processed", 0)) + agent_decision_count
	metrics["memories_written"] = int(metrics.get("memories_written", 0)) + _memory_writes_this_step
	metrics["environmental_processes"] = int(metrics.get("environmental_processes", 0)) + (decisions.size() - agent_decision_count)
	next_state["metrics"] = metrics

	var event_payload := {
		"runtime_version": RUNTIME_VERSION,
		"branch_id": next_state.branch_id,
		"tick": next_tick,
		"decisions": decisions,
		"updates": updates,
		"agent_updates": agent_updates.duplicate(true),
		"creature_updates": creature_updates.duplicate(true),
		"trial_creatures": next_state.trial_creatures.duplicate(true),
		"environment": next_state.environment.duplicate(true),
		"ecological_processes": next_state.ecological_processes.duplicate(true),
		"scheduler": scheduler.duplicate(true),
		"metrics": metrics.duplicate(true),
		"recent_events": next_state.recent_events.duplicate(true)
	}
	if _core != null:
		var commit_result: Dictionary = _core.commit_domain_event(
			"SimulationStepCommitted", "system", event_payload,
			"SimulationKernel", "wla0b_autonomy_runtime", next_tick
		)
		if not commit_result.get("accepted", false):
			_last_error = String(commit_result.get("message", "No se pudo confirmar el ciclo autónomo."))
			return {"ok": false, "message": _last_error, "tick": current_tick()}
		next_state["last_core_event_sequence"] = int(commit_result.get("sequence", _core.last_event_sequence))
	else:
		next_state["last_core_event_sequence"] = int(next_state.get("last_core_event_sequence", 0)) + 1
	_state = next_state
	_last_decision_batch = decisions.duplicate(true)
	_last_error = ""
	if current_tick() % AUTOSAVE_INTERVAL == 0 and _core != null:
		save_checkpoint()
	return {
		"ok": true,
		"tick": current_tick(),
		"decisions": decisions.size(),
		"npc_decisions": batch_ids.size(),
		"creature_decisions": creature_ids.size(),
		"events": decisions.size(),
		"metrics": get_metrics()
	}

func emit_vibration(room_id: String, intensity: float = 1.0) -> Dictionary:
	return _commit_intervention("vibration", room_id, clampf(intensity, 0.0, 1.0), "observer_manual_stimulus")

func damage_fungus(amount: float = 0.55) -> Dictionary:
	var colony: Dictionary = _state.get("ecological_processes", {}).get("trial_fungus_01", {})
	if colony.is_empty():
		return {"ok": false, "message": "No hay colonia experimental cargada."}
	return _commit_intervention("tissue_damage", String(colony.get("location", "R10")), clampf(amount, 0.0, 1.0), "observer_manual_stimulus")

func save_checkpoint() -> Dictionary:
	if _core == null or _core.world_id.is_empty():
		return {"ok": true, "message": "La simulación está en memoria de prueba; no hay persistencia de mundo."}
	var world_dir := "%s/worlds/%s" % [_core.persistence.storage_root, _core.world_id]
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(world_dir))
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "message": "No se pudo crear el directorio del snapshot autónomo."}
	var payload := {
		"snapshot_schema": SNAPSHOT_SCHEMA,
		"runtime_version": RUNTIME_VERSION,
		"world_id": _core.world_id,
		"last_core_event_sequence": _core.last_event_sequence,
		"state": _state.duplicate(true)
	}
	var payload_text := JSON.stringify(payload, "", true, true)
	var wrapper := {"envelope_version": 1, "payload_json": payload_text, "sha256": payload_text.sha256_text()}
	var final_path := "%s/autonomy_snapshot.json" % world_dir
	var temp_path := "%s.tmp" % final_path
	var backup_path := "%s.bak" % final_path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "No se pudo crear el snapshot autónomo temporal."}
	file.store_string(JSON.stringify(wrapper, "", true, true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {"ok": false, "message": "Falló la escritura del snapshot autónomo."}
	if FileAccess.file_exists(final_path):
		var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(final_path), ProjectSettings.globalize_path(backup_path))
		if copy_error != OK:
			return {"ok": false, "message": "No se pudo preservar el snapshot autónomo anterior."}
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(final_path))
	if rename_error != OK:
		return {"ok": false, "message": "No se pudo publicar el snapshot autónomo verificado."}
	var core_save: Dictionary = _core.save_checkpoint("wla0b_autonomy_snapshot")
	if not core_save.get("ok", false):
		return {"ok": false, "message": "El estado autónomo se guardó, pero el snapshot del núcleo falló: %s" % core_save.get("message", "")}
	return {"ok": true, "message": "Estado autónomo y núcleo guardados.", "tick": current_tick()}

func inspect_perception(agent_id: String) -> Dictionary:
	var agents: Dictionary = _state.get("agents", {})
	if not agents.has(agent_id):
		return {}
	return _perceive_human(_state, agents[agent_id])

func _create_initial_state(social_data: Dictionary, bestiary_data: Dictionary, seed_value: int) -> Dictionary:
	var agents: Dictionary = {}
	var people: Array = social_data.get("people", [])
	for person_value in people:
		if typeof(person_value) != TYPE_DICTIONARY:
			continue
		var person: Dictionary = person_value
		var person_id := String(person.get("person_id", ""))
		if person_id.is_empty() or agents.has(person_id):
			continue
		var context_values: Array = _extract_work_contexts(_source_text(person.get("source_work_area", "")))
		var validated_presence := _dictionary_or_empty(person.get("validated_presence", {}))
		var presence_valid := String(validated_presence.get("status", "")) == "validated" and not String(validated_presence.get("location_id", "")).is_empty()
		var traits := _array_or_empty(person.get("personality_traits", []))
		var aptitudes := _dictionary_or_empty(person.get("aptitudes", {}))
		var cognitive := _dictionary_or_empty(aptitudes.get("cognitive_aptitudes_0_100", {}))
		var source_identity := _dictionary_or_empty(person.get("source_identity", {}))
		var physical_profile := _dictionary_or_empty(aptitudes.get("physical_functional_aptitudes_0_100", {}))
		var goal_text := _source_text(person.get("motivation_summary", ""))
		var tension_text := _source_text(person.get("current_tension_summary", ""))
		var routine_text := _source_text(person.get("routine_summary", ""))
		var role_key := _source_text(person.get("source_role_key", ""))
		var agent := {
			"agent_id": person_id,
			"display_name": String(person.get("display_name", person_id)),
			"agent_kind": "person",
			"population_layer": String(person.get("population_layer", "authored_named_cast")),
			"source_record": String(person.get("source_record", "")),
			"source_role": _source_text(person.get("source_role", "")),
			"source_role_key": role_key,
			"source_work_area": _source_text(person.get("source_work_area", "")),
			"work_contexts": context_values,
			"location_basis": "source_work_area_abstract_context_not_physical_coordinate",
			"motivation": goal_text,
			"goal_category": _goal_category(goal_text, role_key, routine_text, String(person.get("source_role", ""))),
			"goal_category_source": "heuristic_from_declared_motivation_and_role_not_authoritative",
			"validated_current_location_id": String(validated_presence.get("location_id", "")) if presence_valid else "",
			"presence_provenance": String(validated_presence.get("provenance", "")) if presence_valid else "not_supplied_unknown",
			"presence_source_record": String(person.get("source_record", "")) if presence_valid else "not_supplied",
			"current_tension": tension_text,
			"routine_summary": routine_text,
			"personality_traits": traits.duplicate(true),
			"cognitive_profile": cognitive.duplicate(true),
			"physical_profile": physical_profile.duplicate(true),
			"cognitive_profile_status": "source_estimate" if not cognitive.is_empty() else "not_supplied_unknown",
			"knowledge_scope": _source_text(person.get("knowledge_scope", "")) if not _source_text(person.get("knowledge_scope", "")).is_empty() else "not_supplied_unknown",
			"household_id": person.get("household_id", null),
			"declared_affiliation_ids": person.get("declared_affiliation_ids", []).duplicate(true),
			"relationship_views": person.get("relationship_views", []).duplicate(true),
			"universal_identity_id": _source_text(source_identity.get("universal_identity_id", "")),
			"identity_dimensions_status": "source_dimensions_partial" if not source_identity.is_empty() else "not_supplied_unknown",
			"life_episode_id": _source_text(source_identity.get("life_episode_id", "")),
			"body_id": _source_text(source_identity.get("body_id", "")),
			"cognitive_profile_id": _source_text(source_identity.get("cognitive_profile_id", "")),
			"social_identity_id": _source_text(source_identity.get("social_identity_id", "")),
			"life_state": "active",
			"fatigue": 0.0,
			"needs": {"rest":0.0, "purpose_pressure":0.0, "tension_pressure":0.0, "routine_pressure":0.0},
			"goal_steps": {},
			"tension_investigation_steps": 0,
			"routine_practice_steps": 0,
			"learning_practice": {},
			"teaching_practice_steps": 0,
			"social_contact_count": 0,
			"pending_offers": [],
			"memory": [],
			"experience": {},
			"last_decision_tick": -1,
			"last_action": "not_evaluated",
			"last_decision": {},
			"profile_provenance": "user_supplied_social_registry_v0.2.0",
			"unknown_attributes_remain_unknown": true
		}
		agents[person_id] = agent

	return {
		"runtime_version": RUNTIME_VERSION,
		"branch_id": "WLA0B_AUTONOMY_TRIAL",
		"branch_scope": "experimental_runtime_proposal_not_canonical_world_content",
		"seed": seed_value,
		"tick": 0,
		"agents": agents,
		"trial_creatures": _create_trial_creatures(bestiary_data),
		"environment": _create_trial_environment(),
		"ecological_processes": _create_trial_ecology(),
		"scheduler": {"cursor": 0, "last_batch_size": 0, "total_decisions": 0, "human_decision_budget": HUMAN_DECISION_BUDGET},
		"metrics": {
			"npc_decisions": 0, "creature_decisions": 0, "decisions_processed": 0, "actions_committed": 0,
			"observations_processed": 0, "memories_written": 0, "environmental_processes": 0, "social_contacts": 0,
			"lesson_offers": 0, "lessons_accepted": 0, "lessons_declined": 0,
			"movement_steps": 0, "resources_consumed": 0, "spore_releases": 0,
			"observer_interventions": 0, "rejected_actions": 0, "idle_decisions": 0
		},
		"recent_events": [],
		"last_core_event_sequence": 0,
		"provisional_parameters": {
			"human_decision_budget_per_tick": HUMAN_DECISION_BUDGET,
			"ticks_are_abstract_simulation_steps": true,
			"time_conversion_to_seconds": "not_calibrated",
			"trial_ecology_values": "explicit_test_fixtures_not_canonical_population_or_physics",
			"trial_metabolism_rates": "laboratory_fixture_rates_not_canonical_physiology",
			"work_contexts": "coarse source tags for interaction tests, not physical co-location claims",
			"personality_and_cognitive_unknowns": "left unknown; no default traits assigned"
		}
	}

func _create_trial_creatures(bestiary_data: Dictionary) -> Dictionary:
	var species: Dictionary = {}
	for item_value in bestiary_data.get("species", []):
		if typeof(item_value) == TYPE_DICTIONARY:
			var item: Dictionary = item_value
			species[String(item.get("id", ""))] = item
	var creatures: Dictionary = {}
	var fixtures: Array = [
		{"id":"trial_rat_01", "species":"MON-F1-001", "name":"Rata de filón", "room":"R07", "hunger":0.72, "channels":["vibration", "chemical", "air_current"], "style":"forager_escape"},
		{"id":"trial_beetle_01", "species":"MON-F1-002", "name":"Escarabajo ferrante", "room":"R03", "hunger":0.48, "channels":["vibration", "humidity", "chemical"], "style":"detritivore_defense"},
		{"id":"trial_bat_01", "species":"MON-F1-004", "name":"Murciélago de eco", "room":"R04", "hunger":0.63, "channels":["echolocation", "sound", "air_current"], "style":"aerial_insectivore"},
		{"id":"trial_crawler_01", "species":"MON-F1-005", "name":"Rastrero de escombro", "room":"R08", "hunger":0.68, "channels":["vibration", "chemical", "movement"], "style":"ambush_predator"}
	]
	for fixture_value in fixtures:
		var fixture: Dictionary = fixture_value
		var species_id := String(fixture.species)
		var source_species: Dictionary = species.get(species_id, {})
		creatures[String(fixture.id)] = {
			"entity_id": String(fixture.id),
			"entity_kind": "biological_trial_subject",
			"species_id": species_id,
			"species_name": String(source_species.get("name", fixture.name)),
			"source_behavior": String(source_species.get("behavior", "")),
			"source_ecology": String(source_species.get("ecology", "")),
			"trial_scope": "isolated_experiment_fixture_not_canonical_spawn",
			"location": String(fixture.room),
			"hunger": float(fixture.hunger),
			"fatigue": 0.0,
			"sensory_channels": fixture.channels.duplicate(true),
			"behavior_style": String(fixture.style),
			"hidden_state": {"defensive_retraction": false, "ambush_ready": false, "hidden": false},
			"memory": [],
			"experience": {},
			"last_decision": {},
			"last_action": "not_evaluated",
			"last_decision_tick": -1
		}
	return creatures

func _create_trial_environment() -> Dictionary:
	var rooms := {
		"R01": {"label":"Extracción", "neighbors":["R02"], "narrow":false, "cover":0.20, "high_roof":false, "humidity":0.18, "noise":0.0, "fungal_food":0.0, "detritus":0.4, "insects":0.0, "water":0.0, "airflow":0.15},
		"R02": {"label":"Galería", "neighbors":["R01","R03","R07"], "narrow":false, "cover":0.15, "high_roof":false, "humidity":0.22, "noise":0.0, "fungal_food":0.0, "detritus":0.3, "insects":0.1, "water":0.0, "airflow":0.20},
		"R03": {"label":"Vía minera", "neighbors":["R02","R04","R06"], "narrow":false, "cover":0.30, "high_roof":false, "humidity":0.35, "noise":0.0, "fungal_food":0.0, "detritus":4.0, "insects":0.8, "water":0.0, "airflow":0.15},
		"R04": {"label":"Umbral", "neighbors":["R03","R05"], "narrow":false, "cover":0.10, "high_roof":true, "humidity":0.32, "noise":0.0, "fungal_food":0.0, "detritus":0.2, "insects":4.0, "water":0.0, "airflow":0.30},
		"R05": {"label":"Bombeo", "neighbors":["R04","R06","R12"], "narrow":false, "cover":0.20, "high_roof":true, "humidity":0.78, "noise":0.0, "fungal_food":0.2, "detritus":0.4, "insects":1.0, "water":2.0, "airflow":0.22},
		"R06": {"label":"Veta", "neighbors":["R03","R05","R07"], "narrow":false, "cover":0.12, "high_roof":false, "humidity":0.30, "noise":0.0, "fungal_food":0.0, "detritus":0.3, "insects":0.2, "water":0.0, "airflow":0.18},
		"R07": {"label":"Cruce", "neighbors":["R02","R06","R08"], "narrow":false, "cover":0.70, "high_roof":false, "humidity":0.28, "noise":0.0, "fungal_food":0.0, "detritus":0.8, "insects":0.2, "water":0.0, "airflow":0.10},
		"R08": {"label":"Derrumbe", "neighbors":["R07","R09"], "narrow":true, "cover":0.95, "high_roof":false, "humidity":0.48, "noise":0.0, "fungal_food":1.2, "detritus":0.6, "insects":0.4, "water":0.0, "airflow":0.08},
		"R09": {"label":"Cisterna", "neighbors":["R08","R10"], "narrow":true, "cover":0.85, "high_roof":false, "humidity":0.86, "noise":0.0, "fungal_food":1.0, "detritus":0.4, "insects":0.2, "water":1.0, "airflow":0.06},
		"R10": {"label":"Soportes", "neighbors":["R09","R11"], "narrow":false, "cover":0.50, "high_roof":false, "humidity":0.82, "noise":0.0, "fungal_food":2.8, "detritus":0.8, "insects":0.7, "water":0.0, "airflow":0.08},
		"R11": {"label":"Ruinas", "neighbors":["R10","R12"], "narrow":false, "cover":0.50, "high_roof":true, "humidity":0.45, "noise":0.0, "fungal_food":0.3, "detritus":1.8, "insects":0.8, "water":0.0, "airflow":0.20},
		"R12": {"label":"Escombros", "neighbors":["R11","R05"], "narrow":false, "cover":0.78, "high_roof":false, "humidity":0.25, "noise":0.0, "fungal_food":0.0, "detritus":1.5, "insects":0.5, "water":0.0, "airflow":0.12}
	}
	for room_id_value in rooms.keys():
		var room_id := String(room_id_value)
		var room: Dictionary = rooms[room_id]
		room["fungal_food_capacity"] = maxf(1.0, float(room.get("fungal_food", 0.0)) * 1.25)
		room["detritus_capacity"] = maxf(1.0, float(room.get("detritus", 0.0)) * 1.25)
		room["insect_capacity"] = maxf(1.0, float(room.get("insects", 0.0)) * 1.25)
		rooms[room_id] = room
	return {
		"scope": "experimental_reference_map_not_approved_geography",
		"rooms": rooms,
		"stimuli": [],
		"test_scale": "one abstract movement action per successful transition; not a speed unit"
	}

func _create_trial_ecology() -> Dictionary:
	return {
		"trial_fungus_01": {
			"entity_id": "trial_fungus_01",
			"species_id": "MON-F1-003",
			"name": "Colonia de hongo farolero",
			"nature": "biological_colony_environmental_process_not_cognitive_agent",
			"trial_scope": "isolated_experiment_fixture_not_canonical_spawn",
			"location": "R10",
			"maturity_parameter": 0.72,
			"tissue_damage": 0.0,
			"spore_reserve": 1.0,
			"spore_cloud": 0.0,
			"luminescence": 0.25,
			"last_response": "quiescent"
		}
	}

func _register_population_identities() -> Dictionary:
	if _core == null:
		return {"ok": true, "registered": 0}
	var registered := 0
	for person_value in _social_source.get("people", []):
		if typeof(person_value) != TYPE_DICTIONARY:
			continue
		var person: Dictionary = person_value
		var person_id := String(person.get("person_id", ""))
		if person_id.is_empty() or _core.registry.has_entity(person_id):
			continue
		var source_identity := _dictionary_or_empty(person.get("source_identity", {}))
		var record := {
			"entity_id": person_id,
			"entity_kind": "person",
			"scope": "world_local",
			"schema_version": 1,
			"state_version": 1,
			"created_at_world_tick": _core.clock.world_tick,
			"origin": {
				"type": "user_supplied_population_import",
				"stage": "WLA-0B",
				"source_record": person.get("source_record", "social_registry_v0.2"),
				"source_person_id": person_id,
				"content_authority": "subordinate_population_proposal_pending_author_acceptance"
			},
			"display_label": String(person.get("display_name", person_id)),
			"asset_key": null
		}
		for identity_dimension in ["universal_identity_id", "life_episode_id", "body_id", "cognitive_profile_id", "social_identity_id"]:
			var source_dimension := _source_text(source_identity.get(identity_dimension, ""))
			if not source_dimension.is_empty():
				record[identity_dimension] = source_dimension
		var result: Dictionary = _core.execute_register_entity(record, "import_%s" % person_id, "wla0b_population_bootstrap")
		if not result.get("accepted", false):
			return {"ok": false, "message": "No se pudo registrar %s: %s" % [person_id, result.get("message", "error")], "registered": registered}
		registered += 1
	return {"ok": true, "registered": registered}

func _restore_snapshot_and_replay() -> Dictionary:
	if _core == null:
		return {"ok": true, "restored": false, "replayed_steps": 0}
	var base_path := "%s/worlds/%s/autonomy_snapshot.json" % [_core.persistence.storage_root, _core.world_id]
	var backup_path := "%s.bak" % base_path
	var cursor := 0
	var snapshot_cursor := -1
	var restored := false
	for candidate_path in [base_path, backup_path]:
		if not FileAccess.file_exists(candidate_path):
			continue
		var snapshot_result := _read_autonomy_snapshot(candidate_path)
		if snapshot_result.get("ok", false):
			var snapshot_payload: Dictionary = snapshot_result.payload
			if String(snapshot_payload.get("world_id", "")) != _core.world_id:
				continue
			var loaded_state: Variant = snapshot_payload.get("state", null)
			if typeof(loaded_state) != TYPE_DICTIONARY:
				continue
			_state = loaded_state.duplicate(true)
			cursor = int(snapshot_payload.get("last_core_event_sequence", 0))
			snapshot_cursor = cursor
			restored = true
			break
	var journal_result: Dictionary = _core.persistence.read_journal(_core.world_id)
	if not journal_result.get("ok", false):
		return {"ok": false, "message": "No se puede reconstruir la autonomía: el journal del mundo es inválido."}
	var replayed_steps := 0
	for event_value in journal_result.get("events", []):
		var event: Dictionary = event_value
		if int(event.get("sequence", 0)) <= cursor:
			continue
		var event_type := String(event.get("event_type", ""))
		var event_payload: Dictionary = event.get("payload", {})
		if event_type == "SimulationStepCommitted":
			_apply_step_payload(event_payload)
			replayed_steps += 1
		elif event_type == "ObserverInterventionCommitted":
			_apply_intervention_payload(event_payload)
			var metrics: Dictionary = _state.get("metrics", {})
			metrics["observer_interventions"] = int(metrics.get("observer_interventions", 0)) + 1
			_state["metrics"] = metrics
		cursor = int(event.get("sequence", cursor))
	_state["last_core_event_sequence"] = _core.last_event_sequence
	_state["tick"] = maxi(int(_state.get("tick", 0)), _core.clock.world_tick)
	return {
		"ok": true,
		"restored": restored,
		"replayed_steps": replayed_steps,
		"snapshot_cursor": snapshot_cursor,
		"final_cursor": cursor,
		"core_last_sequence": _core.last_event_sequence
	}

func _read_autonomy_snapshot(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false}
	var wrapper: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(wrapper) != TYPE_DICTIONARY:
		return {"ok": false}
	var payload_text := String(wrapper.get("payload_json", ""))
	if payload_text.is_empty() or payload_text.sha256_text() != String(wrapper.get("sha256", "")):
		return {"ok": false}
	var payload: Variant = JSON.parse_string(payload_text)
	if typeof(payload) != TYPE_DICTIONARY or int(payload.get("snapshot_schema", -1)) != SNAPSHOT_SCHEMA:
		return {"ok": false}
	return {"ok": true, "payload": payload}

func _apply_step_payload(payload: Dictionary) -> void:
	## Reproduce el delta del dominio mediante copias explícitas, no referencias compartidas.
	## agent_updates / creature_updates son mapas por ID; updates mantiene compatibilidad.
	var restored_agents: Dictionary = _state.get("agents", {}).duplicate(true)
	var restored_creatures: Dictionary = _state.get("trial_creatures", {}).duplicate(true)

	var agent_updates_value: Variant = payload.get("agent_updates", null)
	if typeof(agent_updates_value) == TYPE_DICTIONARY:
		var agent_updates_map: Dictionary = agent_updates_value
		for agent_id_value in agent_updates_map.keys():
			var agent_id := String(agent_id_value)
			var agent_state: Variant = agent_updates_map[agent_id_value]
			if not agent_id.is_empty() and typeof(agent_state) == TYPE_DICTIONARY:
				restored_agents[agent_id] = agent_state.duplicate(true)

	var creature_updates_value: Variant = payload.get("creature_updates", null)
	if typeof(creature_updates_value) == TYPE_DICTIONARY:
		var creature_updates_map: Dictionary = creature_updates_value
		for creature_id_value in creature_updates_map.keys():
			var creature_id := String(creature_id_value)
			var creature_state: Variant = creature_updates_map[creature_id_value]
			if not creature_id.is_empty() and typeof(creature_state) == TYPE_DICTIONARY:
				restored_creatures[creature_id] = creature_state.duplicate(true)

	# Compatibilidad con eventos WLA-0B anteriores que solo guardaban una lista mixta.
	for update_value in payload.get("updates", []):
		if typeof(update_value) != TYPE_DICTIONARY:
			continue
		var update: Dictionary = update_value
		var entity_id := String(update.get("id", ""))
		var entity_state: Variant = update.get("state", null)
		if entity_id.is_empty() or typeof(entity_state) != TYPE_DICTIONARY:
			continue
		match String(update.get("kind", "")):
			"npc":
				if typeof(agent_updates_value) != TYPE_DICTIONARY:
					restored_agents[entity_id] = entity_state.duplicate(true)
			"creature":
				if typeof(creature_updates_value) != TYPE_DICTIONARY:
					restored_creatures[entity_id] = entity_state.duplicate(true)

	# El mapa completo incluye metabolismo y procesos posteriores a las decisiones;
	# por eso es autoritativo para criaturas cuando está presente. El delta ID-indexado
	# se usa como fallback para eventos que no incluyen el mapa completo.
	var full_creatures_value: Variant = payload.get("trial_creatures", null)
	if typeof(full_creatures_value) == TYPE_DICTIONARY:
		restored_creatures = full_creatures_value.duplicate(true)

	_state["agents"] = restored_agents
	_state["trial_creatures"] = restored_creatures
	for key in ["environment", "ecological_processes", "scheduler", "metrics", "recent_events"]:
		if payload.has(key):
			var value: Variant = payload[key]
			if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
				_state[key] = value.duplicate(true)
	_state["tick"] = int(payload.get("tick", _state.get("tick", 0)))

func _commit_intervention(kind: String, room_id: String, value: float, source: String) -> Dictionary:
	if not _ready:
		return {"ok": false, "message": "Runtime no inicializado."}
	var room_data: Dictionary = _state.get("environment", {}).get("rooms", {})	
	if not room_data.has(room_id):
		return {"ok": false, "message": "La ubicación experimental no existe."}
	var payload := {"kind": kind, "room_id": room_id, "value": value, "source": source, "branch_id": _state.branch_id}
	if _core != null:
		var committed: Dictionary = _core.commit_domain_event("ObserverInterventionCommitted", "system", payload, "SimulationKernel", source, current_tick())
		if not committed.get("accepted", false):
			return {"ok": false, "message": String(committed.get("message", "Intervención rechazada."))}
	_apply_intervention_payload(payload)
	var metrics: Dictionary = _state.get("metrics", {})
	metrics["observer_interventions"] = int(metrics.get("observer_interventions", 0)) + 1
	_state["metrics"] = metrics
	if _core != null:
		_state["last_core_event_sequence"] = _core.last_event_sequence
	return {"ok": true, "message": "Intervención experimental registrada: %s en %s." % [kind, room_id]}

func _apply_intervention_payload(payload: Dictionary) -> void:
	var kind := String(payload.get("kind", ""))
	var room_id := String(payload.get("room_id", ""))
	var value := float(payload.get("value", 0.0))
	var environment: Dictionary = _state.get("environment", {})
	var rooms: Dictionary = environment.get("rooms", {})
	if not rooms.has(room_id):
		return
	var room: Dictionary = rooms[room_id]
	match kind:
		"vibration":
			room["noise"] = maxf(float(room.get("noise", 0.0)), value)
			var stimulus: Array = _state.environment.get("stimuli", [])
			stimulus.append({"type":"vibration", "room_id":room_id, "intensity":value, "tick":current_tick(), "source":"observer_intervention"})
			_state.environment["stimuli"] = stimulus
		"tissue_damage":
			var ecology: Dictionary = _state.get("ecological_processes", {})
			for colony_value in ecology.values():
				var colony: Dictionary = colony_value
				if String(colony.get("location", "")) == room_id:
					colony["tissue_damage"] = clampf(float(colony.get("tissue_damage", 0.0)) + value, 0.0, 1.0)
					colony["last_response"] = "tissue_disturbed_by_observer"
					break
	rooms[room_id] = room
	environment["rooms"] = rooms
	_state["environment"] = environment

func _select_human_batch(source_state: Dictionary, budget: int) -> Array:
	var agents: Dictionary = source_state.get("agents", {})
	var ids: Array = agents.keys()
	ids.sort()
	if ids.is_empty():
		return []
	var selected: Array = []
	var selected_map: Dictionary = {}
	# Urgencias verificables: fatiga elevada y ofertas pendientes recibidas.
	var urgent: Array = []
	for id_value in ids:
		var agent: Dictionary = agents[String(id_value)]
		var priority := 0.0
		priority += maxf(0.0, float(agent.get("fatigue", 0.0)) - 0.62) * 2.0
		priority += 0.45 if not agent.get("pending_offers", []).is_empty() else 0.0
		if priority > 0.20:
			urgent.append({"id":String(id_value), "priority":priority})
	urgent.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a.priority), float(b.priority)):
			return String(a.id) < String(b.id)
		return float(a.priority) > float(b.priority)
	)
	for item in urgent:
		if selected.size() >= mini(8, budget):
			break
		selected.append(String(item.id))
		selected_map[String(item.id)] = true
	var scheduler: Dictionary = source_state.get("scheduler", {})
	var cursor := posmod(int(scheduler.get("cursor", 0)), ids.size())
	for offset in range(ids.size()):
		if selected.size() >= budget:
			break
		var id := String(ids[(cursor + offset) % ids.size()])
		if selected_map.has(id):
			continue
		selected.append(id)
		selected_map[id] = true
	return selected

func _perceive_human(source_state: Dictionary, agent: Dictionary) -> Dictionary:
	var visible_peers: Array = []
	var own_location := String(agent.get("validated_current_location_id", ""))
	var agents: Dictionary = source_state.get("agents", {})
	if not own_location.is_empty():
		for peer_id_value in agents.keys():
			var peer_id := String(peer_id_value)
			if peer_id == String(agent.get("agent_id", "")):
				continue
			var peer: Dictionary = agents[peer_id]
			if String(peer.get("life_state", "active")) != "active":
				continue
			if String(peer.get("validated_current_location_id", "")) != own_location:
				continue
			visible_peers.append({
				"agent_id":peer_id,
				"display_name":String(peer.get("display_name", peer_id)),
				"role":String(peer.get("source_role", "")),
				"role_key":String(peer.get("source_role_key", "")),
				"visibility_basis":"same_validated_physical_location"
			})
	return {
		"observer_id":String(agent.get("agent_id", "")),
		"observer_location":own_location,
		"visible_peers":visible_peers,
		"pending_offers":agent.get("pending_offers", []).duplicate(true),
		"own_motivation":String(agent.get("motivation", "")),
		"own_tension":String(agent.get("current_tension", "")),
		"own_memory_count":agent.get("memory", []).size(),
		"recalled_memories":_recall_memories(agent, int(source_state.get("tick", 0)), 5),
		"knowledge_scope":String(agent.get("knowledge_scope", "")),
		"omniscient_world_access":false,
		"work_area_is_not_presence":true
	}

func _decide_human(agent: Dictionary, perception: Dictionary, tick: int) -> Dictionary:
	var candidates: Array = []
	var motivation := String(agent.get("motivation", ""))
	var tension := String(agent.get("current_tension", ""))
	var routine := String(agent.get("routine_summary", ""))
	var category := String(agent.get("goal_category", "personal_goal"))
	var traits: Array = agent.get("personality_traits", [])
	var fatigue := float(agent.get("fatigue", 0.0))
	var needs: Dictionary = agent.get("needs", {})
	var peers: Array = perception.get("visible_peers", [])
	var pending: Array = perception.get("pending_offers", [])

	if not motivation.is_empty():
		var goal_score := 0.43 + _category_bias(category)
		goal_score += float(needs.get("purpose_pressure", 0.0)) * 0.15
		goal_score += _trait_bias(traits, "goal")
		goal_score += _aptitude_bias(agent, "reasoning", 0.11)
		goal_score += _aptitude_bias(agent, "attention", 0.08)
		goal_score += _experience_bias(agent, "advance_motivation")
		goal_score += _memory_bias(agent, "advance_motivation", tick)
		goal_score -= fatigue * 0.42
		candidates.append(_candidate("advance_motivation", goal_score, "motivación declarada + capacidad cognitiva estimada + experiencia", ["motivation_present"]))
	if not tension.is_empty():
		var tension_score := 0.34 + _trait_bias(traits, "verify") + _trait_bias(traits, "investigate")
		tension_score += float(needs.get("tension_pressure", 0.0)) * 0.14
		tension_score += _aptitude_bias(agent, "reasoning", 0.10)
		tension_score += _aptitude_bias(agent, "attention", 0.08)
		tension_score += _memory_bias(agent, "address_tension", tick)
		tension_score += _experience_bias(agent, "address_tension")
		candidates.append(_candidate("address_tension", tension_score, "tensión declarada; investigar no equivale a resolver", ["tension_present"]))
	if not routine.is_empty():
		var routine_score := 0.35 + _trait_bias(traits, "routine") + _trait_bias(traits, "persistence")
		routine_score += float(needs.get("routine_pressure", 0.0)) * 0.12
		routine_score += _aptitude_bias(agent, "learning", 0.09)
		routine_score += _aptitude_bias(agent, "attention", 0.05)
		routine_score += _experience_bias(agent, "continue_routine")
		routine_score += _memory_bias(agent, "continue_routine", tick)
		routine_score -= fatigue * 0.38
		candidates.append(_candidate("continue_routine", routine_score, "rutina de origen + capacidad de aprendizaje estimada", ["routine_present"]))
	if fatigue >= 0.22:
		var rest_score := 0.12 + fatigue * 0.90 + _trait_bias(traits, "rest")
		rest_score += _aptitude_bias(agent, "physical_endurance", -0.07, true)
		rest_score += _memory_bias(agent, "rest", tick)
		candidates.append(_candidate("rest", rest_score, "fatiga + resistencia funcional estimada + experiencia de descanso", ["fatigue_positive"]))
	if not peers.is_empty():
		var social_score := 0.24 + _trait_bias(traits, "social") + _aptitude_bias(agent, "communication", 0.10) + _experience_bias(agent, "social_contact") + _memory_bias(agent, "social_contact", tick)
		if not pending.is_empty():
			social_score -= 0.15
		candidates.append(_candidate("social_contact", social_score, "pares observados en la misma ubicación física validada", ["peer_visible"]))
	var role_key := String(agent.get("source_role_key", ""))
	if role_key == "teacher" or role_key == "instructor":
		if _has_peer_role(peers, ["student", "apprentice"]):
			var teach_score := 0.40 + _trait_bias(traits, "help") + _aptitude_bias(agent, "communication", 0.08) + _aptitude_bias(agent, "reasoning", 0.05) + _memory_bias(agent, "offer_lesson", tick) + _experience_bias(agent, "offer_lesson")
			candidates.append(_candidate("offer_lesson", teach_score, "estudiante físicamente visible; oferta voluntaria", ["student_visible", "shared_context"]))
	if not pending.is_empty():
		var accept_score := 0.28 + (0.30 if category == "education" else 0.0)
		accept_score += _trait_bias(traits, "study") + _trait_bias(traits, "social")
		accept_score += _aptitude_bias(agent, "learning", 0.10) + _aptitude_bias(agent, "communication", 0.05)
		accept_score += _memory_bias(agent, "accept_lesson", tick)
		accept_score -= _trait_bias(traits, "verify") * 0.55
		candidates.append(_candidate("accept_lesson", accept_score, "oferta recibida; aceptación no automática", ["offer_received"]))
		var decline_score := 0.30 + _trait_bias(traits, "risk") * -0.5 + _memory_bias(agent, "decline_lesson", tick)
		if category != "education":
			decline_score += 0.12
		candidates.append(_candidate("decline_lesson", decline_score, "oferta recibida; decisión individual", ["offer_received"]))
	if candidates.is_empty():
		candidates.append(_candidate("observe", 0.1, "sin acción de mayor utilidad disponible", []))
	var selected := _select_candidate(candidates, String(agent.get("agent_id", "")), tick)
	return {
		"agent_id":String(agent.get("agent_id", "")),
		"action":String(selected.get("action", "observe")),
		"intent":category,
		"reason":String(selected.get("reason", "")),
		"candidate_scores":_candidate_summary(candidates),
		"preconditions":selected.get("preconditions", []).duplicate(true),
		"memory_considered":perception.get("recalled_memories", []).size(),
		"cognitive_profile_status":String(agent.get("cognitive_profile_status", "not_supplied_unknown")),
		"planner":"utility_arbitration_over_valid_actions",
		"tie_break":"stable_seeded_only_for_near_equal_scores"
	}

func _execute_human_action(source_state: Dictionary, agent_id: String, decision: Dictionary, perception: Dictionary, tick: int) -> Dictionary:
	var agents: Dictionary = source_state.get("agents", {})
	var agent: Dictionary = agents.get(agent_id, {})
	var action := String(decision.get("action", "observe"))
	var success := true
	var result_code := "committed"
	var target_id := ""
	match action:
		"advance_motivation":
			if String(agent.get("motivation", "")).is_empty():
				success = false
				result_code = "missing_motivation"
			else:
				var category := String(agent.get("goal_category", "personal_goal"))
				var progress: Dictionary = agent.get("goal_steps", {})
				progress[category] = int(progress.get(category, 0)) + 1
				agent["goal_steps"] = progress
				var motivation_needs: Dictionary = agent.get("needs", {})
				motivation_needs["purpose_pressure"] = maxf(0.0, float(motivation_needs.get("purpose_pressure", 0.0)) - 0.34)
				agent["needs"] = motivation_needs
				agent["fatigue"] = clampf(float(agent.get("fatigue", 0.0)) + 0.045, 0.0, 1.0)
				_remember(agent, tick, "goal_effort", "Dedicó un paso de trabajo a su motivación declarada.", "self_experience", 0.75, 0.35)
		"address_tension":
			if String(agent.get("current_tension", "")).is_empty():
				success = false
				result_code = "no_declared_tension"
			else:
				agent["tension_investigation_steps"] = int(agent.get("tension_investigation_steps", 0)) + 1
				var tension_needs: Dictionary = agent.get("needs", {})
				tension_needs["tension_pressure"] = maxf(0.0, float(tension_needs.get("tension_pressure", 0.0)) - 0.30)
				agent["needs"] = tension_needs
				agent["fatigue"] = clampf(float(agent.get("fatigue", 0.0)) + 0.025, 0.0, 1.0)
				_remember(agent, tick, "tension_investigation", "Dedicó tiempo a examinar una tensión declarada; la tensión sigue sin resolverse.", "self_experience", 0.8, 0.55)
		"continue_routine":
			if String(agent.get("routine_summary", "")).is_empty():
				success = false
				result_code = "no_source_routine"
			else:
				agent["routine_practice_steps"] = int(agent.get("routine_practice_steps", 0)) + 1
				var routine_needs: Dictionary = agent.get("needs", {})
				routine_needs["routine_pressure"] = maxf(0.0, float(routine_needs.get("routine_pressure", 0.0)) - 0.28)
				agent["needs"] = routine_needs
				agent["fatigue"] = clampf(float(agent.get("fatigue", 0.0)) + 0.035, 0.0, 1.0)
				_remember(agent, tick, "routine_practice", "Practicó un paso de la rutina descrita en su registro de origen.", "self_experience", 0.75, 0.25)
		"rest":
			var before := float(agent.get("fatigue", 0.0))
			agent["fatigue"] = maxf(0.0, before - 0.18)
			_remember(agent, tick, "rest", "Descansó y redujo su fatiga operativa.", "self_experience", 0.9, 0.30)
		"social_contact":
			var peers: Array = perception.get("visible_peers", [])
			if peers.is_empty():
				success = false
				result_code = "no_visible_peer"
			else:
				var chosen_peer: Dictionary = _choose_peer(peers, agent_id, tick)
				target_id = String(chosen_peer.get("agent_id", ""))
				if target_id.is_empty() or not agents.has(target_id):
					success = false
					result_code = "peer_unavailable"
				else:
					var target: Dictionary = agents[target_id]
					_remember(agent, tick, "social_encounter", "Tuvo un contacto directo con %s en una ubicación físicamente validada." % target.get("display_name", target_id), "direct_encounter", 0.9, 0.45)
					_remember(target, tick, "social_encounter", "%s inició un contacto directo en una ubicación físicamente validada." % agent.get("display_name", agent_id), "direct_encounter", 0.9, 0.45)
					target["social_contact_count"] = int(target.get("social_contact_count", 0)) + 1
					agents[target_id] = target
					agent["social_contact_count"] = int(agent.get("social_contact_count", 0)) + 1
					var social_metrics: Dictionary = source_state.get("metrics", {})
					social_metrics["social_contacts"] = int(social_metrics.get("social_contacts", 0)) + 1
					source_state["metrics"] = social_metrics
		"offer_lesson":
			var student: Dictionary = _find_peer_by_role(perception.get("visible_peers", []), ["student", "apprentice"], agent_id, tick)
			target_id = String(student.get("agent_id", ""))
			if target_id.is_empty() or not agents.has(target_id):
				success = false
				result_code = "no_student_in_shared_context"
			else:
				var learner: Dictionary = agents[target_id]
				var offers: Array = learner.get("pending_offers", [])
				var offer_id := "lesson_%s_%s_%d" % [agent_id, target_id, tick]
				offers.append({"offer_id":offer_id, "teacher_id":agent_id, "teacher_name":String(agent.get("display_name", agent_id)), "domain":String(agent.get("goal_category", "general")), "created_tick":tick, "status":"pending"})
				learner["pending_offers"] = offers
				_remember(learner, tick, "lesson_offer_received", "Recibió una oferta de enseñanza de %s; aún no la ha aceptado." % agent.get("display_name", agent_id), "direct_message", 0.95, 0.55)
				agents[target_id] = learner
				agent["teaching_practice_steps"] = int(agent.get("teaching_practice_steps", 0)) + 1
				_remember(agent, tick, "lesson_offer_sent", "Ofreció enseñar a %s; la respuesta está pendiente." % learner.get("display_name", target_id), "self_experience", 0.95, 0.45)
				var offer_metrics: Dictionary = source_state.get("metrics", {})
				offer_metrics["lesson_offers"] = int(offer_metrics.get("lesson_offers", 0)) + 1
				source_state["metrics"] = offer_metrics
		"accept_lesson":
			var offers_to_accept: Array = agent.get("pending_offers", [])
			if offers_to_accept.is_empty():
				success = false
				result_code = "no_lesson_offer"
			else:
				var offer: Dictionary = offers_to_accept.pop_front()
				agent["pending_offers"] = offers_to_accept
				var domain := String(offer.get("domain", "general"))
				var practice: Dictionary = agent.get("learning_practice", {})
				practice[domain] = int(practice.get(domain, 0)) + 1
				agent["learning_practice"] = practice
				target_id = String(offer.get("teacher_id", ""))
				_remember(agent, tick, "lesson_accepted", "Aceptó una oferta de enseñanza de %s; obtuvo una práctica, no maestría automática." % offer.get("teacher_name", target_id), "direct_encounter", 0.95, 0.65)
				if agents.has(target_id):
					var accepting_teacher: Dictionary = agents[target_id]
					_remember(accepting_teacher, tick, "lesson_accepted_by_peer", "%s aceptó una oferta de enseñanza." % agent.get("display_name", agent_id), "direct_feedback", 0.95, 0.65)
					agents[target_id] = accepting_teacher
				var accept_metrics: Dictionary = source_state.get("metrics", {})
				accept_metrics["lessons_accepted"] = int(accept_metrics.get("lessons_accepted", 0)) + 1
				source_state["metrics"] = accept_metrics
		"decline_lesson":
			var offers_to_decline: Array = agent.get("pending_offers", [])
			if offers_to_decline.is_empty():
				success = false
				result_code = "no_lesson_offer"
			else:
				var declined: Dictionary = offers_to_decline.pop_front()
				agent["pending_offers"] = offers_to_decline
				_remember(agent, tick, "lesson_declined", "Rechazó una oferta de enseñanza de %s." % declined.get("teacher_name", "otra persona"), "own_decision", 1.0, 0.4)
				target_id = String(declined.get("teacher_id", ""))
				if agents.has(target_id):
					var declining_teacher: Dictionary = agents[target_id]
					_remember(declining_teacher, tick, "lesson_declined_by_peer", "%s rechazó la oferta; no se infiere el motivo." % agent.get("display_name", agent_id), "direct_feedback", 0.95, 0.45)
					agents[target_id] = declining_teacher
				var decline_metrics: Dictionary = source_state.get("metrics", {})
				decline_metrics["lessons_declined"] = int(decline_metrics.get("lessons_declined", 0)) + 1
				source_state["metrics"] = decline_metrics
		"observe":
			_remember(agent, tick, "observation", "No encontró una acción de mayor utilidad; mantuvo observación local.", "direct_observation", 0.6, 0.15)
			var idle_metrics: Dictionary = source_state.get("metrics", {})
			idle_metrics["idle_decisions"] = int(idle_metrics.get("idle_decisions", 0)) + 1
			source_state["metrics"] = idle_metrics
		_:
			success = false
			result_code = "unsupported_action"

	var experience: Dictionary = agent.get("experience", {})
	var record: Dictionary = experience.get(action, {"attempts":0, "successes":0, "failures":0})
	record["attempts"] = int(record.get("attempts", 0)) + 1
	if success:
		record["successes"] = int(record.get("successes", 0)) + 1
	else:
		record["failures"] = int(record.get("failures", 0)) + 1
	record["estimated_success_rate"] = float(record.successes) / maxf(1.0, float(record.attempts))
	experience[action] = record
	agent["experience"] = experience
	_remember(agent, tick, "action_outcome", "Acción %s: %s (%s)." % [action, "éxito" if success else "fallo", result_code], "self_experience", 0.90 if success else 0.82, 0.42 if success else 0.58, {"action":action, "success":success, "result":result_code})
	agents[agent_id] = agent
	source_state["agents"] = agents
	if not success:
		var metrics: Dictionary = source_state.get("metrics", {})
		metrics["rejected_actions"] = int(metrics.get("rejected_actions", 0)) + 1
		source_state["metrics"] = metrics
	return {"success":success, "result":result_code, "target_id":target_id, "consequence":_human_consequence_text(action, success)}

func _perceive_creature(source_state: Dictionary, creature: Dictionary) -> Dictionary:
	var room_id := String(creature.get("location", ""))
	var rooms: Dictionary = source_state.get("environment", {}).get("rooms", {})
	var room: Dictionary = rooms.get(room_id, {})
	var visible: Array = []
	var threats: Array = []
	var prey: Array = []
	var creatures: Dictionary = source_state.get("trial_creatures", {})
	var ordered_creature_ids: Array = creatures.keys()
	ordered_creature_ids.sort()
	for other_id_value in ordered_creature_ids:
		var other_id := String(other_id_value)
		if other_id == String(creature.get("entity_id", "")):
			continue
		var other: Dictionary = creatures[other_id]
		var other_room := String(other.get("location", ""))
		var distance := _room_distance(rooms, room_id, other_room, 2)
		if distance < 0 or distance > 1:
			continue
		var other_species := String(other.get("species_id", ""))
		var observation := {
			"entity_id":other_id,
			"species_id":other_species,
			"distance_steps":distance,
			"same_room":distance == 0,
			"target_room":other_room
		}
		# No se filtra información del mundo por proximidad solamente: el sujeto
		# debe disponer de un canal sensorial capaz de detectar al otro individuo.
		if not _can_detect_species(creature, other_species, room, other):
			continue
		visible.append(observation)
		if _is_predatory(other_species):
			threats.append(observation)
		if _is_prey_for(other_species, String(creature.get("species_id", ""))):
			prey.append(observation)
	return {
		"observer_id":String(creature.get("entity_id", "")),
		"location":room_id,
		"local_environment":_sensor_environment_view(creature, room),
		"visible_entities":visible,
		"threats":threats,
		"prey":prey,
		"omniscient_world_access":false
	}

func _can_detect_species(observer: Dictionary, other_species: String, local_room: Dictionary, other: Dictionary) -> bool:
	var channels: Array = observer.get("sensory_channels", [])
	# _perceive_creature ya limitó la observación a la misma cámara o una conexión.
	# Aquí solo se aplica la modalidad y el ruido, sin consultar el estado omnisciente.
	if channels.has("vibration"):
		return true
	if channels.has("echolocation"):
		return float(local_room.get("noise", 0.0)) < 0.75
	if channels.has("movement"):
		return true
	return channels.has("chemical") and String(observer.get("location", "")) == String(other.get("location", ""))

func _sensor_environment_view(creature: Dictionary, room: Dictionary) -> Dictionary:
	var view: Dictionary = {}
	var channels: Array = creature.get("sensory_channels", [])
	if channels.has("humidity"):
		view["humidity"] = float(room.get("humidity", 0.0))
	if channels.has("vibration") or channels.has("sound"):
		view["noise"] = float(room.get("noise", 0.0))
	if channels.has("chemical"):
		view["fungal_food"] = float(room.get("fungal_food", 0.0))
		view["detritus"] = float(room.get("detritus", 0.0))
	if channels.has("echolocation"):
		view["insects"] = float(room.get("insects", 0.0))
		view["airflow"] = float(room.get("airflow", 0.0))
	return view

func _decide_creature(source_state: Dictionary, creature: Dictionary, perception: Dictionary, tick: int) -> Dictionary:
	var species_id := String(creature.get("species_id", ""))
	var style := String(creature.get("behavior_style", ""))
	var hunger := float(creature.get("hunger", 0.0))
	var room_id := String(creature.get("location", ""))
	var local: Dictionary = perception.get("local_environment", {})
	var candidates: Array = []
	var threats: Array = perception.get("threats", [])
	var prey: Array = perception.get("prey", [])
	var rooms: Dictionary = source_state.get("environment", {}).get("rooms", {})
	var neighbors: Array = rooms.get(room_id, {}).get("neighbors", [])
	match species_id:
		"MON-F1-001":
			var strong_vibration := float(local.get("noise", 0.0)) >= 0.55
			if not threats.is_empty() or strong_vibration:
				var refuge := _best_refuge(neighbors, rooms, true)
				var alarm_reason := "depredador detectado" if not threats.is_empty() else "vibración intensa detectada"
				if not refuge.is_empty():
					candidates.append(_candidate("flee_to_narrow_refuge", 1.15 + _experience_bias(creature, "flee_to_narrow_refuge") + _memory_bias(creature, "flee_to_narrow_refuge", tick), alarm_reason + "; refugio estrecho alcanzable", ["threat_or_vibration_detected", "narrow_refuge_reachable"]))
				else:
					candidates.append(_candidate("hide_or_retreat", 0.88, alarm_reason + "; buscar cobertura", ["threat_or_vibration_detected"]))
			if hunger > 0.32 and float(local.get("fungal_food", 0.0)) > 0.1:
				candidates.append(_candidate("forage_fungi", 0.45 + hunger * 0.35, "alimento detectado químicamente en el entorno local", ["food_detected", "not_in_deep_water"]))
			if threats.is_empty() and candidates.is_empty():
				candidates.append(_candidate("explore_safe_edge", 0.32, "forrajeo local insuficiente; buscar entorno próximo", ["adjacent_route_available"]))
		"MON-F1-002":
			if not threats.is_empty():
				candidates.append(_candidate("retract_elytra", 0.96, "vibración cercana; repliegue defensivo", ["threat_detected"]))
				if bool(creature.get("hidden_state", {}).get("defensive_retraction", false)) and float(local.get("noise", 0.0)) > 0.55:
					candidates.append(_candidate("short_defensive_bump", 0.58, "refugio comprometido; respuesta corta", ["threat_close", "escape_blocked"]))
			if hunger > 0.25 and float(local.get("detritus", 0.0)) > 0.1:
				candidates.append(_candidate("consume_detritus", 0.50 + hunger * 0.25 + _experience_bias(creature, "consume_detritus") + _memory_bias(creature, "consume_detritus", tick), "detritus detectado; alimentación sin persecución", ["detritus_available"]))
			if candidates.is_empty():
				candidates.append(_candidate("remain_sheltered", 0.25, "sin recurso o amenaza que justifique desplazamiento", []))
		"MON-F1-004":
			if float(local.get("noise", 0.0)) > 0.45:
				candidates.append(_candidate("evasive_flight", 1.0, "ruido/eco perturbado; ganar altura", ["disturbance_detected", "flight_route_available"]))
			if hunger > 0.28 and float(local.get("insects", 0.0)) > 0.1:
				candidates.append(_candidate("forage_insects", 0.55 + hunger * 0.30 + _experience_bias(creature, "forage_insects") + _memory_bias(creature, "forage_insects", tick), "insectos detectados por ecolocalización", ["insects_detected"]))
			if candidates.is_empty():
				candidates.append(_candidate("roost_and_rest", 0.35 + float(creature.get("fatigue", 0.0)) * 0.5, "sin estímulo o alimento adecuado; descansar en altura", ["roost_available"]))
		"MON-F1-005":
			if not prey.is_empty():
				var target: Dictionary = prey[0]
				if bool(rooms.get(String(target.target_room), {}).get("narrow", false)):
					candidates.append(_candidate("abandon_narrow_pursuit", 0.98 + _experience_bias(creature, "abandon_narrow_pursuit") + _memory_bias(creature, "abandon_narrow_pursuit", tick), "la presa alcanzó una grieta demasiado estrecha", ["prey_in_inaccessible_narrow_space"]))
				elif int(target.distance_steps) == 0:
					candidates.append(_candidate("prepare_ambush", 0.95, "presa detectada dentro de alcance espacial de prueba", ["prey_localized", "ambush_position_available"]))
				else:
					candidates.append(_candidate("stalk_prey", 0.86 + _experience_bias(creature, "stalk_prey") + _memory_bias(creature, "stalk_prey", tick), "presa detectada por vibración/olor; aproximación cautelosa", ["prey_detected", "route_available"]))
			if threats.size() > 0:
				candidates.append(_candidate("withdraw_from_stronger_threat", 0.72, "amenaza no rentable o superior detectada", ["threat_detected"]))
			if candidates.is_empty():
				candidates.append(_candidate("hold_ambush", 0.35, "esperar inmóvil junto a cobertura", ["cover_available"]))
		_:
			candidates.append(_candidate("hold", 0.0, "sin perfil de decisión implementado", []))
	var selected := _select_candidate(candidates, String(creature.get("entity_id", "")), tick)
	return {
		"agent_id":String(creature.get("entity_id", "")),
		"action":String(selected.get("action", "hold")),
		"intent":style,
		"reason":String(selected.get("reason", "")),
		"candidate_scores":_candidate_summary(candidates),
		"preconditions":selected.get("preconditions", []).duplicate(true),
		"planner":"species_specific_conditioned_utility",
		"tie_break":"stable_seeded_only_for_near_equal_scores"
	}

func _execute_creature_action(source_state: Dictionary, creature_id: String, decision: Dictionary, perception: Dictionary, tick: int) -> Dictionary:
	var creatures: Dictionary = source_state.get("trial_creatures", {})
	var creature: Dictionary = creatures.get(creature_id, {})
	var action := String(decision.get("action", "hold"))
	var success := true
	var code := "committed"
	var target_id := ""
	var movement := false
	var rooms: Dictionary = source_state.get("environment", {}).get("rooms", {})
	var current_room := String(creature.get("location", ""))
	var local: Dictionary = rooms.get(current_room, {})
	match action:
		"flee_to_narrow_refuge":
			var refuge := _best_refuge(local.get("neighbors", []), rooms, true)
			if refuge.is_empty():
				success = false
				code = "no_valid_narrow_refuge"
			else:
				creature["location"] = refuge
				creature.hidden_state["hidden"] = true
				creature["fatigue"] = clampf(float(creature.get("fatigue", 0.0)) + 0.08, 0.0, 1.0)
				movement = true
		"hide_or_retreat":
			var retreat := _best_refuge(local.get("neighbors", []), rooms, false)
			if retreat.is_empty():
				creature.hidden_state["hidden"] = true
			else:
				creature["location"] = retreat
				movement = true
		"forage_fungi":
			var food := float(local.get("fungal_food", 0.0))
			if food <= 0.1 or float(local.get("water", 0.0)) > 1.5:
				success = false
				code = "food_unavailable_or_water_too_deep"
			else:
				local["fungal_food"] = maxf(0.0, food - 0.45)
				creature["hunger"] = maxf(0.0, float(creature.get("hunger", 0.0)) - 0.24)
				source_state.environment.rooms[current_room] = local
				source_state.metrics["resources_consumed"] = int(source_state.metrics.get("resources_consumed", 0)) + 1
		"explore_safe_edge":
			var food_target_room := _best_food_room(local.get("neighbors", []), rooms, "fungal_food")
			if food_target_room.is_empty():
				success = false
				code = "no_usable_food_signal"
			else:
				creature["location"] = food_target_room
				movement = true
		"retract_elytra":
			creature.hidden_state["defensive_retraction"] = true
			creature["fatigue"] = clampf(float(creature.get("fatigue", 0.0)) + 0.01, 0.0, 1.0)
		"short_defensive_bump":
			# No daño: el dominio SR-09 todavía no está implementado. Se registra postura.
			creature.hidden_state["defensive_retraction"] = false
			creature.hidden_state["last_defensive_response"] = "short_bump_attempt_no_damage_resolution"
		"consume_detritus":
			var detritus := float(local.get("detritus", 0.0))
			if detritus <= 0.1:
				success = false
				code = "detritus_depleted"
			else:
				local["detritus"] = maxf(0.0, detritus - 0.35)
				creature["hunger"] = maxf(0.0, float(creature.get("hunger", 0.0)) - 0.22)
				source_state.environment.rooms[current_room] = local
				source_state.metrics["resources_consumed"] = int(source_state.metrics.get("resources_consumed", 0)) + 1
		"evasive_flight":
			var high_room := _nearest_room_with_property(rooms, current_room, "high_roof", true)
			if high_room.is_empty():
				success = false
				code = "no_high_roof_route"
			else:
				creature["location"] = high_room
				creature.hidden_state["hidden"] = false
				movement = high_room != current_room
		"forage_insects":
			var insects := float(local.get("insects", 0.0))
			if insects <= 0.1:
				success = false
				code = "insects_not_available"
			else:
				local["insects"] = maxf(0.0, insects - 0.55)
				creature["hunger"] = maxf(0.0, float(creature.get("hunger", 0.0)) - 0.26)
				source_state.environment.rooms[current_room] = local
				source_state.metrics["resources_consumed"] = int(source_state.metrics.get("resources_consumed", 0)) + 1
		"roost_and_rest":
			creature["fatigue"] = maxf(0.0, float(creature.get("fatigue", 0.0)) - 0.16)
		"abandon_narrow_pursuit":
			creature.hidden_state["ambush_ready"] = false
			creature.hidden_state["last_target_id"] = ""
			_remember(creature, tick, "failed_pursuit", "Abandonó la persecución porque la presa entró en una grieta inaccesible para su anatomía.", "sensory_inference", 0.9, 0.7)
		"prepare_ambush":
			var prey: Array = perception.get("prey", [])
			if prey.is_empty():
				success = false
				code = "prey_not_visible"
			else:
				target_id = String(prey[0].get("entity_id", ""))
				creature.hidden_state["ambush_ready"] = true
				creature.hidden_state["last_target_id"] = target_id
				_remember(creature, tick, "prey_localized", "Localizó una presa mediante los sentidos disponibles y adoptó una posición de emboscada.", "sensory_inference", 0.8, 0.65)
		"stalk_prey":
			var prey_list: Array = perception.get("prey", [])
			if prey_list.is_empty():
				success = false
				code = "prey_lost"
			else:
				var prey_observation: Dictionary = prey_list[0]
				target_id = String(prey_observation.get("entity_id", ""))
				var prey_target_room := String(prey_observation.get("target_room", ""))
				var next_room := _next_step_toward(rooms, current_room, prey_target_room, false)
				if next_room.is_empty():
					success = false
					code = "no_feasible_stalking_route"
				else:
					creature["location"] = next_room
					creature.hidden_state["ambush_ready"] = false
					movement = true
		"withdraw_from_stronger_threat":
			var retreat_room := _best_refuge(local.get("neighbors", []), rooms, false)
			if not retreat_room.is_empty():
				creature["location"] = retreat_room
				movement = true
			else:
				creature.hidden_state["ambush_ready"] = false
		"hold_ambush":
			creature.hidden_state["ambush_ready"] = true
		"remain_sheltered", "hold":
			pass
		_:
			success = false
			code = "unsupported_species_action"
	if movement:
		source_state.metrics["movement_steps"] = int(source_state.metrics.get("movement_steps", 0)) + 1
		creature["fatigue"] = clampf(float(creature.get("fatigue", 0.0)) + 0.035, 0.0, 1.0)
	var experience: Dictionary = creature.get("experience", {})
	var record: Dictionary = experience.get(action, {"attempts":0, "successes":0, "failures":0})
	record["attempts"] = int(record.get("attempts", 0)) + 1
	if success:
		record["successes"] = int(record.get("successes", 0)) + 1
	else:
		record["failures"] = int(record.get("failures", 0)) + 1
	record["estimated_success_rate"] = float(record.successes) / maxf(1.0, float(record.attempts))
	experience[action] = record
	creature["experience"] = experience
	_remember(creature, tick, "action_outcome", "Conducta %s: %s (%s)." % [action, "éxito" if success else "fallo", code], "self_experience", 0.90 if success else 0.82, 0.42 if success else 0.58, {"action":action, "success":success, "result":code})
	creatures[creature_id] = creature
	source_state["trial_creatures"] = creatures
	if not success:
		source_state.metrics["rejected_actions"] = int(source_state.metrics.get("rejected_actions", 0)) + 1
	return {"success":success, "result":code, "target_id":target_id, "consequence":_creature_consequence_text(action, success), "movement":movement}

func _process_environmental_organisms(source_state: Dictionary, tick: int, decisions: Array) -> void:
	var ecology: Dictionary = source_state.get("ecological_processes", {})
	var rooms: Dictionary = source_state.get("environment", {}).get("rooms", {})
	for colony_id_value in ecology.keys():
		var colony_id := String(colony_id_value)
		var colony: Dictionary = ecology[colony_id]
		var room_id := String(colony.get("location", ""))
		var room: Dictionary = rooms.get(room_id, {})
		var damage := float(colony.get("tissue_damage", 0.0))
		var humidity := float(room.get("humidity", 0.0))
		var maturity := float(colony.get("maturity_parameter", 0.0))
		if damage >= 0.35 and humidity >= 0.45 and maturity >= 0.50 and float(colony.get("spore_reserve", 0.0)) > 0.05:
			colony["spore_cloud"] = minf(1.0, float(colony.get("spore_cloud", 0.0)) + 0.45)
			colony["spore_reserve"] = maxf(0.0, float(colony.get("spore_reserve", 0.0)) - 0.25)
			colony["tissue_damage"] = maxf(0.0, damage - 0.08)
			colony["last_response"] = "spore_release_from_damage_humidity_and_maturity"
			var metrics: Dictionary = source_state.get("metrics", {})
			metrics["spore_releases"] = int(metrics.get("spore_releases", 0)) + 1
			source_state["metrics"] = metrics
			var process_event := {
				"tick":tick, "agent_id":colony_id, "entity_kind":"environmental_biology",
				"action":"physiological_spore_release", "result":"released",
				"cause":"local_tissue_damage + humidity + maturity", "cognitive_decision":false
			}
			decisions.append(process_event)
			_append_recent_event(source_state, process_event)
		ecology[colony_id] = colony
	source_state["ecological_processes"] = ecology


func _advance_agent_pressures(source_state: Dictionary, scheduled_ids: Array) -> void:
	## Presión de objetivos abstracta al llegar el turno cognitivo del individuo;
	## no representa dinero, hambre, necesidad biológica ni un estado canónico SR.
	var agents: Dictionary = source_state.get("agents", {})
	for agent_id_value in scheduled_ids:
		var agent_id := String(agent_id_value)
		if not agents.has(agent_id):
			continue
		var agent: Dictionary = agents[agent_id]
		var needs: Dictionary = agent.get("needs", {})
		if not String(agent.get("motivation", "")).is_empty():
			needs["purpose_pressure"] = minf(1.0, float(needs.get("purpose_pressure", 0.0)) + 0.012)
		if not String(agent.get("current_tension", "")).is_empty():
			needs["tension_pressure"] = minf(1.0, float(needs.get("tension_pressure", 0.0)) + 0.009)
		if not String(agent.get("routine_summary", "")).is_empty():
			needs["routine_pressure"] = minf(1.0, float(needs.get("routine_pressure", 0.0)) + 0.008)
		agent["needs"] = needs
		agents[agent_id] = agent
	source_state["agents"] = agents

func _advance_creature_metabolism(source_state: Dictionary) -> void:
	## Tasas de laboratorio explícitas; no se convierten en fisiología canónica.
	var creatures: Dictionary = source_state.get("trial_creatures", {})
	for creature_id_value in creatures.keys():
		var creature_id := String(creature_id_value)
		var creature: Dictionary = creatures[creature_id]
		creature["hunger"] = clampf(float(creature.get("hunger", 0.0)) + 0.012, 0.0, 1.0)
		creature["fatigue"] = maxf(0.0, float(creature.get("fatigue", 0.0)) - 0.018)
		creatures[creature_id] = creature
	source_state["trial_creatures"] = creatures
	var rooms: Dictionary = source_state.get("environment", {}).get("rooms", {})
	for room_id_value in rooms.keys():
		var room_id := String(room_id_value)
		var room: Dictionary = rooms[room_id]
		var fungal_capacity := float(room.get("fungal_food_capacity", maxf(1.0, float(room.get("fungal_food", 0.0)))))
		var detritus_capacity := float(room.get("detritus_capacity", maxf(1.0, float(room.get("detritus", 0.0)))))
		var insect_capacity := float(room.get("insect_capacity", maxf(1.0, float(room.get("insects", 0.0)))))
		room["fungal_food"] = minf(float(room.get("fungal_food", 0.0)) + 0.006, fungal_capacity)
		room["detritus"] = minf(float(room.get("detritus", 0.0)) + 0.003, detritus_capacity)
		room["insects"] = minf(float(room.get("insects", 0.0)) + 0.004, insect_capacity)
		rooms[room_id] = room
	source_state.environment["rooms"] = rooms

func _decay_environment(source_state: Dictionary) -> void:
	var rooms: Dictionary = source_state.get("environment", {}).get("rooms", {})
	for room_id_value in rooms.keys():
		var room_id := String(room_id_value)
		var room: Dictionary = rooms[room_id]
		room["noise"] = maxf(0.0, float(room.get("noise", 0.0)) - 0.22)
		rooms[room_id] = room
	var stimuli: Array = source_state.environment.get("stimuli", [])
	var retained: Array = []
	for stimulus in stimuli:
		if int(stimulus.get("tick", 0)) >= int(source_state.get("tick", 0)) - 4:
			retained.append(stimulus)
	source_state.environment["rooms"] = rooms
	source_state.environment["stimuli"] = retained

func _make_trace(agent_id: String, agent: Dictionary, perception: Dictionary, decision: Dictionary, result: Dictionary, tick: int) -> Dictionary:
	return {
		"tick":tick,
		"agent_id":agent_id,
		"display_name":String(agent.get("display_name", agent.get("species_name", agent_id))),
		"entity_kind":String(agent.get("agent_kind", agent.get("entity_kind", "creature"))),
		"location":String(agent.get("location", "")),
		"perceived_count":perception.get("visible_peers", perception.get("visible_entities", [])).size(),
		"action":String(decision.get("action", "")),
		"intent":String(decision.get("intent", "")),
		"reason":String(decision.get("reason", "")),
		"candidate_scores":decision.get("candidate_scores", []).duplicate(true),
		"result":String(result.get("result", "")),
		"success":bool(result.get("success", false)),
		"target_id":String(result.get("target_id", "")),
		"consequence":String(result.get("consequence", "")),
		"planner":String(decision.get("planner", ""))
	}

func _append_recent_event(source_state: Dictionary, event: Dictionary) -> void:
	var recent: Array = source_state.get("recent_events", [])
	recent.append(event.duplicate(true))
	while recent.size() > MAX_RECENT_EVENTS:
		recent.pop_front()
	source_state["recent_events"] = recent

func _remember(agent: Dictionary, tick: int, memory_type: String, content: String, source: String, confidence: float, importance: float, metadata: Dictionary = {}) -> void:
	_memory_writes_this_step += 1
	var memories: Array = agent.get("memory", [])
	var entry := {
		"memory_id":"mem_%s_%d_%s" % [String(agent.get("agent_id", agent.get("entity_id", "entity"))), tick, memory_type],
		"tick":tick,
		"type":memory_type,
		"content":content,
		"source":source,
		"confidence":confidence,
		"importance":importance,
		"epistemic_status":"individual_memory_not_world_truth"
	}
	entry.merge(metadata, true)
	memories.append(entry)
	while memories.size() > MAX_MEMORY_ITEMS:
		var remove_index := 0
		var lowest := INF
		for i in range(memories.size()):
			var memory: Dictionary = memories[i]
			var retention := float(memory.get("importance", 0.0)) + float(memory.get("confidence", 0.0)) * 0.15 + float(memory.get("tick", 0)) * 0.0001
			if retention < lowest:
				lowest = retention
				remove_index = i
		memories.remove_at(remove_index)
	agent["memory"] = memories

func _aptitude_bias(agent: Dictionary, key: String, maximum_effect: float, physical: bool = false) -> float:
	var aptitudes: Dictionary = agent.get("cognitive_profile", {}) if not physical else agent.get("physical_profile", {})
	if not aptitudes.has(key):
		return 0.0
	var estimated_score := clampf(float(aptitudes.get(key, 50.0)), 0.0, 100.0)
	return clampf((estimated_score - 50.0) / 50.0 * maximum_effect, -absf(maximum_effect), absf(maximum_effect))

func _recall_memories(agent: Dictionary, tick: int, limit: int = 5) -> Array:
	var memories: Array = agent.get("memory", [])
	if memories.is_empty() or limit <= 0:
		return []
	var cognitive: Dictionary = agent.get("cognitive_profile", {})
	var has_memory_aptitude := cognitive.has("memory")
	var memory_capacity := clampf(float(cognitive.get("memory", 0.0)), 0.0, 100.0) / 100.0 if has_memory_aptitude else 0.0
	var ranked: Array = []
	for memory_value in memories:
		if typeof(memory_value) != TYPE_DICTIONARY:
			continue
		var source_memory: Dictionary = memory_value
		var age := maxi(0, tick - int(source_memory.get("tick", tick)))
		var base_retention := float(source_memory.get("importance", 0.0)) * 0.65 + float(source_memory.get("confidence", 0.0)) * 0.35
		var capacity_modifier := 1.0
		if has_memory_aptitude:
			capacity_modifier = 0.85 + memory_capacity * 0.30
		var decay_horizon := 34.0
		if has_memory_aptitude:
			decay_horizon = 18.0 + memory_capacity * 42.0
		var retention := base_retention * capacity_modifier * exp(-float(age) / decay_horizon)
		if retention >= 0.08:
			ranked.append({"memory":source_memory, "retention":retention})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.retention) > float(b.retention))
	var recalled: Array = []
	for item in ranked.slice(0, mini(limit, ranked.size())):
		var recalled_memory: Dictionary = item.memory
		recalled.append({"tick":int(recalled_memory.get("tick", 0)), "type":String(recalled_memory.get("type", "")), "content":String(recalled_memory.get("content", "")), "source":String(recalled_memory.get("source", "")), "confidence":float(recalled_memory.get("confidence", 0.0)), "retention":snappedf(float(item.retention), 0.001), "epistemic_status":String(recalled_memory.get("epistemic_status", "individual_memory_not_world_truth"))})
	return recalled

func _memory_bias(agent: Dictionary, action: String, tick: int) -> float:
	## Los resultados recordados inclinan decisiones futuras; no fuerzan una repetición.
	var cognitive: Dictionary = agent.get("cognitive_profile", {})
	var has_memory_aptitude := cognitive.has("memory")
	var memory_capacity := clampf(float(cognitive.get("memory", 0.0)), 0.0, 100.0) / 100.0 if has_memory_aptitude else 0.0
	var memory_modifier := 1.0
	if has_memory_aptitude:
		memory_modifier = 0.75 + memory_capacity * 0.50
	var memories: Array = agent.get("memory", [])
	var bias := 0.0
	var considered := 0
	for index in range(memories.size() - 1, -1, -1):
		var memory: Dictionary = memories[index]
		if String(memory.get("type", "")) != "action_outcome" or String(memory.get("action", "")) != action:
			continue
		var age := maxi(0, tick - int(memory.get("tick", tick)))
		var decay_horizon := 30.0
		if has_memory_aptitude:
			decay_horizon = 18.0 + memory_capacity * 30.0
		var recall := memory_modifier * exp(-float(age) / decay_horizon)
		var reliability := clampf(float(memory.get("confidence", 0.5)), 0.0, 1.0)
		var importance := clampf(float(memory.get("importance", 0.3)), 0.0, 1.0)
		var effect := 0.055 * recall * reliability * (0.55 + importance * 0.45)
		bias += effect if bool(memory.get("success", false)) else -effect * 1.65
		considered += 1
		if considered >= 3:
			break
	return clampf(bias, -0.16, 0.10)

func _candidate(action: String, score: float, reason: String, preconditions: Array) -> Dictionary:
	return {"action":action, "score":score, "reason":reason, "preconditions":preconditions}

func _select_candidate(candidates: Array, agent_id: String, tick: int) -> Dictionary:
	var ranked := candidates.duplicate(true)
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if absf(score_a - score_b) <= 0.015:
			return _stable_unit("%d|%s|%s|%d" % [int(_state.get("seed", 0)), agent_id, a.get("action", ""), tick]) > _stable_unit("%d|%s|%s|%d" % [int(_state.get("seed", 0)), agent_id, b.get("action", ""), tick])
		return score_a > score_b
	)
	return ranked[0] if not ranked.is_empty() else {}

func _candidate_summary(candidates: Array) -> Array:
	var copy := candidates.duplicate(true)
	copy.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	var result: Array = []
	for item in copy.slice(0, mini(4, copy.size())):
		result.append({"action":String(item.get("action", "")), "score":snappedf(float(item.get("score", 0.0)), 0.001), "reason":String(item.get("reason", ""))})
	return result

func _category_bias(category: String) -> float:
	match category:
		"education": return 0.12
		"expedition": return 0.08
		"care": return 0.10
		"livelihood": return 0.10
		"research": return 0.09
		"craft": return 0.08
		"administration": return 0.07
		_: return 0.0

func _trait_bias(traits: Array, key: String) -> float:
	var value := 0.0
	for trait_value in traits:
		var trait_name := String(trait_value).to_lower()
		var bias: Dictionary = TRAIT_BIASES.get(trait_name, {})
		value += float(bias.get(key, 0.0))
	return clampf(value, -0.30, 0.30)

func _experience_bias(agent: Dictionary, action: String) -> float:
	var experience: Dictionary = agent.get("experience", {})
	if not experience.has(action):
		return 0.0
	var record: Dictionary = experience[action]
	var attempts := int(record.get("attempts", 0))
	if attempts < 1:
		return 0.0
	var success_rate := float(record.get("estimated_success_rate", 0.5))
	return clampf((success_rate - 0.5) * 0.20, -0.10, 0.10)

func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _array_or_empty(value: Variant) -> Array:
	return value if typeof(value) == TYPE_ARRAY else []

func _source_text(value: Variant) -> String:
	return String(value) if typeof(value) == TYPE_STRING else ""

func _goal_category(motivation: String, role_key: String, routine: String, source_role: String = "") -> String:
	var value := (motivation + " " + role_key + " " + routine + " " + source_role).to_lower()
	if _contains_any(value, ["aprender", "estudi", "maestro", "enseñ", "ensen", "leccion", "lección", "formación", "formacion", "instructor", "student", "teacher"]):
		return "education"
	if _contains_any(value, ["expedición", "expedicion", "explor", "mazmorra", "reputación", "reputacion", "aventur", "rastrear"]):
		return "expedition"
	if _contains_any(value, ["ayudar", "cuidar", "hogar", "rescate", "familia", "apoyo", "protege"]):
		return "care"
	if _contains_any(value, ["mantener", "solvente", "negocio", "empleo", "comerc", "inventario", "cliente", "recursos", "salario", "abastec", "suministro", "responsable de suministros", "tesorer", "gestor de tienda"]):
		return "livelihood"
	if _contains_any(value, ["investig", "conocer", "observar", "document", "reclamación", "reclamacion", "archivo", "escritura"]):
		return "research"
	if _contains_any(value, ["fabric", "herr", "constru", "técnica", "tecnica", "artesano", "repar"]):
		return "craft"
	if _contains_any(value, ["mensaj", "registr", "contrato", "gestión", "gestion", "administr", "gremio", "evaluador", "archivista", "archivo", "reclamacion", "reclamación", "document"]):
		return "administration"
	match role_key:
		"student", "teacher", "instructor", "apprentice": return "education"
		"merchant", "inn_worker", "cook": return "livelihood"
		"builder", "smith", "craftsman": return "craft"
		"scribe": return "research"
	return "personal_goal"

func _contains_any(value: String, needles: Array) -> bool:
	for needle_value in needles:
		if value.contains(String(needle_value)):
			return true
	return false

func _extract_work_contexts(raw: String) -> Array:
	var result: Array = []
	for part in raw.split("/", false):
		var context := String(part).strip_edges().to_lower()
		if not context.is_empty() and not result.has(context):
			result.append(context)
	return result

func _contexts_overlap(a: Array, b: Array) -> bool:
	for item in a:
		if b.has(item):
			return true
	return false

func _has_peer_role(peers: Array, roles: Array) -> bool:
	for peer_value in peers:
		var peer: Dictionary = peer_value
		if roles.has(String(peer.get("role_key", ""))):
			return true
	return false

func _find_peer_by_role(peers: Array, roles: Array, agent_id: String, tick: int) -> Dictionary:
	var matches: Array = []
	for peer_value in peers:
		var peer: Dictionary = peer_value
		if roles.has(String(peer.get("role_key", ""))):
			matches.append(peer)
	if matches.is_empty():
		return {}
	return _choose_peer(matches, agent_id, tick)

func _choose_peer(peers: Array, agent_id: String, tick: int) -> Dictionary:
	var sorted := peers.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("agent_id", "")) < String(b.get("agent_id", "")))
	var index := int(_stable_unit("%d|%s|%d" % [int(_state.get("seed", 0)), agent_id, tick]) * sorted.size())
	return sorted[clampi(index, 0, sorted.size() - 1)] if not sorted.is_empty() else {}

func _stable_unit(value: String) -> float:
	var hash_value: int = 2166136261
	for i in range(value.length()):
		hash_value = int((hash_value ^ value.unicode_at(i)) * 16777619) & 0x7fffffff
	return float(hash_value % 1000003) / 1000003.0

func _best_refuge(neighbors: Array, rooms: Dictionary, narrow_only: bool) -> String:
	var best_room := ""
	var best_score := -INF
	for room_id_value in neighbors:
		var room_id := String(room_id_value)
		var room: Dictionary = rooms.get(room_id, {})
		if room.is_empty():
			continue
		if narrow_only and not bool(room.get("narrow", false)):
			continue
		var score := float(room.get("cover", 0.0)) + (0.5 if bool(room.get("narrow", false)) else 0.0) - float(room.get("noise", 0.0))
		if score > best_score:
			best_score = score
			best_room = room_id
	return best_room

func _best_food_room(neighbors: Array, rooms: Dictionary, resource_key: String) -> String:
	var best_room := ""
	var best_food := 0.1
	for room_id_value in neighbors:
		var room_id := String(room_id_value)
		var room: Dictionary = rooms.get(room_id, {})
		var food := float(room.get(resource_key, 0.0))
		if food > best_food:
			best_food = food
			best_room = room_id
	return best_room

func _nearest_room_with_property(rooms: Dictionary, origin: String, key: String, expected: bool) -> String:
	var queue: Array = [origin]
	var visited: Dictionary = {origin:true}
	while not queue.is_empty():
		var current := String(queue.pop_front())
		var room: Dictionary = rooms.get(current, {})
		if bool(room.get(key, false)) == expected:
			return current
		for neighbor_value in room.get("neighbors", []):
			var neighbor := String(neighbor_value)
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return ""

func _room_distance(rooms: Dictionary, origin: String, destination: String, max_distance: int = 99) -> int:
	if origin.is_empty() or destination.is_empty() or not rooms.has(origin) or not rooms.has(destination):
		return -1
	if origin == destination:
		return 0
	var queue: Array = [{"room":origin, "distance":0}]
	var visited: Dictionary = {origin:true}
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		if int(current.distance) >= max_distance:
			continue
		for neighbor_value in rooms.get(String(current.room), {}).get("neighbors", []):
			var neighbor := String(neighbor_value)
			if visited.has(neighbor):
				continue
			var distance := int(current.distance) + 1
			if neighbor == destination:
				return distance
			visited[neighbor] = true
			queue.append({"room":neighbor, "distance":distance})
	return -1

func _next_step_toward(rooms: Dictionary, origin: String, destination: String, allow_narrow: bool) -> String:
	if origin == destination:
		return origin
	var queue: Array = [origin]
	var came_from: Dictionary = {origin:""}
	while not queue.is_empty():
		var current := String(queue.pop_front())
		if current == destination:
			break
		for neighbor_value in rooms.get(current, {}).get("neighbors", []):
			var neighbor := String(neighbor_value)
			if came_from.has(neighbor):
				continue
			if not allow_narrow and bool(rooms.get(neighbor, {}).get("narrow", false)):
				continue
			came_from[neighbor] = current
			queue.append(neighbor)
	if not came_from.has(destination):
		return ""
	var cursor := destination
	while String(came_from[cursor]) != origin and not String(came_from[cursor]).is_empty():
		cursor = String(came_from[cursor])
	return cursor

func _is_predatory(species_id: String) -> bool:
	return species_id == "MON-F1-005"

func _is_prey_for(candidate_species: String, predator_species: String) -> bool:
	return predator_species == "MON-F1-005" and candidate_species == "MON-F1-001"

func _creature_consequence_text(action: String, success: bool) -> String:
	if not success:
		return "La acción no superó sus precondiciones; el agente conserva el resultado del intento."
	match action:
		"flee_to_narrow_refuge": return "La rata alcanzó una grieta estrecha; un depredador demasiado grande no puede seguirla en esta prueba."
		"retract_elytra": return "El escarabajo protegió el dorso; no recibió daño ni se calculó combate."
		"consume_detritus": return "El escarabajo consumió parte del detritus local disponible."
		"forage_insects": return "El murciélago consumió parte de los insectos de la cámara."
		"prepare_ambush": return "El rastrero localizó la presa y adoptó una posición de emboscada; no se resolvió daño."
		"stalk_prey": return "El rastrero avanzó un paso válido hacia una presa detectada."
		"abandon_narrow_pursuit": return "El rastrero abandonó la persecución por una limitación anatómica observada."
		"evasive_flight": return "El murciélago cambió de cámara buscando altura y reduciendo la perturbación."
		_: return "La acción ecológica produjo un cambio de estado experimental."

func _human_consequence_text(action: String, success: bool) -> String:
	if not success:
		return "La acción fue rechazada por falta de una precondición válida."
	match action:
		"advance_motivation": return "Se registró esfuerzo en un objetivo propio; no se declaró completado."
		"address_tension": return "Se añadió un paso de investigación; la tensión no se declaró resuelta."
		"continue_routine": return "Se registró práctica; no se concedió dominio automático ni producción económica."
		"rest": return "La fatiga operativa disminuyó."
		"social_contact": return "Ambos individuos recordaron el contacto; confianza y afecto permanecen sin medir."
		"offer_lesson": return "Se envió una oferta; el destinatario puede aceptarla o rechazarla."
		"accept_lesson": return "El individuo aceptó una oferta y registró práctica guiada, no maestría."
		"decline_lesson": return "El individuo rechazó una oferta; no se inventó el motivo."
		_: return "La acción se registró sin otorgar resultados no validados."

