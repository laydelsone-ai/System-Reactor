# WLA-0B.2 — Contrato de la vertical slice autónoma y límites explícitos

## Propósito experimental

Comprobar que agentes pueden percibir información parcial, generar alternativas, elegir acciones sin órdenes del jugador, aplicar consecuencias, recordar resultados y continuar desde el estado persistido. El Observatorio es un instrumento de lectura; no debe dirigir la simulación para fabricar una historia.

## Separación de dominios

- `SystemCore`: identidad, tiempo, validación, journal y persistencia.
- `AutonomyRuntime`: scheduler, estado cognitivo individual, selección/ejecución y procesos ecológicos de prueba.
- `pixel_observatory.gd`: presentación, control del ritmo y perturbaciones explícitas.
- `WLA0B_AUTONOMY_TRIAL`: rama aislada, no canónica.

## Ciclo por agente

1. Captura una vista sensorial limitada.
2. Recupera recuerdos relevantes, con confianza e importancia.
3. Construye candidatas únicamente si están presentes las precondiciones.
4. Puntúa objetivo, rutina, tensión, descanso, interacción y experiencia.
5. Desempata solo si las puntuaciones son casi iguales mediante un hash estable de semilla/identidad/tick.
6. Ejecuta una sola acción del catálogo actual; registra éxito, rechazo o falta de precondición.
7. Guarda experiencia y memoria individual; los resultados influyen de forma acotada en futuras utilidades.
8. Emite traza y evento persistente.

El agente no lee el estado completo del mundo. La percepción humana solo incluye pares que comparten una misma ubicación marcada explícitamente como validada. Los campos de área de trabajo y hogar no constituyen co-presencia.

## Scheduler

- Presupuesto: hasta 24 decisiones humanas por tick abstracto.
- Los agentes de urgencia (fatiga alta/oferta pendiente) pueden adelantarse en un cupo limitado; el cursor round-robin conserva cobertura de población.
- En ausencia de urgencias, 180 agentes se recorren en ocho ticks.
- Las cuatro criaturas de prueba se evalúan en cada tick. El hongo se procesa como organismo ambiental.
- El tick no equivale a segundos/minutos/días. La app lo programa cada 1.25 s como ritmo de observación, no como escala del mundo.

## Acciones humanas actualmente ejecutables

| Acción | Precondición | Consecuencia limitada |
|---|---|---|
| `advance_motivation` | Motivación fuente no vacía | Incrementa pasos de esfuerzo por categoría y fatiga; no completa metas |
| `address_tension` | Tensión fuente no vacía | Incrementa pasos de investigación; no resuelve la tensión |
| `continue_routine` | Rutina fuente no vacía | Incrementa práctica; no concede dominio ni producción |
| `rest` | Fatiga operativa suficiente | Reduce fatiga abstracta |
| `social_contact` | Pares físicamente presentes en ubicación validada | Recuerdo bilateral del encuentro; no mide confianza/afecto |
| `offer_lesson` | Docente y aprendiz visibles en contexto validado | Crea oferta pendiente, no aprendizaje automático |
| `accept_lesson` / `decline_lesson` | Oferta recibida | Decisión individual; aceptación registra práctica guiada, rechazo no inventa motivo |

Las acciones actuales demuestran arbitraje/memoria pero no son equivalentes a acciones espaciales o económicas. Hasta definir dominios concretos no se debe afirmar que un comerciante ha vendido mercancía o que un artesano ha fabricado un objeto.

## Criaturas y ambiente de prueba

- Rata MON-F1-001: forrajeo, huida y refugio estrecho según sensores y recursos del fixture.
- Escarabajo MON-F1-002: detritivoría y repliegue/defensa condicionados.
- Murciélago MON-F1-004: ecolocalización sensible al ruido, forrajeo y vuelo evasivo.
- Rastrero MON-F1-005: detección, acecho, emboscada y abandono de persecución no viable.
- Hongo MON-F1-003: respuesta fisiológica por daño tisular, humedad, madurez y reserva; nunca agente cognitivo.

Las criaturas y cámaras están colocadas como sujetos/escenario de prueba, no como spawns ni posiciones del mundo real. Sus tasas de hambre, fatiga, humedad, regeneración, recurso y respuesta son valores de fixture, no canon.

## Persistencia

- `SimulationStepCommitted` confirma tick, trazas, cambios de agentes, criaturas, ambiente, procesos, scheduler, métricas y eventos recientes.
- `ObserverInterventionCommitted` registra vibración/daño manual separado de la autonomía.
- Snapshot autónomo con checksum SHA-256 y backup; replay de eventos posteriores al cursor.
- `AutonomyRuntime` no sustituye el journal del núcleo.

## Criterios de prueba

La suite Godot debe comprobar sin intervención del jugador:

- creación de 180 modelos de agente y cobertura round-robin;
- perfiles fuente incompletos permanecen incompletos;
- aptitudes/rasgos/memorias cambian las utilidades de forma individual;
- limitación sensorial por modalidad/ruido;
- decisiones y consecuencias específicas de especie;
- conducta no dependiente del orden de diccionario;
- misma semilla e inputs producen estado/trace idénticos;
- snapshot y replay recuperan agentes, memoria, criaturas y tick.

## Fuera de alcance (pendiente)

Ubicación y desplazamiento de NPC, acciones físicas/productivas, mercado/inventario, relaciones/amistad, reproducción, migración, dinámica poblacional completa, constructos, combate/lesiones, escala temporal civil, niveles de resolución y catch-up offline. Su ausencia debe mostrarse con honestidad, no simularse mediante random walks o eventos escritos.
