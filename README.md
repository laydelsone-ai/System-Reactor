# World Laboratory / Sistema Reactor
## Paquete integrado 0.3.8 — WLA-0B Autonomy Trial (Android / Godot)

**Versión integrada 0.3.8:** corrige el error de sintaxis confirmado por Godot 4.7.2 en `_apply_intervention_payload()`: la escritura de `rooms[room_id]` ahora ocurre después del `match`, con actualización explícita de `environment`. Se añade una prueba de regresión para la persistencia y procedencia del estímulo de vibración. La carga de escena y las correcciones del renderizador de 0.3.6/0.3.7 se conservan. La corrección debe pasar todavía por el parser y las pruebas reales de GitHub Actions; no se declara APK compilada.

Esta entrega cambia el foco de la anterior: el Observatorio ya no es únicamente una presentación de pixel-art. Incorpora un primer runtime experimental de autonomía que evalúa agentes sin órdenes del jugador, produce decisiones justificadas, ejecuta cambios de estado, guarda recuerdos individuales y persiste las consecuencias mediante eventos y snapshots.

**No es todavía la simulación total del universo.** Es una primera vertical slice WLA-0B, deliberadamente acotada, para probar el ciclo cognitivo y un pequeño caso ecológico antes de ampliar población, geografía, economía, combate y simulación fuera de pantalla.

## Qué incluye WLA-0B.2

### Agentes humanos

- Importa las 180 identidades del Registro Social v0.2.0 como modelos de agentes individuales.
- Considera motivaciones, tensiones, rutinas, roles, rasgos y aptitudes cuando existen en la fuente.
- Los 180 registros contienen motivaciones (`motivation_summary`); los 60 personajes del reparto principal también aportan tensiones (`current_tension_summary`), y los 120 perfiles de fondo aportan rutinas (`routine_summary`). El runtime conserva esos textos fuente exactos como entradas de decisión.
- Los 60 personajes del reparto principal no suministran rasgos, aptitudes ni identidad vital; esos campos permanecen desconocidos. Tampoco se les inventan hogares, residencia ni coordenadas.
- Los 120 perfiles de población de fondo contienen rasgos, rutinas y estimaciones cognitivas/funcionales provisionales; se conservan como estimaciones fuente, no como unidades físicas.
- Cada agente obtiene una observación limitada, calcula alternativas válidas y escoge según utilidad, motivaciones, tensión, rutina, fatiga operativa, rasgos, aptitudes conocidas, experiencia y memoria.
- Acciones humanas disponibles en este primer nivel: avanzar un paso de una motivación declarada, investigar una tensión declarada, practicar una rutina declarada, descansar; y, cuando haya co-presencia física explícitamente validada, contacto social y ofertas voluntarias de enseñanza.
- El progreso de motivación, tensión y rutina es un registro de esfuerzo/práctica. No afirma que una meta externa esté completada, que un producto se haya fabricado, que exista dinero o que una tensión se haya resuelto.
- El scheduler evalúa hasta 24 agentes por tick abstracto y recorre la población completa. En condiciones de prueba, los 180 obtienen turno en ocho ticks.
- Las memorias tienen fuente, confianza, importancia y estado epistémico. Los resultados recordados alteran ligeramente la utilidad futura de repetir una acción; no obligan a repetirla.

### Criaturas y ecología experimental

- Cuatro individuos de prueba derivados de las fichas originales del Piso 1: rata de filón, escarabajo ferrante, murciélago de eco y rastrero de escombro.
- Un hongo farolero se modela como proceso biológico ambiental, no como criatura cognitiva.
- Cada criatura usa reglas condicionadas a su especie, sentidos, alimento, refugio, fatiga y geometría de la cámara.
- En el escenario aislado, la rata puede huir a una grieta estrecha, el rastrero puede seguirla y abandonar la persecución por limitación anatómica, el escarabajo consume detritus y puede replegarse, y el murciélago busca insectos o responde al ruido.
- Las acciones cambian ubicación, hambre, fatiga, recursos y estado ambiental; se guardan memoria/experiencia y se registran resultados y precondiciones.
- La colonia fúngica responde fisiológicamente a daño, humedad y madurez. No tiene voluntad, agenda ni decisiones cognitivas.
- La percepción de otras criaturas está filtrada por los canales sensoriales del observador. La proximidad por sí sola no concede información.

