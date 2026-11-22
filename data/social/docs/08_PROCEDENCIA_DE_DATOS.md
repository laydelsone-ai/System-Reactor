# Procedencia de los datos — Social Registry v0.2.0

La población procede del archivo original `World_Laboratory_NPC_Poblacion_Inicial_v0.1.zip` aportado por el usuario. El ZIP incluye 60 registros nombrados y 120 registros de fondo, además de la población completa de 180 NPC con semilla `20261120`.

El registro v0.2 usa como plantilla social el `social_registry_v0.1.json` del paquete v0.1, importa los 120 registros de fondo y conserva sus IDs/identificadores técnicos. Los 40 `household_id` y las 240 relaciones `same_household_member` provienen directamente de `npc_background_population.json`.

Los archivos fuente usados para reconstruir están dentro de `data/source/`. El archivo `social_registry_v0.1_template.json` se conserva sin modificar. El generador `scripts/build_social_registry_v2.py` reconstruye el registro.

No se deduce parentesco, confianza, amistad, dirección física, edificio, propiedad o estado legal.
