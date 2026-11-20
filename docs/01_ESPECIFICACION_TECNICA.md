# Especificación técnica de implementación — World Laboratory Android

**Documento:** WLA-TECH-001  
**Versión:** 0.1.0  
**Fecha:** 19-11-2026  
**Estado:** propuesta técnica derivada de SR-01 a SR-07 y de las decisiones explícitas del usuario. No es una enmienda de los SR.

---

## 1. Propósito y alcance

Construir en Android un World Laboratory offline-first que permita inicializar un universo sin jugador humano, ejecutar agentes autónomos, observar acontecimientos objetivos y conservar la continuidad al cerrar y reabrir la aplicación.

El laboratorio no será una simulación paralela al futuro RPG. Sus contratos de entidades, comandos, eventos, tiempo y causalidad deberán poder convertirse en la base del runtime del juego. La interfaz del Observatorio es una vista sobre el mismo estado; no tiene permiso para decidir resultados.

Esta especificación establece el primer mapa técnico y una implementación inicial reducida. La ambición de mundo grande se conserva en la arquitectura, pero el rendimiento real en el teléfono debe medirse antes de fijar máximos definitivos. El scaffold inicial genera 64 agentes con representación humanoide provisional y 24 agentes de tipo criatura (88 entidades lógicas en total). Es una población de prueba acotada para validar el flujo local; la arquitectura prevista es Large y los máximos definitivos se fijarán por medición en Android.

### 1.1 Decisiones confirmadas

| Área | Decisión |
|---|---|
| Plataforma de ejecución | Android |
| Red | No necesaria; funcionamiento completamente offline |
| Tiempo | Catchup al volver a abrir |
| Visualización | 2.5D isométrica, construida con escena 3D |
| Players | Agentes autónomos; no jugador humano inicial |
| Escala | Large: regiones, población y ecosistemas con niveles de resolución |
| Representación | Modelos 3D; assets preparados y validados, no generación de mallas complejas en runtime |
| Distribución de fuente | ZIP para subir a GitHub |
| Compilación | GitHub Actions genera APK Debug |
| Datos | Persistencia local; sin base de datos/servidor remoto |

### 1.2 Supuestos técnicos adoptados

1. Godot 4.7.2-stable Standard + GDScript. No se usa Godot 4.8 beta.
2. Renderizador Compatibility como base inicial para priorizar compatibilidad Android; se comparará con Mobile cuando haya pruebas en el dispositivo.
3. Cámara ortográfica inclinada, movimiento sobre plano X/Z y altura Y para producir la presentación 2.5D.
4. Primer ritmo de prueba: 1 segundo real equivale a 1 segundo del mundo. Será configurable después; SR-06 no fija una conversión normativa.
5. La instancia individual instalada en el teléfono es autoridad local de ese mundo. No representa un canon compartido entre varios dispositivos.
6. El primer escenario técnico contiene una región de muestra, agentes y criaturas de prueba. No equivale aún a la ciudad principal ni al primer piso definitivo.
7. Se evita una dependencia SQLite o GDExtension en la primera entrega. Se usará JSON/NDJSON con snapshots y recuperación; si la carga real lo exige, se evaluará una base embebida Android compatible sin alterar los contratos de dominio.

---

## 2. Plataforma y pipeline

### 2.1 Motor

**Godot 4.7.2-stable Standard** con GDScript. La rama 4.8 aparece como beta en el archivo oficial consultado el 19-11-2026; se fija 4.7.2 estable para evitar que una versión preliminar cambie el comportamiento del proyecto. Fuente: https://godotengine.org/download/archive/.

La documentación oficial de exportación Android de Godot 4.7 indica OpenJDK 17 como versión recomendada, Android SDK Platform-Tools 35 o posterior, Build-Tools 35.0.1, Platform 35, Command-line Tools, NDK r28b y CMake 3.10.2.4988404. El workflow instala estas dependencias en un runner Ubuntu. Fuente: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html.

### 2.2 Render y representación

- Escena 3D real con cámara ortográfica isométrica.
- Escenario modular por regiones/sectores.
- Modelos GLB/glTF como formato de importación preferente para personajes, criaturas y objetos.
- LOD/visibilidad y carga por región; no todos los modelos deben estar instanciados al mismo tiempo.
- MultiMeshInstance3D o equivalentes para vegetación/elementos repetidos cuando corresponda.
- Las primitivas incluidas en el scaffold son proxies temporales, no assets finales.
- La posición, anatomía, capacidades, material, daño y estado lógico proceden de los datos de dominio; el modelo solo los representa.