### Núcleo, observatorio y persistencia

- Se conserva el núcleo WLA-0A: reloj, identidades, comandos validados, eventos confirmados, journal, snapshots y recuperación.
- `AutonomyRuntime` confirma `SimulationStepCommitted` y `ObserverInterventionCommitted`. La UI no es autoridad del estado.
- La decisión y consecuencia se evalúan sobre una fotografía coherente del ciclo; no se da ventaja a una criatura por aparecer antes en el diccionario.
- La pestaña **AUTONOMIA** muestra ciclos, agentes, criaturas experimentales, decisiones, memorias y trazas con razones/resultados.
- El runtime avanza automáticamente mientras la aplicación está activa, sin necesitar acciones del jugador. Puede pausarse, avanzar un tick manualmente, guardar y registrar perturbaciones de laboratorio diferenciadas de la conducta autónoma.
- El Observatorio pixel-art y las 12 cámaras/14 conexiones siguen siendo una referencia experimental, no geografía canónica aprobada.

## Qué NO debe confundirse con simulación ya terminada

| Área | Estado en 0.3.0 |
|---|---|
| 180 identidades sociales | Modelos de agente activos en el scheduler; no implica 180 cuerpos ubicados en el mapa |
| Rutinas y motivaciones humanas | Decisiones y progreso abstracto individual; aún no son acciones físicas/productivas en el mundo |
| Presencia física de NPC | No hay coordenadas validadas en el registro; por tanto no se inventan encuentros |
| Relaciones sociales | Se conservan fuentes y co-pertenencia; amistad, afecto, confianza y parentesco no se deducen |
| Criaturas | Cuatro sujetos de prueba aislados; no es spawn canónico ni el bestiario completo |
| Geografía | Grafo de cámaras experimental; pendiente de mapa espacial aprobado |
| Combate/lesiones | No implementados; el sistema se detiene antes de aplicar daño o HP improvisados (requiere SR-09) |
| Reproducción, migración y población ecológica | No implementadas |
| Economía, inventarios, fabricación y mercado | No implementados como dominios persistentes |
| Constructos activos | No implementados en el runtime autónomo |
| Simulación mientras la app está cerrada | No implementada; al pausar/cerrar se guarda, pero todavía no se hace catch-up offline |
| Tiempo de mundo | Los ticks son pasos abstractos; no existe conversión validada a segundos, minutos o días |

Los valores de hambre, fatiga, recursos, humedad, madurez, ruido, daño tisular y regeneración de la cámara son **parámetros de fixture de laboratorio** para probar causalidad. No deben citarse como física, población, tasa metabólica ni geografía canónica.

La categoría de objetivo (`education`, `livelihood`, etc.) es una clasificación heurística auxiliar derivada de texto de origen; no reemplaza el significado original ni se presenta como un hecho añadido al registro.

## Diseño del ciclo de autonomía

1. **Percepción:** recoge solo señales y sujetos detectables con los sentidos disponibles.
2. **Interpretación:** compara observaciones con conocimiento y recuerdos individuales.
3. **Motivación:** considera metas declaradas, tensión, rutina y presiones abstractas de laboratorio.
4. **Alternativas:** genera acciones únicamente cuando existen sus precondiciones.
5. **Arbitraje:** compara utilidad, rasgos, aptitudes conocidas, fatiga y experiencia.
6. **Validación/ejecución:** verifica precondiciones y aplica solo consecuencias implementadas.
7. **Memoria:** registra resultado, origen, confianza e importancia.
8. **Persistencia:** confirma el paso en el journal y mantiene snapshot/recuperación.

La aleatoriedad no elige conductas sin contexto. Solo se usa una resolución estable basada en la semilla del mundo para desempatar puntuaciones casi iguales. Con iguales fuentes y semilla, las pruebas exigen reproducibilidad.

## Cómo probar el laboratorio en la app

