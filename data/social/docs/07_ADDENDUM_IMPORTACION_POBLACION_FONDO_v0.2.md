# Addendum v0.2.0 — Importación de los 120 NPC de fondo

**Estado:** actualización de datos subordinada, no enmienda de SR.

## Resultado comprobado
- 60 NPC nombrados preservados sin cambiar sus IDs.
- 120 NPC de fondo importados desde `npc_background_population.json` sin regenerar nombres ni IDs.
- Total: 180 personas.
- Semilla: `20261120`; versión de generador preservada en el JSON.
- 40 grupos de hogar generados por fuente, con 3 miembros cada uno.
- 240 enlaces dirigidos `same_household_member` preservados como co-pertenencia de hogar.

## Lo que significa y lo que no
El archivo fuente declara `household_id` y enlaces `same_household_member`. Se conservan como agrupación doméstica. No permiten concluir parentesco, amistad, afinidad, estatus legal, propiedad, dirección o edificio exacto. Ningún domicilio físico se asigna.

Los 60 NPC nombrados mantienen el estado social v0.1: 1 hipótesis familiar Kall pendiente de aprobación y 4 declaraciones abiertas sin personas fantasma.

## Reglas de identidad
Los IDs `npc_bg_*`, `uid_*`, `life_*`, `body_*`, `cog_*` y `social_*` se importan exactamente. No ejecutar de nuevo un generador sobre una partida existente. Una regeneración solo puede crear una nueva población en un mundo nuevo, con su semilla y versión registradas.
