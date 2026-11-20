# World Laboratory — Documento maestro del mapa y blockout

**ID:** WLA-MAP-001  
**Versión:** 0.2.0  
**Motor objetivo:** Godot 4.7.2 Standard  
**Renderizador inicial:** Compatibility / GL  
**Estado:** especificación de diseño aprobada por el usuario + primer blockout geométrico ejecutable.

## 1. Decisiones maestras confirmadas

- Geografía mixta: llanuras, colinas, río, campos, bosque y desniveles.
- Arquitectura de fantasía medieval, con referencias de género tipo *DanMachi* e isekai clásico.
- Cámara isométrica ortográfica y presentación 2.5D construida con geometría 3D.
- Un único mundo exterior continuo para el reino y el bosque jugable. No se crea contenido de regiones exteriores al reino amurallado en esta etapa.
- Una muralla marca y controla el límite entre el reino urbanizado y el bosque.
- La torre monumental está físicamente en el mapa exterior. Su interior es un dominio espacial no euclidiano: las dimensiones internas no tienen que corresponder con su huella exterior.
- La Mazmorra es un entorno de combate completo: pasillos, galerías, túneles, cámaras y conexiones son zonas potenciales de combate; no existen salas reservadas exclusivamente para luchar.
- Cada piso dispone de una zona segura de baja presión de aparición. No es una barrera: una criatura puede entrar si su comportamiento, persecución o causa lo justifica.
- Primer piso: mina de roca natural, ruinas y pilares antiguos, minerales claramente visibles y al menos 12 cámaras de diseño distinto.
- No se implementan cofres, cajas rompibles ni recompensas de contenedores. El futuro cristal de monstruo queda fuera del alcance de este blockout.

## 2. Escala y coordenadas

Convención: X = este/oeste, Z = norte/sur, Y = altura. Una unidad de Godot equivale a un metro.

| Elemento | Dimensión de blockout |
|---|---:|
| Extensión jugable exterior inicial | 2.4 × 2.4 km |
| Territorio exterior authored | solo el lado interior de la muralla y sus zonas de conexión |
| Pueblo principal | aprox. 900 × 850 m de huella urbana expandida |
| Muralla | tramos de 1.2 km en el eje principal, puertas y torres |
| Bosque interior jugable | aprox. 600 × 1.8 km, en el lado forestal de la muralla |
| Torre exterior | aprox. 144 m de diámetro de base y 800 m de altura visual |
| Dominio interior del piso 1 | aprox. 1.5 × 1.25 km en el blockout |
| Cámaras del piso 1 | 12 únicas en la primera pasada |

Estas dimensiones son una escala inicial de blockout y se validarán caminando el mapa con un personaje de referencia de 1.7–1.9 m. No son límites normativos definitivos.

## 3. Distribución exterior

### 3.1 Pueblo principal

La ciudad se organiza alrededor de la torre y sus plazas, con calles de distinta jerarquía:

- Plaza central y plaza de gremio.
- Gremio de aventureros, de escala monumental y lectura visual dominante.
- Taberna principal, posada y posibles tabernas secundarias.
- Mercado cubierto, puestos y almacenes.
- Herrería, carpintería, alquimia y talleres.
- Templo/iglesia como institución social y cultural; su presencia no define ni concede poderes sobrenaturales.
- Cuartel, establos, viviendas, campos y almacenes.
- Barrios residenciales y lotes de hogares candidatos.

La inspiración es de género, no una reproducción literal de mapas, nombres o assets protegidos.

### 3.2 Hogar variable del jugador

El hogar es una asignación de mundo, no un punto fijo universal:

1. En la creación de un mundo local se genera una semilla.
2. Un sistema de asignación elige un lote/hogar elegible según reglas futuras (disponibilidad, estado social, economía, historia, etc.).
3. La elección se guarda en el snapshot local y se mantiene al reabrir.
4. Una instalación nueva sin datos locales puede generar otra semilla y, por tanto, otra asignación probable.
5. Desinstalar no es el mecanismo de reroll recomendado dentro del diseño: no se garantiza que Android preserve o borre todos los datos de usuario en todos los escenarios; la regla técnica es “nuevo mundo local = nueva asignación”.

No se asignará una vivienda al azar en cada arranque, porque eso rompería la continuidad de la partida.

### 3.3 Muralla y bosque

La muralla es una frontera funcional y visual, no una pantalla de carga. Tendrá:

- Puertas principales y secundarias.
- Torres de vigilancia.
- Camino de guardia y pasos de patrulla.
- Puertas controladas por horarios/estado social más adelante.
- Rutas forestales estrechas, senderos de caza y claros.
- Transición gradual de terreno urbanizado a bosque.

El bosque del blockout está dentro del límite de contenido de esta primera región. No se modelan tierras exteriores más allá de la muralla.

## 4. Torre y Mazmorra no euclidiana

La torre exterior comunica escala y sirve como referencia espacial del reino. La huella exterior no limita el volumen del interior.

El runtime mantendrá dos conceptos separados:
- **Exterior físico:** torre visible en la coordenada del reino.
- **Dominio interior:** geometría de piso con coordenadas propias y `floor_id` persistente.

El portal/umbral vincula ambos dominios mediante una transformación de entrada/salida. La transición podrá ser fluida y sin pantalla de carga visible; no se debe fingir que una geometría interior de 1.5 km cabe dentro del cilindro exterior. La instancia interior puede estar cargada bajo el mismo WorldRoot, aunque su origen técnico se ubique en otro dominio de coordenadas.

## 5. Primer piso: mina de ruinas

### 5.1 Identidad espacial

