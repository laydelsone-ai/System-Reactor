extends RefCounted

const ClockScript = preload("res://scripts/core/world_clock.gd")
const SchedulerScript = preload("res://scripts/core/world_scheduler.gd")
const GeneratorScript = preload("res://scripts/generation/world_generator.gd")
const SaveServiceScript = preload("res://scripts/persistence/local_save_service.gd")
const EventStoreScript = preload("res://scripts/persistence/event_store.gd")
const CommandProcessorScript = preload("res://scripts/core/command_processor.gd")
const DecisionTraceScript = preload("res://scripts/agents/decision_trace.gd")

const AUTOSAVE_INTERVAL_SECONDS: float = 20.0
const HUMANOID_COUNT: int = 64
const CREATURE_COUNT: int = 24

var state: Dictionary = {}
var clock = ClockScript.new()
var scheduler = SchedulerScript.new()
var generator = GeneratorScript.new()
var save_service = SaveServiceScript.new()
var event_store = EventStoreScript.new()
var command_processor = CommandProcessorScript.new()
var rng := RandomNumberGenerator.new()
var is_ready: bool = false
var real_time_accumulator: float = 0.0

func initialize(now_epoch: int) -> Dictionary:
	var loaded: Dictionary = save_service.load_snapshot()
	if loaded.is_empty():
		var seed_value := now_epoch if now_epoch > 0 else 20261119
		state = generator.generate(seed_value, HUMANOID_COUNT, CREATURE_COUNT)
		rng.state = int(state.get("rng_state", seed_value))
		state["last_wall_epoch"] = now_epoch
		clock.world_tick = 0
		clock.commit_wall_checkpoint(now_epoch)
		is_ready = true
		save_now(now_epoch)
		return {"created": true, "catchup_seconds": 0, "clock_anomaly": ""}

	state = loaded
	clock.world_tick = int(state.get("world_tick", 0))
	var stored_rng_state := int(state.get("rng_state", int(state.get("seed", 1))))
	rng.state = stored_rng_state
	var pending_events: Array = event_store.load_events_after(
		str(state.get("world_id", "world")),
		str(state.get("last_event_id", "")),
		int(state.get("world_tick", 0))
	)
	for pending_event in pending_events:
		command_processor.replay_confirmed_event(pending_event, state)
	clock.world_tick = int(state.get("world_tick", 0))
	var recovery := clock.calculate_offline_gap(int(state.get("last_wall_epoch", now_epoch)), now_epoch)
	var gap := int(recovery.get("elapsed_seconds", 0))
	var anomaly := str(recovery.get("anomaly", ""))
	if bool(state.get("paused", false)):
		gap = 0
	state["clock_anomalies"] = state.get("clock_anomalies", [])
	if not anomaly.is_empty():
		var anomalies: Array = state["clock_anomalies"]
		anomalies.append({"world_tick": clock.world_tick, "kind": anomaly, "observed_epoch": now_epoch})
		state["clock_anomalies"] = anomalies
	if gap > 0:
		advance_seconds(gap)
	state["last_wall_epoch"] = now_epoch
	clock.commit_wall_checkpoint(now_epoch)
	is_ready = true
	save_now(now_epoch)
	return {"created": false, "catchup_seconds": gap, "clock_anomaly": anomaly}

func advance_real_time(delta: float) -> void:
	if not is_ready or bool(state.get("paused", false)):
		return
	real_time_accumulator += maxf(delta, 0.0)
	var whole_seconds := int(floor(real_time_accumulator))
	if whole_seconds > 0:
		real_time_accumulator -= float(whole_seconds)
		advance_seconds(whole_seconds)

func advance_seconds(seconds: int) -> void:
	if seconds <= 0 or state.is_empty() or bool(state.get("paused", false)):
		return
	var agents: Dictionary = state.get("agents", {})
	var regions: Dictionary = state.get("regions", {})
	var target_tick := int(state.get("world_tick", 0)) + seconds
	var next_ecology_tick := int(state.get("next_ecology_tick", 3600))
	var safety_counter := 0
	while int(state.get("world_tick", 0)) < target_tick:
		var current_tick := int(state.get("world_tick", 0))
		var next_tick := scheduler.find_next_tick(current_tick, target_tick, agents, next_ecology_tick)
		state["world_tick"] = next_tick
		clock.world_tick = next_tick
		var ids: Array = agents.keys()
		ids.sort()
		for agent_id in ids:
			var agent: Dictionary = agents[agent_id]
			if int(agent.get("next_decision_tick", target_tick + 1)) <= next_tick:
				agent = _process_agent_decision(agent, next_tick)
				agents[agent_id] = agent
		if next_ecology_tick <= next_tick:
			_process_ecology(regions, next_tick)
			next_ecology_tick += 3600
			state["next_ecology_tick"] = next_ecology_tick
		state["agents"] = agents
		state["regions"] = regions
		safety_counter += 1
		if safety_counter > 200000:
			push_error("Scheduler superó el límite de seguridad de iteraciones.")
			break
	state["rng_state"] = rng.state

