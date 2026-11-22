# Hogares, Vivienda y Economía Doméstica

## 1. Unidad doméstica

Un hogar es una unidad de convivencia y/o administración de recursos domésticos. Su identidad es persistente y no depende de que el jugador observe el edificio. Puede cambiar de miembros, dividirse, fusionarse, desplazarse o desaparecer mediante eventos válidos.

## 2. Miembros y funciones

Un hogar puede registrar miembros residentes, residentes temporales, huéspedes, personas a cargo, cuidadores, tutores, ausentes temporales y antiguos miembros. Estos estados no son parentescos. Una persona que trabaja en una posada no es automáticamente miembro del hogar propietario.

Cada relación de convivencia tiene vigencia temporal (`valid_from`, `valid_to`) y causa. Se pueden registrar aportaciones y responsabilidades sin convertirlas en rasgos de personalidad permanentes.

## 3. Recursos domésticos

El hogar puede tener:
- vivienda y derechos de uso;
- objetos y almacenamiento compartidos;
- comida y reservas;
- aportaciones económicas;
- gastos y deudas;
- producción doméstica;
- servicios contratados;
- obligaciones de cuidado;
- mantenimiento y reparación.

Los recursos se administran mediante el ledger económico de SR-10. Este catálogo no añade una moneda, no fija salarios, no crea tesoros ni otorga presupuesto por defecto. La propiedad y la posesión pueden ser distintas.

## 4. Tipos estructurales disponibles

El JSON incluye arquetipos opcionales: unipersonal, dos convivientes, familiar nuclear, familia extensa, multigeneracional, compartido sin parentesco, aprendices/trabajadores, hogar de cuidado, alojamiento temporal y colectivo. Son patrones, no hogares ya existentes ni proporciones demográficas.

## 5. Residencias candidatas de la ciudad

El registro de ciudad señala los siguientes espacios residenciales, todos pendientes de ocupación real y calibración espacial:
- `BLD-COURTYARD-HOUSING` — Viviendas de patio compartido.
- `BLD-WORKERS-HOUSING` — Vivienda de trabajadores.
- `BLD-FAMILY-ROW` — Conjunto de casas familiares.
- `BLD-RENTAL-ROOMS` — Casa de habitaciones de alquiler.
- `BLD-APPRENTICE-HOUSE` — Alojamiento de aprendices.
- `BLD-SMALL-HOMES` — Casas pequeñas independientes.
- `BLD-MIXED-RENTALS` — Edificio mixto y alquiler.
- `BLD-ADVENTURER-LODGING` — Casa de habitaciones para aventureros.

Sus capacidades del catálogo fuente son estimaciones sujetas a calibración, no cupos asignados.

## 6. Asignación de residencia

Antes de asignar un hogar o vivienda, comprobar:
1. existencia y estado operativo de la unidad residencial;
2. capacidad, accesibilidad y condiciones físicas;
3. disponibilidad real y derechos de ocupación;
4. coste, contrato, propiedad o patrocinio cuando corresponda;
5. compatibilidad con historia/condición del personaje;
6. ausencia de ocupaciones incompatibles;
7. ruta transitable;
8. persistencia e idempotencia.

El hogar inicial del jugador puede variar entre mundos/personajes, pero una asignación realizada debe conservarse en esa partida. El sistema no mueve a un NPC al azar cada vez que se abre la aplicación.

## 7. Cambios de hogar

`HouseholdFormed`, `MemberJoinedHousehold`, `MemberLeftHousehold`, `ResidenceAssigned`, `ResidenceVacated`, `HouseholdSplit`, `HouseholdMerged` y `HouseholdDissolved` son nombres de eventos propuestos para el dominio social. Cada evento requiere una causa y validación, no basta la animación o el texto de interfaz.

## 8. Cuidado y dependencia

Se distinguen:
- relación familiar;
- tutela o autoridad de cuidado;
- dependencia material;
- compromiso voluntario;
- deber legal;
- prestación profesional;
- apoyo comunitario.

No se presume que una persona mayor, enferma, menor o discapacitada esté necesariamente en un hogar concreto, ni se presume quién es su cuidador. Las responsabilidades requieren capacidad, tiempo, consentimiento y/o autoridad según proceda.