### 2.3 GitHub Actions

En cada push a `main` y mediante ejecución manual:

1. Checkout del repositorio.
2. Instalar Godot 4.7.2 Standard y plantillas.
3. Instalar JDK 17 y Android SDK.
4. Importar/validar el proyecto en modo headless.
5. Exportar el preset `Android Debug` a APK.
6. Publicar el APK como artifact.

El APK de CI será de depuración. No se guardan contraseñas, keystores privados ni credenciales dentro del ZIP. Una futura publicación firmada requiere un keystore de release guardado en GitHub Secrets; no se necesita para instalar un APK de prueba.

---

## 3. Arquitectura lógica

Los motores de SR-02 son límites de responsabilidad. No se convierten en microservicios ni procesos separados en Android.

```text
Android App / God View 2.5D
          │ (consultas y controles de observación)
          ▼
     Simulation Kernel
   ┌──────┼─────────┐
   ▼      ▼         ▼
Scheduler Cognition Command Processor
   │      │         │
   │      ▼         ▼
   │   Memory     Domain Validators
   │      │         │
   ▼      ▼         ▼
World Model / Entity Registry / Creation Engine
          │
          ▼
Causal Engine → Chronicle / Event Journal
          │
          ▼
Local Snapshots + Recovery
```

### 3.1 Responsabilidad única por dominio

| Dominio | Responsable de | No debe hacer |
|---|---|---|
| System Core / Kernel | coordinar comandos, tiempo, versiones y transacciones | decidir arbitrariamente la vida de un NPC |
| Entity Registry | IDs, identidad, continuidad, vínculos y ámbito | usar nombre/modelo visual como identidad |
| World Model | estado objetivo consultable | convertirse en memoria omnisciente de los agentes |
| Cognitive Engine | percepción disponible, motivación, opciones, planes y comandos | escribir directamente el estado del mundo |
| Memory Engine | recuerdos, creencias, conocimientos, confianza y fuente | alterar los hechos objetivos históricos |
| Evolution Engine | aprendizaje, adaptación, transformación y herencia | convertir deseos en capacidades sin mecanismo |
| Causal Engine | dependencias y consecuencias pendientes | inventar resultados sin resolverlos |
| Narrative Engine | oportunidades/objetivos derivados de hechos | crear hechos retroactivos o forzar aceptación |
| Social Engine | relaciones, grupos, instituciones y cultura | conceder conocimiento automático a todos |
| Ecology Engine | poblaciones, recursos, migración y procesos | depender de la cámara o del jugador |
| Creation Engine | definiciones, plantillas, individuos, objetos y assets | confundir representación con existencia |
| Chronicle Engine | eventos confirmados, snapshots, procedencia y auditoría | sobrescribir hechos silenciosamente |
| Validation & Governance | precondiciones, autoridad, invariantes y concurrencia | aceptar un hecho solo porque quedó registrado |
| Observatory | consulta y presentación pasiva | intervenir en decisiones o probabilidades |

### 3.2 Autoridad de escritura

Todo cambio persistente se realiza mediante un comando tipado. El agente solo propone. El procesador competente comprueba actor, capacidad, recursos, precondiciones, ámbito y versión del estado; si es válido, aplica el cambio y crea evento confirmado. Se serializan las operaciones que compiten por un objeto único, recurso limitado o ubicación exclusiva.

---

## 4. Contratos de datos

Los contratos se versionan y se serializan sin referencias directas a nodos visuales de Godot.

### 4.1 Identidad y entidad

La entidad de dominio tendrá, como mínimo:

```json
{
  "entity_id": "ent_...",
  "entity_kind": "individual",
  "universal_identity_id": "uid_...",
  "life_episode_id": "life_...",
  "body_id": "body_...",
  "cognitive_profile_id": "cog_...",
  "social_identity_id": "social_...",
  "species_definition_id": "species_...",
  "template_id": "template_...",
  "scope": "world_local",
  "asset_key": "characters/placeholder_humanoid",
  "state_version": 1
}
```

