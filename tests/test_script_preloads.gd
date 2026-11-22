extends SceneTree

## Test de carga de scripts. Se ejecuta diferido para que SceneTree termine
## su inicialización antes de cargar recursos y solicitar el cierre.

var _failures: int = 0

func _initialize() -> void:
	print("[preloads] SceneTree initialized; scheduling checks")
	call_deferred("_run_checks")

func _run_checks() -> void:
	_check_script("res://scripts/core/system_core.gd", "SystemCore")
	_check_script("res://scripts/app/application_shell.gd", "ApplicationShell")
	_check_script("res://scripts/app/pixel_observatory.gd", "PixelObservatory")
	_check_script("res://scripts/simulation/autonomy_runtime.gd", "AutonomyRuntime")
	if _failures == 0:
		print("GDSCRIPT PRELOAD TESTS: passed")
	else:
		push_error("GDSCRIPT PRELOAD TESTS: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)

func _check_script(path: String, label: String) -> void:
	print("[preloads] Loading %s: %s" % [label, path])
	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		_failures += 1
		push_error("FAIL: %s could not be loaded: %s" % [label, path])
		return
	if not resource is Script:
		_failures += 1
		push_error("FAIL: %s did not resolve to a Script resource" % label)
		return
	var script: Script = resource as Script
	if not script.can_instantiate():
		_failures += 1
		push_error("FAIL: %s cannot be instantiated" % label)
		return
	print("PASS: %s loaded and parsed" % label)
