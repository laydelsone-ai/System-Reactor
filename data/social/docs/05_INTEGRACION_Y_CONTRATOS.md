# Integración Técnica y Contratos del Dominio Social

## 1. Identificadores

Los 60 NPC conservan `npc_0001` a `npc_0060`. El registro de ciudad anterior utilizaba identificadores legibles (`NPC-ILYEN-ARVETH`, etc.). Se genera un crosswalk por coincidencia exacta de nombre para los cinco puestos que ya existían. No se reemplazan IDs ni se crean duplicados.

## 2. Contratos de entidades

- `PersonSocialProfile`: extensión social de una entidad/persona existente; no reemplaza `EntityRegistry`.
- `FamilyGroup`: red de parentesco o reconocimiento con relaciones internas explícitas.
- `Household`: unidad de convivencia/recursos domésticos, separada de familia.
- `ResidenceAssignment`: vínculo temporal con lugar residencial válido.
- `SocialRelationship`: relación entre personas con tipo, dirección, fuente, estado y vigencia.
- `AffiliationMembership`: pertenencia o afiliación a grupo, con su propia procedencia.
- `CareObligation`: obligación de cuidado con sujeto, destinatario, tipo, alcance, vigencia y autoridad.
- `SocialKnowledge`: creencia/recuerdo individual acerca de otro sujeto, con fuente y confianza.

## 3. Comandos propuestos

Todos son intenciones tipadas sujetas a SR-02. La interfaz solo emite la intención; el motor social no confirma sin validación.

- `ProposeSocialRelationship`
- `ConfirmSocialRelationship`
- `DisputeSocialRelationship`
- `EndSocialRelationship`
- `FormFamilyGroup`
- `AddFamilyMember`
- `RemoveFamilyMember`
- `CreateHousehold`
- `JoinHousehold`
- `LeaveHousehold`
- `AssignResidence`
- `VacateResidence`
- `CreateCareObligation`
- `FulfillCareObligation`
- `RecordSocialObservation`
- `UpdateRelationshipPerception`
- `DiscloseSocialInformation`

No comando de «ser amigo» debe saltarse la evidencia y crear confianza alta. Las propuestas de filiación legal, tutela, unión reconocida y derechos necesitan autoridad social/jurídica válida según cultura y jurisdicción, aspectos que no están definidos globalmente.

## 4. Eventos confirmados propuestos

`SocialRelationshipProposed`, `SocialRelationshipConfirmed`, `SocialRelationshipDisputed`, `SocialRelationshipEnded`, `FamilyGroupFormed`, `FamilyMemberAdded`, `FamilyMemberRemoved`, `HouseholdFormed`, `HouseholdMemberJoined`, `HouseholdMemberLeft`, `ResidenceAssigned`, `ResidenceVacated`, `CareObligationCreated`, `CareObligationFulfilled`, `SocialObservationRecorded`, `RelationshipPerceptionChanged`, `SocialInformationDisclosed`.

Cada evento registra event_id, command_id, actor, target(s), tick, scope, source/evidence, result, previous state hash and new state hash. El almacenamiento y la idempotencia pertenecen a SR-04/SR-15.

## 5. Reglas de consistencia

1. Una persona tiene un solo hogar principal co-residencial por intervalo, salvo que un caso cultural/social específico defina otra estructura.
2. Una persona puede mantener vínculos familiares a través de hogares distintos.
3. Las relaciones son temporales: pueden tener vigencia inicial y final.
4. No se duplica una persona para representar dos perspectivas.
5. Las relaciones afectivas/sociales son direccionales; filiación puede tener reciprocidad tipada, pero debe provenir de una afirmación común validada.
6. Un hogar requiere al menos un miembro; una residencia debe referir un lugar residencial válido.
7. No se permite ocupación superior a la capacidad validada.
8. Un evento repetido con el mismo command_id es idempotente.
9. La salida/cierre de un NPC no elimina su historial social.
10. Ninguna relación crea dinero, objetos, derechos legales o conocimiento sin evento de dominio correspondiente.

## 6. Resolución de población de fondo

El build actual no importa los 120 NPC de fondo porque el CSV de elenco solo contiene los 60 nombrados. Cuando se aporte el JSON/CSV de población de fondo, el importador debe conservar sus IDs y semilla. No hay que volver a generar sus nombres ni estados. La integración acepta opcionalmente `household_seed_id`, `family_group_id`, `explicit_relationships` y `residence_facility_id` si están presentes y documentados.

## 7. Pruebas de aceptación

- No se crea un parentesco al compartir apellido.
- No se crea convivencia por compartir empleo.
- No se asigna una vivienda que no exista o no esté disponible.
- Un rumor de familia no cambia el árbol de parentesco objetivo.
- A→B y B→A pueden tener percepciones diferentes.
- Una relación puede terminar sin borrar su historial.
- Un hogar compartido puede no tener parentesco.
- Una familia puede repartirse en más de un hogar.
- Cambiar de residencia no crea ni destruye una familia.
- La población de fondo se puede importar conservando identidades e IDs.
- El paquete actual reconstruye las 60 fichas a partir de su CSV fuente y conserva el crosswalk de puestos.
