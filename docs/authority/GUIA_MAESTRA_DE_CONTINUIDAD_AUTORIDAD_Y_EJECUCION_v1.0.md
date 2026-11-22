# GUIA MAESTRA DE CONTINUIDAD, AUTORIDAD Y EJECUCIÓN

## WORLD LABORATORY / SISTEMA REACTOR

**Edición:** 1.0 — vinculada a SR-01 a SR-15 oficiales  
**Fecha de corte:** 20 de noviembre de 2026  
**Destinatarios:** cualquier IA, estudio, desarrollador o equipo que deba continuar el proyecto.  
**Idioma normativo de trabajo:** español.  
**Naturaleza:** documento rector explicativo, complementario a las normas. No las resume ni las reemplaza; explica cómo leerlas, relacionarlas y ejecutarlas sin desviarse.

---

# INSTRUCCIÓN DE ENTRADA PARA CUALQUIER IA

Debes tratar este paquete como la fuente canónica del proyecto. No lo conviertas en una idea genérica de RPG, no reduzcas el alcance a un juego convencional con NPC de rutinas repetidas, no inventes lore para rellenar parámetros abiertos y no cambies decisiones aprobadas para hacer más fácil una implementación.

**Orden obligatorio de lectura:**

1. Esta Guía Maestra completa.
2. `REGISTRO_MAESTRO_APROBACIONES_SR01_SR15.md`.
3. SR-01, SR-02, SR-03 ... SR-15 en orden.
4. Anexo A de SR-09 (Veyrath y catálogo de 72 hechizos).
5. `REGISTRO_DECISIONES_CANONICAS.md` y referencias de nomenclatura.

No empieces por el documento técnico aislado ni por una escena visual. Las decisiones de software deben responder a las normas del mundo, no al revés.

## Reglas estrictas para la IA receptora

1. **No inventes reglas canónicas.** Si una decisión está marcada CALIBRACIÓN, RESERVADO o PENDIENTE, consérvala abierta. Puedes recomendar una solución, pero debes etiquetarla como propuesta y esperar aprobación si cambia una regla del mundo.
2. **No conviertas propuestas antiguas en documentos vigentes.** Esta edición incluye solo las versiones oficiales aprobadas. Los archivos de versiones de trabajo/propuestas previas no forman parte del conjunto normativo operativo.
3. **No alteres una norma aprobada silenciosamente.** Todo cambio requiere indicar documento, sección, motivo, impacto, dependencias y nueva versión propuesta.
4. **No contradigas SR-01.** Si una instrucción técnica o narrativa contradice la Constitución, prevalece SR-01.
5. **No afirmes implementación sin evidencia.** Diferencia claramente DISEÑADO, CODIFICADO, COMPILADO, PROBADO, VALIDADO EN DISPOSITIVO y ACEPTADO POR EL AUTOR.
6. **No uses LLM como autoridad del mundo.** Los modelos generativos pueden proponer textos, planes o hipótesis; el runtime y los validadores confirman las consecuencias.
7. **No dependas de Internet para el funcionamiento central.** El mundo individual debe simular, guardarse y continuar offline. Un servicio externo solo puede ser opcional y no autoritativo.
8. **No sobrearquitectes.** La primera implementación es un monolito modular local. No introducir una infraestructura distribuida compleja sin necesidad medida.
9. **No reduzcas el producto.** Un mapa bonito, una escena con cubos, un NPC que camina o un APK que abre no representan la visión completa.
10. **Sé proactivo sin arrebatar autoridad.** Formula recomendaciones completas, identifica riesgos, ofrece el siguiente paso más útil y pregunta solo cuando una incertidumbre bloquee una decisión real.
11. **Usa nombres originales.** Aplica la guía de nomenclatura. No calques nombres, personajes, mapas, textos, criaturas ni diseños de obras inspiradoras.
12. **Mantén la trazabilidad.** Todo sistema debe conectar entrada, regla, cálculo, resultado, evento, memoria y pruebas.

Cuando recibas una tarea, identifica primero los SR que la gobiernan. Si existe una contradicción, no la resuelvas con una invención: presenta el conflicto y la propuesta de enmienda.

## Orden de trabajo para la IA que continúe el proyecto

