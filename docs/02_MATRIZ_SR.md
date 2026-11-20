# Matriz de trazabilidad SR-01 a SR-07

**Propósito:** demostrar dónde se refleja cada SR en la arquitectura de implementación y evitar que el scaffold se presente como cumplimiento completo.

| Documento / principio | Decisión técnica reflejada | Estado real de la base 0.1.0 |
|---|---|---|
| SR-01: existencia e identidad | IDs persistentes separados de nombres/representaciones; entidad lógica antes del asset | Parcial: estructura de IDs inicial; identidad vital completa pendiente |
| SR-01: estado objetivo | World Model separado de memoria/creencias de cada agente | Arquitectura definida; percepción epistemológica completa pendiente |
| SR-01: causalidad | comandos → validación → eventos confirmados → consecuencias | Base de comando/evento; cadenas causales completas pendientes |
| SR-01: tiempo persistente | world_tick + catchup al reabrir | Catchup inicial local; autoridad temporal inviolable no posible offline |
| SR-01: muerte condicional/reencarnación mixta | separar identidad universal, vida y cuerpo | Contrato documentado; no implementado funcionalmente |
| SR-01: narrativa emergente | misiones solo organizan oportunidades derivadas de hechos | Narrative Engine completo pendiente |
| SR-01: información limitada | agentes no acceden directamente al World Model omnisciente | Diseñado; sistema de percepción limitado pendiente |
| SR-02: System Core | kernel local coordina contratos y versiones | Kernel inicial parcial |
| SR-02: Entity Registry | IDs y ámbitos independientes de assets | Estructura inicial parcial |
| SR-02: Cognitive Engine | decisiones emiten comandos, nunca mutan dominio directamente | ciclo rudimentario implementado como prueba, no autonomía completa |
| SR-02: Memory Engine | recuerdos/creencias con fuente y confianza | estructura prevista; memoria rica pendiente |
| SR-02: Causal Engine | efectos derivados y tareas pendientes | interfaz/contrato previstos; motor completo pendiente |
| SR-02: Chronicle | journal append-only + snapshot | escritura y replay básico de cuatro eventos de prueba; transacciones generales pendientes |
| SR-02: Governance | validación por dominio, idempotencia y permisos | validación básica de acciones iniciales |
| SR-03: dimensiones de inteligencia | perfiles de capacidad por especie/individuo | estructura prevista; dimensiones cognitivas completas pendientes |
| SR-03: motivación/emoción | necesidades, personalidad y prioridades diferenciadas | perfil inicial reducido; conflictos motivacionales pendientes |
| SR-03: decisiones imperfectas | información incompleta, riesgo y error trazables | no implementado íntegramente |
| SR-03: memoria | tipos de memoria, origen, momento, confianza y olvido | pendiente salvo traza mínima de prueba |
| SR-03: aprendizaje | experiencia y retroalimentación; no desbloqueo automático | pendiente |
| SR-04: realidad única | un solo World Model compartido por app/observatorio | arquitectura base |
| SR-04: canon/crónica/instancia | el mundo local es una instancia individual offline; no simula multiusuario | capas futuras documentadas; no hay sincronización online |
| SR-04: eventos | scope, visibilidad, autoridad, procedencia y causalidad | contrato de evento inicial |
| SR-04: tiempo durante ausencia | simulación resumida al reabrir | catchup básico implementado como scaffold |
| SR-04: pausa/offline | autoridad local y estado provisional local | mundo individual local; sin canon global |
| SR-05: separación existencia/representación | asset_key opcional, modelos proxy reemplazables | separación documentada y escena proxy |
| SR-05: definición/plantilla/individuo | creación reproducible con seed y definición versionada | generador inicial con seed; Creation Engine completo pendiente |
| SR-05: anatomía/capacidades | capacidad lógica independiente de apariencia | pendiente |
| SR-05: material/objeto | propiedades reales independientes de textura | pendiente |
| SR-05: Asset Factory | GLB, LOD, rigging y biblioteca preparada | pipeline descrito; assets finales inexistentes |
| SR-05: offline-first | runtime sin APIs obligatorias | sin conectividad obligatoria |
| SR-06: no requiere jugador | inicialización sin entidad jugador | scaffold inicia agentes; no crea jugador |
| SR-06: mismo núcleo para juego/observatorio | UI consulta kernel compartido | arquitectura base |
| SR-06: observador pasivo | inspector sin presencia en el mundo | diseño; UI observatoria inicial parcial |
| SR-06: eventos genéricos emergentes | generadores de mecanismos, no misiones por nombre | solo acciones de prueba; generación emergente completa pendiente |
| SR-06: scheduler multiescala | interacción/actividad/ecología/historia | planificado; scheduler inicial básico |
| SR-06: determinismo | seed, versiones, IDs y orden estable | seed inicial; replay exacto pendiente |
| SR-06: pruebas prolongadas | 10/30/100 días, recuperación y escalabilidad | harness inicial; campañas largas pendientes |
| SR-07: leyes generales/naturales | dominios de movimiento, materiales, daño, energía | solo interfaz/prototipo reducido; modelos calibrados pendientes |
| SR-07: Trama/flujo/Resonancias | operaciones con fuente, coste, objetivo, duración y validación | no implementado funcionalmente |
| SR-07: aprendizaje y casting | conocimiento/competencia separados de interfaz | pendiente |
| SR-07: interacción natural-arcana | física/química determinan efectos, no etiquetas elementales | pendiente |
| SR-07: religión y dioses | fe sin bendición automática; deidades reservadas | se conserva como regla de diseño; sin mecánicas implementadas |
| SR-07: lógica antes que VFX | visuales reciben resultados lógicos | principio fijado; VFX no funcional en scaffold |

## Criterio de lectura

- **Arquitectura definida** no significa código terminado.
- **Implementado parcialmente** no significa que haya superado pruebas en Android.
- Ninguna autonomía se considera demostrada por una escena con modelos que se desplazan.
- El paquete original declara explícitamente que los SR son especificaciones, no implementación.
