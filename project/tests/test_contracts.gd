extends SceneTree

const ClockScript = preload("res://scripts/core/world_clock.gd")
const GeneratorScript = preload("res://scripts/generation/world_generator.gd")
const CommandProcessorScript = preload("res://scripts/core/command_processor.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_catchup_delta()
	_test_seeded_generation()
	_test_command_idempotency()
	_test_event_replay()
	print("WORLD LAB CONTRACT TESTS: PASS")
	quit(0)

func _test_catchup_delta() -> void:
	var clock = ClockScript.new()
	var good: Dictionary = clock.calculate_offline_gap(1000, 4600)
	assert(int(good["elapsed_seconds"]) == 3600)
	assert(str(good["anomaly"]).is_empty())
	var rollback: Dictionary = clock.calculate_offline_gap(4600, 1000)
	assert(int(rollback["elapsed_seconds"]) == 0)
	assert(str(rollback["anomaly"]) == "system_clock_moved_backwards")

func _test_seeded_generation() -> void:
	var generator = GeneratorScript.new()
	var first: Dictionary = generator.generate(424242, 3, 2)
	var second: Dictionary = generator.generate(424242, 3, 2)
	assert(first["agents"].size() == 5)
	assert(first["agents"]["agent_0001"]["position"] == second["agents"]["agent_0001"]["position"])
	assert(first["agents"]["agent_0004"]["entity_kind"] == "creature")

func _test_command_idempotency() -> void:
	var processor = CommandProcessorScript.new()
	var state := {
		"world_tick": 100,
		"agents": {
			"agent_test": {
				"agent_id": "agent_test",
				"life_state": "alive",
				"capabilities": {"eat": true},
				"inventory": {"food": 1},
				"needs": {"hunger": 80.0}
			}
		},
		"regions": {},
		"processed_command_ids": {}
	}
	var command := {"command_id": "cmd_once", "actor_id": "agent_test", "action_type": "eat"}
	var first: Dictionary = processor.execute(command, state)
	assert(bool(first["accepted"]))
	var second: Dictionary = processor.execute(command, state)
	assert(not bool(second["accepted"]))
	assert(str(second["reason"]) == "duplicate_command")
	assert(int(state["agents"]["agent_test"]["inventory"]["food"]) == 0)
	assert(float(state["agents"]["agent_test"]["needs"]["hunger"]) == 45.0)

func _test_event_replay() -> void:
	var processor = CommandProcessorScript.new()
	var original := {
		"world_tick": 200,
		"agents": {
			"agent_replay": {
				"agent_id": "agent_replay",
				"life_state": "alive",
				"capabilities": {"eat": true},
				"inventory": {"food": 2},
				"needs": {"hunger": 90.0},
				"position": [0.0, 0.0, 0.0]
			}
		},
		"regions": {},
		"processed_command_ids": {},
		"recent_events": []
	}
	var recovery_state: Dictionary = original.duplicate(true)
	var result: Dictionary = processor.execute({
		"command_id": "cmd_replay_once",
		"actor_id": "agent_replay",
		"action_type": "eat"
	}, original)
	assert(bool(result["accepted"]))
	var event: Dictionary = result["event"]
	assert(processor.replay_confirmed_event(event, recovery_state))
	assert(int(recovery_state["agents"]["agent_replay"]["inventory"]["food"]) == 1)
	assert(float(recovery_state["agents"]["agent_replay"]["needs"]["hunger"]) == 55.0)
	assert(not processor.replay_confirmed_event(event, recovery_state))
