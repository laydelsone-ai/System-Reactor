# Changelog

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