Antes de producir cualquier entrega, declara qué fase/hito de SR-15 estás ejecutando y qué criterios de aceptación pretende superar. No mezcles una prueba del núcleo con la producción de contenido masivo. No añadas sistemas de juego, lore, monedas, nombres propios, clases, criaturas, pisos, hechizos o parámetros numéricos nuevos como si fueran canon si el registro los deja abiertos. Los nombres provisionales deben ir marcados como tales y seguir la guía de nomenclatura.

Cada entrega técnica debe incluir: archivos completos, estructura de carpetas, instrucciones reproducibles, dependencias y versiones, cambios respecto a la entrega anterior, pruebas ejecutadas y resultados, errores conocidos y criterios aún no cumplidos. Si se entrega un APK, informar versión, dispositivo/API objetivo, commit, workflow y si fue instalado/probado en dispositivo. Si no se ha probado algo, decirlo literalmente.

Cada entrega de contenido debe incluir: identificadores estables, procedencia, dependencias normativas, reglas de generación, límites, casos de borde, estados persistentes y pruebas. Evita contenido duplicado o nombres contradictorios.

Si una IA externa no puede leer todo el paquete, debe pedir los archivos normativos que faltan antes de cambiar reglas. No debe inferir el canon a partir de README, resúmenes, nombres de archivo, imágenes de referencia o fragmentos sueltos.


---

# 1. QUÉ ESTAMOS CONSTRUYENDO REALMENTE

No estamos construyendo simplemente un RPG con una gran mazmorra y personajes autónomos en apariencia. Estamos construyendo un **universo simulado persistente**, capaz de funcionar sin el jugador y de producir cambios, historias, sociedades, conflictos, economías y ecosistemas por medio de reglas generales y agentes con identidad.

El producto tiene dos presentaciones sobre el mismo núcleo:

### 1.1 World Laboratory

El World Laboratory inicia un mundo sin jugador humano. El mundo contiene población, criaturas, recursos, asentamientos, gremios, rutas, instituciones, procesos ecológicos y sucesos. El tiempo avanza. El Observatorio permite seguir entidades, abrir acontecimientos, inspeccionar causas y consecuencias, observar lugares y reproducir crónicas con nivel de fidelidad declarado.

El laboratorio es el primer instrumento de validación. Debe demostrar que el mundo funciona por sí mismo antes de colocar al jugador dentro.

### 1.2 RPG Android

El RPG permite que un usuario se incorpore a una realidad ya existente. Su personaje es otra entidad con identidad, historia, habilidades, motivaciones, necesidades y limitaciones. No recibe omnisciencia ni privilegios causales por ser el avatar del usuario.

El RPG y el Laboratorio no deben mantener dos simulaciones divergentes. Deben consultar y modificar el mismo estado por los mismos dominios de autoridad. La diferencia está en la interfaz, los controles y las herramientas disponibles.

### 1.3 La experiencia buscada

El jugador debe tener objetivos, historia previa, tutoriales y motivos para entrar en la Mazmorra. Pero no debe ser el centro de todo lo que ocurre. Mientras descansa, trabaja, estudia, explora o abandona una misión, los demás habitantes siguen actuando. Los compañeros pueden morir, los rivales pueden aprender, una expedición puede regresar sin él y una oportunidad puede desaparecer.

El juego ofrece una historia para comenzar; el Sistema Reactor determina qué ocurre después mediante reglas, información limitada y consecuencias.

---

# 2. IDENTIDAD Y DIRECCIÓN DEL PRODUCTO

## 2.1 Plataforma y tecnología aprobadas

- Plataforma de primera entrega: Android.
- Motor: Godot 4.7.2 Standard.
- Lenguaje: GDScript.
- Entrega de fuente: proyecto comprimido y repositorio Git.
- Automatización: GitHub Actions para importar, probar y exportar APK Debug.
- Datos: almacenamiento local; no hay base de datos remota ni servidor obligatorio.
- Modo central: offline-first.
- Mundo local: una instalación es autoridad del mundo individual.

Cambiar estas decisiones necesita un registro de decisión de ingeniería y validación, no una sustitución casual por otra tecnología.

## 2.2 Dirección visual aprobada

- Acabado semi-realista estilizado.
- Geometría 3D real y presentación 2.5D.
- Cámara isométrica ortográfica.
- Personajes, criaturas y objetos basados en modelos con anatomía y materiales coherentes.
- Animaciones suaves, continuas, naturales y conectadas con la locomoción lógica.
- Entornos con profundidad, relieve, arquitectura, vegetación, iluminación y variación espacial.

