from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
scene = (ROOT / "scenes/main.tscn").read_text(encoding="utf-8")
project = (ROOT / "project.godot").read_text(encoding="utf-8")
script = (ROOT / "scripts/app/main.gd").read_text(encoding="utf-8")

assert 'run/main_scene="res://scenes/main.tscn"' in project
assert '[node name="Camera3D" type="Camera3D" parent="."]' in scene
assert 'current = true' in scene
assert '[node name="HUD" type="CanvasLayer" parent="."]' in scene
assert 'background_color = Color' in scene
assert 'WLA_BOOT_OK' in script
print("WLA static scene-presence checks: PASS")