Los campos de vida, cuerpo, cognición y posición pueden cambiar sin que el nombre o el asset determine continuidad. Los estados vitales no deben tratarse como una única enumeración mutuamente excluyente: herida, incapacitación, muerte, reanimación, reencarnación y transformación pueden requerir dimensiones separadas conforme SR-01/SR-03.

### 4.2 Perfil de agente

Cada agente guarda un perfil apropiado a su especie y capacidad:

- necesidades y su evolución temporal;
- motivaciones y prioridades en conflicto;
- rasgos de personalidad como tendencias, no diálogos;
- emociones con efectos sobre atención, memoria y decisión;
- capacidades físicas, sensoriales y cognitivas;
- conocimientos, creencias e hipótesis con procedencia;
- recuerdos episódicos, semánticos, procedimentales, emocionales, sociales, espaciales y prospectivos;
- relaciones asimétricas;
- objetivos, compromisos y planes;
- próxima evaluación programada.

No se impone cognición humana a todas las especies. El agente inicial del scaffold es deliberadamente más simple y no se declara inteligencia completa.

### 4.3 Decision Trace

Cada decisión de prueba conservará:

```json
{
  "decision_id": "dec_...",
  "agent_id": "ent_...",
  "world_tick": 12345,
  "available_observations": ["obs_ref_..."],
  "beliefs_used": ["belief_ref_..."],
  "motivations_ranked": ["survival", "rest"],
  "alternatives": ["eat", "forage", "rest", "patrol"],
  "selected_action": "forage",
  "capability_check": "passed",
  "command_id": "cmd_...",
  "execution_result": "confirmed",
  "event_id": "evt_...",
  "learning_update": []
}
```

Esta traza es requisito de auditoría para poder distinguir autonomía de una secuencia guionizada. No hace falta guardar razonamiento privado textual; deben guardarse hechos de decisión estructurados y reproducibles.

### 4.4 Comando

Campos mínimos: `command_id`, `actor_id`, `target_ids`, `domain`, `scope`, `action_type`, `preconditions_observed`, `resource_requirements`, `state_version`, `decision_id`, `correlation_id`, `created_at_world_tick`.

El mismo `command_id` no puede producir el mismo efecto dos veces. La idempotencia es requisito especialmente importante en recuperación tras cierre inesperado.

### 4.5 Evento

Cada evento persistente conserva:

- `event_id`, `schema_version`, `event_type`, `world_tick`;
- ubicación/región y participantes/entidades afectadas;
- causa/antecedentes y consecuencias derivadas;
- comando o proceso originador;
- resultado y ámbito;
- autoridad que lo confirmó;
- versión de reglas/definiciones;
- procedencia (agente, proceso de sistema, intervención administrativa, prueba o contenido authored);
- referencias al snapshot y Decision Trace cuando proceda.

**Interpretación técnica de estados SR-04:** para no confundir hecho con difusión, el contrato separa `confirmation_status` (propuesto/provisional/validado/confirmado/rechazado), `dissemination_status` (no difundido/difundido), `visibility` (privado/restringido/público) y `disposition` (normal/aislado/compensado). Esta es una forma de implementación compatible con el principio de SR-04 de que un hecho confirmado puede seguir secreto y que un rumor difundido no prueba su contenido. No modifica el texto de SR-04.

### 4.6 Representación visual

`asset_key` es opcional. Un modelo puede faltar o no cargarse sin invalidar una entidad lógica. El registro visual resuelve la clave a un GLB, variante, esqueleto, animación y LOD; nunca crea identidad por sí mismo.

---

## 5. Ciclo de simulación

El Kernel aplica este orden lógico:

1. Determinar el siguiente punto de evaluación temporal.
2. Actualizar reloj del mundo.
3. Actualizar procesos ambientales/temporales pertinentes.
4. Construir percepción limitada para agentes elegibles.
5. Evaluar necesidades, motivaciones, creencias y objetivos.
6. Generar alternativas y planificar dentro de capacidades/presupuesto.
7. Emitir comando.
8. Validar precondiciones, recursos, permisos y autoridad de dominio.
9. Resolver físicamente/social/económica/biológicamente la operación.
10. Confirmar y registrar evento.
11. Programar consecuencias causales.
12. Actualizar conocimiento/memoria de quienes puedan percibir o recibir información.
13. Actualizar métricas y snapshot según política.