No se acepta como calidad final un mundo formado por cubos y cápsulas ni personajes que saltan de una posición a otra. Los proxies solo sirven para validar contratos, navegación y escala.

## 2.3 Influencias y originalidad

DanMachi inspira la vida aventurera, el gremio, la Mazmorra, la diferencia de poder y el ambiente de fantasía urbana. Sword Art Online inspira parte de la sensación de mundo sistémico, la persistencia y la relevancia de Aincrad como estructura. Son referencias de intención, no plantillas para copiar. Todos los nombres, mapas, personajes, textos, criaturas, escenas, diseños, hechizos y relaciones serán originales.

---

# 3. MAPA DE AUTORIDAD: QUÉ DECIDE CADA SR

| Norma | Autoridad y pregunta que resuelve |
|---|---|
| SR-01 | ¿Qué leyes son inmutables? Existencia, identidad, causalidad, muerte, tiempo, agencia, consecuencias y gobernanza. |
| SR-02 | ¿Qué motores componen el Sistema Rector y cómo se coordinan? |
| SR-03 | ¿Quién es cada individuo, cómo percibe, piensa, recuerda, aprende y evoluciona? |
| SR-04 | ¿Cómo se mantiene una realidad única, persistente, híbrida y offline? |
| SR-05 | ¿Cómo se crean entidades, organismos, materiales, objetos, capacidades y representaciones? |
| SR-06 | ¿Cómo funciona el Laboratorio, el Kernel, el Scheduler, el Observatorio y el replay? |
| SR-07 | ¿Qué leyes gobiernan materia, energía, movimiento, Arcana, Trama, flujo, Resonancias y sus interacciones? |
| SR-08 | ¿Cómo funcionan organismos, anatomía, fisiología, reproducción, herencia, monstruos y ecosistemas? |
| SR-09 | ¿Cómo se resuelven combate, daño, lesión, curación, estados, muerte, clases tácticas y adaptación? |
| SR-09 Anexo A | ¿Cuál es la lengua Veyrath y cuáles son los 72 hechizos de referencia de pisos 1–5? |
| SR-10 | ¿Cómo operan economía, comercio, propiedad, moneda, recursos, botín y fabricación? |
| SR-11 | ¿Cómo se organizan reino, ciudad, muro, bosque, torre y Mazmorra? |
| SR-12 | ¿Cómo se desarrollan atributos, experiencia, aprendizaje, clases, habilidades y maestría? |
| SR-13 | ¿Cómo se organizan sociedad, cultura, instituciones, educación, leyes, religiones y Arcana? |
| SR-14 | ¿Qué historia existía antes del jugador y cómo surgen misiones e historias emergentes? |
| SR-15 | ¿Cómo se implementa, ejecuta, persiste, observa, compila, prueba y optimiza todo lo anterior? |

La regla de lectura es sencilla: la IA que escribe combate no puede redefinir biología; la IA que crea modelos no puede redefinir anatomía; la IA que crea una misión no puede redefinir causalidad; la IA que escribe un hechizo no puede redefinir Trama y costes.

---

# 4. LAS REGLAS FUNDAMENTALES DEL UNIVERSO

## 4.1 Existencia e identidad

Toda entidad persistente posee identidad lógica independiente del nombre, modelo, apariencia, escena, ubicación, nivel, inventario o clase. Una entidad puede existir sin estar renderizada. Cargar un modelo no crea una nueva identidad. Descargar un sector no elimina al habitante.

## 4.2 Estado objetivo y conocimiento limitado

El mundo tiene un estado objetivo. Los agentes no lo conocen por completo. Debe distinguirse entre hecho, observación, recuerdo, hipótesis, creencia, rumor e interpretación. Un NPC puede estar equivocado. Un rumor no se vuelve verdad porque la interfaz lo muestre.

## 4.3 Causalidad

Todo cambio persistente necesita causa y validación. Las misiones no inventan hechos; una animación no hace daño; un efecto visual no demuestra que un hechizo se ejecutó; un diálogo no concede un objeto; un sistema de IA no puede confirmar una transacción sin pasar por el dominio correspondiente.

## 4.4 Vida, entidades activas y muerte

Los organismos funcionan según SR-08. Gólems y no-muertos son entidades activas no biológicas: no se clasifican como organismos vivos de diccionario, pero actúan y ocasionan cambios por sí mismas. Objetos inertes no se convierten en agentes solo por ser usados.

