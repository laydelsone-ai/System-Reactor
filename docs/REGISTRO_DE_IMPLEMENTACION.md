# Registro de implementación — World Laboratory / Sistema Reactor

## Autoridad y principio de implementación

SR-01..SR-15 son la única autoridad normativa. Este registro describe el estado de la implementación y no crea reglas nuevas del universo. UI, observador, arte, texto o modelos generativos no tienen autoridad sobre el estado objetivo.

## WLA-0A — núcleo

Se conserva el proyecto base: `SystemCore`, identidad, reloj monotónico, comandos validados, eventos confirmados, journal append-only, snapshots, recuperación y diagnóstico.

## WLA-0A.2 — Observatorio pixel-art

Se añade una presentación táctil isométrica experimental, cinco fichas del Piso 1, Registro Social v0.2.0 y 12 plantillas de misión. El plano de 12 cámaras/14 conexiones es referencia visual y no geografía canónica. El arte no modifica SR-15 v1.0.

## WLA-0B.2 — Autonomy Trial (0.3.0)

### Runtime humano

`AutonomyRuntime` instancia 180 modelos de agente a partir de los registros fuente. Conserva 180 motivaciones, 60 tensiones y 120 rutinas mediante los campos `motivation_summary`, `current_tension_summary` y `routine_summary`. No equivale a materializar 180 cuerpos con coordenadas. Se conserva desconocido todo campo sin fuente: rasgos, aptitudes, household, identidad de episodio/cuerpo y presencia física no se completan por inferencia.

Cada agente recibe observaciones limitadas, compara alternativas y selecciona entre acciones cuyas precondiciones existen. La utilidad usa motivación, tensión, rutina, presión abstracta, fatiga, rasgos y aptitudes conocidas, memoria y experiencia. Las acciones actuales registran esfuerzo o práctica; no declaran metas completadas ni producen inventarios, dinero o relaciones de confianza.

El scheduler procesa hasta 24 agentes humanos por tick abstracto. El recorrido completo de 180 agentes requiere ocho ticks en el caso base de prueba. La priorización por urgencia se combina con cursor de recorrido. Los ticks no equivalen a tiempo civil.

El dominio social solo permitirá encuentros y enseñanza cuando la presencia física de ambos agentes esté respaldada por una ubicación explícitamente validada. Ningún registro actual proporciona esa presencia, por lo que no hay socialización fabricada a partir de etiquetas de área de trabajo o co-pertenencia doméstica.

### Runtime ecológico

Cuatro individuos de prueba (rata, escarabajo, murciélago, rastrero) ejecutan políticas condicionadas a sus especies, sentidos, recursos y geometría. Una colonia de hongo farolero es un proceso biológico ambiental sin cognición. Los sujetos y las 12 cámaras de prueba están aislados en la rama `WLA0B_AUTONOMY_TRIAL`; no representan apariciones ni geografía del mundo canónico.

El escenario valida, entre otras cosas, evasión de la rata hacia una grieta, seguimiento del rastrero y abandono cuando su anatomía no permite continuar, alimentación del escarabajo y del murciélago y liberación fúngica condicionada por parámetros de prueba. No hay daño/HP ni combate (SR-09 aún requerido).

### Persistencia y observación

Cada ciclo confirma `SimulationStepCommitted`. Las perturbaciones del observador confirman `ObserverInterventionCommitted`, manteniendo separado lo que decidió el agente de lo que provocó la persona que prueba el laboratorio. Snapshot y replay reconstruyen el estado autónomo.

La UI ofrece ejecución automática, pausa, paso manual, estímulos y guardado. La aplicación no necesita instrucciones del jugador para que el scheduler emita decisiones. El avance se detiene durante pausa/cierre; catch-up con la app cerrada no está implementado.

## Validación

| Control | Estado |
|---|---|
| Validadores Python del registro social | Pasan en entorno local |
| Reproducción exacta del Registro Social desde sus fuentes | Pasa en entorno local |
| Cotejo del bestiario Piso 1 contra CSV | Pasa en entorno local |
| Preflight de archivos, JSON, assets y referencias | Pasa en entorno local |
| Parser/import de Godot 4.7.2 | Pendiente CI |
| Pruebas Godot de núcleo y contenido | Pendiente CI |
| Pruebas Godot WLA-0B de autonomía | Incluidas; pendiente CI |
| Exportación Android Debug | Pendiente CI |
| Instalación, rendimiento y persistencia en Android físico | Pendiente QA de dispositivo |

## Próxima ampliación necesaria

1. Definir y validar un modelo espacial para la población humana antes de activar encuentros.
2. Convertir intents abstractos en acciones de dominio concretas (movimiento, trabajo, uso de recursos y transacciones) con validación y consecuencias.
3. Ampliar memoria, aprendizaje y cognición con pruebas de causalidad, falsas creencias, percepción parcial y planificación a más pasos.
4. Implementar niveles de simulación y catch-up offline con equivalencia temporal, límites y reproyección segura.
5. Ampliar ecosistemas, reproducción, migración y constructos según contratos; combate solo con SR-09.
