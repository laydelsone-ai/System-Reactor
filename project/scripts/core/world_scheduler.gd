extends RefCounted

# Primera versión: calendario por próxima evaluación. Puede migrar a heap
# sin cambiar los contratos de agente/evento.

func find_next_tick(current_tick: int, target_tick: int, agents: Dictionary, next_ecology_tick: int) -> int:
	var next_tick: int = target_tick
	if next_ecology_tick > current_tick:
		next_tick = mini(next_tick, next_ecology_tick)
	var ids: Array = agents.keys()
	ids.sort()
	for agent_id in ids:
		var agent: Dictionary = agents[agent_id]
		var due_tick: int = int(agent.get("next_decision_tick", target_tick))
		if due_tick > current_tick:
			next_tick = mini(next_tick, due_tick)
	return maxi(next_tick, current_tick + 1)