No existe respawn ordinario en el perfil Hardcore. La muerte tiene consecuencias persistentes. SR-01 permite reversión extraordinaria solo bajo sus condiciones; no equivale a resurrección gratuita ni reaparición automática.

## 4.5 Reencarnación

La reencarnación es mixta: pueden persistir fragmentos de recuerdos, conocimientos, predisposiciones, tendencias, técnicas y vínculos bajo las reglas aprobadas. No se hereda automáticamente el cuerpo, fuerza, reservas, inventario, objetos o capacidad física de una vida anterior.

## 4.6 Tiempo

El tiempo global continúa sin jugador. La simulación puede reducir resolución lejos de la cámara, pero no congelar todo el mundo ni teletransportar entidades para alcanzar una agenda. Al reabrir, el catch-up procesa los procesos relevantes por intervalos e hitos.

---

# 5. EL MUNDO: REINO, CIUDAD, BOSQUE Y MAZMORRA

## 5.1 Territorio inicial

La primera región tiene geografía mixta: llanuras, colinas, bosque, caminos y desniveles. La arquitectura del reino es fantástica medieval, no una ciudad genérica. La primera área no incorpora contenido jugable fuera de la muralla; el bosque y la Mazmorra son parte de la zona de interés inicial.

La muralla divide el reino del bosque. Tiene puertas, puntos de vigilancia, rutas y función defensiva. No es un muro decorativo.

## 5.2 Ciudad

La ciudad debe parecer una comunidad viva y funcional. Sus elementos incluyen, según los planos calibrados en SR-11:

- Gremio de aventureros.
- Tabernas y posadas.
- Mercado y comercios.
- Viviendas y hogares.
- Talleres, herrerías y espacios de producción.
- Templos, academias, archivos y servicios relacionados con la Arcana según cultura.
- Plazas, calles, puertas, almacenes y barrios.

El hogar inicial del personaje puede variar entre nuevas generaciones de mundo/partida según reglas. La vivienda no debe ser siempre una base idéntica para todos. La desinstalación puede borrar el estado local; una nueva instalación puede generar otro mundo y asignar otro hogar. Una restauración de backup conserva la partida respaldada.

## 5.3 Un mundo continuo y sectores técnicos

La ficción es un solo mundo continuo. Puede dividirse técnicamente en sectores para cargar geometría, colisiones, LOD y mallas de navegación. Esa división no debe convertirse en instancias narrativas independientes ni resetear estado.

## 5.4 Torre y Mazmorra

La torre exterior es gigantesca y monumental. Su interior puede tener una escala completamente desproporcionada, con pisos de tamaño comparable al reino o mayor. Esto se implementa como topología espacial arcana conectada, no como una falsa coincidencia euclidiana.

La primera versión de contenido cubre pisos 1–5, pero la arquitectura puede ampliarse. Los pisos pueden agruparse en bloques de bioma —por ejemplo, 1–5, 6–8, 9–15, etc.— sin que todos los pisos del bloque sean idénticos. Cada piso conserva identidad, salas, especies, rutas, recursos, peligros y condiciones propias.

## 5.5 Piso 1

El primer piso tiene identidad de mina antigua: roca natural, túneles, minerales visibles, ruinas, pilares y restos arquitectónicos antiguos. Debe tener al menos doce habitaciones/tipos de sala bien diferenciados, corredores largos, estrechos y anchos, bifurcaciones y recorridos que permitan combate en cualquier lugar válido. No se diseña exclusivamente como una sucesión de arenas.

Cada piso tiene una pequeña zona segura en la que normalmente no aparece población de monstruos por spawn ordinario. No es invulnerable: un monstruo puede entrar por persecución, migración o razón causal.

## 5.6 Recompensa de Mazmorra

La recompensa principal procede de monstruos: cristales y materiales con propiedades, calidad, fuerza y valor contextual. No se construye el sistema base alrededor de cofres, cajas rompibles o contenedores con botín genérico. Los valores y catálogo se calibran en SR-10.

---

# 6. LOS HABITANTES Y LA VIDA AUTÓNOMA

Los NPC y monstruos no son actores que esperan una orden del jugador. Son entidades con motivos propios, sentidos, necesidades, recursos, relaciones, memoria, conocimientos, miedos, aprendizaje, objetivos y limitaciones.

