# Estado de validación — Paquete integrado WLA-0B Autonomy Trial 0.3.10

## Validado durante el empaquetado

- Integridad estructural y preflight del proyecto empaquetado.
- Los JSON incluidos parsean correctamente.
- Registro Social v0.2.0: 180 personas, 60 del reparto principal, 120 de población de fondo, 40 grupos de hogar, 240 enlaces `same_household_member`, 4 declaraciones sin resolver. No se fabrican residencias.
- El JSON social se reproduce con igualdad estructural desde las fuentes preservadas.
- Bestiario Piso 1: cinco perfiles cotejados contra el CSV de estadísticas fuente.
- Las 12 plantillas de misión coinciden con su fuente.
- PNG, recursos, atlas, iconos adaptativos y tamaños del export preset Android.
- Preflight estructural de versión WLA-0B, presencia de runtime/pruebas y workflow de diagnóstico por etapas.
- Inspección estática del renderizador: las llamadas `draw_texture_rect()` incluyen el argumento obligatorio `tile`; los resultados dinámicos del panel están tipados como `Dictionary`.
- El test de precarga ya no hace trabajo pesado dentro de `SceneTree._initialize()`: difiere la ejecución, carga scripts uno a uno y comprueba `can_instantiate()`.
- El workflow transmite la salida de cada chequeo en vivo, conserva el log y limita cada proceso Godot a 180 segundos.
- La asignación `rooms[room_id]` se ha movido fuera del bloque `match` en `_apply_intervention_payload()`; el write-back de `environment` está tipado y la suite incluye una prueba de persistencia/procedencia de vibración.
- Se ha comprobado el parseo YAML del workflow y la sintaxis Bash de su mecanismo de timeout/tee.

## Pruebas de motor incluidas, con diagnóstico de Actions del 22-11-2026

`tests/test_script_preloads.gd` comprueba la carga y capacidad de instanciación de SystemCore, ApplicationShell, PixelObservatory y AutonomyRuntime.

`tests/test_autonomy.gd` comprueba inicialización de los 180 modelos, límites epistémicos, motivaciones y tensiones importadas, cognición/memoria, límites sensoriales, decisiones ecológicas, persistencia y procedencia de intervenciones del observador, scheduler, determinismo, snapshot y replay.

También permanecen las pruebas de contratos del núcleo, contenido y arranque de escena.

### Resultado del diagnóstico WLA-0B 0.3.9

- Editor/importación: PASS.
- Precarga de scripts: PASS.
- Contratos WLA-0A: 33 PASS, 0 FAIL.
- Contenido: 56 PASS, 0 FAIL.
- Autonomía: 94 PASS, 2 FAIL inicialmente.
- Los dos fallos se debían a comparar snapshots mediante igualdad estricta de `Variant`: después del round-trip JSON, valores numéricos enteros (por ejemplo `2`) se decodifican como floats (`2.0`). El valor persistido era igual; el subtipo numérico de GDScript no.
- La versión 0.3.10 compara recursivamente el valor numérico y conserva la detección de diferencias reales. Añade una prueba de ida/vuelta JSON, comparación del estado completo y continuación determinista del ciclo siguiente desde copias aisladas.

La nueva comparación semántica y la continuación deben confirmarse en la siguiente ejecución de Godot 4.7.2. No se declara esta nueva prueba como aprobada antes de Actions.

## No ejecutado en este entorno

- Import/parsing GDScript con Godot 4.7.2.
- Pruebas `test_script_preloads.gd`, `test_contracts.gd`, `test_content_data.gd` y `test_autonomy.gd` dentro de Godot.
- Smoke test de escena.
- Exportación de Android Debug APK.
- Instalación, rendimiento, ciclo de vida, force-stop y recuperación en Android físico.

**Motivo:** el contenedor no incluye el motor Godot y la red de descarga no pudo resolver GitHub. No se declara APK compilada ni prueba GDScript aprobada.

## Verificación en GitHub Actions

`.github/workflows/android.yml` instala Godot 4.7.2 Standard, Java 17 y los componentes Android fijados. Ejecuta importación, precarga, contratos, contenido, autonomía y smoke test por separado. La salida se transmite en vivo y se conserva en logs; cada proceso tiene un máximo de 180 segundos. Los diagnósticos se suben incluso en caso de fallo. La exportación Android Debug y la subida de APK + SHA-256 solo ocurren si todas las etapas pasan.
