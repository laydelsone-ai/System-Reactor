# WLA-0A — Contrato de implementación y aceptación

**Base normativa:** SR-01 a SR-15 consolidados, corte 2026-11-20.  
**Estado:** implementación inicial propuesta; no declarada validada hasta ejecutar Godot 4.7.2 y pruebas reproducibles.

## 1. Propósito del hito

Entregar una aplicación Android que inicie un mundo local y conserve eventos/estado. El hito se limita al núcleo mínimo y persistencia. No incorpora aún el scheduler o la autonomía del hito WLA-0B.

## 2. Contratos implementados

| Área | Contrato WLA-0A |
|---|---|
| Mundo | Un `world_id` local estable y metadatos versionados |
| Identidad | `entity_id` no se deriva de nombre, modelo, skin ni ubicación |
| Dimensiones de identidad | identidad universal, episodio vital, cuerpo, perfil cognitivo, identidad social, especie y plantilla mantienen semánticas separadas; son opcionales cuando la clase de entidad aún no las necesita |
| Tiempo | `world_tick` entero, monotónico, separado de `event.sequence` |
| Comando | ID idempotente, actor, objetivo, dominio, ámbito, acción, precondiciones, versión, tick y payload |
| Validación | Un comando inválido no añade evento ni cambia el registro |
| Evento | ID, esquema, tipo, mundo, secuencia, tick, participantes, causas, autoridad, procedencia, estado de confirmación, difusión y payload |
| Journal | NDJSON append-only; eventos solo se escriben después de validar el comando |
| Snapshot | estado materializado + cursor del journal + versiones + metadata |
| Recuperación | snapshot vigente; backup si el principal falla; reproyección idempotente de eventos posteriores |
| Diagnóstico | estado del núcleo, reloj, IDs, contadores, cursor y anomalías |

## 3. Flujo de escritura

1. Se recibe un comando tipado.
2. `CommandValidator` comprueba esquema, `command_id`, actor, dominio, ámbito, tick, payload, unicidad e invariantes iniciales de la entidad.
3. El comando inválido se rechaza sin mutación ni evento confirmado.
4. Se crea un evento confirmado con secuencia siguiente.
5. El evento se añade y vacía al journal.
6. La proyección de dominio aplica el evento al `EntityRegistry`.
7. Si la proyección posterior a la escritura falla, se bloquean nuevas escrituras y se exige recuperación desde journal.

El journal es el registro durable de la confirmación. La proyección materializada puede reconstruirse.

## 4. Proyecciones de recuperación implementadas

- `WorldInitialized`: valida metadata y mundo de destino; no añade entidades.
- `EntityRegistered`: vuelve a registrar la entidad en el `EntityRegistry`.

Otros tipos se conservan en el journal, pero no se aplican hasta que exista un proyector y sus pruebas. Esta limitación debe desaparecer al incorporar dominios nuevos; no se permite simular que un evento desconocido fue aplicado.

## 5. Decisiones técnicas locales de esta iteración

Estas decisiones implementan SR-15 sin modificar el canon:

- Almacenamiento archivo-local JSON + NDJSON detrás de `PersistenceEngine`.
- Checksum SHA-256 del texto de payload del snapshot.
- IDs aleatorios opacos para mundo, entidad, comando y evento.
- Un evento `WorldInitialized` al crear un mundo.
- Fixture `diagnostic_fixture` solo para probar el pipeline. No representa población, especie o NPC.
- `world_tick` se inicia en 0 y no avanza en WLA-0A. No se fija calendario ni escala segundos/ticks.
- La UI solo puede generar el comando técnico de fixture; no tiene escritura directa al registro.

## 6. Matriz de pruebas

| Prueba | Resultado requerido |
|---|---|
| Crear mundo | ID estable, metadata, `WorldInitialized` y snapshot |
| Registro válido | un comando, un evento, una entidad |
| Duplicar `command_id` | rechazo sin segundo evento |
| Duplicar `entity_id` | rechazo sin mutación |
| Reabrir tras evento no checkpointed | entidad restaurada por replay |
| Reabrir tras checkpoint | identidad y cursor conservados |
| Snapshot principal corrupto | usar backup y reproyectar eventos posteriores |
| Última línea journal truncada | descartar solo la línea incompleta, avisar y conservar eventos completos |
| Corrupción intermedia o secuencia rota | detener recuperación segura |
| Comando inválido | no añadir evento y no modificar el estado |
| Reloj monotónico | rechazar un world_tick menor y conservar el valor anterior |

## 7. Aceptación pendiente fuera de CI

- Abrir en Android físico.
- Crear mundo y registrar fixture.
- Forzar cierre del proceso desde el sistema operativo.
- Reabrir y verificar el mismo `world_id`, `entity_id`, evento y secuencia.
- Repetir tras checkpoint y durante un cierre abrupto simulado.
- Registrar versión de Android, dispositivo, commit, APK SHA-256 y logs.

Un build que exporta el APK no demuestra por sí mismo que la aplicación funciona correctamente en el dispositivo.