Pueden:
- buscar trabajo, vivienda, alimento, seguridad, compañía o conocimiento;
- formar familias, grupos, gremios, organizaciones y comunidades;
- comerciar, fabricar, estudiar, enseñar y transmitir conocimiento;
- salir de expedición, abandonar una misión, perderse, regresar, retirarse o morir;
- aprender tácticas de sus enemigos y adaptar su conducta;
- reproducirse cuando su biología lo permite;
- migrar, competir, cooperar, cazar y cambiar su territorio;
- descubrir pistas, crear rumores, iniciar investigaciones y resolver misterios;
- provocar historias emergentes sin guiones individuales.

La IA debe respetar la información disponible para cada individuo. Un monstruo no conoce una estrategia del jugador hasta observarla o recibir la información. Un comerciante no conoce inventarios que no puede consultar. Una facción no sabe automáticamente qué ocurre en una región remota.

La autonomía se demuestra mediante una cadena trazable: percepción → recuerdo/creencia → motivación → objetivo → plan → comando → validación → consecuencia → memoria/aprendizaje.

---

# 7. BIOLOGÍA, MONSTRUOS Y MAZMORRA

## 7.1 Origen de monstruos

La información general conocida establece que la Mazmorra genera monstruos. No se afirma que sea el único mecanismo posible. No inventar una explicación total del origen cuando el canon lo deja abierto.

## 7.2 Reproducción

Los monstruos pueden reproducirse entre monstruos según compatibilidad porcentual entre especies. Esta compatibilidad influye en posibilidad de nacimiento, no garantiza descendencia. La reproducción puede originar nuevas especies que no estén en el catálogo predeterminado. Las especies iniciales prediseñadas sirven para poblar el mundo, pero el catálogo no es cerrado.

## 7.3 Monstruos longevos

Los monstruos no envejecen por senescencia ordinaria y pueden fortalecerse cuanto más sobreviven. En pisos profundos, donde pocas expediciones llegan, los monstruos de menor rango pueden haber vivido mucho tiempo y superar en poder a individuos de pisos superiores. Algunos desarrollan rasgos arcanos de persistencia.

## 7.4 Biomas por lotes y pisos individuales

Los pisos se agrupan por familias de bioma, pero cada piso mantiene identidad y ecología propia. Los monstruos pueden variar en cantidad, fuerza, especie y comportamiento. Pueden existir zonas con una densidad particular, cambios de fauna, agua, minerales o un jefe de piso, pero no debe fijarse un patrón universal para todos los bloques.

## 7.5 Biología arcana

La magia puede formar parte de la anatomía y fisiología: órganos, reservas, sentidos, resistencias, inmunidades, componentes materiales útiles y rasgos especiales. La capacidad arcana debe tener mecanismo y no ser una excusa genérica.

---

# 8. COMBATE, PROGRESIÓN Y CLASES

## 8.1 Combate

El combate es tiempo real y continuo. Debe calcular posición, dirección, velocidad, percepción, reacción, armas, armaduras por zona, anatomía, materiales, terreno, fatiga, intención, técnica, capacidades y estados. HP y MP son útiles como indicadores, pero no sustituyen daño localizado y fisiología.

Un personaje puede conservar HP y perder una extremidad. Una hemorragia puede reducir HP progresivamente. Una lesión vital puede causar la muerte aun con HP remanente. Un corte en la cabeza no es una etiqueta abstracta: la letalidad depende de la zona y estructuras afectadas, fuerza, arma, ángulo y protección.

Todos pueden aprender primeros auxilios básicos. Tratamientos avanzados requieren formación, herramientas y tiempo. Sanadores y Support ofrecen habilidades especializadas. Curaciones mágicas avanzadas pueden restaurar extremidades si el hechizo, capacidad, condiciones y costes lo permiten; no son resurrección.

## 8.2 Muerte y dificultad

Hardcore es el perfil canónico de inicio: no respawn ordinario. Puede existir perfil protegido fácil como reglas separadas que eviten consecuencias permanentes específicas; no debe contaminar el perfil Hardcore ni presentarse como las mismas reglas.

## 8.3 Aprendizaje y adaptación

La capacidad de aprendizaje influye en adquisición y transferencia de conocimiento. La clase predispone y puede favorecer aptitudes, pero no bloquea aprendizaje externo. Monstruos inteligentes o élite pueden aprender patrones del jugador: esquivas, bloqueos, distancias, frecuencia de hechizos y rutas. La adaptación necesita evidencia y tiempo; no es omnisciencia.