No es una sucesión de arenas. Es un sistema de minería y ruinas excavadas:
- paredes de roca y lecho rocoso;
- corredores rectos, curvos o quebrados;
- galerías largas y estrechas;
- túneles anchos aptos para grupos;
- cámaras asimétricas;
- desniveles, pozos, fallas y galerías derrumbadas;
- pilares, obeliscos, arcos, acueductos y restos de una civilización anterior;
- vetas de minerales visibles incrustadas en roca;
- soportes de madera en tramos mineros inestables.

### 5.2 Cámaras iniciales

| # | Cámara | Rasgo que la hace distinta |
|---:|---|---|
| 01 | Galería de entrada | galería longitudinal con soportes de mina |
| 02 | Patio de pilares | retícula irregular de pilares antiguos |
| 03 | Veta cristalina | concentración visible de cristales/mineral |
| 04 | Nave derrumbada | columnas caídas y escombros |
| 05 | Pozo profundo | abertura vertical central |
| 06 | Campamento minero abandonado | bancos y restos de estación de trabajo |
| 07 | Acueducto roto | canal seco y soportes arqueados |
| 08 | Sala del obelisco | monolito central |
| 09 | Falla estrecha | garganta rocosa que fuerza paso angosto |
| 10 | Bóveda de estalactitas | techo rocoso y formaciones colgantes |
| 11 | Fundición en ruinas | horno frío y chimeneas |
| 12 | Santuario profundo | podio y monolitos periféricos |

Los nombres son etiquetas de trabajo. No son historia definitiva ni contenido narrativo canon.

### 5.3 Corredores y combate

Los corredores tendrán anchuras variables de referencia: 7–10 m (angostos), 12–18 m (medios), 20–35 m (anchos), y tramos longitudinales de decenas o cientos de metros. La geometría y el sistema de navegación no impondrán una separación entre “zona de combate” y “zona de tránsito”.

### 5.4 Zona segura

La zona segura aplica una política de probabilidad/peso de spawn bajo o nulo para aparición espontánea normal. No aplica invulnerabilidad, bloqueo físico ni exclusión absoluta. Persecución, huida, desplazamiento, migración o un evento causal pueden llevar monstruos a esa zona. La regla exacta de spawn se implementará en el sistema de ecología/IA, no en la malla.

### 5.5 Minerales y recompensa

Las vetas visibles son marcadores ambientales. No se implementa minería, recolección ni inventario en esta fase. La economía futura de cristales de monstruos se diseñará en su propio documento: calidad, nivel y fuerza del monstruo son variables mencionadas por el usuario, no fórmulas ya decididas.

## 6. Navegación y mundo continuo

Arquitectura objetivo:

1. Navegación local: NavMesh/NavigationRegion3D en superficies caminables.
2. Navegación entre barrios y biomas: grafo de conexiones con puertas, puentes, caminos y restricciones.
3. Navegación regional: planificación por sectores/objetivos.
4. Simulación abstracta: viajes y actividades de agentes fuera de la zona visible.

La carga por sectores es una optimización de memoria/renderizado, no una partición narrativa. Las coordenadas persistentes y los IDs de regiones siguen siendo estables. No hay pantallas de carga entre pueblo, bosque y torre en el mundo exterior.

## 7. Estructura técnica y persistencia

- `WorldRoot`: raíz común del mundo y del runtime.
- `ExteriorRealm`: reino, pueblo, caminos, muralla y bosque.
- `TowerLandmark`: representación exterior de la torre.
- `DungeonDomain`: piso interior con `floor_id` y coordenadas propias.
- `MapGraph`: nodos de camino, puertas, puentes, entrada de torre y conexiones de piso.
- `HomeAllocation`: selección y persistencia del hogar del jugador.
- `RegionStreamer`: carga/unload transparente por proximidad.
- `WorldPersistence`: snapshot/diario de eventos.

La vista no decide estado del mundo. Los meshes son representación visual y no son la autoridad de identidad, navegación, economía ni simulación.

## 8. Alcance del primer blockout 0.2.0

Incluye:
- reino continuo de blockout;
- pueblo con landmarks y distritos;
- muralla con acceso;
- bosque interior;
- campos, río y puentes;
- torre exterior monumental;
- piso 1 de mazmorra con 12 cámaras diferenciadas;
- corredores angostos, medios y anchos;
- vetas minerales visibles;
- zona segura marcada;
- cámara isométrica y conmutación de inspección exterior/interior.

No incluye todavía:
- personaje controlable;
- NPC y monstruos con IA;
- navegación NavMesh horneada;
- combate;
- portales con transición diegética final;
- hogares asignados por semilla en el runtime;
- minería, inventario, botín o cristales;
- arte final, texturas PBR o assets GLB.

## 9. Criterios de aceptación de la fase siguiente

- Se puede recorrer desde plaza central hasta la puerta de muralla y entrar al bosque sin transición de escena.
- La entrada de torre se reconoce desde varios puntos del pueblo.
- El piso 1 contiene al menos 12 cámaras distintas y conectadas.
- Existen rutas estrechas y anchas que permiten navegación.
- Los obstáculos no bloquean accidentalmente todos los caminos.
- El jugador puede cruzar el umbral y llegar al dominio interior sin que el tamaño exterior limite el interior.
- La zona segura no se trata como prohibición absoluta de entrada.
- El estado del hogar se persiste por mundo local.
- El blockout funciona en Godot 4.7.2 y puede exportarse a Android Debug.

## 10. Relación con SR-01 a SR-07

Este documento desarrolla el diseño espacial y técnico. No sustituye ni modifica SR-01 a SR-07. Cualquier futura regla de muerte, reencarnación, causalidad, magia, dioses, identidad o sociedad debe respetar los documentos normativos y sus enmiendas. El hogar variable es una decisión de generación de mundo, no una excepción a identidad/persistencia.
