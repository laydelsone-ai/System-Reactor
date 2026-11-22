#!/usr/bin/env python3
"""Structural/content preflight for the World Laboratory Android project."""
from __future__ import annotations

import json
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")
    print(f"PASS: {message}")


def main() -> None:
    required = [
        "project.godot",
        "scenes/main.tscn",
        "scripts/app/pixel_observatory.gd",
        "scripts/core/system_core.gd",
        "scripts/simulation/autonomy_runtime.gd",
        "scripts/persistence/persistence_engine.gd",
        "tests/test_autonomy.gd",
        ".github/workflows/android.yml",
        "export_presets.cfg",
        "README.md",
        "VERSION.txt",
    ]
    for rel in required:
        require((ROOT / rel).is_file(), f"required project file exists: {rel}")

    autonomy_script = (ROOT / "scripts/simulation/autonomy_runtime.gd").read_text(encoding="utf-8")
    require('const RUNTIME_VERSION := "WLA-0B.2"' in autonomy_script, "WLA-0B.2 autonomous runtime is included")
    require('"omniscient_world_access":false' in autonomy_script, "agent perception explicitly excludes omniscient world access")
    require('"SimulationStepCommitted"' in autonomy_script, "autonomous decisions are committed as world events")
    require('"individual_memory_not_world_truth"' in autonomy_script, "memories are epistemically separate from world truth")
    require('person.get("motivation_summary", "")' in autonomy_script, "runtime imports the registry's canonical motivation field")
    require('person.get("current_tension_summary", "")' in autonomy_script, "runtime imports the registry's canonical tension field")
    require('cognitive.has("memory")' in autonomy_script, "unknown memory aptitude is not replaced with a fabricated score")
    autonomy_tests = (ROOT / "tests/test_autonomy.gd").read_text(encoding="utf-8")
    require("_test_memory_and_individual_cognition" in autonomy_tests, "autonomy tests cover cognition and memory")
    require("echolocation" in autonomy_tests, "autonomy tests cover sensory limits")
    require("imported_motivations == 180" in autonomy_tests, "autonomy tests verify all 180 source motivations")
    require("imported_tensions == 60" in autonomy_tests, "autonomy tests verify the 60 supplied tensions")
    require('first_named_agent.get("last_action", "")' in autonomy_tests, "autonomy tests verify an authored NPC acts on its own motivation")
    require("post_snapshot_step" in autonomy_tests, "autonomy tests cover replay after a committed snapshot")
    require('snapshot_payload.get("last_core_event_sequence", 0)' in autonomy_script, "autonomy snapshot cursor uses its verified payload")
    workflow = (ROOT / ".github/workflows/android.yml").read_text(encoding="utf-8")
    require("tests/test_autonomy.gd" in workflow, "GitHub Actions runs the autonomous simulation test suite")

    main_script = (ROOT / "scripts/app/pixel_observatory.gd").read_text(encoding="utf-8")
    preload_paths = re.findall(r'preload\("res://([^"\n]+)"\)', main_script)
    require(bool(preload_paths), "application declares preloaded visual assets")
    for rel in preload_paths:
        require((ROOT / rel).is_file(), f"GDScript preload resolves: {rel}")

    # Parse every JSON file included in the repo, including the preserved source bundle.
    json_files = list(ROOT.rglob("*.json"))
    require(len(json_files) >= 10, "JSON source/catalogue payload is present")
    for path in json_files:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise SystemExit(f"FAIL: invalid JSON {path.relative_to(ROOT)}: {exc}")
    print(f"PASS: parsed {len(json_files)} JSON documents")

    # Validate generated sprites/tiles/icons have readable dimensions and alpha channels.
    png_files = list((ROOT / "assets").rglob("*.png"))
    require(len(png_files) >= 20, "pixel-art sprites, tiles, font and Android icon assets included")
    png_info: dict[str, tuple[int, int, int]] = {}
    for path in png_files:
        payload = path.read_bytes()
        require(payload[:8] == b"\x89PNG\r\n\x1a\n" and payload[12:16] == b"IHDR", f"PNG signature/header valid: {path.relative_to(ROOT)}")
        width, height, bit_depth, color_type = struct.unpack(">IIBB", payload[16:26])
        require(width > 0 and height > 0 and bit_depth in (8, 16) and color_type in (2, 6), f"PNG has supported RGB/RGBA channels: {path.relative_to(ROOT)}")
        png_info[str(path.relative_to(ROOT))] = (width, height, color_type)
    icon_sizes = {
        "assets/icons/main_192.png": (192, 192),
        "assets/icons/adaptive_foreground_432.png": (432, 432),
        "assets/icons/adaptive_background_432.png": (432, 432),
        "assets/icons/adaptive_monochrome_432.png": (432, 432),
        "assets/icons/splash_512.png": (512, 512),
    }
    for rel, expected in icon_sizes.items():
        require(png_info[rel][:2] == expected, f"Android artwork dimensions: {rel} = {expected}")
    require(png_info["assets/ui/font_5x7.png"][:2] == (60, 48), "bitmap font atlas is a 10×6 grid of 5×7 glyph cells with 1px spacing")

    export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    for asset_key in [
        'launcher_icons/main_192x192="res://assets/icons/main_192.png"',
        'launcher_icons/adaptive_foreground_432x432="res://assets/icons/adaptive_foreground_432.png"',
        'launcher_icons/adaptive_background_432x432="res://assets/icons/adaptive_background_432.png"',
        'launcher_icons/adaptive_monochrome_432x432="res://assets/icons/adaptive_monochrome_432.png"',
    ]:
        require(asset_key in export, f"Android export preset references: {asset_key.split('=')[0]}")

    font_chars = (ROOT / "assets/ui/font_chars.txt").read_text(encoding="ascii").strip("\n")
    require(len(font_chars) <= 60 and len(set(font_chars)) == len(font_chars), "bitmap font glyph mapping fits 10×6 atlas without duplicates")
    require(font_chars == re.search(r'const FONT_CHARS := "([^"]+)"', main_script).group(1), "bitmap font mapping matches GDScript")
    require("floori(float(index) / 10.0)" in main_script, "bitmap font samples exact integer atlas rows")

    source_root = ROOT / "data/social/source"
    for rel in ["npc_named_cast.csv", "npc_background_population.json", "social_registry_v0.1_template.json", "mission_templates.json"]:
        require((source_root / rel).is_file(), f"social import source preserved: {rel}")
    require((ROOT / "scripts/build_social_registry_v2.py").is_file(), "social registry reproducibility builder preserved")
    with tempfile.TemporaryDirectory(prefix="wla-social-rebuild-") as temp_dir:
        rebuilt_path = Path(temp_dir) / "social_registry_v0.2.rebuilt.json"
        subprocess.run(
            [sys.executable, "scripts/build_social_registry_v2.py", "--output", str(rebuilt_path)],
            cwd=ROOT,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        original_registry = json.loads((ROOT / "data/social/social_registry_v0.2.json").read_text(encoding="utf-8"))
        rebuilt_registry = json.loads(rebuilt_path.read_text(encoding="utf-8"))
        require(original_registry == rebuilt_registry, "social registry v0.2.0 reproduces exactly from preserved source files")

    mission_data = json.loads((ROOT / "data/missions/mission_templates_v0.1.json").read_text(encoding="utf-8"))
    mission_source = json.loads((ROOT / "data/social/source/mission_templates.json").read_text(encoding="utf-8"))
    require(mission_data == mission_source and len(mission_data.get("missions", [])) == 12, "12 mission templates match their preserved source")

    print("PROJECT PAYLOAD PREFLIGHT PASSED")


if __name__ == "__main__":
    main()