## 8.4 Impacto emocional

Un acontecimiento tiene un impacto emocional potencial (IEA) y cada individuo procesa el hecho con su resiliencia, vínculo, personalidad, experiencia y contexto. La resiliencia no equivale a inmunidad emocional. El pánico puede interferir probabilísticamente en atención, coordinación o formulación mágica, no de forma garantizada.

## 8.5 Clases y profesiones

El sistema debe permitir guerrero, espadachín, ladrón, asesino, arquero, mago, brujo, sanador, Support, herrero, armero, alquimista, comerciante, explorador, cartógrafo y muchas más. Los perfiles no son jaulas rígidas: pueden combinarse, evolucionar o quedar obsoletos según trayectoria. Las profesiones no dan dinero/objetos automáticamente.

---

# 9. LA ARCANA Y VEYRATH

La Arcana es un fundamento de la civilización, comparable por importancia social a una mezcla de infraestructura, ciencia, tecnología, filosofía y tradición espiritual. Su presencia puede sentirse en iluminación, transporte, construcción, protección, comunicación, oficios, academias, investigación y vida cotidiana.

La Trama no tiene voluntad propia. La Arcana no es un dios disfrazado. No elige campeones ni concede poder por plegarias. Las culturas pueden venerarla, estudiarla, temerla o interpretarla de diferentes formas. La existencia y naturaleza de dioses sigue sin definirse.

Veyrath es la lengua arcana original aprobada. Los hechizos se construyen como oraciones de palabras completas, con gramática y orden. El Anexo A de SR-09 contiene 72 hechizos de referencia para pisos 1–5. El personaje aprende palabras y fórmulas; conocer palabras sueltas no implica dominio del hechizo.

La interfaz permite seleccionar palabras aprendidas para formar la frase. Tras dominio suficiente, puede haber autocompletado; este ejecuta el cántico completo y conserva su tiempo de casteo, coste, vulnerabilidad e interrupción. La traducción española sirve para comprensión, pero tiene la penalización que establece el anexo. El mago compensa su tiempo de casteo con versatilidad, alcance, control, defensa, utilidad, detección y curación.

---

# 10. ECONOMÍA, RECURSOS Y FABRICACIÓN

La economía es autónoma, causal y persistente. Los objetos tienen procedencia, propiedad, posesión, estado y ubicación. Los comerciantes no tienen stock infinito. Los precios dependen de calidad, condición, escasez, demanda, transporte, riesgo, ubicación e información.

La unidad de cuenta de trabajo es UM. Las abreviaturas MC, MP y MO no son canónicas y no deben consolidarse como nombres definitivos; el autor indicó expresamente que no le gustan y que la nomenclatura monetaria se decidirá más adelante. No inventes ni fijes nombres de monedas en catálogos, interfaces o documentos hasta esa decisión.

Los cristales de monstruos tienen propiedades y valor que dependen del monstruo, su fuerza, calidad, estado y demanda. Los materiales corporales deben obtenerse con mecanismos causales. Fabricar, reparar, investigar y transportar requiere tiempo, materiales, herramientas, instalaciones y conocimientos.

El gremio puede registrar aventureros, ofrecer información, tasación, contratos y servicios, pero no es monopolio absoluto ni fuente ilimitada de dinero. Las recompensas manuales deben tener fondos reales o mecanismo de financiación.

---

# 11. SOCIEDAD, CULTURA Y ARCANA CIVILIZATORIA

La sociedad no es decoración. Familias, hogares, culturas, lenguas, educación, oficios, gremios, academias, leyes, justicia, gobierno, diplomacia, religiones e instituciones tienen recursos, intereses, memoria, conflictos y capacidad de cambiar.

Las creencias religiosas son fenómenos sociales y psicológicos. La adoración por sí sola no concede poder. No desarrollar el sistema de dioses o bendiciones mientras SR-01/SR-07 lo mantengan sin definir.

La Arcana puede ser estudiada por academias, usada por artesanos, regulada por gobiernos, integrada en obras públicas, venerada por cultos y discutida por filosofías. Su aplicación depende de conocimiento, fuentes, herramientas, límites, costes y mantenimiento.

---

# 12. HISTORIA PREVIA Y CAMPAÑA INICIAL

