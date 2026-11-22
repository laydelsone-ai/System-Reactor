extends SceneTree

const SystemCoreScript = preload("res://scripts/core/system_core.gd")
const IdFactoryScript = preload("res://scripts/core/id_factory.gd")
const WorldClockScript = preload("res://scripts/core/world_clock.gd")

var _failures: int = 0
var _passes: int = 0
var _test_root: String = ""

func _initialize() -> void:
	_test_root = "user://wla0a_contract_tests_%d" % Time.get_ticks_usec()
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_create_world_and_bootstrap_event()
	_test_world_clock_contract()
	_test_command_validation_and_replay()
	_test_snapshot_backup_and_truncated_tail()
	print("WLA-0A TESTS: %d passed, %d failed" % [_passes, _failures])
	quit(1 if _failures > 0 else 0)

func _test_create_world_and_bootstrap_event() -> void:
	var core = SystemCoreScript.new(_test_root)
	var result: Dictionary = core.open_last_or_create()
	_check(result.get("ok", false), "new local world can be initialized")
	_check(core.ready, "SystemCore reaches ready state")
	_check(core.clock.world_tick == 0, "world_tick starts at zero")
	_check(core.event_count == 1, "WorldInitialized is durably journaled")
	_check(core.registry.entity_count() == 0, "WLA-0A does not invent NPC or world content")


func _test_world_clock_contract() -> void:
	var clock = WorldClockScript.new()
	_check(clock.restore(5) == OK, "WorldClock restores a non-negative world_tick")
	_check(clock.advance_to(4) == ERR_INVALID_PARAMETER, "WorldClock rejects backwards movement")
	_check(clock.world_tick == 5, "rejected clock movement leaves state unchanged")
	_check(clock.advance_to(6) == OK, "WorldClock accepts monotonic progression")
	var restored = WorldClockScript.new()
	_check(restored.load_snapshot(clock.to_snapshot()) == OK, "WorldClock snapshot can be restored")
	_check(restored.world_tick == 6, "WorldClock snapshot preserves world_tick")

func _test_command_validation_and_replay() -> void:
	var core = SystemCoreScript.new(_test_root)
	var open_result: Dictionary = core.open_last_or_create()
	_check(open_result.get("ok", false), "previous world can be reopened")

	var entity_id := IdFactoryScript.new_id("ent_test")
	var command_id := IdFactoryScript.new_id("cmd_test")
	var record := {
		"entity_id": entity_id,
		"entity_kind": "diagnostic_fixture",
		"scope": "world_local",
		"schema_version": 1,
		"state_version": 1,
		"created_at_world_tick": core.clock.world_tick,
		"origin": {"type": "automated_test", "stage": "WLA-0A"},
		"display_label": "persisted test fixture",
		"asset_key": null
	}
	var command_result: Dictionary = core.execute_register_entity(record, command_id, "automated_test")
	_check(command_result.get("accepted", false), "valid RegisterEntity command is confirmed")
	_check(core.registry.has_entity(entity_id), "confirmed event updates entity registry")
	_check(core.event_count == 2, "successful command appends one event")

	var duplicate_command: Dictionary = core.execute_register_entity(record, command_id, "automated_test")
	_check(not duplicate_command.get("accepted", false), "duplicate command_id is rejected")
	_check(core.event_count == 2, "rejected duplicate command creates no duplicate event")

	var duplicate_entity_record := record.duplicate(true)
	var duplicate_entity_command: Dictionary = core.execute_register_entity(duplicate_entity_record, IdFactoryScript.new_id("cmd_test"), "automated_test")
	_check(not duplicate_entity_command.get("accepted", false), "an entity_id cannot be registered twice")
	_check(core.event_count == 2, "invalid entity command does not append event")
	var malformed_record := record.duplicate(true)
	malformed_record["entity_id"] = IdFactoryScript.new_id("ent_test")
	malformed_record.erase("origin")
	var malformed_command: Dictionary = core.execute_register_entity(malformed_record, IdFactoryScript.new_id("cmd_test"), "automated_test")
	_check(not malformed_command.get("accepted", false), "entity without provenance is rejected")
	_check(core.event_count == 2, "missing provenance creates no confirmed event")

	# No checkpoint after EntityRegistered: a fresh core must replay seq 2 from journal.
	var reopened = SystemCoreScript.new(_test_root)
	var recovery_result: Dictionary = reopened.open_last_or_create()
	_check(recovery_result.get("ok", false), "journal event can be replayed after a fresh core instance")
	_check(reopened.registry.has_entity(entity_id), "entity identity survives journal replay")
	_check(reopened.event_count == 2, "replay does not duplicate event count")
	var replayed_duplicate: Dictionary = reopened.execute_register_entity(record, command_id, "automated_test")
	_check(not replayed_duplicate.get("accepted", false), "command idempotency survives reopening")

func _test_snapshot_backup_and_truncated_tail() -> void:
	var core = SystemCoreScript.new(_test_root)
	var opened: Dictionary = core.open_last_or_create()
	_check(opened.get("ok", false), "world opens before checkpoint test")
	var checkpoint_result: Dictionary = core.save_checkpoint("test_backup_generation")
	_check(checkpoint_result.get("ok", false), "snapshot checkpoint is saved")

	var journal_path: String = core.persistence.journal_path(core.world_id)
	var journal_file := FileAccess.open(journal_path, FileAccess.READ_WRITE)
	_check(journal_file != null, "journal opens for crash-tail simulation")
	if journal_file != null:
		journal_file.seek_end()
		journal_file.store_string("{\"event_id\":\"truncated")
		journal_file.flush()
		journal_file.close()

	# Corromper snapshot principal para comprobar que se usa backup + journal.
	var main_snapshot_path: String = core.persistence.snapshot_path(core.world_id)
	var corrupt_file := FileAccess.open(main_snapshot_path, FileAccess.WRITE)
	_check(corrupt_file != null, "snapshot can be replaced by corruption fixture")
	if corrupt_file != null:
		corrupt_file.store_string("{corrupt")
		corrupt_file.flush()
		corrupt_file.close()

	var recovered = SystemCoreScript.new(_test_root)
	var recovery: Dictionary = recovered.open_last_or_create()
	_check(recovery.get("ok", false), "backup snapshot is used when primary snapshot is corrupt")
	_check(String(recovery.get("snapshot_source", "")) == "backup", "recovery records that backup was used")
	_check(recovered.registry.entity_count() == 1, "backup plus complete journal events restores entity")
	_check(not recovered.diagnostics.is_empty(), "recovery exposes diagnostics for damaged data")

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)