Una intención no garantiza ejecución. Un rechazo también puede dejar una traza y alimentar aprendizaje sin convertir el intento en un hecho exitoso.

---

## 6. Scheduler y mundo grande

### 6.1 Niveles de resolución

Se mantienen los cuatro niveles de SR-06 dentro de una sola cronología:

| Nivel | Ejemplos | Resolución |
|---|---|---|
| Interacción | combate, movimiento cercano, impactos | alta y de corta duración |
| Actividad | rutinas, trabajo, viajes, conversaciones, expediciones | evaluaciones programadas |
| Ecología/población | reproducción, migración, supervivencia, disponibilidad | lotes y procesos agregados |
| Historia | evolución social, generaciones, cambios regionales | eventos/procesos de largo plazo |

### 6.2 Priorización

Se prioriza por urgencia, riesgo, impacto causal, obligaciones, entidades afectadas, compromisos pendientes y necesidad de precisión. La distancia a la cámara no decide la existencia ni la actualización.

### 6.3 Escala y representación

- El mundo se divide en regiones y sectores con identidad lógica estable.
- El scheduler procesa eventos y tareas próximas, no cada NPC en cada frame.
- Las entidades fuera de la región activa permanecen simuladas en nivel de actividad/ecología/historia.
- La vista 2.5D carga modelos de la región observable y libera/agrupa los demás.
- Poblaciones grandes pueden agruparse mientras el agregado conserve recursos, individuos singulares y consecuencias relevantes.
- El cambio de resolución no puede inventar viajes, fabricar recursos, borrar daños o cambiar ganadores retroactivamente.

En la primera iteración, el scheduler usa una cola simple/escaneo de próximas fechas. Si los benchmarks lo exigen, se cambia internamente a heap/priority queue sin modificar el contrato de agentes y eventos.

---

## 7. Catchup y autoridad temporal local

### 7.1 Política

La aplicación no necesita mantenerse viva en segundo plano. Al cerrar o suspender se guarda el mundo; al reabrir se estima el tiempo ausente y se procesa por eventos/tareas resumidas, no por fotogramas perdidos.

### 7.2 Fuente temporal y limitación honesta

En un mundo offline individual no hay servidor externo que certifique el tiempo transcurrido. Por tanto:

- `world_tick` es la cronología autoritativa del universo;
- la hora UTC del sistema se usa solamente para estimar el intervalo entre checkpoints;
- un retroceso del reloj se registra como anomalía y no produce tiempo negativo;
- una ausencia extraordinariamente larga se procesa en lotes y queda marcada para auditoría;
- un cambio deliberado del reloj del dispositivo no puede detectarse con garantía absoluta después de apagar el teléfono.

Esto es una limitación de autoridad local, no una promesa de tiempo global antimanipulación. Un futuro canon compartido necesitaría autoridad común en línea, expresamente fuera del alcance de esta primera app.

### 7.3 Pausa

La pausa manual significa que el mundo queda detenido incluso durante la ausencia. Al reanudar, se restablece el punto de referencia para no acumular catchup durante la pausa. Cerrarla sin pausa mantiene catchup habilitado.

### 7.4 Ejecución del catchup

Se calcula el intervalo pendiente y el Scheduler salta entre tareas programadas. Procesos cercanos reciben resolución fina; viajes, economía y ecología pueden avanzar por lotes con resultados compatibles. No se resuelve «ganó» o «perdió» sin comprobar capacidades, recursos, riesgos y tiempo.

---

## 8. Persistencia local y recuperación

### 8.1 Estrategia inicial

- Snapshot JSON versionado del estado materializado.
- Diario append-only NDJSON para acontecimientos persistentes.
- Checkpoint periódico y al pausar/salir.
- Copia de respaldo del último snapshot válido.
- IDs idempotentes para comandos.
- `save_schema_version`, `rules_version`, `generator_version` y `seed` persistidos.

No se guarda cada frame. Se guardan cambios persistentes y hechos significativos. El diario se segmentará por bloques/periodos cuando el volumen haga necesario compactar o archivar.

### 8.2 Recuperación

1. Leer snapshot vigente; si falla, intentar backup.
2. Validar versión y estructura.
3. Leer eventos posteriores al cursor del último snapshot.
4. Reaplicar de forma idempotente únicamente los tipos de evento cuyo contrato tenga proyección de recuperación implementada.
5. Ignorar una línea NDJSON truncada, dejando diagnóstico; no aplicar parcialmente un evento.
6. Restaurar seed/estado del generador y secuencia de IDs.
7. Calcular catchup desde la última marca temporal válida.
8. Ejecutar tareas pendientes y guardar nuevo snapshot.