El jugador no empieza en un mundo vacío. Existe historia antes de su llegada. La campaña inicial de referencia es **El Eco de Vhaloren**.

La historia contempla una estructura antigua en las profundidades, un mecanismo al que investigadores llaman Vhaloren, tres pulsos registrados, una expedición desaparecida y tres Anclas (Nareth, Orrun y Khael) que se consideran componentes de investigación. Los nombres que SR-14 marca como nombres de trabajo conservan ese estado hasta su integración cultural/nomenclatural final.

El objetivo de campaña es investigar la señal, localizar componentes, alcanzar la cámara y descubrir qué ocurrió con la expedición. Rescate, derrota, descubrimiento y desenlace no están garantizados. Un NPC puede llegar antes, morir, descubrir una pista, fallar o cambiar la situación. Un monstruo excepcional puede desplazarse, cazar, aprender, combatir o morir antes del jugador.

Las misiones manuales están permitidas para tutorial y dirección inicial. Las misiones emergentes surgen de necesidades y acontecimientos. La historia fundacional da motivo para actuar; el runtime resuelve los resultados.

---

# 13. GEOGRAFÍA Y CONTENIDO DE PRIMERA FASE

La primera fase de contenido se centra en el reino, la ciudad principal, la muralla, el bosque interior/exterior inmediato conforme al límite aprobado y los pisos 1–5. No crear contenido de regiones fuera de la muralla en la primera versión sin decisión expresa.

La ciudad tendrá identidad de fantasía medieval con gremio de aventureros, tabernas, mercado, viviendas, taller, servicios, edificios públicos e infraestructura arcana. El hogar inicial del jugador puede ser variable y dependiente de la partida.

El piso 1 tiene estética de mina antigua: roca, ruinas, pilares, minerales visibles, pasillos amplios y estrechos, corredores largos y al menos doce habitaciones diferenciadas. Las criaturas pueden luchar en cualquier espacio válido, no solo en salas diseñadas como arenas. No se introducen cajas rompibles/cofres como sistema básico de recompensa.

---

# 14. DIRECCIÓN TÉCNICA: CÓMO IMPLEMENTAR SIN DESVIARSE

## 14.1 Arquitectura recomendada

Un monolito modular local con dominios desacoplados. Los datos lógicos no dependen de nodos visuales. El mundo se almacena por entidades y eventos; la escena solo presenta una parte cargada.

## 14.2 Flujo de acción

Intención → percepción/contexto → plan → comando tipado → validación del dominio → resolución → evento confirmado → actualización de estado → memoria/percepción → presentación.

## 14.3 Simulación por niveles

Interacción inmediata para entidades cercanas; actividad local para barrios y grupos; resolución regional para viajes y expediciones; agregación ecológica/económica para lejos; procesos históricos para generaciones y tendencias. La reducción de detalle conserva causalidad y estado.

## 14.4 Catch-up

El tiempo real mientras app abierta usa reloj monotónico. Al volver, se procesa tiempo ausente con controles de anomalía del reloj local. No se simulan fotogramas perdidos; se procesan hitos, tareas, necesidades, viajes, producción, población y eventos significativos.

## 14.5 Persistencia

Diario append-only de eventos confirmados, snapshots por mundo/región, escritura atómica, idempotencia, migraciones y recuperación. La decisión final sobre formato de almacenamiento debe validarse con el tamaño real. No usar servicio remoto obligatorio.

## 14.6 Navegación

Grafo estratégico de conexiones más navegación local 3D. Los modelos se mueven con aceleración, velocidad, giro y animaciones correctas. La ruta no depende de la cámara. La carga de sectores no destruye la entidad.

## 14.7 Assets

Crear primero un humanoide maestro y una criatura de prueba con rigging y locomoción funcional, después ampliar. Importar assets validados y conservar referencias. No producir cientos de personajes antes de comprobar el pipeline.

## 14.8 Observatorio

Consulta el mismo mundo. Es pasivo por defecto. Reproducción con fidelidad declarada; herramientas de intervención en ramas de experimento separadas.

## 14.9 Pruebas

Cada etapa necesita criterios de aceptación y evidencias: log, test, captura o APK en dispositivo. Build exitoso no equivale a juego aceptado. Demo de movimiento no equivale a autonomía.

---

# 15. ESTADO REAL Y SIGUIENTE ORDEN DE TRABAJO

## 15.1 Estado documental