func _process_agent_decision(agent: Dictionary, tick: int) -> Dictionary:
	if agent.get("life_state", "alive") != "alive":
		agent["next_decision_tick"] = tick + 3600
		return agent
	var last_tick := int(agent.get("last_decision_tick", 0))
	var elapsed_hours := maxf(float(tick - last_tick) / 3600.0, 0.0)
	var needs: Dictionary = agent.get("needs", {})
	needs["hunger"] = minf(100.0, float(needs.get("hunger", 0.0)) + elapsed_hours * 4.0)
	needs["fatigue"] = minf(100.0, float(needs.get("fatigue", 0.0)) + elapsed_hours * 2.0)
	agent["needs"] = needs
	var alternatives: Array[String] = ["eat", "forage", "rest", "patrol"]
	var selected_action := "patrol"
	if float(needs.get("hunger", 0.0)) >= 70.0:
		selected_action = "eat" if int(agent.get("inventory", {}).get("food", 0)) > 0 else "forage"
	elif float(needs.get("fatigue", 0.0)) >= 70.0:
		selected_action = "rest"
	var command_id := "cmd_%s_%s" % [agent.get("agent_id", "unknown"), str(tick)]
	var trace: Dictionary = DecisionTraceScript.build(agent, tick, alternatives, selected_action, command_id)
	var next_decision_tick := tick + rng.randi_range(900, 3600)
	agent["last_decision_tick"] = tick
	agent["next_decision_tick"] = next_decision_tick
	var payload := {}
	if selected_action == "patrol":
		payload = {"dx": rng.randf_range(-0.35, 0.35), "dz": rng.randf_range(-0.35, 0.35)}
	var command := {
		"command_id": command_id,
		"actor_id": str(agent.get("agent_id", "")),
		"domain": "survival_and_activity",
		"scope": "world_local",
		"action_type": selected_action,
		"decision_id": trace.get("decision_id", ""),
		"created_at_world_tick": tick,
		"payload": payload
	}
	var result: Dictionary = command_processor.execute(command, state)
	trace["execution_result"] = "confirmed" if bool(result.get("accepted", false)) else str(result.get("reason", "rejected"))
	var event: Dictionary = result.get("event", {})
	if not event.is_empty():
		trace["event_id"] = event.get("event_id", "")
		_record_event(event)
	var updated_agent: Dictionary = result.get("agent", agent)
	updated_agent["last_decision_trace"] = trace
	updated_agent["last_decision_tick"] = tick
	updated_agent["next_decision_tick"] = next_decision_tick
	if not event.is_empty():
		var event_payload: Dictionary = event.get("payload", {})
		event_payload["decision_trace"] = trace.duplicate(true)
		event_payload["agent_after"] = {
			"needs": updated_agent.get("needs", {}).duplicate(true),
			"inventory": updated_agent.get("inventory", {}).duplicate(true),
			"position": updated_agent.get("position", [0.0, 0.0, 0.0]).duplicate(true),
			"last_decision_tick": tick,
			"next_decision_tick": next_decision_tick,
			"last_decision_trace": trace.duplicate(true)
		}
		event["payload"] = event_payload
	return updated_agent

func _process_ecology(regions: Dictionary, tick: int) -> void:
	# Modelo de prueba deliberadamente pequeño: regeneración limitada de alimento.
	# El sistema ecológico definitivo debe declarar producción, consumo, presión y capacidad.
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		var food := int(region.get("food_units", 0))
		region["food_units"] = mini(food + 2, 900)
		regions[region_id] = region

func _record_event(event: Dictionary) -> void:
	var events: Array = state.get("recent_events", [])
	events.append(event)
	if events.size() > 100:
		events.pop_front()
	state["recent_events"] = events
	var stored := event_store.append_event(str(state.get("world_id", "world")), event)
	if stored:
		state["last_event_id"] = str(event.get("event_id", ""))
	else:
		push_error("El evento no pudo escribirse en el journal; revisar persistencia antes de seguir.")

func set_paused(paused: bool) -> void:
	state["paused"] = paused
	save_now(int(Time.get_unix_time_from_system()))

func save_now(now_epoch: int = -1) -> bool:
	if state.is_empty():
		return false
	var epoch := now_epoch
	if epoch < 0:
		epoch = int(Time.get_unix_time_from_system())
	state["last_wall_epoch"] = epoch
	state["world_tick"] = maxi(clock.world_tick, int(state.get("world_tick", 0)))
	state["rng_state"] = rng.state
	return save_service.save_snapshot(state)

func get_world_tick() -> int:
	return int(state.get("world_tick", 0))
