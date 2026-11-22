# Changelog

## 0.3.10 — JSON numeric semantics in snapshot recovery (2026-11-22)

- Corrected the durable autonomy test comparison: JSON round-trips can decode integral JSON numbers as either integer or float Variants, so persistence equivalence is now checked recursively by numeric value rather than Variant subtype.
- Added regression tests proving `2` and `2.0` are semantically equivalent while true numeric changes and array-shape changes remain detectable.
- Added whole-runtime-state comparison after loading the autonomy snapshot and replaying later journal events.
- Added isolated twin continuation checks so the pre-save and restored states must generate equivalent next-cycle outcomes and traces.
- Updated project and Android version metadata to 0.3.10.
- Godot 4.7.2 execution of the new tests remains pending GitHub Actions; no engine pass is claimed here.

## 0.3.9 — 22 de noviembre de 2026
- Persistencia WLA-0B: eventos autónomos registran deltas explícitos por ID para NPC y criaturas.
- Replay reconstruye entidades mediante copias profundas explícitas y conserva compatibilidad con eventos anteriores.
- La prueba exige cargar el snapshot y reproducir al menos un evento posterior; si hay divergencia, imprime campos distintos.

# Changelog

## 0.3.8 — Autonomy intervention parser fix (2026-11-22)

- Fixed the invalid indentation of the room-state write-back after the `match` in `AutonomyRuntime._apply_intervention_payload()`. The assignment is now executed after the selected intervention branch instead of being parsed as a match pattern.
- Reworked the write-back through explicitly typed `environment` and `rooms` dictionaries, then stores the updated environment back into the runtime state.
- Added a regression test that sends an observer vibration, verifies the room noise is persisted, checks the `observer_intervention` provenance on the stimulus, and confirms the intervention metric is separate from autonomous actions.
- The exact GDScript parser issue reported by GitHub Actions at `autonomy_runtime.gd:695` is addressed. Godot parser/tests and Android export still require the next GitHub Actions run; no successful engine run is claimed here.

## 0.3.7 — Godot test runner hang repair (2026-11-22)

- Reworked `tests/test_script_preloads.gd` to defer its checks until `SceneTree` initialization has completed.
- Replaced top-level preload/constructor work in that test with sequential `ResourceLoader.load()` checks and explicit `can_instantiate()` validation.
- Added per-script progress output so the exact resource under test is visible.
- Changed GitHub Actions Godot checks to stream output live through `tee` while retaining full per-check logs.
- Added a 180-second timeout to each Godot check so a stuck headless process cannot occupy the runner indefinitely.
- Removed unnecessary `--verbose` output from the six checks; parser/load errors are still detected from saved logs.
- The five Python source/catalogue/payload validators pass. Godot tests and Android export remain pending a real Actions run.

## 0.3.6 — Integrated Godot renderer and CI repair (2026-11-22)

- Rebuilt the complete repository from the full 0.3.0 project, retaining all original game data, assets, normative references, autonomy runtime and Android export settings.
- Integrated the diagnostic-safe WLA-0B runtime and headless preload test; the application loads the autonomy script dynamically instead of requiring a global `class_name` dependency.
- Corrected every incomplete `draw_texture_rect()` call in `scripts/app/pixel_observatory.gd` with the required `tile` argument (`false` for single-sprite drawing).
- Added explicit `Dictionary` annotations to the autonomy report/state values that Godot could not infer.
- Integrated the GitHub Actions diagnostics workflow: separate editor import, preload, core, content, autonomy and app-boot checks; full logs are uploaded even when checks fail.
- Updated project/app version and regenerated the full SHA-256 manifest.
- Python source/catalogue/payload validation is run for this package. Godot 4.7.2 parsing, GDScript tests and Android APK export are **not claimed as passed** until GitHub Actions completes successfully.


## 0.3.0 — WLA-0B Autonomy Trial (2026-11-22)

- Added `AutonomyRuntime` with an autonomous bounded scheduler for 180 individual human agent models.
- Added limited perception, goal/tension/routine arbitration, fatigue management, candidate scoring, seeded tie-breaking, memory provenance, recall decay, action experience and outcome bias.
- Added persistence through `SimulationStepCommitted` and `ObserverInterventionCommitted`, snapshots and journal replay.
- Added four isolated biological trial subjects from the original Floor 1 bestiary and a non-cognitive lantern-fungus process.
- Added species-conditioned choices, sensory filtering, movement, feeding, refuge constraints and ecological fixture state changes.
- Added an AUTONOMIA tab with automatic run/pause/step, action trace, inspector and explicitly marked observer interventions.
- Added Godot headless tests for cognition, memory, scheduler coverage, sensory limits, species-specific behavior, determinism and persistence/recovery.
- Normalized null/missing source fields without inventing identity, profile, residence or validated location data.
- Updated GitHub Actions to run the autonomy suite before APK export.
- Still pending: Godot parser/test execution, Android APK export, physical device QA, validated NPC placement/social simulation, NPC spatial actions, canonical ecology, SR-09 combat, offline catch-up and time-scale calibration.

## 0.2.0 — Pixel Observatory (2026-11-22)

- Preserved WLA-0A core and persistence.
- Added pixel-art/isometric observational UI and Floor 1 bestiary.
- Added Social Register v0.2.0, mission templates and source provenance material.
- Added original sprites, tiles, bitmap font, adaptive Android icons and splash.
- Added GitHub Actions for Android Debug APK.