**Límite de 0.1.0:** el scaffold incluye lectura/reaplicación básica para `FoodConsumed`, `ResourceGathered`, `RestCompleted` y `AgentMoved`, mediante campos de estado posterior incluidos en el evento. No constituye todavía recuperación transaccional general de todos los dominios. Las migraciones de esquema son explícitas. Una actualización del motor no reescribe silenciosamente eventos históricos.

---

## 9. NPC Autonomous Runtime

### 9.1 Perfil cognitivo

No se reduce a una puntuación de inteligencia. Se estructura por capacidades de percepción, atención, reconocimiento, comprensión, memoria de trabajo, razonamientos específicos, planificación, aprendizaje, creatividad, comunicación y metacognición cuando correspondan.

### 9.2 Arquitectura offline

La combinación se adapta a cada especie/individuo: comportamientos reactivos para respuestas inmediatas, utility/prioridades para conflictos de motivación, GOAP para objetivos, HTN para procesos largos, memoria estructurada y aprendizaje acotado por resultados. No se exige aplicar todos los métodos a cada criatura.

Los modelos generativos quedan opcionales y fuera de la ruta crítica. Si se integran más adelante, solo proponen diálogo, hipótesis, estrategias o planes estructurados; nunca escriben estado ni confirman hechos.

### 9.3 Individualidad

Mismo hecho observado no implica misma respuesta. La decisión depende de información disponible, memoria, relaciones, salud, personalidad, necesidades, capacidades, recursos, obligaciones y contexto. No se revela al agente el World Model completo.

---

## 10. Creation Engine, modelos y assets

### 10.1 Separación

Definición → plantilla → individuo → variante → representación. Miles de individuos pueden compartir una plantilla sin compartir identidad ni trayectoria.

### 10.2 Assets

- GLB/glTF como paquete de modelos 3D.
- Rigging y animaciones validadas en desarrollo, no construidas arbitrariamente en runtime.
- Materiales y objetos con propiedades lógicas separadas de shaders/VFX.
- Variantes generadas desde parámetros limitados y assets aprobados.
- LOD, texturas comprimidas y carga por región para Android.
- Las entidades excepcionales pueden usar assets específicos, pero su singularidad lógica no obliga a un modelo exclusivo.

### 10.3 Validación

El asset debe concordar con escala, anatomía, articulaciones y capacidades. Un modelo con alas no implica vuelo; una espada visualmente enorme no recibe masa sin propiedad lógica. La capa de animación no puede producir resultados de daño.

---

## 11. Leyes naturales y arcanas — implementación por capas

SR-07 describe un conjunto amplio de leyes. No es razonable afirmar que todas están completas en el primer prototipo.

Primera implementación verificable:

1. Espacio 3D, posición, distancia, colisión básica y movimiento.
2. Masa/volumen simplificados donde sean relevantes.
3. Integridad/daño físico básico y estados corporales.
4. Materiales con un conjunto pequeño de propiedades explícitas.
5. Fuentes y consumo de recursos.
6. Interfaces de operación arcana con fuente, coste, objetivo, alcance, duración, condiciones y validación, aunque el catálogo funcional de hechizos llegue después.

No habrá tabla elemental universal. Las interacciones dependerán de propiedades y condiciones. La Trama no tiene voluntad propia; las Resonancias son principios/patrones abiertos; la afinidad no concede poder automáticamente. Dioses y bendiciones siguen reservados: religión/fe no otorga poderes por sí sola.

La lógica del fenómeno calcula causa y consecuencias; los VFX solo lo representan.

---

## 12. Observatory / God View

La interfaz inicial deberá:

- mostrar la región y agentes visibles;
- mostrar hora del mundo, estado de pausa, población y métricas;
- consultar cronología y eventos por tipo/entidad/región;
- seleccionar un evento y centrar la cámara en su ubicación cuando existan coordenadas;
- inspeccionar identidad lógica, estado, necesidades, conocimiento/memoria autorizados y última traza de decisión;
- permitir seguimiento de entidad;
- mantener observación pasiva por defecto.

