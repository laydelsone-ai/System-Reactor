extends SceneTree

# El orden reproduce el que usa la escena real: primero el núcleo y después
# los recursos que dependen de su contrato.
const SystemCoreScript = preload("res://scripts/core/system_core.gd")
const ApplicationShellScript = preload("res://scripts/app/application_shell.gd")
const PixelObservatoryScript = preload("res://scripts/app/pixel_observatory.gd")

func _initialize() -> void:
	var core_instance: RefCounted = SystemCoreScript.new()
	_check(core_instance != null, "SystemCore can be instantiated")
	var autonomy_script: Script = load("res://scripts/simulation/autonomy_runtime.gd") as Script
	if autonomy_script == null:
		push_error("AutonomyRuntime script failed to load; inspect the parser diagnostic immediately above this line.")
		quit(1)
		return
	var autonomy_instance: RefCounted = autonomy_script.new()
	_check(autonomy_instance != null, "Autonomy runtime can be instantiated without a global class_name")
	_check(ApplicationShellScript is Script, "legacy application shell script parses")
	_check(PixelObservatoryScript is Script, "Pixel Observatory scene script parses")
	print("GDSCRIPT PRELOAD TESTS: passed")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		push_error("FAIL: " + message)
		quit(1)
