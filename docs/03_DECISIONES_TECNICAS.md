# Registro de decisiones técnicas (ADR)

| ID | Decisión | Motivo | Consecuencia / estado |
|---|---|---|---|
| ADR-001 | Godot 4.7.2-stable Standard | motor 3D ligero, escenas 2.5D, export Android y GDScript | fijado para reproducibilidad; 4.8 beta excluida |
| ADR-002 | GDScript; sin C# en v1 | evitar experimentalidad/limitaciones C# Android y simplificar CI | revisable solo con benchmark/razón concreta |
| ADR-003 | Renderer Compatibility como base | prioriza compatibilidad Android en primer prototipo | validar en dispositivo real; comparar con Mobile luego |
| ADR-004 | 3D ortográfico isométrico | da modelos 3D con lectura visual 2.5D | no usar TileMap 2D como autoridad de mundo |
| ADR-005 | Kernel modular local único | no duplicar reglas entre observatorio y futuro juego | módulos GDScript en un solo proceso |
| ADR-006 | Persistencia JSON snapshot + NDJSON append-only | sin plugins nativos ni servidores; fácil auditar | vigilar crecimiento, migrar storage si benchmarks lo requieren |
| ADR-007 | Catchup al reabrir | respeta continuidad temporal sin mantener Android despierto | UTC local estima el lapso; anomalías marcadas |
| ADR-008 | Hora mundial en ticks enteros | separación entre cronología del mundo y reloj visual/FPS | ratio inicial 1:1, configurable |
| ADR-009 | PRNG con seed persistida | reproducibilidad de experimentos | almacenar también versión de reglas/generador y orden de ejecución |
| ADR-010 | GLB/glTF para modelos | formato de intercambio 3D común y pipeline soportado por Godot | sin modelos artísticos finales en este paquete |
| ADR-011 | Assets preparados, no generación 3D compleja en móvil | coste, batería, memoria y validación anatómica | variantes por parámetros y biblioteca aprobada |
| ADR-012 | Sin API generativa obligatoria | autonomía básica y offline real | planificación determinista/estructurada como base |
| ADR-013 | APK Debug como artifact CI | descarga e instalación de pruebas sin gestionar keystore privado | release firmado queda para etapa posterior |
| ADR-014 | Sin permiso de Internet en export preset | requisito offline-first | no hay sincronización ni servicios externos en esta app inicial |

## ADR temporal: límite conocido

El teléfono apagado no ofrece un reloj monotónico accesible que continúe midiendo el tiempo durante un apagado. Sin servidor externo, el catchup después de reinicio debe estimarse usando hora UTC del sistema y registrar anomalías. La hora local no se convierte en «verdad del universo»: solo aporta una duración candidata; el Kernel la acepta/rechaza y transforma en world ticks.

## Decisiones pendientes de medición

- máximo de entidades lógicas y renderizadas según el dispositivo;
- FPS objetivo y presupuesto de memoria;
- intervalos de decisión por perfil de agente;
- intervalos de snapshots y segmentación del journal;
- elección futura de base de datos embebida si el JSON/NDJSON deja de cumplir;
- tamaño, LOD, esqueleto, número de materiales y animaciones de los assets definitivos;
- fidelidad exacta/por aproximación para replay de procesos agregados.