La intervención administrativa se desarrollará aparte, desactivada en el modo ordinario y registrada en el Chronicle.

---

## 13. Pruebas y criterios de aceptación

### 13.1 Pruebas de contratos iniciales

- Catchup: un intervalo positivo avanza el reloj; un retroceso no crea tiempo negativo y genera anomalía.
- Reproducibilidad: misma seed + mismas versiones produce los mismos individuos iniciales.
- Idempotencia: repetir un command_id no vuelve a consumir alimento ni aplicar un efecto.
- Autoridad: command processor valida recursos y capacidades antes de mutar estado.
- Evento: confirmación y difusión pueden divergir; un evento secreto puede estar confirmado.
- Representación: entidad lógica persiste aunque asset_key no resuelva.
- Persistencia: snapshot puede recuperarse desde backup si el vigente se corrompe.

### 13.2 Pruebas de autonomía futuras obligatorias

- Eliminar jugador; el mundo sigue.
- Desactivar Narrative Engine; las acciones cotidianas siguen produciéndose.
- Desactivar cualquier proveedor generativo; el núcleo mantiene movimiento, supervivencia, recursos y persistencia.
- Cambiar relación/conocimiento de dos agentes ante el mismo hecho; sus decisiones pueden diferir y la traza explica por qué.
- Eliminar capacidad/recurso; la acción correspondiente deja de ser posible.
- Alterar un hecho y observar consecuencias diferentes.
- Repetir experimento determinista con seed/orden registrado.
- Quitar una misión preparada; no debe impedir que emerja un proceso equivalente desde hechos si existen condiciones.
- Probar condiciones no incluidas en escenarios escritos.
- Comprobar que la historia no contiene eventos authored disfrazados de emergentes.

### 13.3 Rendimiento

No se fija todavía un máximo universal de NPC ni un presupuesto absoluto de RAM/CPU. En el teléfono se medirán: tiempo real por día simulado, decisiones/s, eventos/s, duración del catchup, RAM, almacenamiento, tiempo de carga, FPS de interfaz y frecuencia de stutter. Se realizarán pruebas a 100, 500 y 1.000 entidades lógicas, separando entidades renderizadas de simuladas. Los máximos se aprobarán por medición, no por estimación.

---

## 14. Etapas técnicas de ejecución

Estas etapas son hitos internos de implementación, no nuevos documentos normativos SR ni ampliación de las fases 0–5.

| Hito | Entrega verificable |
|---|---|
| WLA-0A | Proyecto Android abre, exporta y guarda localmente |
| WLA-0B | Kernel, reloj, comandos, eventos, snapshots y recuperación |
| WLA-1A | Ciclo de agentes, memoria y Decision Trace |
| WLA-1B | Scheduler multiescala y catchup con procesos causales |
| WLA-2A | Región 2.5D, modelos y observatorio pasivo |
| WLA-2B | Recursos, expediciones, ecología y eventos emergentes |
| WLA-3 | Pruebas prolongadas, replay y ramas experimentales |

La base incluida corresponde a un scaffold para iniciar WLA-0A/0B. No certifica el cierre de esos hitos.

---

## 15. Riesgos y decisiones no resueltas

1. Tiempo offline confiable después de reiniciar: la app local no puede autenticar la hora sin autoridad externa.
2. Escala móvil: falta benchmark en el teléfono real y con assets reales.
3. Modelos: no existe biblioteca artística final ni pipeline de rigging aprobado para este RPG.
4. Física/química/magia: SR-07 exige modelos calibrados, aún por definir y probar.
5. Persistencia: JSON/NDJSON es una base inicial; puede necesitar migración a almacenamiento embebido al aumentar población/historia.
6. Replay: todavía debe definirse fidelidad exacta vs aproximada para cada tipo de proceso agregado.
7. Autonomía: es el objetivo principal, pero sigue sin demostrarse.

---

## 16. Regla de control de cambios

- SR-01 a SR-07 mantienen autoridad normativa.
- Este documento decide únicamente tecnología y traducción técnica dentro de esas leyes.
- Si una implementación parece contradecir un SR, se detiene y se documenta la discrepancia; no se adapta el SR silenciosamente.
- Nuevos SR o enmiendas requieren decisión explícita del usuario.
- Cada cambio técnico debe indicar versión, motivo, impacto en persistencia y pruebas de regresión.
