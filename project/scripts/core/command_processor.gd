extends RefCounted

const EventRecordScript = preload("res://scripts/core/event_record.gd")

func execute(command: Dictionary, state: Dictionary) -> Dictionary:
	var command_id := str(command.get("command_id", ""))
	if command_id.is_empty():
		return {"accepted": false, "reason": "missing_command_id", "event": {}}
	var processed: Dictionary = state.get("processed_command_ids", {})
	if processed.has(command_id):
		return {"accepted": false, "reason": "duplicate_command", "event": {}}
	var actor_id := str(command.get("actor_id", ""))
	var agents: Dictionary = state.get("agents", {})
	if not agents.has(actor_id):
		return {"accepted": false, "reason": "unknown_actor", "event": {}}
	var agent: Dictionary = agents[actor_id]
	if agent.get("life_state", "alive") != "alive":
		return {"accepted": false, "reason": "actor_not_alive", "event": {}}
	var action_type := str(command.get("action_type", ""))
	var event_type := ""
	var payload: Dictionary = {}
	match action_type:
		"eat":
			var inventory: Dictionary = agent.get("inventory", {})
			if int(inventory.get("food", 0)) <= 0 or not bool(agent.get("capabilities", {}).get("eat", false)):
				return _reject(command_id, "food_or_capability_missing")
			inventory["food"] = int(inventory.get("food", 0)) - 1
			agent["inventory"] = inventory
			var needs: Dictionary = agent.get("needs", {})
			needs["hunger"] = maxf(0.0, float(needs.get("hunger", 0.0)) - 35.0)
			agent["needs"] = needs
			event_type = "FoodConsumed"
			payload = {"food_units": 1}
		"forage":
			if not bool(agent.get("capabilities", {}).get("forage", false)):
				return _reject(command_id, "capability_missing")
			var regions: Dictionary = state.get("regions", {})
			var region_id := str(agent.get("region_id", ""))
			if not regions.has(region_id):
				return _reject(command_id, "region_missing")
			var region: Dictionary = regions[region_id]
			if int(region.get("food_units", 0)) <= 0:
				return _reject(command_id, "resource_depleted")
			region["food_units"] = int(region.get("food_units", 0)) - 1
			regions[region_id] = region
			state["regions"] = regions
			var inventory: Dictionary = agent.get("inventory", {})
			inventory["food"] = int(inventory.get("food", 0)) + 1
			agent["inventory"] = inventory
			event_type = "ResourceGathered"
			payload = {"resource": "food", "amount": 1, "region_id": region_id}
		"rest":
			if not bool(agent.get("capabilities", {}).get("rest", false)):
				return _reject(command_id, "capability_missing")
			var needs: Dictionary = agent.get("needs", {})
			needs["fatigue"] = maxf(0.0, float(needs.get("fatigue", 0.0)) - 35.0)
			agent["needs"] = needs
			event_type = "RestCompleted"
			payload = {"fatigue_after": needs["fatigue"]}
		"patrol":
			if not bool(agent.get("capabilities", {}).get("move", false)):
				return _reject(command_id, "movement_capability_missing")
			var position: Array = agent.get("position", [0.0, 0.0, 0.0])
			var dx := float(command.get("payload", {}).get("dx", 0.0))
			var dz := float(command.get("payload", {}).get("dz", 0.0))
			position[0] = clampf(float(position[0]) + dx, -18.0, 18.0)
			position[2] = clampf(float(position[2]) + dz, -18.0, 18.0)
			agent["position"] = position
			event_type = "AgentMoved"
			payload = {"position": position.duplicate(), "movement_kind": "patrol"}
		_:
			return _reject(command_id, "unknown_action")

	payload["agent_after"] = {
		"needs": agent.get("needs", {}).duplicate(true),
		"inventory": agent.get("inventory", {}).duplicate(true),
		"position": agent.get("position", [0.0, 0.0, 0.0]).duplicate(true)
	}
	if action_type == "forage":
		var after_region: Dictionary = state.get("regions", {}).get(str(agent.get("region_id", "")), {})
		payload["region_after"] = {
			"region_id": str(agent.get("region_id", "")),
			"food_units": int(after_region.get("food_units", 0))
		}
	agents[actor_id] = agent
	state["agents"] = agents
	processed[command_id] = true
	state["processed_command_ids"] = processed
	var event: Dictionary = EventRecordScript.create_event(
		event_type,
		int(state.get("world_tick", 0)),
		actor_id,
		command_id,
		payload
	)
	return {"accepted": true, "reason": "confirmed", "event": event, "agent": agent}

func replay_confirmed_event(event: Dictionary, state: Dictionary) -> bool:
	var command_id := str(event.get("command_id", ""))
	var processed: Dictionary = state.get("processed_command_ids", {})
	if command_id.is_empty() or processed.has(command_id):
		return false
	var actor_id := str(event.get("actor_id", ""))
	var agents: Dictionary = state.get("agents", {})
	var payload: Dictionary = event.get("payload", {})
	if agents.has(actor_id) and payload.get("agent_after", {}) is Dictionary:
		var agent: Dictionary = agents[actor_id]
		var agent_after: Dictionary = payload["agent_after"]
		for key in agent_after.keys():
			agent[key] = agent_after[key]
		agents[actor_id] = agent
		state["agents"] = agents
	if payload.get("region_after", {}) is Dictionary and not payload.get("region_after", {}).is_empty():
		var region_after: Dictionary = payload["region_after"]
		var regions: Dictionary = state.get("regions", {})
		var region_id := str(region_after.get("region_id", ""))
		if regions.has(region_id):
			var region: Dictionary = regions[region_id]
			region["food_units"] = int(region_after.get("food_units", region.get("food_units", 0)))
			regions[region_id] = region
			state["regions"] = regions
	processed[command_id] = true
	state["processed_command_ids"] = processed
	state["world_tick"] = maxi(int(state.get("world_tick", 0)), int(event.get("world_tick", 0)))
	state["last_event_id"] = str(event.get("event_id", ""))
	state["last_wall_epoch"] = maxi(int(state.get("last_wall_epoch", 0)), int(event.get("recorded_at_epoch", 0)))
	var recent: Array = state.get("recent_events", [])
	recent.append(event)
	if recent.size() > 100:
		recent.pop_front()
	state["recent_events"] = recent
	return true

func _reject(command_id: String, reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "event": {"command_id": command_id}}
