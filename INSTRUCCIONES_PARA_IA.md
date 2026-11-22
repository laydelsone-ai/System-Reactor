# Continuidad de implementación — World Laboratory / Sistema Reactor

## Autoridad

- SR-01..SR-15 son las fuentes normativas. SR-15 v1.0 conserva autoridad técnica.
- La normativa consolidada y la guía maestra están en `docs/authority/`.
- Bestiario, población, registro social, misiones y arte son fuentes subordinadas; no modifican las normas.
- Consulta `docs/WLA0B_AUTONOMIA_Y_LIMITES.md` antes de alterar el runtime.

## Base técnica que no se debe reemplazar

- Motor Godot 4.7.2 Standard + GDScript.
- App Android offline-first.
- `scripts/core/system_core.gd` y módulos WLA-0A son la autoridad base; no crear estado paralelo desde UI.
- Los cambios persistentes atraviesan validación del dominio, evento confirmado, journal y proyección.
- `AutonomyRuntime` es un dominio de simulación que confirma ciclos como eventos; la presentación no escribe estado arbitrario.
- `world_tick` y `event.sequence` son dimensiones distintas.

## Paquete integrado 0.3.10 — WLA-0B.2 Autonomy Trial

La versión 0.3.10 corrige la suite de restauración autónoma: el round-trip JSON puede cambiar el subtipo GDScript de números enteros a float sin cambiar el valor. Las pruebas comparan estados JSON recursivamente por valor numérico exacto, conservando validación de claves, tipos no numéricos y longitudes/orden de arrays. Además cotejan el estado completo y la continuación del siguiente ciclo autónomo usando réplicas aisladas.

- El diagnóstico 45072906863 confirma importación, precargas, contratos y contenido aprobados; en autonomía hubo 94 PASS y 2 FAIL por igualdad estricta int/float en los estados restaurados.
- No se alteró la lógica del runtime ni se convirtieron contadores indiscriminadamente: el cambio está en el contrato de comparación de snapshots JSON.
- Godot 4.7.2 debe volver a ejecutar la suite 0.3.10; no declarar la reparación como aprobada hasta ver Actions verde.

## Límites que no deben ocultarse

- Modelos de 180 personas no significa 180 cuerpos ya colocados en el mapa.
- En el registro fuente actual no hay ubicaciones físicas validadas; no inventar presencias o encuentros.
- Las acciones humanas actuales son esfuerzo/práctica abstracta, no trabajo físico, producción, comercio o finalización de metas.
- Los ticks no tienen conversión de calendario; la app deja de simular al pausar/cerrar y no realiza catch-up offline.
- La rama ecológica y sus parámetros son fixtures de laboratorio, no spawns, mapa, densidad o fisiología canónicos.
- No hay HP, daño, combate ni loot; respetar SR-09 y SR-10.
- No se han implementado los 23 tipos biológicos, constructos, reproducción, migración, economía, Arcana o navegación completa.
- No declarar parser, tests Godot ni APK verificados hasta que CI real termine satisfactoriamente. La versión 0.3.8 incorpora la corrección del parser de intervenciones y las correcciones previas del renderizador; todas deben ser validadas por el motor 4.7.2 en CI.

## Reglas de datos

- No inventar domicilio, parentesco, amistad, afecto, confianza, contrato laboral, presupuesto, propiedad o ubicación.
- Los 40 `household_id` son grupos fuente, no prueba de parentesco.
- Los 240 `same_household_member` expresan co-pertenencia doméstica, no parentesco o amistad.
- El posible vínculo familiar Kall sigue sin resolverse.
- Los campos `null` y ausentes permanecen desconocidos. `aptitudes` y `personality_traits` varían entre el reparto nombrado y la población de fondo; normalizar el tipo no significa asignar perfil.
- Aptitudes 0–100 son referencias funcionales, peligro 1–5 es orientación de campo.
- No derivar HP, daño, velocidad universal, nivel, precio o probabilidades de combate.

## Próximas tareas en orden

1. Definir la geografía/presencia NPC con datos aprobados y procedencia verificable.
2. Reemplazar los pasos abstractos de motivación/rutina por acciones concretas de dominio con coste, precondiciones, resultados y reversibilidad.
3. Implementar relaciones sociales efectivas solo sobre encuentros válidos, con estados diferenciados y evidencia.
4. Ampliar cognición/memoria: creencias de origen, percepción parcial, olvido, inferencia incierta y planificación multietapa.
5. Añadir multi-resolución/catch-up temporal offline y probar determinismo ante distinta frecuencia de paso.
6. Desarrollar ecología, constructos y combate según las SR aplicables.

## CI y entrega

El workflow ejecuta import headless, pruebas de precarga, contratos, contenido y `tests/test_autonomy.gd`, smoke test y exportación Android Debug. Los logs de Godot se conservan como artefacto incluso si falla una comprobación. Ningún archivo se considera APK compilada hasta que se descargue del artefacto generado por una ejecución verde con SHA-256.


## WLA-0B.3.9 — Persistencia autónoma

Los eventos SimulationStepCommitted llevan agent_updates y creature_updates como mapas separados por ID. El replay aplica esos deltas con copias profundas. La prueba de restauración exige confirmar snapshot y replay del evento posterior, y detalla campos discrepantes si el estado no coincide.
