extends RefCounted

static func build(agent: Dictionary, world_tick: int, alternatives: Array, selected_action: String, command_id: String) -> Dictionary:
	var needs: Dictionary = agent.get("needs", {})
	return {
		"decision_id": "dec_%s_%s" % [agent.get("agent_id", "unknown"), str(world_tick)],
		"agent_id": agent.get("agent_id", "unknown"),
		"world_tick": world_tick,
		"available_observations": ["own_needs", "current_region_resources"],
		"beliefs_used": agent.get("beliefs", []).duplicate(true),
		"motivations_ranked": ["survival", "condition"],
		"need_snapshot": needs.duplicate(true),
		"alternatives": alternatives.duplicate(true),
		"selected_action": selected_action,
		"capability_check": "pending_domain_validation",
		"command_id": command_id,
		"execution_result": "pending",
		"event_id": "",
		"learning_update": []
	}
