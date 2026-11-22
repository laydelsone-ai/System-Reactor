# Changelog

## 0.3.1 — Corrección de carga y tipos Godot 4.7.2
- El test autónomo y el test de precarga cargan primero `SystemCore` y después `AutonomyRuntime`, respetando la dependencia tipada y el orden de la escena principal.
- Tipos explícitos (`float`/`int`) para las expresiones del test que Godot no infería desde el objeto creado por `Script.new()`.
- `project.godot` declara `config/features` para Godot 4.7 y recupera el color base del antiguo System Reactor.
- Versión Android incrementada a 0.3.1 / versionCode 4.

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
