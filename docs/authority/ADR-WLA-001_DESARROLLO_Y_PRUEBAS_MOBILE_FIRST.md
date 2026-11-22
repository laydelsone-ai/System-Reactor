# ADR-WLA-001 — Desarrollo y pruebas mobile-first

**Proyecto:** World Laboratory / Sistema Reactor  
**Estado:** Propuesta técnica de implementación subordinada a SR-15  
**Versión:** 1.0  
**Fecha:** 2026-11-20  
**Autoridad:** No modifica SR-01 a SR-15. Si existe conflicto, prevalecen los SR.

## 1. Decisión

El trabajo de documentación, arquitectura, generación de código, revisión y preparación de entregables se realizará desde la conversación móvil y mediante archivos descargables. No se exigirá al usuario disponer de un PC para continuar el desarrollo inicial.

La validación se dividirá en tres entornos:

1. **Validación automatizada en CI:** análisis estático, pruebas unitarias y de integración ejecutadas en un entorno Linux remoto con la versión fijada de Godot.
2. **Prueba de ejecución Android:** instalación y ejecución del APK en el teléfono real del usuario.
3. **Prueba de rendimiento y diagnóstico ampliado:** se utilizará PC cuando sea necesario para perfilar, inspeccionar escenas complejas, analizar volcados o comparar renderizadores; no será requisito para iniciar WLA-0A.

## 2. Motivo

El destino inicial del producto es Android, pero eso no significa que todas las pruebas deban ejecutarse exclusivamente en Android. El teléfono real es imprescindible para comprobar comportamiento de plataforma, ciclo de vida, almacenamiento, temperatura, memoria, entrada táctil y rendimiento final. Las pruebas de lógica aisladas son más reproducibles y fáciles de automatizar fuera del dispositivo.

La combinación CI + teléfono reduce la necesidad de un PC personal y evita convertir el editor móvil en un punto único de fallo.

## 3. Motor y versión

- Motor de referencia: Godot 4.7.2 Standard.
- Lenguaje: GDScript.
- No migrar a Godot 4.8 beta ni a otro motor sin justificación técnica y aprobación del autor.
- Renderizador inicial: Compatibility, con comparación controlada frente a Mobile cuando exista una escena representativa y una prueba en dispositivo.
- La versión del motor y dependencias deberán quedar fijadas en los workflows y documentadas en cada entrega.

## 4. Flujo operativo desde teléfono

1. El asistente prepara documentación, código, pruebas y paquetes versionados.
2. El usuario recibe archivos descargables que puede revisar y conservar desde Android.
3. Cuando exista repositorio Git, los cambios se incorporarán de forma controlada y se conservará historial; no se asumirán nombres o repositorios que no hayan sido confirmados.
4. GitHub Actions ejecutará las pruebas y, cuando proceda, construirá un APK Debug.
5. El usuario descargará e instalará el APK en su teléfono.
6. El usuario compartirá errores, registros o capturas reales de ejecución; se corregirá el código y se repetirá el ciclo.

Hasta que exista un repositorio verificado, los ZIP descargables serán entregas de trabajo, no prueba de integración continua.

## 5. Orden de pruebas

### 5.1 Antes de exportar a Android

- Análisis de sintaxis y carga del proyecto con la versión exacta de Godot.
- Pruebas de contratos y serialización.
- Pruebas de identidad e IDs estables.
- Validación de comandos, precondiciones, idempotencia y rechazo de operaciones inválidas.
- Pruebas de eventos confirmados y proyecciones.
- Pruebas de snapshot, journal, recuperación y respaldo.
- Pruebas deterministas con semilla fija.
- Pruebas de migración de esquema cuando se introduzcan versiones nuevas.

### 5.2 En Android

- Inicio limpio y cierre normal.
- Suspensión y reanudación desde segundo plano.
- Cierre forzado del proceso y recuperación.
- Poco espacio disponible y errores de escritura simulados cuando sea posible.
- Persistencia después de reiniciar el teléfono.
- Medición de memoria, tiempo de inicio, duración de guardado y recuperación.
- Pruebas de entrada y orientación según el diseño de producto aprobado.
- Prueba prolongada para detectar degradación, bloqueos y calentamiento.

### 5.3 En PC, cuando sea posible

- Perfilado de CPU y memoria en simulaciones largas.
- Diagnóstico ampliado de errores y volcados.
- Ejecución acelerada de escenarios grandes.
- Comparación de renderizadores y herramientas de inspección.

Las pruebas en PC no sustituyen las pruebas Android; las complementan.

## 6. Política de evidencias

No se declarará una función como implementada solo porque exista código o una escena.

Cada afirmación de validación debe indicar:

- versión/commit probado;
- versión exacta de Godot;
- entorno y dispositivo;
- comando o procedimiento de prueba;
- resultado observado;
- registros o artefactos disponibles;
- limitaciones conocidas.

Una captura se etiquetará como **captura real** solo si procede de una ejecución identificable del proyecto. Un mockup, un render, una imagen generada o una composición conceptual nunca se presentará como captura de gameplay.

## 7. Uso del editor Android

El editor Android de Godot puede utilizarse para abrir, editar, ejecutar y exportar proyectos. Sin embargo, su estado de acceso anticipado y las limitaciones de interfaz táctil impiden tratarlo como sustituto perfecto del escritorio. Se recomienda teclado y ratón Bluetooth si el usuario decide editar directamente en el teléfono.

No es obligatorio instalar el editor Android para seguir desarrollando mediante archivos y CI. Si se usa, deberá ser Godot 4.7.2 Standard para mantener correspondencia con el proyecto.

## 8. Límites de esta decisión

- Un APK que instala no demuestra que todos los sistemas del mundo funcionen.
- Una prueba unitaria no demuestra rendimiento en el teléfono.
- Una simulación headless no demuestra calidad visual.
- Una captura de pantalla solo demuestra el estado visible en ese instante; no demuestra causalidad ni persistencia.
- Un PC puede ser necesario más adelante para diagnóstico/perfilado profundo, pero no se bloqueará el avance inicial por no disponer de uno.

## 9. Criterio de aceptación del flujo

El flujo estará validado cuando una versión identificada del proyecto pueda:

1. superar las pruebas automatizadas en CI;
2. producir un APK Debug reproducible;
3. instalarse y ejecutarse en el dispositivo Android de referencia;
4. guardar estado, cerrar o ser terminada por el sistema;
5. reabrirse y recuperar identidad, `world_tick`, eventos y estado sin duplicaciones ni pérdidas;
6. entregar registros suficientes para diagnosticar un fallo.

---

**Nota de implementación:** este ADR organiza el proceso de trabajo. No sustituye los requisitos funcionales de SR-01 a SR-15 ni certifica que WLA-0A ya haya superado sus pruebas.