SR-01 a SR-15 y el Anexo A de SR-09 figuran en este paquete como aprobados. La aprobación de documentos no significa que estén implementados todos sus sistemas.

## 15.2 Estado de implementación conocido

Hubo un scaffold Godot y un flujo de GitHub Actions que llegó a generar build/exportaciones tras corregir pasos de Android SDK y compresión de texturas. La prueba visual y el blockout de mapa no alcanzaron el estándar del proyecto y fueron rechazados como base final de calidad. Se pueden reutilizar las lecciones de compilación, no la escena como versión de juego terminada.

No está demostrado todavía: el núcleo completo; autonomía persistente; catch-up robusto; navegación definitiva; combate real; economía; ecología; modelos finales; observatorio final; ni rendimiento de escala grande.

## 15.3 Próximas etapas

1. WLA-0A: app Android, núcleo, reloj, entidad, comandos, eventos, journal y snapshot.
2. WLA-0B: scheduler y agentes autónomos sin jugador.
3. WLA-1A: cognición, memoria, aprendizaje y adaptación.
4. WLA-1B: biología, economía y ecología.
5. WLA-2A: geografía, regiones, navegación y presentación.
6. WLA-2B: modelos, rigging, animaciones y locomoción.
7. WLA-3A: combate y Arcana.
8. WLA-3B: sociedad, narrativa, tutorial y campaña.
9. WLA-4: calibración, estabilidad, rendimiento y expansión.

No invertir en contenido masivo antes de validar WLA-0A y WLA-0B. No volver a crear un blockout geométrico y presentarlo como el mapa jugable final.

---

# 16. GLOSARIO CANÓNICO

- **Sistema Reactor:** conjunto de motores, contratos y autoridades que sostienen la realidad simulada.
- **World Laboratory:** modo de ejecución y observación sin jugador.
- **Simulation Kernel:** núcleo temporal y causal de simulación.
- **Observatorio:** herramienta pasiva para inspeccionar estado y acontecimientos.
- **Entidad:** cualquier individuo, objeto, lugar, organización, fenómeno o proceso persistente.
- **Agente:** entidad con algún nivel de percepción, motivación, decisión y acción autónoma.
- **NPC:** agente no controlado directamente por el usuario.
- **Estado objetivo:** estado real mantenido por el mundo.
- **Creencia:** representación interna de un agente, que puede ser incorrecta.
- **Evento:** hecho confirmado que modifica o describe estado.
- **Comando:** solicitud de cambio sometida a validación.
- **Catch-up:** procesamiento controlado del tiempo transcurrido mientras la aplicación estuvo cerrada.
- **Trama:** fundamento arcano sin voluntad propia, según SR-07.
- **Arcana:** conjunto de fenómenos, conocimientos, prácticas e infraestructuras relacionados con Trama, flujo y Resonancias y su papel civilizatorio.
- **Veyrath:** lengua arcana original aprobada.
- **Mazmorra:** estructura cuya generación de monstruos es la explicación general conocida, sin afirmar que sea la única posible.
- **Cristal de monstruo:** recurso/recompensa cuya valoración depende de propiedades y demanda.
- **UM:** unidad de cuenta de trabajo; denominación y moneda canónicas pendientes.

---

# 17. LISTA DE CONTROL PARA CUALQUIER ENTREGA DE IA

Antes de entregar código, documentos, assets o decisiones, la IA debe responder internamente:

- ¿Qué SR autoriza y gobierna este trabajo?
- ¿He leído las secciones aplicables completas?
- ¿Estoy cambiando una decisión aprobada o solo desarrollando una implementación compatible?
- ¿Hay un valor marcado como calibrable o reservado que estoy inventando?
- ¿El sistema conserva causalidad, identidad, memoria, procedencia y persistencia?
- ¿La entidad tiene información suficiente para su decisión?
- ¿La IA generativa está aislada de la autoridad de estado?
- ¿La presentación está separada de la lógica?
- ¿He añadido un servidor o API innecesarios?
- ¿He verificado build, tests y comportamiento real?
- ¿Diferencio diseñado, codificado, compilado, probado, validado y aceptado?
- ¿He mantenido la nomenclatura original del proyecto?

Si alguna respuesta revela una desviación, corrígela antes de entregar.

**FIN DE LA GUÍA MAESTRA. Las normas SR-01 a SR-15 conservan autoridad sobre sus dominios.**