1. Abre la pestaña **AUTONOMIA**. El runtime inicia ciclos automáticamente mientras la app está en primer plano.
2. Observa las trazas. Cada entrada muestra agente, acción, razón, candidatos puntuados y resultado.
3. Usa **PASO +1** para ejecutar un ciclo controlado, o **PAUSAR/REANUDAR** para separar observación de intervención.
4. **RUIDO R07** y **DAÑAR HONGO** son intervenciones explícitas del observador. Sus eventos se etiquetan como `observer_intervention`; no se confunden con decisiones autónomas.
5. **GUARDAR** escribe el estado autónomo y el checkpoint del núcleo.
6. La pestaña muestra el número de agentes sin ubicación validada para que no se confunda el modelo cognitivo con la presencia física.

La simulación no necesita una partida ni un jugador para producir decisiones. La app es el observador y el ritmo visual del experimento.

## Estructura importante

- `scripts/simulation/autonomy_runtime.gd` — scheduler, percepción, selección de acciones, ejecución, memoria, aprendizaje y persistencia.
- `scripts/core/system_core.gd` — autoridad de núcleo y confirmación de eventos de dominio.
- `scripts/app/pixel_observatory.gd` — Observatorio y consola táctil de autonomía.
- `tests/test_autonomy.gd` — pruebas headless del ciclo autónomo.
- `data/social/` — Registro Social v0.2.0 y fuentes originales.
- `data/bestiary/` — cinco especies del Piso 1 y CSV de origen.
- `docs/WLA0B_AUTONOMIA_Y_LIMITES.md` — contrato experimental, límites y criterios de ampliación.
- `docs/authority/` — SR-01..SR-15, SR-15 v1.0 y decisiones técnicas.
- `.github/workflows/android.yml` — validación, pruebas Godot y exportación Android Debug.

## Herramientas y compilación

- Godot 4.7.2 Standard + GDScript
- Java 17
- Android SDK platform 35 / build-tools 35.0.1
- NDK 28.1.13356709 / CMake 3.10.2.4988404
- Android arm64-v8a, Compatibility renderer, offline-first

### GitHub

El workflow actual conserva `build/diagnostics/` como artefacto incluso en caso de fallo. Ejecuta cada comprobación por separado para identificar la etapa y el log exactos.

1. Crea un repositorio vacío.
2. Extrae el ZIP y sube su contenido completo a la raíz, incluyendo `.github/`.
3. Haz push a `main` o ejecuta **Actions → World Laboratory - Android Debug → Run workflow**.
4. El workflow ejecuta los validadores Python, importa el proyecto en Godot, ejecuta pruebas de contrato, contenido y autonomía, inicia la escena y exporta una APK Android Debug.
5. Descarga el artefacto `WorldLaboratory-WLA0B-Autonomy-Android-Debug-...` que contiene el APK y el SHA-256.

El entorno de preparación no dispone del binario Godot y no pudo descargarlo por limitación de red. Por tanto, esta entrega **no afirma que la APK ya haya sido compilada**. El workflow es el paso de verificación de motor y exportación real. La APK Debug se firma con un keystore desechable; no es una build de publicación comercial ni de Google Play.

### Validación local

```bash
godot --headless --editor --path . --quit
godot --headless --path . -s tests/test_contracts.gd
godot --headless --path . -s tests/test_content_data.gd
godot --headless --path . -s tests/test_autonomy.gd
python3 tests/python/validate_social_registry_v2.py data/social/social_registry_v0.2.json
python3 tests/python/validate_social_registry_source_v2.py data/social/social_registry_v0.2.json
python3 tests/python/test_social_registry_source_v2.py
python3 tests/python/validate_bestiary_data.py
python3 tests/python/validate_project_payload.py
godot --headless --path . --export-debug "Android Debug" build/WorldLaboratory-WLA0B-Autonomy-debug.apk
```

**Criterio de aceptación:** no declarar WLA-0B validado hasta que `tests/test_autonomy.gd` pase dentro de Godot 4.7.2 y el workflow produzca un APK no vacío con hash. Instalar y probar el ciclo de vida y el rendimiento en un Android físico sigue pendiente.
